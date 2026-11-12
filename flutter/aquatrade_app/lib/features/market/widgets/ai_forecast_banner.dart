import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';

/// Banner "Dự báo thị trường AI" nền tối trên màn Chợ.
class AiForecastBanner extends StatelessWidget {
  const AiForecastBanner({
    super.key,
    required this.overline,
    required this.title,
    required this.subtitle,
  });

  final String overline;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bannerDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline.toUpperCase(),
            style: AppTypography.chip.copyWith(
              fontSize: 10,
              letterSpacing: 2,
              height: 15 / 10,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.cardValue.copyWith(
              height: 25 / 20,
              color: AppColors.onBannerDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const PulseDot(size: 8, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xxs),
              Opacity(
                opacity: 0.8,
                child: Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    height: 16.5 / 11,
                    color: AppColors.onBannerDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
