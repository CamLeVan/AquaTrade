import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Brand block Login (Figma 2008:11) — logo + AquaTrade AI + tagline.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, this.compact = false});

  /// Register dùng logo nhỏ hơn, không tagline tiếng Anh dài.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 56.0;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: compact ? AppColors.authLink : AppColors.authBlob,
            borderRadius: BorderRadius.circular(compact ? 12 : 8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/auth/logo_lock_fish.png',
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => Icon(
              Icons.lock_outline,
              color: compact ? AppColors.onDark : AppColors.authLink,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.sm),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTypography.cardValue.copyWith(
                fontSize: 20,
                height: 28 / 20,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
              children: [
                const TextSpan(text: 'AquaTrade '),
                TextSpan(
                  text: 'AI',
                  style: AppTypography.cardValue.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.authLink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'SÀN GIAO DỊCH THỦY SẢN\nVẬN HÀNH BẰNG AI',
            textAlign: TextAlign.center,
            style: AppTypography.chip.copyWith(
              fontSize: 12,
              letterSpacing: 1.2,
              height: 16 / 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
