import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/quantity_stepper.dart';
import '../../../widgets/status_chip.dart';
import 'cart_checkbox.dart';

/// Ma trận bỏ bão hòa màu (grayscale) cho ảnh sản phẩm có giá thay đổi.
const _grayscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

/// Thẻ 1 sản phẩm trong Giỏ hàng (Figma 2109:3256).
/// [priceChanged] = true → thẻ mờ, ảnh xám, hiện giá cũ gạch ngang, khoá chọn.
class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.name,
    required this.price,
    this.assetPath,
    this.imageUrl,
    this.oldPrice,
    this.quantity = 1,
    this.chipLabel,
    this.checked = true,
    this.priceChanged = false,
    this.showRemove = false,
    this.onCheckChanged,
    this.onQuantityChanged,
    this.onRemove,
  });

  final String name;
  final String price;
  final String? oldPrice;
  final int quantity;
  final String? chipLabel;
  final String? assetPath;
  final String? imageUrl;
  final bool checked;
  final bool priceChanged;
  final bool showRemove;
  final ValueChanged<bool>? onCheckChanged;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md + 1,
        AppSpacing.md + 1,
        AppSpacing.md + 1,
      ),
      decoration: BoxDecoration(
        color: priceChanged
            ? AppColors.segmentTrack.withValues(alpha: 0.5)
            : AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: priceChanged
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CartCheckbox(
            checked: checked,
            disabled: priceChanged,
            onChanged: onCheckChanged,
          ),
          const SizedBox(width: AppSpacing.md - 1),
          _thumb(),
          const SizedBox(width: AppSpacing.md - 1),
          Expanded(
            child: SizedBox(
              height: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.itemTitle.copyWith(
                            fontSize: 14,
                            height: 17.5 / 14,
                            color: priceChanged
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (showRemove && onRemove != null)
                        GestureDetector(
                          onTap: onRemove,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (chipLabel != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    StatusChip(
                      label: chipLabel!,
                      type: priceChanged
                          ? StatusChipType.errorSoft
                          : StatusChipType.successDeep,
                    ),
                  ],
                  const Spacer(),
                  if (priceChanged) _changedPrice() else _priceRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return priceChanged ? Opacity(opacity: 0.7, child: card) : card;
  }

  Widget _thumb() {
    Widget image;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => const Center(
          child: Icon(Icons.set_meal, size: 36, color: AppColors.primary30),
        ),
      );
    } else if (assetPath != null && assetPath!.isNotEmpty) {
      image = Image.asset(assetPath!, fit: BoxFit.cover);
    } else {
      image = const Center(
        child: Icon(Icons.set_meal, size: 36, color: AppColors.primary30),
      );
    }

    if (priceChanged) {
      image = Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
            child: image,
          ),
          Container(color: AppColors.card.withValues(alpha: 0.2)),
        ],
      );
    }
    return Container(
      width: 96,
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: image,
    );
  }

  Widget _priceRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.itemTitle.copyWith(
              fontSize: 16,
              height: 24 / 16,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        QuantityStepper(
          value: quantity,
          dense: true,
          onChanged: onQuantityChanged,
        ),
      ],
    );
  }

  Widget _changedPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          oldPrice ?? '',
          style: AppTypography.caption.copyWith(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            decoration: TextDecoration.lineThrough,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        Text(
          price,
          style: AppTypography.itemTitle.copyWith(
            fontSize: 16,
            height: 24 / 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
