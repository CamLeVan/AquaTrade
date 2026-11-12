import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/animations.dart';

/// Checkbox bo góc kiểu Aqua Crystal dùng trong Giỏ hàng
/// (chọn sản phẩm / chọn theo người bán / chọn tất cả).
class CartCheckbox extends StatelessWidget {
  const CartCheckbox({
    super.key,
    required this.checked,
    this.onChanged,
    this.disabled = false,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: disabled
            ? AppColors.surfaceDim
            : (checked ? AppColors.primary : AppColors.card),
        borderRadius: BorderRadius.circular(6),
        border: checked && !disabled
            ? null
            : Border.all(
                color: disabled
                    ? AppColors.textSecondary.withValues(alpha: 0.2)
                    : AppColors.primary20,
              ),
      ),
      child: checked && !disabled
          ? const Icon(Icons.check, size: 16, color: AppColors.onDark)
          : null,
    );

    if (disabled) return box;
    return PressableScale(
      onTap: () => onChanged?.call(!checked),
      pressedScale: 0.85,
      child: box,
    );
  }
}
