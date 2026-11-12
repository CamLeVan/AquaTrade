import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Ô nhập liệu có nhãn dùng chung (nền [AppColors.inputFill]).
/// Hỗ trợ icon đầu dòng và widget đuôi (VD chevron cho dropdown).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.leadingIcon,
    this.trailing,
    this.readOnly = false,
    this.uppercaseValue = false,
    this.onTap,
    this.onChanged,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool readOnly;
  final bool uppercaseValue;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.chip.copyWith(
      fontSize: 11,
      letterSpacing: 1.1,
      height: 16.5 / 11,
      color: AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  initialValue: controller == null ? initialValue : null,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  validator: validator,
                  textCapitalization: uppercaseValue
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTypography.body.copyWith(
                      fontSize: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
