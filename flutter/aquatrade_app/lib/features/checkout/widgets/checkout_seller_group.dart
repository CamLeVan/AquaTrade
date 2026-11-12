import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/app_smart_image.dart';
import '../../../widgets/status_chip.dart';

class CheckoutLineItem {
  const CheckoutLineItem({
    required this.productName,
    required this.quantity,
    required this.priceLabel,
    this.imageUrl,
    this.imageAsset,
    this.subtitle,
    this.chipLabel,
  });

  final String productName;
  final String? imageUrl;
  final String? imageAsset;
  final int quantity;
  final String priceLabel;
  final String? subtitle;
  final String? chipLabel;
}

/// Nhóm SP theo 1 người bán trên màn xác nhận thanh toán.
class CheckoutSellerGroup extends StatelessWidget {
  const CheckoutSellerGroup({
    super.key,
    required this.sellerName,
    required this.items,
    required this.shippingLabel,
    this.sellerAvatarUrl,
    this.sellerAvatarAsset,
    this.badge = 'Người bán AquaTrade',
  });

  final String sellerName;
  final String? sellerAvatarUrl;
  final String? sellerAvatarAsset;
  final String badge;
  final List<CheckoutLineItem> items;
  final String shippingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sellerName,
                        style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                    Text(
                      badge,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.onPrimaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, size: 16, color: AppColors.primary),
            ],
          ),
          for (final item in items) ...[
            const SizedBox(height: AppSpacing.md),
            _productRow(item),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.borderFaint),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'CHI PHÍ VẬN CHUYỂN',
                style: AppTypography.chip.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(shippingLabel,
                  style: AppTypography.itemTitle.copyWith(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    if (sellerAvatarUrl != null && sellerAvatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          sellerAvatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _avatarFallback(),
        ),
      );
    }
    if (sellerAvatarAsset != null && sellerAvatarAsset!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          sellerAvatarAsset!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _avatarFallback(),
        ),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.storefront, size: 18, color: AppColors.primary),
    );
  }

  Widget _productRow(CheckoutLineItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: SizedBox(
            width: 72,
            height: 72,
            child: _productImage(item),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName,
                  style: AppTypography.itemTitle.copyWith(fontSize: 14)),
              if (item.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(item.subtitle!,
                    style: AppTypography.caption.copyWith(fontSize: 11)),
              ],
              if (item.chipLabel != null) ...[
                const SizedBox(height: AppSpacing.xs),
                StatusChip(
                  label: item.chipLabel!,
                  type: StatusChipType.successDeep,
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text('Số lượng: ${item.quantity}',
                  style: AppTypography.caption.copyWith(fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                item.priceLabel,
                style: AppTypography.itemTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.onPrimaryDeep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productImage(CheckoutLineItem item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return AppSmartImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
      );
    }
    if (item.imageAsset != null && item.imageAsset!.isNotEmpty) {
      return Image.asset(
        item.imageAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(),
      );
    }
    return _imageFallback();
  }

  Widget _imageFallback() {
    return const ColoredBox(
      color: AppColors.imagePlaceholder,
      child: Center(
        child: Icon(Icons.set_meal, size: 28, color: AppColors.primary30),
      ),
    );
  }
}
