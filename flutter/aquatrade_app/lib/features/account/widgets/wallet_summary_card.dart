import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';

/// Card ví trên hub Tài khoản: số dư + Nạp tiền (+ Rút tiền nếu [showWithdraw]).
/// Tóm tắt số dư ví trên màn Tài khoản.
/// Data: `GET /users/me/wallet` qua [WalletProvider] (parent truyền [balanceLabel]).
class WalletSummaryCard extends StatelessWidget {
  const WalletSummaryCard({
    super.key,
    required this.balanceLabel,
    this.showWithdraw = true,
    this.onDeposit,
    this.onWithdraw,
    this.onTap,
  });

  /// Chuỗi đã format sẵn (VD "12.450.000").
  final String balanceLabel;
  final bool showWithdraw;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;

  /// Chạm vùng header/số dư → mở màn Ví đầy đủ.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF), // trắng ~80% (glass)
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primary05,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PressableScale(
                onTap: onTap,
                pressedScale: 0.99,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary10,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              size: 22, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'VÍ AQUATRADE',
                          style: AppTypography.overline.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.trending_up,
                            size: 18, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          balanceLabel,
                          style: AppTypography.heading.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            height: 36 / 30,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'VND',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'SỐ DƯ KHẢ DỤNG',
                      style: AppTypography.overline.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.borderFaint),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _walletBtn(
                      label: 'Nạp tiền',
                      bg: AppColors.primary,
                      fg: AppColors.onPrimary,
                      onTap: onDeposit,
                    ),
                  ),
                  if (showWithdraw) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _walletBtn(
                        label: 'Rút tiền',
                        bg: AppColors.primary10,
                        fg: AppColors.primary,
                        onTap: onWithdraw,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletBtn({
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(
            fontSize: 12,
            height: 16 / 12,
            color: fg,
          ),
        ),
      ),
    );
  }
}
