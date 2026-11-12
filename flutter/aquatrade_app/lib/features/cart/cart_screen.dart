import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import 'widgets/cart_checkbox.dart';
import 'widgets/cart_item_card.dart';

/// Giỏ hàng — Figma node 2109:3238.
/// Data: cart local (listing từ BE khi add). Checkout → `AppRoutes.checkout`.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<CartProvider>().loadCart();
      }
    });
  }

  String _money(num v) {
    final n = AppFormatters.formatNumber(v);
    return '$n' 'đ';
  }

  String? _imageUrl(CartItemModel item) {
    final t = item.listing.thumbnailUrl;
    if (t.isNotEmpty) return t;
    if (item.listing.imageUrls.isNotEmpty) return item.listing.imageUrls.first;
    return null;
  }

  int _selectedSellerCount(CartProvider cart) {
    final names = <String>{};
    for (final item in cart.selectedItems) {
      names.add(
        item.listing.sellerName.isNotEmpty
            ? item.listing.sellerName
            : 'Người bán',
      );
    }
    return names.length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(title: 'Giỏ hàng'),
        body: const AuthGateView(
          reason: LoginReasons.cart,
          from: AppRoutes.cart,
          title: 'Đăng nhập để xem giỏ hàng',
        ),
      );
    }

    final cart = context.watch<CartProvider>();
    final count = cart.totalItemCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Giỏ hàng ($count)',
        trailing: count == 0
            ? null
            : PressableScale(
                onTap: () => setState(() => _editing = !_editing),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    _editing ? 'Xong' : 'Sửa',
                    style: AppTypography.body.copyWith(
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
      ),
      body: cart.isLoading && count == 0
          ? const Center(child: CircularProgressIndicator())
          : count == 0
              ? _emptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          24,
                        ),
                        children: [
                          for (final entry in cart.itemsBySeller.entries) ...[
                            _sellerHeader(
                              cart,
                              sellerName: entry.key,
                              items: entry.value,
                            ),
                            const SizedBox(height: AppSpacing.sm + 4),
                            for (final item in entry.value) ...[
                              CartItemCard(
                                name: item.listing.title,
                                price: _money(item.listing.pricePerFish),
                                quantity: item.quantity,
                                checked: item.isSelected,
                                imageUrl: _imageUrl(item),
                                chipLabel: item.listing.qualityLabel
                                        .trim()
                                        .isNotEmpty
                                    ? item.listing.qualityLabel
                                        .trim()
                                        .toUpperCase()
                                    : 'GIÁ ĐÃ THỎA THUẬN',
                                showRemove: _editing,
                                onCheckChanged: (_) => cart
                                    .toggleSelection(item.listing.id),
                                onQuantityChanged: (q) => cart.updateQuantity(
                                  item.listing.id,
                                  q,
                                ),
                                onRemove: () => _confirmRemove(cart, item),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          _suggestionCard(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                    _footerBar(cart),
                  ],
                ),
    );
  }

  Widget _sellerHeader(
    CartProvider cart, {
    required String sellerName,
    required List<CartItemModel> items,
  }) {
    final allSelected = cart.isSellerAllSelected(sellerName);
    return Row(
      children: [
        CartCheckbox(
          checked: allSelected,
          onChanged: (v) => cart.toggleSeller(sellerName, v),
        ),
        const SizedBox(width: 11),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: const Icon(Icons.store, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  sellerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.itemTitle.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.verified, size: 16, color: AppColors.primary),
            ],
          ),
        ),
        PressableScale(
          onTap: () => cart.toggleSeller(sellerName, !allSelected),
          child: Text(
            'CHỌN TẤT CẢ',
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg + 1),
      decoration: BoxDecoration(
        color: AppColors.primary05,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Icon(
              Icons.auto_awesome,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GỢI Ý',
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: const Color(0xFF005143),
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    height: 22.75 / 14,
                    color: AppColors.textPrimary,
                  ),
                  children: const [
                    TextSpan(text: 'Bạn có muốn thêm '),
                    TextSpan(
                      text: 'Cá Tầm Sapa',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          '? Loại này đang có giá tốt nhất trong phiên giao dịch hiện tại.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PressableScale(
                onTap: () => context.go(AppRoutes.market),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem chi tiết',
                      style: AppTypography.chip.copyWith(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerBar(CartProvider cart) {
    final selected = cart.selectedItemCount;
    final sellerSplits = _selectedSellerCount(cart);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md + 1,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.borderFaint)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CartCheckbox(
                  checked: cart.isAllSelected,
                  onChanged: (v) => cart.toggleAll(v),
                ),
                const SizedBox(width: 7),
                Text(
                  'Tất cả',
                  style: AppTypography.body.copyWith(fontSize: 14),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TỔNG CỘNG',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _money(cart.selectTotalPrice),
                      style: AppTypography.heading.copyWith(
                        fontSize: 20,
                        height: 28 / 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: selected == 0
                  ? 'Chọn sản phẩm để thanh toán'
                  : 'Tiến hành thanh toán ($selected sản phẩm)',
              icon: Icons.chevron_right,
              onPressed: selected == 0
                  ? null
                  : () => context.push(AppRoutes.checkout),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              sellerSplits <= 1
                  ? 'Đơn hàng sẽ được xử lý theo người bán đã chọn'
                  : 'Đơn hàng sẽ được tách thành $sellerSplits đơn riêng theo từng người bán',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.primary10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Giỏ hàng đang trống',
              style: AppTypography.heading.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Khám phá Chợ và thêm sản phẩm AVAILABLE để bắt đầu đặt hàng.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Đến Chợ',
              onPressed: () => context.go(AppRoutes.market),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(CartProvider cart, CartItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: Text('Xóa "${item.listing.title}" khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              cart.removeFromCart(item.listing.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
