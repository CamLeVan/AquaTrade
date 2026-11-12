import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Card tối "PHÂN TÍCH THỊ TRƯỜNG AI" trên dashboard.
class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'PHÂN TÍCH THỊ TRƯỜNG AI',
                style: AppTypography.chip.copyWith(
                  letterSpacing: 1,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.onDark,
            ),
          ),
        ],
      ),
    );
  }
}
