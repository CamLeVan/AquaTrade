import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Thẻ số liệu nhanh trên màn Quản lý gian hàng (VD "Tổng đơn hàng", "Chờ xác nhận").
class ShopStatCard extends StatelessWidget {
  const ShopStatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;

  /// Badge hoặc icon bên phải giá trị.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.chip.copyWith(
              fontSize: 10,
              letterSpacing: 1.5,
              height: 15 / 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTypography.heading.copyWith(
                    fontSize: 28,
                    letterSpacing: -1,
                    height: 1,
                    color: valueColor ?? AppColors.textStrong,
                  ),
                  children: [
                    TextSpan(text: value),
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          color: valueColor ?? AppColors.textStrong,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}
