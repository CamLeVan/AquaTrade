import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'animations.dart';

/// Nút bấm dùng chung của app.
/// - [AppButtonVariant.primary]   nền teal, chữ tối (CTA chính)
/// - [AppButtonVariant.secondary] nền xám nhạt (VD "Quay lại")
/// - [AppButtonVariant.softTeal]  nền teal 20% + chữ teal đậm (VD "Gửi đăng ký")
/// - [AppButtonVariant.ghost]     trong suốt, chữ teal
enum AppButtonVariant { primary, secondary, softTeal, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.leadingIcon,
    this.expand = true,
    this.uppercase = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Icon đứng SAU nhãn (VD mũi tên "→").
  final IconData? icon;

  /// Icon đứng TRƯỚC nhãn.
  final IconData? leadingIcon;

  final bool expand;
  final bool uppercase;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, shadow) = switch (variant) {
      AppButtonVariant.primary => (
          AppColors.primary,
          AppColors.onPrimary,
          const [
            BoxShadow(
              color: Color(0x3313ECC8),
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ],
        ),
      AppButtonVariant.secondary => (
          AppColors.stepInactive,
          AppColors.textStrong,
          <BoxShadow>[],
        ),
      AppButtonVariant.softTeal => (
          AppColors.primary20,
          AppColors.onPrimaryDeep,
          <BoxShadow>[],
        ),
      AppButtonVariant.ghost => (
          AppColors.inputFill,
          AppColors.textSecondary,
          <BoxShadow>[],
        ),
    };

    final textStyle = AppTypography.chip.copyWith(
      fontSize: 16,
      height: 24 / 16,
      color: fg,
      letterSpacing: uppercase ? 1.2 : 0,
    );

    final button = PressableScale(
      onTap: onPressed,
      pressedScale: 0.97,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: onPressed == null ? const [] : shadow,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 16, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                uppercase ? label.toUpperCase() : label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(icon, size: 16, color: fg),
            ],
          ],
        ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
