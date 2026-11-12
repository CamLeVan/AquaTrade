import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_top_bar.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/chat_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../data/models/listing_model.dart';
import '../auth/auth_navigation.dart';
import 'widgets/ai_analysis_panel.dart';
import 'widgets/product_bottom_bar.dart';
import '../../widgets/app_smart_image.dart';

/// Chi tiết sản phẩm — bind `GET /listings/{id}` (không hardcode Figma).
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, this.listingId});

  final String? listingId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _tab = 0; // 0 Thông số, 1 Phân tích AI, 2 Mô tả
  ListingModel? _listing;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null && widget.listingId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
    }
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final detail =
        await context.read<ListingProvider>().fetchListingDetail(widget.listingId!);
    if (!mounted) return;
    setState(() {
      _listing = detail;
      _loading = false;
      if (detail == null) {
        _error = context.read<ListingProvider>().errorMessage.isNotEmpty
            ? context.read<ListingProvider>().errorMessage
            : 'Không tải được sản phẩm';
      }
    });
  }

  String? get _imageUrl {
    final l = _listing;
    if (l == null) return null;
    if (l.thumbnailUrl.isNotEmpty) return l.thumbnailUrl;
    if (l.imageUrls.isNotEmpty) return l.imageUrls.first;
    return null;
  }

  String get _qualityBadge {
    final l = _listing;
    if (l == null) return '';
    if (l.qualityLabel.trim().isNotEmpty) return l.qualityLabel.trim().toUpperCase();
    if (l.aiVerified) return 'AI ĐÃ XÁC MINH';
    return 'CHƯA CÓ AI';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.listingId != null &&
        widget.listingId!.isNotEmpty &&
        _listing == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Chi tiết sản phẩm',
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              _error ?? 'Không tìm thấy sản phẩm',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final listing = _listing;

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.subPage(
        title: 'Chi tiết sản phẩm',
        centerTitle: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (listing != null &&
                (context.watch<AuthProvider>().currentUser?.id == listing.sellerId ||
                 context.watch<RoleProvider>().currentRole == UserRole.admin ||
                 context.watch<AuthProvider>().currentUser?.role.name == 'ADMIN')) ...[
              PressableScale(
                onTap: () async {
                  await context.push(AppRoutes.createListing, extra: listing);
                  if (mounted) {
                    _fetchDetail();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Sửa',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PressableScale(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      title: Text('Xác nhận xóa', style: AppTypography.sectionTitle),
                      content: Text(
                        'Bạn có chắc chắn muốn xóa sản phẩm "${listing.title}" không?',
                        style: AppTypography.body,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('HỦY', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('XÓA NGAY', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    try {
                      await context.read<ListingProvider>().deleteListing(listing.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xóa sản phẩm thành công!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                        context.pop();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Lỗi xóa sản phẩm: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        'Xóa',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            PressableScale(
              onTap: () {},
              child: const SizedBox(
                width: 36,
                child: Icon(Icons.share_outlined,
                    size: 20, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ProductBottomBar(
        unitPrice: listing?.pricePerFish ?? 0,
        onNegotiate: () {
          final auth = context.read<AuthProvider>();
          if (!auth.isAuthenticated) {
            final from = listing != null
                ? AppRoutes.productOf(listing.id)
                : AppRoutes.product;
            goLoginRequired(
              context,
              from: from,
              reason: LoginReasons.chat,
            );
            return;
          }
          if (listing == null) return;
          
          final user = auth.currentUser;
          final convId = context.read<ChatProvider>().startConversationWithSeller(
            listing: listing,
            currentUserId: user?.id ?? 'buyer_me',
            currentUserName: user?.fullName.trim().isNotEmpty == true
                ? user!.fullName.trim()
                : 'Người mua',
          );
          context.push('/chat/detail/$convId');
        },
        onAddToCart: (selectedQuantity) async {
          final auth = context.read<AuthProvider>();
          final from = listing != null
              ? AppRoutes.productOf(listing.id)
              : AppRoutes.product;
          if (!auth.isAuthenticated) {
            goLoginRequired(
              context,
              from: from,
              reason: LoginReasons.cart,
            );
            return;
          }
          if (listing == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Chưa có dữ liệu sản phẩm để thêm giỏ')),
            );
            return;
          }
          final ok = await context
              .read<CartProvider>()
              .addToCart(listing, selectedQuantity);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      ok
                          ? 'Đã thêm $selectedQuantity sản phẩm vào giỏ hàng!'
                          : 'Không thêm được — tin demo không thanh toán được.')),
            );
            if (ok) context.push(AppRoutes.cart);
          }
        },
        onBookmark: () {},
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 61,
        ),
        children: [
          _hero(),
          Transform.translate(
            offset: const Offset(0, -AppSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(listing),
                  const SizedBox(height: AppSpacing.xl),
                  _tabBar(),
                  const SizedBox(height: AppSpacing.lg),
                  switch (_tab) {
                    0 => _specsGrid(listing),
                    1 => const AiAnalysisPanel(),
                    _ => _description(listing),
                  },
                  const SizedBox(height: AppSpacing.lg),
                  _noteCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final url = _imageUrl;
    return SizedBox(
      height: 406,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppSmartImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: _imagePlaceholder(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00F6F8F8), Color(0x00F6F8F8), AppColors.surface],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 6),
              decoration: BoxDecoration(
                color: (_listing?.aiVerified ?? false)
                    ? AppColors.primary
                    : AppColors.textSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (_listing?.aiVerified ?? false)
                        ? Icons.verified
                        : Icons.info_outline,
                    size: 14,
                    color: AppColors.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _qualityBadge,
                    style: AppTypography.chip.copyWith(
                        letterSpacing: 1, color: AppColors.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: AppColors.imagePlaceholder,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.set_meal, size: 56, color: AppColors.primary30),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chưa có ảnh sản phẩm',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(ListingModel? listing) {
    final title = listing?.title.isNotEmpty == true ? listing!.title : 'Sản phẩm';
    final seller =
        listing?.sellerName.isNotEmpty == true ? listing!.sellerName : 'Người bán';
    final priceLabel = listing != null
        ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
            .format(listing.pricePerFish)
        : '—';
    final chip = listing?.qualityLabel.trim().isNotEmpty == true
        ? listing!.qualityLabel.trim().toUpperCase()
        : (listing?.species.isNotEmpty == true
            ? listing!.species.toUpperCase()
            : 'THỦY SẢN');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: AppTypography.heading.copyWith(
                        fontSize: 24,
                        height: 30 / 24,
                        letterSpacing: -0.6,
                        color: AppColors.textStrong)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.primary10,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(chip,
                    style: AppTypography.chip.copyWith(
                        letterSpacing: 1, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(seller,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.itemTitle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ),
                    if (listing?.province.isNotEmpty == true) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text('•',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(listing!.province.toUpperCase(),
                          style: AppTypography.caption
                              .copyWith(letterSpacing: -0.5)),
                    ],
                  ],
                ),
              ),
              if (listing != null &&
                  context.watch<AuthProvider>().currentUser?.id != listing.sellerId)
                PressableScale(
                  onTap: () {
                    final auth = context.read<AuthProvider>();
                    if (!auth.isAuthenticated) {
                      goLoginRequired(
                        context,
                        from: AppRoutes.productOf(listing.id),
                        reason: LoginReasons.chat,
                      );
                      return;
                    }
                    final user = auth.currentUser;
                    final convId = context.read<ChatProvider>().startConversationWithSeller(
                      listing: listing,
                      currentUserId: user?.id ?? 'buyer_me',
                      currentUserName: user?.fullName.trim().isNotEmpty == true
                          ? user!.fullName.trim()
                          : 'Người mua',
                    );
                    context.push('/chat/detail/$convId');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary10,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Chat',
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(priceLabel,
                  style: AppTypography.heading.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      color: AppColors.textStrong)),
              const SizedBox(width: AppSpacing.xxs),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Text('VND / CON',
                    style: AppTypography.sectionTitle
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
      ),
      child: Row(
        children: [
          _tabBtn('THÔNG SỐ', 0),
          const SizedBox(width: AppSpacing.xl),
          _tabBtn('PHÂN TÍCH AI', 1),
          const SizedBox(width: AppSpacing.xl),
          _tabBtn('MÔ TẢ', 2),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      behavior: HitTestBehavior.opaque,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.overline.copyWith(
                  color: active
                      ? AppColors.onPrimaryDeep
                      : AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              height: 2,
              color: active ? AppColors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _specsGrid(ListingModel? listing) {
    final sizeLabel = listing == null
        ? '—'
        : '${AppFormatters.formatNumber(listing.sizeMin)} - ${AppFormatters.formatNumber(listing.sizeMax)} cm';
    final qty = listing == null
        ? '—'
        : '${AppFormatters.formatNumber(listing.availableQuantity > 0 ? listing.availableQuantity : listing.estimatedQuantity)} con';
    final specs = [
      ('KÍCH CỠ', sizeLabel),
      ('XUẤT XỨ', listing?.province.isNotEmpty == true ? listing!.province : '—'),
      ('SỐ LƯỢNG', qty),
      ('LOÀI', listing?.species.isNotEmpty == true ? listing!.species : '—'),
    ];
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _specCard(specs[row * 2])),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _specCard(specs[row * 2 + 1])),
            ],
          ),
        ],
      ],
    );
  }

  Widget _specCard((String, String) spec) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.segmentTrack,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.$1,
              style: AppTypography.caption.copyWith(letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(spec.$2, style: AppTypography.itemTitle.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _description(ListingModel? listing) {
    final text = listing?.description.trim().isNotEmpty == true
        ? listing!.description.trim()
        : 'Chưa có mô tả chi tiết cho sản phẩm này.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: AppTypography.body.copyWith(height: 22 / 14),
        ),
        if (listing?.status == ListingStatus.PENDING_REVIEW) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tin đăng đang chờ duyệt — chưa bán công khai trên Chợ.',
            style: AppTypography.caption.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _noteCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        '* GIÁ TRÊN CHƯA BAO GỒM PHÍ VẬN CHUYỂN VÀ THUẾ VAT. LIÊN HỆ BỘ PHẬN '
        'KINH DOANH ĐỂ NHẬN BÁO GIÁ SỈ CHO SỐ LƯỢNG TRÊN 100 CON.',
        style: AppTypography.caption.copyWith(
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
          height: 16 / 10,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
