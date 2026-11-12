import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';

/// Màn Lỗi hệ thống / hết hàng (Stitch).
class CheckoutErrorSystemScreen extends StatelessWidget {
  const CheckoutErrorSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Không thể hoàn tất',
        centerTitle: true,
        trailing: PressableScale(
          onTap: () {},
          child: const SizedBox(
            width: 48,
            child: Icon(Icons.account_circle_outlined,
                color: AppColors.textSecondary),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xl, horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.1,
                colors: [
                  AppColors.primary10,
                  AppColors.surface.withValues(alpha: 0),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.priority_high,
                        color: AppColors.onDark, size: 28),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'LỖI HỆ THỐNG / HẾT HÀNG',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.onPrimaryDeep,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Không thể hoàn tất đơn hàng',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading
                      .copyWith(fontSize: 22, height: 30 / 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                    children: const [
                      TextSpan(
                        text:
                            'Một sản phẩm trong giỏ hàng vừa hết hàng hoặc có lỗi kết nối. Vui lòng kiểm tra lại giỏ hàng. ',
                      ),
                      TextSpan(
                        text: 'Tài khoản của bạn chưa bị trừ tiền.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _infoCard(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.primary,
            title: 'Cập nhật kho vận',
            body:
                'Dữ liệu thời gian thực cho thấy một số mặt hàng đã đạt giới hạn tồn kho.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _infoCard(
            icon: Icons.security,
            iconColor: AppColors.tertiary,
            title: 'An toàn giao dịch',
            body:
                'Hệ thống bảo mật AquaTrade đã tạm dừng quy trình để bảo vệ số dư của bạn.',
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Quay lại giỏ hàng',
            leadingIcon: Icons.shopping_cart_outlined,
            onPressed: () => context.go(AppRoutes.cart),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Liên hệ hỗ trợ',
            leadingIcon: Icons.support_agent,
            variant: AppButtonVariant.softTeal,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'REFERENCE ID: AT-SYS-ERR-9021-X',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
