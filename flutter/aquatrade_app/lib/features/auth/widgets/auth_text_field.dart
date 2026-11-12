import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';

/// Ô nhập Auth (Figma Login/Register).
/// Hỗ trợ leading icon + toggle hiện mật khẩu — khác [AppTextField] (onboarding).
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.leadingIcon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? leadingIcon;

  /// Khi true: che chữ. [onToggleObscure] != null → hiện nút mắt (PressableScale).
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.chip.copyWith(
      fontSize: 12,
      letterSpacing: 0.6,
      height: 16 / 12,
      color: AppColors.textStrong,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: AppTypography.body.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(
              fontSize: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.45),
            ),
            filled: true,
            fillColor: AppColors.authInputFill,
            contentPadding: EdgeInsets.only(
              left: leadingIcon != null ? 48 : AppSpacing.md,
              right: onToggleObscure != null ? 48 : AppSpacing.md,
              top: 18,
              bottom: 18,
            ),
            prefixIcon: leadingIcon == null
                ? null
                : Icon(leadingIcon, size: 18, color: AppColors.textSecondary),
            suffixIcon: onToggleObscure == null
                ? null
                : PressableScale(
                    onTap: onToggleObscure,
                    pressedScale: 0.9,
                    child: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
