import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'animations.dart';

/// Kiểu hiển thị của [SegmentedControl].
/// - [SegmentedStyle.pill] : track xám, segment active nền teal + chữ tối, IN HOA
///   (dùng cho tab "KHÁM PHÁ / GIAN HÀNG CỦA TÔI").
/// - [SegmentedStyle.card] : track xanh nhạt, segment active nền trắng + chữ teal
///   (dùng cho toggle "Cá nhân / Doanh nghiệp").
enum SegmentedStyle { pill, card }

class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.style = SegmentedStyle.pill,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final SegmentedStyle style;

  @override
  Widget build(BuildContext context) {
    final isPill = style == SegmentedStyle.pill;
    return Container(
      padding: EdgeInsets.all(isPill ? 5 : 4),
      decoration: BoxDecoration(
        color: isPill ? AppColors.segmentTrack : AppColors.inputFill,
        borderRadius: BorderRadius.circular(
          isPill ? AppSpacing.radiusLg : AppSpacing.radiusMd,
        ),
        border: isPill ? Border.all(color: AppColors.borderFaint) : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: i == selectedIndex,
                isPill: isPill,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.isPill,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isPill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (isPill) {
      bg = selected ? AppColors.primary : Colors.transparent;
      fg = selected ? AppColors.onPrimary : AppColors.textSecondary;
    } else {
      bg = selected ? AppColors.card : Colors.transparent;
      fg = selected ? AppColors.primary : AppColors.textSecondary;
    }

    final textStyle = isPill
        ? AppTypography.chip.copyWith(
            fontSize: 12,
            letterSpacing: 1.2,
            height: 16 / 12,
            color: fg,
          )
        : AppTypography.chip.copyWith(
            fontSize: 14,
            height: 20 / 14,
            color: fg,
          );

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: isPill ? 10 : 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            isPill ? AppSpacing.radiusMd : AppSpacing.radiusSm + 2,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ]
              : const [],
        ),
        child: Text(
          isPill ? label.toUpperCase() : label,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}
