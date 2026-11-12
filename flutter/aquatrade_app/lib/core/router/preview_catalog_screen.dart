import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../shared_providers/role_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_routes.dart';

/// Catalog review UI — chỉ dùng với `main_preview.dart`.
class PreviewCatalogScreen extends StatelessWidget {
  const PreviewCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text('AquaTrade · UI Preview', style: AppTypography.cardValue),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('TRẠNG THÁI (role-aware)', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final r in const [
                (UserRole.buyer, SellerStatus.none, 'Buyer'),
                (UserRole.seller, SellerStatus.active, 'Seller'),
                (UserRole.buyer, SellerStatus.pending, 'Pending'),
              ])
                ChoiceChip(
                  label: Text(r.$3),
                  selected: role.currentRole == r.$1 &&
                      role.sellerStatus == r.$2,
                  onSelected: (_) => role.applyPreview(r.$1, r.$2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('SHELL / TAB', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.xs),
          _tile(context, 'App shell · Trang chủ', Icons.dashboard_outlined,
              AppRoutes.home),
          _tile(context, 'App shell · Chợ', Icons.storefront_outlined,
              AppRoutes.market),
          _tile(
              context,
              'App shell · Chợ (Gian hàng)',
              Icons.store_mall_directory_outlined,
              '${AppRoutes.market}?tab=shop'),
          _tile(context, 'App shell · Tin nhắn', Icons.chat_bubble_outline,
              AppRoutes.chat),
          _tile(context, 'App shell · Tài khoản', Icons.person_outline,
              AppRoutes.account),
          _tile(context, 'Quét AI (placeholder)', Icons.center_focus_strong,
              AppRoutes.aiScan),
          const SizedBox(height: AppSpacing.lg),
          Text('MÀN HÌNH', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.xs),
          _tile(context, 'Đăng nhập', Icons.login, AppRoutes.login),
          _tile(context, 'Đăng ký', Icons.person_add_alt_1_outlined,
              AppRoutes.register),
          _tile(context, 'Chi tiết sản phẩm', Icons.set_meal_outlined,
              AppRoutes.product),
          _tile(context, 'Đăng sản phẩm (Seller)', Icons.add_box_outlined,
              AppRoutes.createListing),
          _tile(context, 'Giỏ hàng', Icons.shopping_cart_outlined,
              AppRoutes.cart),
          _tile(context, 'Xác nhận thanh toán', Icons.payments_outlined,
              AppRoutes.checkout),
          _tile(context, 'Lỗi thanh toán (thiếu số dư)',
              Icons.warning_amber_outlined, AppRoutes.checkoutErrorBalance),
          _tile(context, 'Lỗi hệ thống / hết hàng', Icons.error_outline,
              AppRoutes.checkoutErrorSystem),
          _tile(context, 'Đặt hàng thành công', Icons.celebration_outlined,
              AppRoutes.checkoutSuccess),
          _tile(context, 'Lịch sử đơn mua', Icons.receipt_long_outlined,
              AppRoutes.orders),
          _tile(context, 'Chi tiết đơn hàng', Icons.local_shipping_outlined,
              AppRoutes.orderDetail),
          _tile(context, 'Ví AquaTrade', Icons.account_balance_wallet_outlined,
              AppRoutes.wallet),
          _tile(context, 'Nạp tiền vào ví', Icons.add_circle_outline,
              AppRoutes.walletTopup),
          _tile(context, 'Nạp tiền thành công', Icons.check_circle_outline,
              AppRoutes.walletTopupSuccess),
          _tile(context, 'Rút tiền (Seller)', Icons.outbox_outlined,
              AppRoutes.walletWithdraw),
          _tile(context, 'Rút tiền thành công', Icons.task_alt_outlined,
              AppRoutes.walletWithdrawSuccess),
          _tile(context, 'Đăng ký người bán — B1', Icons.badge_outlined,
              AppRoutes.sellerRegisterInfo),
          _tile(context, 'Đăng ký người bán — B2',
              Icons.verified_user_outlined, AppRoutes.sellerRegisterVerify),
          _tile(context, 'Đăng ký người bán — B3',
              Icons.assignment_turned_in_outlined, AppRoutes.sellerRegisterTerms),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    String location,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => context.push(location),
      ),
    );
  }
}
