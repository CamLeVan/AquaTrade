import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';

/// Một dòng giao dịch ví (nạp / chi / mua hàng).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    required this.timeLabel,
    required this.amountLabel,
    required this.isCredit,
    required this.statusLabel,
    this.statusProcessing = false,
    this.icon = Icons.south_west,
  });

  final String title;
  final String timeLabel;
  final String amountLabel;
  final bool isCredit;
  final String statusLabel;
  final bool statusProcessing;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final iconBg = isCredit ? AppColors.primary10 : AppColors.neutralBg;
    final iconFg = isCredit ? AppColors.primary : AppColors.textSecondary;
    final amountColor = isCredit ? AppColors.textPrimary : AppColors.error;
    final statusFg =
        statusProcessing ? AppColors.tertiary : AppColors.primary;
    final statusBg = statusProcessing
        ? AppColors.tertiary.withValues(alpha: 0.05)
        : AppColors.primary05;

    return PressableScale(
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs, vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(icon, color: iconFg, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.itemTitle
                          .copyWith(fontSize: 14, height: 20 / 14)),
                  Text(timeLabel,
                      style: AppTypography.caption.copyWith(
                          fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountLabel,
                    style: AppTypography.itemTitle.copyWith(
                        fontSize: 14, height: 20 / 14, color: amountColor)),
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (statusProcessing)
                        PulseDot(size: 6, color: statusFg)
                      else
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusFg, shape: BoxShape.circle),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel.toUpperCase(),
                        style: AppTypography.chip.copyWith(
                          fontSize: 10,
                          letterSpacing: -0.2,
                          color: statusFg,
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
    );
  }
}
