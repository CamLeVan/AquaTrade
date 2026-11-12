import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';
import '../../../widgets/app_smart_image.dart';

/// Thẻ sản phẩm dạng full-width trên màn Chợ:
/// ảnh (kèm badge AI góc trên) + tên + giá + nút thêm vào giỏ.
class MarketProductCard extends StatelessWidget {
  const MarketProductCard({
    super.key,
    required this.name,
    required this.price,
    this.unit = '/con',
    required this.aiBadge,
    this.isWarning = false,
    this.assetPath,
    this.imageUrl,
    this.onTap,
    this.onAdd,
  });

  final String name;
  final String price;
  final String unit;

  /// VD "AI 98%" hoặc "Cảnh báo AI".
  final String aiBadge;
  final bool isWarning;

  /// Ảnh local (preview). Khi nối backend → dùng [imageUrl].
  final String? assetPath;
  final String? imageUrl;

  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.borderFaint),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageArea(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.itemTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: AppTypography.chip.copyWith(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        unit,
                        style: AppTypography.caption.copyWith(fontSize: 9),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onAdd,
                        child: const Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageArea() {
    return Stack(
      children: [
        Container(
          height: 128,
          width: double.infinity,
          color: AppColors.imagePlaceholder,
          child: AppSmartImage(
            imageUrl: imageUrl,
            assetPath: assetPath,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          left: AppSpacing.xs,
          top: AppSpacing.xs,
          child: _AiBadge(label: aiBadge, isWarning: isWarning),
        ),
      ],
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge({required this.label, required this.isWarning});
  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.verified,
            size: 11,
            color: isWarning ? Colors.orange : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.chip.copyWith(
              fontSize: 9,
              height: 13.5 / 9,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
