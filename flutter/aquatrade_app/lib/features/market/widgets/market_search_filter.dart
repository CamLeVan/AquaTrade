import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';

/// Ô tìm kiếm + hàng chip lọc (cuộn ngang) cho màn Chợ.
class MarketSearchFilter extends StatelessWidget {
  const MarketSearchFilter({
    super.key,
    this.hint = 'Tìm kiếm thủy sản cao cấp...',
    this.filters = const ['Danh mục', 'Giá', 'Xuất xứ', 'Điểm sức khỏe'],
    this.activeFilter = 0,
    this.onFilterTap,
    this.searchController,
    this.onSearchChanged,
  });

  final String hint;
  final List<String> filters;
  final int activeFilter;
  final ValueChanged<int>? onFilterTap;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ô tìm kiếm
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Chip lọc
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, i) {
              final active = i == activeFilter;
              return _FilterChip(
                label: filters[i],
                active: active,
                showIcon: i == 0,
                onTap: () => onFilterTap?.call(i),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.showIcon,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool showIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.segmentTrack,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: active ? null : Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.tune,
                size: 12,
                color: active ? AppColors.onPrimary : AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label.toUpperCase(),
              style: AppTypography.chip.copyWith(
                fontSize: 12,
                letterSpacing: 1.2,
                height: 16 / 12,
                color: active ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
