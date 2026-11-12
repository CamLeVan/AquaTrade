import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_smart_image.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import 'ai_scan_eligibility.dart';

/// Đếm AI theo đơn: pick video → Cloudinary → start-ai → poll đến DONE.
/// Nút mẻ mới bị khóa khi còn proof PENDING (tránh race job_{orderId}.json).
class AiOrderCountScreen extends StatefulWidget {
  const AiOrderCountScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<AiOrderCountScreen> createState() => _AiOrderCountScreenState();
}

class _AiOrderCountScreenState extends State<AiOrderCountScreen> {
  final _picker = ImagePicker();
  Timer? _pollTimer;
  bool _uploading = false;
  bool _starting = false;
  String? _statusMessage;
  final List<String> _pickedPaths = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<OrderProvider>().fetchOrderById(widget.orderId);
    if (!mounted) return;
    final order = context.read<OrderProvider>().currentOrder;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (order != null) {
      final role = proofRoleForUser(order, userId);
      final pendingCount = proofsForRole(order, role).where((p) => p.status == 'PENDING').length;
      if (pendingCount > 0) {
        setState(() {
          _statusMessage = 'Đang chờ AI hoàn tất xử lý $pendingCount mẻ cá...';
        });
        _startPolling();
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        await context.read<OrderProvider>().fetchOrderById(widget.orderId);
      } catch (_) {
        return;
      }
      if (!mounted) return;
      final order = context.read<OrderProvider>().currentOrder;
      if (order == null) return;
      final userId = context.read<AuthProvider>().currentUser?.id ?? '';
      final role = proofRoleForUser(order, userId);
      if (!hasPendingProofForRole(order, role)) {
        _pollTimer?.cancel();
        _pollTimer = null;
        final latest = proofsForRole(order, role).isNotEmpty
            ? proofsForRole(order, role).last
            : null;
        setState(() {
          if (latest?.status == 'FAILED') {
            _statusMessage =
                'Mẻ thất bại: ${latest!.errorMessage.isNotEmpty ? latest.errorMessage : 'AI không xử lý được video'}';
          } else if (latest?.status == 'SUCCESS') {
            _statusMessage =
                'Mẻ "${latest!.batchName}" xong — đếm được ${latest.aiFishCount} con.';
          } else {
            _statusMessage = 'Đã cập nhật kết quả AI.';
          }
        });
      } else {
        setState(() {
          _statusMessage = 'Đang chờ AI hoàn tất xử lý các mẻ cá...';
        });
      }
    });
  }

  /// Khóa nút khi đang upload/start.
  bool _canStartNewBatch(OrderModel? order, String userId) {
    if (order == null || _uploading || _starting) return false;
    return true;
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final sourceFile = File(file.path);
    if (!await sourceFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đọc file video đã chọn.')),
      );
      return;
    }
    
    // Copy sang Directory.systemTemp với tên duy nhất để tránh Android ImagePicker xoá file cache khi chọn nhiều video
    final tempDir = Directory.systemTemp;
    final targetPath = '${tempDir.path}/aquatrade_vid_${DateTime.now().millisecondsSinceEpoch}_${_pickedPaths.length}.mp4';
    final copiedFile = await sourceFile.copy(targetPath);

    setState(() {
      if (!_pickedPaths.contains(copiedFile.path)) {
        _pickedPaths.add(copiedFile.path);
      }
      _statusMessage = 'Đã chọn ${_pickedPaths.length} video mẻ cá — bấm bắt đầu quét.';
    });
  }

  void _removePickedVideo(int index) {
    setState(() {
      if (index >= 0 && index < _pickedPaths.length) {
        final pathToRemove = _pickedPaths.removeAt(index);
        try {
          File(pathToRemove).delete();
        } catch (_) {}
      }
    });
  }

  Future<void> _startBatch() async {
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    final order = orders.currentOrder;
    final userId = auth.currentUser?.id ?? '';
    if (!_canStartNewBatch(order, userId)) {
      return;
    }
    if (_pickedPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn video mẻ cá trước')),
      );
      return;
    }

    final role = proofRoleForUser(order!, userId);
    final remaining = remainingQuantity(order, role);

    if (remaining <= 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tổng AI đã đủ số lượng'),
          content: Text(
            'Hệ thống ghi nhận đã đếm đủ ${sumSuccessfulCounts(order, role)}/${order.finalQuantity} con. Bạn vẫn muốn đếm thêm mẻ nữa để bổ sung bằng chứng?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đồng ý đếm mẻ mới'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final pathsToUpload = List<String>.from(_pickedPaths);
    setState(() {
      _uploading = true;
      _statusMessage = 'Đang tải ${pathsToUpload.length} video lên Cloudinary...';
    });

    try {
      int successCount = 0;
      for (int i = 0; i < pathsToUpload.length; i++) {
        final videoPath = pathsToUpload[i];
        final videoFile = File(videoPath);
        if (!await videoFile.exists()) {
          throw Exception('File video mẻ ${i + 1} không tồn tại hoặc đã bị bộ nhớ tạm xóa. Vui lòng chọn lại.');
        }

        final currentOrder = orders.currentOrder ?? order;
        final currentRoleProofs = proofsForRole(currentOrder, role);
        final batchName = 'Mẻ ${currentRoleProofs.length + 1}';

        setState(() {
          _statusMessage = 'Đang tải mẻ ${i + 1}/${pathsToUpload.length} lên Cloudinary...';
        });

        final upload = await orders.uploadAiVideo(videoFile);
        if (!mounted) return;

        setState(() {
          _uploading = false;
          _starting = true;
          _statusMessage = 'Đang gửi mẻ ${i + 1}/${pathsToUpload.length} sang AI...';
        });

        final currentRemaining = remainingQuantity(orders.currentOrder ?? order, role);
        await orders.startAiAnalysis(
          orderId: widget.orderId,
          videoUrl: upload.videoUrl,
          videoPublicId: upload.videoPublicId,
          batchName: batchName,
          expectedQuantity: currentRemaining > 0 ? currentRemaining : null,
        );
        successCount++;
      }

      if (!mounted) return;
      setState(() {
        _starting = false;
        _pickedPaths.clear();
        _statusMessage = 'Đã gửi thành công $successCount mẻ cá sang bộ phận AI đếm song song!';
      });
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _starting = false;
        _statusMessage = 'Lỗi gửi mẻ: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmAndSendToBuyer() async {
    final orders = context.read<OrderProvider>();
    try {
      await orders.updateOrderStatus(widget.orderId, OrderStatus.AI_VERIFIED);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chốt bằng chứng đếm AI và chuyển đến Người mua thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chốt bằng chứng: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Đếm AI theo đơn',
          centerTitle: true,
        ),
        body: AuthGateView(
          reason: LoginReasons.ai,
          from: AppRoutes.aiScanOrderPath(widget.orderId),
          title: 'Đăng nhập để quét AI',
        ),
      );
    }

    final orders = context.watch<OrderProvider>();
    final order = orders.currentOrder;
    final userId = auth.currentUser?.id ?? '';
    final loadingDetail = orders.isLoading && order?.id != widget.orderId;
    final canStart = _canStartNewBatch(
      order?.id == widget.orderId ? order : null,
      userId,
    );
    final role = order != null ? proofRoleForUser(order, userId) : 'SELLER';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Đếm AI theo đơn',
        centerTitle: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.aiScanOrders);
          }
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: _uploading
                    ? 'Đang upload video...'
                    : _starting
                        ? 'Đang gửi AI đếm...'
                        : (_pickedPaths.length > 1
                            ? 'BẮT ĐẦU QUÉT ${_pickedPaths.length} MẺ ĐÃ CHỌN'
                            : 'BẮT ĐẦU QUÉT MẺ CÁ'),
                leadingIcon: Icons.play_circle_outline,
                onPressed: canStart && _pickedPaths.isNotEmpty ? _startBatch : null,
              ),
              if (order != null && successfulProofsForRole(order, role).isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'CHỐT BẰNG CHỨNG AI & CHUYỂN NGƯỜI MUA',
                  leadingIcon: Icons.check_circle,
                  variant: AppButtonVariant.primary,
                  onPressed: _confirmAndSendToBuyer,
                ),
              ],
            ],
          ),
        ),
      ),
      body: loadingDetail && order == null
          ? const Center(child: CircularProgressIndicator())
          : order == null || order.id != widget.orderId
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          orders.error.isNotEmpty
                              ? orders.error
                              : 'Không tìm thấy đơn hàng',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(label: 'Tải lại', onPressed: _refresh),
                      ],
                    ),
                  ),
                )
              : _buildContent(order, userId, canStart),
    );
  }

  Widget _buildContent(OrderModel order, String userId, bool canStart) {
    final role = proofRoleForUser(order, userId);
    final roleProofs = proofsForRole(order, role);
    final successProofs = successfulProofsForRole(order, role);
    final counted = role == 'SELLER'
        ? (order.sellerAiTotalCount > 0
            ? order.sellerAiTotalCount
            : sumSuccessfulCounts(order, role))
        : (order.buyerAiTotalCount > 0
            ? order.buyerAiTotalCount
            : sumSuccessfulCounts(order, role));
    final expected = expectedQuantity(order);
    final remaining = remainingQuantity(order, role);
    final pending = hasPendingProofForRole(order, role);
    final progress = expected > 0 ? (counted / expected).clamp(0.0, 1.0) : 0.0;
    final isTargetReached = expected > 0 && counted >= expected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: [
        // --- 1. HERO PROGRESS CARD ---
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isTargetReached
                  ? Colors.green.shade400
                  : AppColors.borderFaint,
              width: isTargetReached ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isTargetReached ? Colors.green : AppColors.primary)
                    .withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.listingTitle.isNotEmpty
                              ? order.listingTitle
                              : 'Đơn hàng AquaTrade',
                          style: AppTypography.itemTitle.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vai trò: ${role == 'SELLER' ? 'Người bán (Seller)' : 'Người mua (Buyer)'}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isTargetReached ? Colors.green : AppColors.primary)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      isTargetReached ? 'ĐÃ ĐẠT CHỈ TIÊU' : 'ĐANG ĐẾM AI',
                      style: AppTypography.chip.copyWith(
                        color: isTargetReached
                            ? Colors.green.shade700
                            : AppColors.onPrimaryDeep,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ đếm tổng',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$counted / $expected con (${(progress * 100).toInt()}%)',
                        style: AppTypography.chip.copyWith(
                          color: isTargetReached
                              ? Colors.green.shade700
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isTargetReached
                            ? Colors.green.shade600
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.borderFaint),
              const SizedBox(height: AppSpacing.md),
              // Quick Metrics Grid
              Row(
                children: [
                  _metricTile('Chỉ tiêu đơn', '$expected con', Icons.assignment_outlined),
                  _metricTile('AI Đã đếm', '$counted con', Icons.smart_toy_outlined, color: isTargetReached ? Colors.green.shade700 : null),
                  _metricTile('Còn lại', '$remaining con', Icons.pending_actions_outlined),
                ],
              ),
              if (pending) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Hệ thống AI đang đếm mẻ cá mới ngầm...',
                        style: AppTypography.chip
                            .copyWith(color: AppColors.onPrimaryDeep),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        if (_statusMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _statusMessage!,
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // --- 2. VIDEO DROPZONE (MULTI-VIDEO SUPPORT) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TẢI VIDEO MẺ CÁ MỚI',
              style: AppTypography.chip.copyWith(
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            if (_pickedPaths.isNotEmpty)
              Text(
                'Đã chọn ${_pickedPaths.length} video',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: canStart ? _pickVideo : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: _pickedPaths.isNotEmpty ? AppColors.primary : AppColors.borderFaint,
                width: _pickedPaths.isNotEmpty ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _pickedPaths.isNotEmpty ? Icons.video_library : Icons.video_call_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedPaths.isNotEmpty
                            ? 'Chạm để thêm video mẻ nữa (${_pickedPaths.length} đã chọn)'
                            : 'Chạm để chọn Video mẻ cá mới',
                        style: AppTypography.itemTitle.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _pickedPaths.isNotEmpty
                            ? 'Sẵn sàng gửi đếm AI song song'
                            : 'Hỗ trợ chọn nhiều mẻ đếm cùng lúc (.mp4, .mov)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        if (_pickedPaths.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ..._pickedPaths.asMap().entries.map((entry) {
            final idx = entry.key;
            final path = entry.value;
            final fileName = path.split(Platform.pathSeparator).last;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Mẻ cá ${idx + 1}: $fileName',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: () => _removePickedVideo(idx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: AppSpacing.lg),

        // --- 3. RECORDED BATCHES TIMELINE ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CÁC MẺ ĐÃ ĐẾM',
              style: AppTypography.chip.copyWith(
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${successProofs.length} mẻ thành công',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (roleProofs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Chưa có mẻ nào được đếm. Hãy chọn video và bắt đầu quét.',
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...roleProofs.reversed.map((p) {
            final isSuccess = p.status == 'SUCCESS';
            final isFailed = p.status == 'FAILED';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderFaint),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (p.aiImageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: AppSmartImage(imageUrl: p.aiImageUrl),
                            ),
                          )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: const Icon(Icons.analytics_outlined, color: AppColors.textMuted),
                          ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.batchName.isNotEmpty ? p.batchName : 'Mẻ ${p.batchIndex}',
                                style: AppTypography.itemTitle.copyWith(fontSize: 14),
                              ),
                              Text(
                                isSuccess
                                    ? '+${p.aiFishCount} con cá'
                                    : (isFailed ? (p.errorMessage.isNotEmpty ? p.errorMessage : 'Thất bại') : 'Đang đếm AI...'),
                                style: AppTypography.caption.copyWith(
                                  color: isSuccess
                                      ? Colors.green.shade700
                                      : (isFailed ? Colors.red : AppColors.textSecondary),
                                  fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isSuccess ? Colors.green : (isFailed ? Colors.red : AppColors.infoBg)).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSuccess ? 'THÀNH CÔNG' : (isFailed ? 'LỖI' : 'ĐANG ĐẾM'),
                            style: AppTypography.chip.copyWith(
                              color: isSuccess ? Colors.green.shade700 : (isFailed ? Colors.red : AppColors.onPrimaryDeep),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isSuccess && p.proofHash.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'SHA-256: ${p.proofHash}',
                                style: AppTypography.caption.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _metricTile(String label, String value, IconData icon, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.itemTitle.copyWith(
              fontSize: 13,
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
