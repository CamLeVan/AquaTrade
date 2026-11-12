import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_smart_image.dart';

/// Card sản phẩm nổi bật / bán chạy (scroll ngang) trên dashboard.
class FeaturedProductCard extends StatelessWidget {
  const FeaturedProductCard({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.assetPath,
    this.badgeIcon,
    this.badgeColor = AppColors.primary,
    this.purchaseCount = 0,
    this.soldQuantity = 0,
    this.rank,
    this.onAdd,
    this.onTap,
  });

  final String name;
  final String price;
  final String? imageUrl;
  final String? assetPath;
  final IconData? badgeIcon;
  final Color badgeColor;
  final int purchaseCount;
  final int soldQuantity;
  final int? rank;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            const SizedBox(height: AppSpacing.sm),
            Text(name, style: AppTypography.itemTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    price,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: const Icon(Icons.add_circle,
                      size: 20, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Badge số lượt mua
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderFaint),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    purchaseCount > 0 
                        ? '$purchaseCount lượt mua'
                        : (soldQuantity > 0 ? '$soldQuantity con đã bán' : 'Mới niêm yết'),
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        height: 112,
        width: double.infinity,
        color: AppColors.imagePlaceholder,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppSmartImage(
                imageUrl: imageUrl,
                assetPath: assetPath,
                fit: BoxFit.cover,
                placeholder: Center(
                  child: Icon(badgeIcon ?? Icons.set_meal,
                      color: AppColors.primary30, size: 36),
                ),
              ),
            ),
            // Top Rank Badge (TOP 1, TOP 2, TOP 3...)
            if (rank != null)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: rank == 1
                        ? const LinearGradient(colors: [Color(0xFFFFB703), Color(0xFFFB8500)])
                        : rank == 2
                            ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                            : rank == 3
                                ? const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)])
                                : const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0369A1)]),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 10, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        'TOP $rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (badgeIcon != null)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badgeIcon, size: 14, color: badgeColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
