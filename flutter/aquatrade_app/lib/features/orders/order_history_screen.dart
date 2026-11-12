import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/order_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../../widgets/status_chip.dart';
import '../auth/auth_navigation.dart';
import 'widgets/order_history_card.dart';

class _OrderRow {
  const _OrderRow({
    required this.filter,
    required this.sellerName,
    required this.statusLabel,
    required this.statusType,
    required this.productName,
    required this.variant,
    required this.quantityLabel,
    required this.unitPriceLabel,
    required this.totalLabel,
    required this.primaryAction,
    this.rawOrder,
    this.id = '',
    this.timeLabel,
    this.sellerAvatar,
    this.productImage,
    this.productImageUrl,
    this.statusShowDot = false,
  });

  final String id;
  final OrderStatusFilter filter;
  final String sellerName;
  final String? timeLabel;
  final String? sellerAvatar;
  final String statusLabel;
  final StatusChipType statusType;
  final bool statusShowDot;
  final String productName;
  final String? productImage;
  final String? productImageUrl;
  final String variant;
  final String quantityLabel;
  final String unitPriceLabel;
  final String totalLabel;
  final String primaryAction;
  final OrderModel? rawOrder;

  factory _OrderRow.fromModel(OrderModel o) {
    final dt = o.createdAt;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    return _OrderRow(
      id: o.id,
      rawOrder: o,
      filter: _filterFor(o.status),
      sellerName: o.sellerName.isNotEmpty ? o.sellerName : 'Người bán',
      timeLabel: timeStr,
      statusLabel: o.status.historyLabel,
      statusType: o.status.historyChipType,
      statusShowDot: o.status.historyShowDot,
      productName:
          o.listingTitle.isNotEmpty ? o.listingTitle : 'Đơn hàng AquaTrade',
      productImageUrl: o.digitalProof?.aiImageUrl,
      variant: o.shippingAddress.isNotEmpty ? o.shippingAddress : '—',
      quantityLabel: 'x${o.finalQuantity} con',
      unitPriceLabel: AppFormatters.formatCurrency(o.unitPriceAtPurchase),
      totalLabel: AppFormatters.formatCurrency(o.totalPrice),
      primaryAction: o.status.historyPrimaryAction,
    );
  }

  static OrderStatusFilter _filterFor(OrderStatus status) {
    if (status == OrderStatus.PENDING || status == OrderStatus.ESCROW_LOCKED) {
      return OrderStatusFilter.awaitingPayment;
    }
    if (status == OrderStatus.SHIPPING) return OrderStatusFilter.shipping;
    if (status == OrderStatus.COMPLETED) return OrderStatusFilter.completed;
    if (status == OrderStatus.CANCELLED) return OrderStatusFilter.cancelled;
    return OrderStatusFilter.all;
  }
}

