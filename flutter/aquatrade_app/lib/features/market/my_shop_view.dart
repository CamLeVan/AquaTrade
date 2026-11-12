import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/order_model.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/status_chip.dart';
import 'widgets/managed_product_card.dart';
import 'widgets/order_card.dart';
import 'widgets/shop_stat_card.dart';

/// Nội dung tab "Gian hàng của tôi" khi người dùng ĐÃ có gian hàng (role Seller).
/// Gồm 2 sub-tab: Đơn hàng (bán) và Sản phẩm (quản lý kho + giá).
class MyShopView extends StatefulWidget {
  const MyShopView({super.key});

  @override
  State<MyShopView> createState() => _MyShopViewState();
}

class _MyShopViewState extends State<MyShopView> {
  int _tab = 0; // 0 Đơn hàng, 1 Sản phẩm

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // my-listings: gồm cả PENDING_REVIEW (public ?sellerId= chỉ AVAILABLE).
      context.read<ListingProvider>().fetchSellerListings();
      context.read<OrderProvider>().fetchMyOrders(isSeller: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _innerTabs(),
        const SizedBox(height: AppSpacing.lg),
        if (_tab == 0) ..._ordersTab() else ..._productsTab(),
      ],
    );
  }

  // ---- Inner tab bar ----
  Widget _innerTabs() {
    final sellerOrders = context.watch<OrderProvider>().orders;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
      ),
      child: Row(
        children: [
          _tabButton('Đơn hàng', 0, badge: sellerOrders.isNotEmpty ? '${sellerOrders.length}' : null),
          const SizedBox(width: AppSpacing.lg),
          _tabButton('Sản phẩm', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, {String? badge}) {
    final active = _tab == index;
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(label,
                    style: AppTypography.itemTitle
                        .copyWith(fontSize: 14, height: 20 / 14, color: color)),
                if (badge != null)
                  Positioned(
                    right: -18,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(badge,
                          style: AppTypography.chip.copyWith(
                              fontSize: 9, height: 13 / 9, color: AppColors.onDark)),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 2,
            width: 56,
            color: active ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // ---- Tab Đơn hàng ----
  List<Widget> _ordersTab() {
    final orderState = context.watch<OrderProvider>();
    final sellerOrders = orderState.orders;
    final pendingCount = sellerOrders.where((o) => o.status == OrderStatus.PENDING).length;
    final totalRevenue = sellerOrders
        .where((o) => o.status == OrderStatus.COMPLETED)
        .fold<double>(0, (sum, o) => sum + o.totalPrice);

    return [
      ShopStatCard(
        label: 'Tổng đơn hàng',
        value: '${sellerOrders.length}',
        trailing: _pill('Cập nhật mới', AppColors.primary10, AppColors.primary),
      ),
      const SizedBox(height: AppSpacing.md),
      ShopStatCard(
        label: 'Chờ xác nhận',
        value: '$pendingCount',
        valueColor: pendingCount > 0 ? AppColors.error : AppColors.textPrimary,
        trailing: _pill(pendingCount > 0 ? 'Ưu tiên' : 'Bình thường',
            pendingCount > 0 ? AppColors.error : AppColors.infoBg,
            pendingCount > 0 ? AppColors.onDark : AppColors.textPrimary,
            square: true, upper: true),
      ),
      const SizedBox(height: AppSpacing.md),
      ShopStatCard(
        label: 'Doanh thu',
        value: AppFormatters.formatCurrency(totalRevenue),
        unit: '',
        trailing: const Icon(Icons.insights, color: AppColors.primary),
      ),
      const SizedBox(height: AppSpacing.lg),
      _sectionHeader('Quản lý đơn hàng', actions: true),
      const SizedBox(height: AppSpacing.md),
      if (sellerOrders.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              const Icon(Icons.inbox, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Gian hàng của bạn chưa có đơn hàng nào.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      else
        for (final o in sellerOrders) ...[
          OrderCard(
            orderCode: '#${o.id.substring(0, o.id.length > 8 ? 8 : o.id.length)}',
            customer: o.buyerName.isNotEmpty ? o.buyerName : 'Người mua sỉ',
            status: _orderStatusLabel(o.status),
            statusType: o.status == OrderStatus.COMPLETED
                ? StatusChipType.success
                : o.status == OrderStatus.PENDING
                    ? StatusChipType.error
                    : StatusChipType.tertiary,
            statusPulse: o.status == OrderStatus.PENDING,
            timeAgo:
                '${o.createdAt.hour.toString().padLeft(2, '0')}:${o.createdAt.minute.toString().padLeft(2, '0')} ${o.createdAt.day.toString().padLeft(2, '0')}/${o.createdAt.month.toString().padLeft(2, '0')}/${o.createdAt.year}',
            productName: o.listingTitle,
            quantity: '${o.finalQuantity} sản phẩm',
            price: AppFormatters.formatCurrency(o.totalPrice),
            actionLabel: 'Chi tiết đơn',
            actionPrimary: true,
            assetPath: null,
            onDetail: () => context.push(AppRoutes.orderDetailPath(o.id)),
            onAction: () => context.push(AppRoutes.orderDetailPath(o.id)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
    ];
  }

  String _orderStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return 'Chờ xác nhận';
      case OrderStatus.ESCROW_LOCKED:
        return 'Đã khóa ký quỹ';
      case OrderStatus.IN_VIDEO_CALL:
        return 'Đang gọi video';
      case OrderStatus.COUNTING_AI:
        return 'Đang đếm AI';
      case OrderStatus.PENDING_ADMIN_REVIEW:
        return 'Chờ admin duyệt';
      case OrderStatus.PREPARING:
        return 'Đang chuẩn bị';
      case OrderStatus.SHIPPING:
        return 'Đang giao';
      case OrderStatus.DELIVERED:
        return 'Đã giao';
      case OrderStatus.AI_VERIFIED:
        return 'AI đã xác minh';
      case OrderStatus.READY_TO_PAYOUT:
        return 'Chờ chi trả';
      case OrderStatus.COMPLETED:
        return 'Hoàn thành';
      case OrderStatus.DISPUTED:
        return 'Tranh chấp';
      case OrderStatus.CANCELLED:
        return 'Đã hủy';
    }
  }

  // ---- Tab Sản phẩm ----
  List<Widget> _productsTab() {
    final listingState = context.watch<ListingProvider>();
    final sellerListings = listingState.sellerListings;
    final pendingListings = sellerListings.where((l) => l.status == ListingStatus.PENDING_REVIEW).length;

    return [
      ShopStatCard(
        label: 'Tổng sản phẩm',
        value: '${sellerListings.length}',
        trailing: _pill('Hoạt động', AppColors.primary10, AppColors.primary),
      ),
      const SizedBox(height: AppSpacing.md),
      ShopStatCard(
        label: 'Chờ duyệt',
        value: '$pendingListings',
        trailing: _pill('Đang xử lý', AppColors.infoBg, AppColors.tertiary),
      ),
      const SizedBox(height: AppSpacing.lg),
      _sectionIconHeader(Icons.inventory_2, 'Danh sách sản phẩm đã đăng'),
      const SizedBox(height: AppSpacing.md),
      if (sellerListings.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            children: [
              const Icon(Icons.storefront, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bạn chưa có sản phẩm nào trong gian hàng.\nHãy bấm "ĐĂNG BÁN THỦY SẢN" để đăng sản phẩm mới!',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      else
        for (final l in sellerListings) ...[
          ManagedProductCard(
            name: l.title,
            stock: '${l.estimatedQuantity} ${l.category == ListingCategory.CA ? 'con' : 'kg'}',
            price: AppFormatters.formatCurrency(l.pricePerFish),
            statusLabel: l.status == ListingStatus.AVAILABLE
                ? 'Đang hiển thị'
                : l.status == ListingStatus.PENDING_REVIEW
                    ? 'Chờ duyệt'
                    : 'Đã ẩn',
            assetPath: null,
            imageUrl: l.thumbnailUrl.isNotEmpty
                ? l.thumbnailUrl
                : (l.imageUrls.isNotEmpty ? l.imageUrls.first : null),
            onEdit: () async {
              await context.push(AppRoutes.createListing, extra: l);
              if (mounted) {
                context.read<ListingProvider>().fetchSellerListings();
              }
            },
            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  title: Text('Xác nhận xóa', style: AppTypography.sectionTitle),
                  content: Text(
                    'Bạn có chắc chắn muốn xóa sản phẩm "${l.title}" không?',
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
                  await context.read<ListingProvider>().deleteListing(l.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa sản phẩm thành công!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
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
          ),
          const SizedBox(height: AppSpacing.md),
        ],
    ];
  }

  // ---- Helpers ----
  Widget _sectionHeader(String title, {bool actions = false}) {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTypography.cardValue
                  .copyWith(fontSize: 20, letterSpacing: -0.5)),
          if (actions)
            Row(
              children: [
                _iconBtn(Icons.filter_list),
                const SizedBox(width: AppSpacing.xs),
                _iconBtn(Icons.search),
              ],
            ),
        ],
      ),
    );
  }

  Widget _sectionIconHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(title.toUpperCase(),
            style: AppTypography.sectionTitle.copyWith(fontSize: 14)),
      ],
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    );
  }

  Widget _pill(String text, Color bg, Color fg,
      {bool square = false, bool upper = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: square ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(square ? AppSpacing.radiusSm : 999),
      ),
      child: Text(upper ? text.toUpperCase() : text,
          style: AppTypography.chip.copyWith(
              fontSize: upper ? 9 : 12, height: 1.4, color: fg)),
    );
  }
}
