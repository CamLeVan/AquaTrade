import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'animations.dart';

/// Chip trạng thái nhỏ (VD: HOÀN THÀNH, CHỜ DUYỆT, CHỜ XÁC NHẬN, ĐANG GIAO).
/// - [successDeep] chữ teal đậm trên nền teal nhạt (VD "GIÁ ĐÃ THỎA THUẬN")
/// - [errorSoft]   nền đỏ nhạt + chữ đỏ đậm (VD "GIÁ ĐÃ THAY ĐỔI")
enum StatusChipType { success, successDeep, info, neutral, error, errorSoft, tertiary }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.type = StatusChipType.success,
    this.showDot = false,
  });

  final String label;
  final StatusChipType type;

  /// Hiện chấm tròn nhấp nháy phía trước (VD đơn "Chờ xác nhận", "Đang giao").
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      StatusChipType.success => (AppColors.primary10, AppColors.primary),
      StatusChipType.successDeep => (AppColors.primary10, AppColors.onPrimaryDeep),
      StatusChipType.info => (AppColors.infoBg, AppColors.infoText),
      StatusChipType.neutral => (AppColors.neutralBg, AppColors.textTertiary),
      StatusChipType.error => (AppColors.errorBg, AppColors.error),
      StatusChipType.errorSoft => (AppColors.errorContainer, AppColors.onErrorContainer),
      StatusChipType.tertiary => (AppColors.infoBg, AppColors.tertiary),
    };

    return Container(
      padding: showDot
          ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4)
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(showDot ? 999 : AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            PulseDot(size: 6, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.chip.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