/// Màn Lịch sử đơn mua.
/// Wire: `GET /orders/my` — không có query status trên BE → lọc tab ở client.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const _filters = [
    (OrderStatusFilter.all, 'TẤT CẢ'),
    (OrderStatusFilter.awaitingPayment, 'CHỜ TT'),
    (OrderStatusFilter.shipping, 'ĐANG GIAO'),
    (OrderStatusFilter.completed, 'HOÀN THÀNH'),
    (OrderStatusFilter.cancelled, 'ĐÃ HỦY'),
  ];

  static const _mockOrders = [
    _OrderRow(
      filter: OrderStatusFilter.completed,
      sellerName: 'Vinh Sang Aqua Farm',
      sellerAvatar: 'assets/images/market/seller_thanh_long.jpg',
      statusLabel: 'Hoàn thành',
      statusType: StatusChipType.successDeep,
      productName: 'Tôm Sú Hữu Cơ - Loại 1 (Size 15-20)',
      productImage: 'assets/images/market/tom_su.jpg',
      variant: 'Cấp đông nhanh (IQF)',
      quantityLabel: 'x200 con',
      unitPriceLabel: '780.000₫',
      totalLabel: '1.560.000₫',
      primaryAction: 'MUA LẠI',
    ),
    _OrderRow(
      filter: OrderStatusFilter.shipping,
      sellerName: 'GreenFish',
      sellerAvatar: 'assets/images/market/seller_can_gio.jpg',
      statusLabel: 'Đang giao',
      statusType: StatusChipType.info,
      statusShowDot: true,
      productName: 'Cá Chẽm Phi Lê Tươi (Khay 500g)',
      productImage: 'assets/images/market/ca_chem.jpg',
      variant: 'Tươi sống - Giao nhanh',
      quantityLabel: 'x1 con',
      unitPriceLabel: '185.000₫',
      totalLabel: '215.000₫',
      primaryAction: 'CHI TIẾT',
    ),
    _OrderRow(
      filter: OrderStatusFilter.cancelled,
      sellerName: 'GreenWave Hatcheries',
      sellerAvatar: 'assets/images/market/vendor_mekong.jpg',
      statusLabel: 'Đã hủy',
      statusType: StatusChipType.errorSoft,
      productName: 'Trứng Cá Hồi Cao Cấp (100g)',
      productImage: 'assets/images/market/ca_hoi.jpg',
      variant: 'Nhập khẩu Na Uy',
      quantityLabel: 'x1 con',
      unitPriceLabel: '450.000₫',
      totalLabel: '450.000₫',
      primaryAction: 'CHI TIẾT',
    ),
  ];

  OrderStatusFilter _selectedFilter = OrderStatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<OrderProvider>().fetchMyOrders();
      }
    });
  }

  List<_OrderRow> _rows(OrderProvider orders) {
    final api = orders.orders;
    final authenticated = context.read<AuthProvider>().isAuthenticated;

    // Đã login: chỉ hiện data API (kể cả rỗng) — không fallback mock giả.
    if (authenticated) {
      if (_selectedFilter == OrderStatusFilter.all) {
        return api.map(_OrderRow.fromModel).toList();
      }
      return api
          .where((o) => _selectedFilter.matches(o.status))
          .map(_OrderRow.fromModel)
          .toList();
    }

    // Guest không vào được màn này (AuthGate); mock chỉ còn cho preview/test.
    if (_selectedFilter == OrderStatusFilter.all) return _mockOrders;
    return _mockOrders.where((o) => o.filter == _selectedFilter).toList();
  }

  void _openDetail(String orderId) {
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đơn demo — chưa có orderId từ API')),
      );
      return;
    }
    context.push(AppRoutes.orderDetailPath(orderId));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppTopBar.subPage(
          title: 'Lịch sử đơn mua',
          centerTitle: true,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.account);
            }
          },
        ),
        body: const AuthGateView(
          reason: LoginReasons.orders,
          from: AppRoutes.orders,
          title: 'Đăng nhập để xem đơn hàng',
        ),
      );
    }

    final orderProvider = context.watch<OrderProvider>();
    final items = _rows(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Lịch sử đơn mua',
        centerTitle: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.account);
          }
        },
        trailing: PressableScale(
          onTap: () {},
          child: const SizedBox(
            width: 48,
            child: Icon(Icons.more_vert, color: AppColors.primary),
          ),
        ),
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<OrderProvider>().fetchMyOrders(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                  itemCount: items.isEmpty ? 1 : items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xl),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 28,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              orderProvider.isLoading
                                  ? 'ĐANG TẢI...'
                                  : 'KHÔNG CÓ ĐƠN HÀNG',
                              style: AppTypography.chip.copyWith(
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (i == items.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 28,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'KHÔNG CÒN ĐƠN HÀNG NÀO KHÁC',
                              style: AppTypography.chip.copyWith(
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final o = items[i];
                    return OrderHistoryCard(
                      sellerName: o.sellerName,
                      timeLabel: o.timeLabel,
                      sellerAvatar: o.sellerAvatar,
                      statusLabel: o.statusLabel,
                      statusType: o.statusType,
                      statusShowDot: o.statusShowDot,
                      productName: o.productName,
                      productImage: o.productImage,
                      productImageUrl: o.productImageUrl,
                      variant: o.variant,
                      quantityLabel: o.quantityLabel,
                      unitPriceLabel: o.unitPriceLabel,
                      totalLabel: o.totalLabel,
                      primaryActionLabel: o.primaryAction,
                      onTap: () => _openDetail(o.id),
                      onChat: () {
                        if (o.rawOrder != null) {
                          final auth = context.read<AuthProvider>();
                          final role = context.read<RoleProvider>().currentRole;
                          final convId = context.read<ChatProvider>().startConversationWithOrder(
                            order: o.rawOrder!,
                            currentUserId: auth.currentUser?.id ?? '',
                            isSeller: role == UserRole.seller,
                          );
                          context.push('/chat/detail/$convId');
                        }
                      },
                      onPrimary: o.primaryAction == 'CHI TIẾT'
                          ? () => _openDetail(o.id)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Mua lại — sẽ nối sau')),
                              );
                            },
                      onProof: () => _openDetail(o.id),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final (value, label) = _filters[i];
          final active = _selectedFilter == value;
          return PressableScale(
            onTap: () => setState(() => _selectedFilter = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                label,
                style: AppTypography.chip.copyWith(
                  letterSpacing: 0.6,
                  color:
                      active ? AppColors.onPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
