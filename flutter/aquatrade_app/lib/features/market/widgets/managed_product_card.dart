import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/app_smart_image.dart';
import '../../../widgets/status_chip.dart';

/// Thẻ sản phẩm đã đăng (có nút Sửa/Xóa) trên tab "Sản phẩm" của gian hàng.
class ManagedProductCard extends StatelessWidget {
  const ManagedProductCard({
    super.key,
    required this.name,
    required this.stock,
    required this.price,
    required this.statusLabel,
    this.outOfStock = false,
    this.assetPath,
    this.imageUrl,
    this.onEdit,
    this.onDelete,
  });

  final String name;
  final String stock;
  final String price;
  final String statusLabel;
  final bool outOfStock;
  final String? assetPath;
  final String? imageUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.imagePlaceholder,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: AppSmartImage(
                  imageUrl: imageUrl,
                  assetPath: assetPath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(name,
                              style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        StatusChip(
                          label: statusLabel,
                          type: outOfStock
                              ? StatusChipType.error
                              : StatusChipType.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('Kho: $stock',
                        style: AppTypography.caption.copyWith(fontSize: 12)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(price,
                        style: AppTypography.itemTitle
                            .copyWith(fontSize: 14, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderFaint),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _iconAction(Icons.edit, 'Sửa', AppColors.textSecondary, onEdit),
              const SizedBox(width: AppSpacing.lg),
              _iconAction(Icons.delete_outline, 'Xóa', AppColors.textSecondary, onDelete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(label,
              style: AppTypography.caption.copyWith(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
