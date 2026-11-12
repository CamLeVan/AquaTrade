import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_smart_image.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../../widgets/status_chip.dart';
import '../orders/widgets/order_history_card.dart';
import '../../core/router/app_routes.dart';
import '../auth/auth_navigation.dart';

import '../../providers/chat_provider.dart';
import '../../shared_providers/role_provider.dart';

/// Chi tiết đơn theo `orderId` — `GET /orders/{id}`.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.orderId.isEmpty) return;
      if (!context.read<AuthProvider>().isAuthenticated) return;
      context.read<OrderProvider>().fetchOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Chi tiết đơn hàng',
          centerTitle: true,
        ),
        body: AuthGateView(
          reason: LoginReasons.orders,
          from: AppRoutes.orderDetailPath(widget.orderId),
          title: 'Đăng nhập để xem đơn hàng',
        ),
      );
    }

    final role = context.watch<RoleProvider>().currentRole;
    final isSeller = role == UserRole.seller;

    final orders = context.watch<OrderProvider>();
    final order = orders.currentOrder;
    final loading = orders.isLoading && order == null;
    final missingId = widget.orderId.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Chi tiết đơn hàng',
        centerTitle: true,
        trailing: order != null
            ? PressableScale(
                onTap: () {
                  final convId = context.read<ChatProvider>().startConversationWithOrder(
                    order: order,
                    currentUserId: auth.currentUser?.id ?? '',
                    isSeller: isSeller,
                  );
                  context.push('/chat/detail/$convId');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.primary30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Chat',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: missingId
          ? Center(
              child: Text(
                'Thiếu mã đơn hàng',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          : loading
              ? const Center(child: CircularProgressIndicator())
              : order == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          orders.error.isNotEmpty
                              ? 'Không tải được đơn: ${orders.error}'
                              : 'Không tìm thấy đơn hàng',
                          textAlign: TextAlign.center,
                          style: AppTypography.body
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<OrderProvider>().fetchOrderById(widget.orderId),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                        children: [
                          _statusCard(order),
                          const SizedBox(height: AppSpacing.md),
                          _actionsCard(order, isSeller),
                          const SizedBox(height: AppSpacing.md),
                          if (order.proofs.isNotEmpty) ...[
                            _aiProofsCard(order),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          _infoCard(order, isSeller),
                          const SizedBox(height: AppSpacing.md),
                          _productCard(order),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: 'Làm mới dữ liệu',
                            leadingIcon: Icons.refresh,
                            onPressed: () => context
                                .read<OrderProvider>()
                                .fetchOrderById(widget.orderId),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _statusCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TRẠNG THÁI HIỆN TẠI',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: order.status.historyLabel,
                type: order.status.historyChipType,
                showDot: order.status.historyShowDot,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.status.historyLabel,
            style: AppTypography.heading.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mã đơn: #${order.id}',
            style: AppTypography.caption.copyWith(fontSize: 12),
          ),
          Text(
            'Thời gian tạo: ${AppFormatters.formatDate(order.createdAt)}',
            style: AppTypography.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard(OrderModel order, bool isSeller) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSeller ? Icons.storefront : Icons.person_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isSeller ? 'THAO TÁC NGƯỜI BÁN' : 'THAO TÁC NGƯỜI MUA',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isSeller
                ? 'Bạn có thể quay video mẻ cá để AI kiểm định số lượng, hoặc cập nhật trạng thái đơn hàng.'
                : 'Bạn có thể xác nhận đã nhận đủ cá để giải ngân Escrow, dùng AI đối soát hoặc tạo khiếu nại.',
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (isSeller) ...[
            AppButton(
              label: 'Kiểm định mẻ cá bằng AI',
              icon: Icons.memory,
              onPressed: () => context.push(AppRoutes.aiScanOrderPath(order.id)),
            ),
            if (order.status == OrderStatus.AI_VERIFIED || order.status == OrderStatus.PREPARING) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Bàn giao Shipper (Đang giao)',
                variant: AppButtonVariant.secondary,
                icon: Icons.local_shipping_outlined,
                onPressed: () async {
                  await context.read<OrderProvider>().updateOrderStatus(order.id, OrderStatus.SHIPPING);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật trạng thái: ĐANG GIAO HÀNG'), backgroundColor: Colors.green),
                    );
                  }
                },
              ),
            ],
          ] else ...[
            if (order.status == OrderStatus.DELIVERED ||
                order.status == OrderStatus.AI_VERIFIED ||
                order.status == OrderStatus.SHIPPING ||
                order.status == OrderStatus.PREPARING ||
                order.status == OrderStatus.ESCROW_LOCKED) ...[
              AppButton(
                label: 'Xác nhận đã nhận đủ hàng',
                icon: Icons.check_circle_outline,
                onPressed: () => _confirmReceiptDialog(order),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              label: 'Nghiệm thu / Đếm AI đối soát (Tùy chọn)',
              variant: AppButtonVariant.secondary,
              icon: Icons.videocam_outlined,
              onPressed: () => context.push(AppRoutes.aiScanOrderPath(order.id)),
            ),
            const SizedBox(height: AppSpacing.sm),
            PressableScale(
              onTap: () => _showDisputeDialog(order),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                alignment: Alignment.center,
                child: Text(
                  'Gửi khiếu nại / Tranh chấp đơn hàng',
                  style: AppTypography.chip.copyWith(
                    color: AppColors.error,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiProofsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.cyan.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, size: 18, color: Colors.cyan),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'BẰNG CHỨNG SỐ HỌC (PROOFS)',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 1.0,
                    color: Colors.cyan.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${order.proofs.length} mẻ đếm',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyan.shade900),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final proof in order.proofs) ...[
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.borderFaint),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppSmartImage(
                      imageUrl: proof.aiImageUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proof.batchName.isNotEmpty ? proof.batchName : 'Mẻ #${proof.batchIndex}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'AI đếm: ${proof.aiFishCount} con | Vai trò: ${proof.proofRole}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                        if (proof.proofHash.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '🔒 SHA-256: ${proof.proofHash.length > 12 ? proof.proofHash.substring(0, 12) : proof.proofHash}...',
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmReceiptDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận nhận đủ hàng'),
        content: const Text(
          'Bạn xác nhận cá giống đã giao đủ số lượng và khỏe mạnh? '
          'Hệ thống sẽ cập nhật đơn hàng và báo Admin giải ngân tiền Escrow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await context.read<OrderProvider>().confirmCompletion(order.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xác nhận nhận đủ hàng! Đơn sẵn sàng chờ Admin giải ngân.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Xác nhận nhận hàng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(OrderModel order) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khiếu nại / Báo cáo sự cố'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập lý do khiếu nại (VD: Hao hụt cá vượt mức, cá chết khi giao...):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Mô tả chi tiết sự cố...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await context.read<OrderProvider>().raiseDispute(orderId: order.id, reason: reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi khiếu nại thành công! Admin sẽ tiến hành phán xử.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi gửi khiếu nại: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Gửi khiếu nại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(OrderModel order, bool isSeller) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin chi tiết giao dịch',
              style: AppTypography.itemTitle.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          _kv('Người bán', order.sellerName.isNotEmpty ? order.sellerName : '—'),
          _kv('Người mua', order.buyerName.isNotEmpty ? order.buyerName : '—'),
          _kv(
            'Địa chỉ giao',
            order.shippingAddress.isNotEmpty ? order.shippingAddress : '—',
          ),
          _kv('Số lượng chốt', '${order.finalQuantity} con'),
          _kv('Đơn giá', AppFormatters.formatCurrency(order.unitPriceAtPurchase)),
          _kv('Tổng Escrow', AppFormatters.formatCurrency(order.totalPrice)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(v, style: AppTypography.itemTitle.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _productCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sản phẩm thủy sản',
              style: AppTypography.itemTitle.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            order.listingTitle.isNotEmpty
                ? order.listingTitle
                : 'Thủy sản AquaTrade',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Đơn hàng được bảo hộ ký quỹ Escrow tự động và nghiệm thu số lượng bằng công nghệ AI.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

