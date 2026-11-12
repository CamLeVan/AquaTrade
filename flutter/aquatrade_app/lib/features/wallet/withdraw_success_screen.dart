import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';

/// Màn kết quả rút tiền (Stitch: Rút tiền thành công).
class WithdrawSuccessScreen extends StatelessWidget {
  const WithdrawSuccessScreen({
    super.key,
    this.amountLabel = '5.000.000',
  });

  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar.subPage(
        title: 'Kết quả rút tiền',
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.primary20,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 48, color: AppColors.onPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Yêu cầu rút tiền đã được gửi!',
            textAlign: TextAlign.center,
            style: AppTypography.heading.copyWith(fontSize: 22, height: 30 / 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tiền sẽ được chuyển về tài khoản của bạn trong vòng 24-48h',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderFaint),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHI TIẾT GIAO DỊCH',
                  style: AppTypography.overline.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text('Số tiền rút',
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      '$amountLabelđ',
                      style: AppTypography.heading.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.borderFaint),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'TÀI KHOẢN THỤ HƯỞNG',
                  style: AppTypography.chip.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.account_balance,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Vietcombank ****8899',
                        style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'MÃ YÊU CẦU',
                  style: AppTypography.chip.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text('RT789012',
                        style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                    const SizedBox(width: AppSpacing.xs),
                    PressableScale(
                      onTap: () {
                        Clipboard.setData(
                            const ClipboardData(text: 'RT789012'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã sao chép mã yêu cầu')),
                        );
                      },
                      child: const Icon(Icons.content_copy,
                          size: 14, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.borderFaint),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Text('Trạng thái',
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PulseDot(size: 6, color: AppColors.infoText),
                          const SizedBox(width: 6),
                          Text(
                            'ĐANG XỬ LÝ',
                            style: AppTypography.chip.copyWith(
                              letterSpacing: 0.8,
                              color: AppColors.infoText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Về trang chủ',
            uppercase: true,
            onPressed: () => context.go(AppRoutes.home),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Xem lịch sử ví',
            uppercase: true,
            variant: AppButtonVariant.softTeal,
            onPressed: () => context.go(AppRoutes.wallet),
          ),
        ],
      ),
    );
  }
}
