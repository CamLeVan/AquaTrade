import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';

/// Màn Lỗi thanh toán — thiếu số dư ví (Stitch).
class CheckoutErrorBalanceScreen extends StatelessWidget {
  const CheckoutErrorBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Lỗi thanh toán',
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
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderFaint),
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.warningBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      size: 44, color: AppColors.warning),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Thanh toán không thành công',
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
                      TextSpan(text: 'Số dư ví '),
                      TextSpan(
                        text: 'AquaTrade',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' không đủ để hoàn tất giao dịch này. Tài khoản của bạn chưa bị trừ tiền.',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MÃ GIAO DỊCH',
                            style: AppTypography.chip.copyWith(
                              fontSize: 10,
                              letterSpacing: 0.8,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('AQ-9821-XRT',
                              style: AppTypography.itemTitle
                                  .copyWith(fontSize: 14)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'CẦN THANH TOÁN',
                            style: AppTypography.chip.copyWith(
                              fontSize: 10,
                              letterSpacing: 0.8,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('2.450.000 VND',
                              style: AppTypography.itemTitle
                                  .copyWith(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Nạp tiền ngay',
            leadingIcon: Icons.account_balance_wallet,
            onPressed: () => context.push(AppRoutes.walletTopup),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Thử phương thức khác',
            variant: AppButtonVariant.softTeal,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: PressableScale(
              onTap: () {},
              child: Text.rich(
                TextSpan(
                  style: AppTypography.caption.copyWith(letterSpacing: 0.4),
                  children: [
                    TextSpan(
                      text: 'CẦN HỖ TRỢ? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text: 'LIÊN HỆ TRUNG TÂM TRỢ GIÚP',
                      style: TextStyle(
                        color: AppColors.onPrimaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary10,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mẹo AquaTrade AI',
                        style: AppTypography.itemTitle.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn có thể thiết lập nạp tiền tự động từ ngân hàng liên kết để tránh gián đoạn giao dịch trong tương lai.',
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
          ),
        ],
      ),
    );
  }
}
