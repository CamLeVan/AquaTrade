import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/order_model.dart';
import '../../../widgets/animations.dart';
import '../../../widgets/app_smart_image.dart';
import '../../../widgets/status_chip.dart';

/// Tab filter UI ↔ BE status (audit):
/// CHỜ TT ≈ PENDING / ESCROW_LOCKED
/// ĐANG GIAO ≈ SHIPPING
/// HOÀN THÀNH ≈ COMPLETED
/// ĐÃ HỦY ≈ CANCELLED
enum OrderStatusFilter { all, awaitingPayment, shipping, completed, cancelled }

extension OrderStatusFilterX on OrderStatusFilter {
  bool matches(OrderStatus status) {
    switch (this) {
      case OrderStatusFilter.all:
        return true;
      case OrderStatusFilter.awaitingPayment:
        return status == OrderStatus.PENDING ||
            status == OrderStatus.ESCROW_LOCKED ||
            status == OrderStatus.PREPARING ||
            status == OrderStatus.COUNTING_AI ||
            status == OrderStatus.AI_VERIFIED;
      case OrderStatusFilter.shipping:
        return status == OrderStatus.SHIPPING ||
            status == OrderStatus.DELIVERED ||
            status == OrderStatus.READY_TO_PAYOUT ||
            status == OrderStatus.DISPUTED;
      case OrderStatusFilter.completed:
        return status == OrderStatus.COMPLETED;
      case OrderStatusFilter.cancelled:
        return status == OrderStatus.CANCELLED;
    }
  }
}

extension OrderStatusUiX on OrderStatus {
  String get historyLabel {
    switch (this) {
      case OrderStatus.PENDING:
        return 'Chờ thanh toán';
      case OrderStatus.ESCROW_LOCKED:
        return 'Đã khóa Escrow';
      case OrderStatus.PREPARING:
        return 'Đang chuẩn bị';
      case OrderStatus.COUNTING_AI:
        return 'Đang đếm AI';
      case OrderStatus.AI_VERIFIED:
        return 'AI đã chốt';
      case OrderStatus.SHIPPING:
        return 'Đang giao hàng';
      case OrderStatus.DELIVERED:
        return 'Đã giao tới';
      case OrderStatus.READY_TO_PAYOUT:
        return 'Chờ giải ngân';
      case OrderStatus.DISPUTED:
        return 'Đang tranh chấp';
      case OrderStatus.COMPLETED:
        return 'Hoàn thành';
      case OrderStatus.CANCELLED:
        return 'Đã hủy';
      default:
        return name;
    }
  }

  StatusChipType get historyChipType {
    switch (this) {
      case OrderStatus.PENDING:
      case OrderStatus.PREPARING:
        return StatusChipType.tertiary;
      case OrderStatus.ESCROW_LOCKED:
      case OrderStatus.AI_VERIFIED:
        return StatusChipType.success;
      case OrderStatus.COUNTING_AI:
      case OrderStatus.SHIPPING:
      case OrderStatus.DELIVERED:
        return StatusChipType.info;
      case OrderStatus.READY_TO_PAYOUT:
        return StatusChipType.successDeep;
      case OrderStatus.DISPUTED:
      case OrderStatus.CANCELLED:
        return StatusChipType.errorSoft;
      case OrderStatus.COMPLETED:
        return StatusChipType.successDeep;
      default:
        return StatusChipType.info;
    }
  }

  bool get historyShowDot =>
      this == OrderStatus.COUNTING_AI ||
      this == OrderStatus.SHIPPING ||
      this == OrderStatus.DELIVERED;

  String get historyPrimaryAction =>
      this == OrderStatus.COMPLETED ? 'MUA LẠI' : 'CHI TIẾT';
}

/// Card 1 đơn trong danh sách lịch sử mua.
class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({
    super.key,
    required this.sellerName,
    required this.statusLabel,
    required this.statusType,
    required this.productName,
    required this.variant,
    required this.quantityLabel,
    required this.unitPriceLabel,
    required this.totalLabel,
    required this.primaryActionLabel,
    this.timeLabel,
    this.sellerAvatar,
    this.productImage,
    this.productImageUrl,
    this.onPrimary,
    this.onProof,
    this.onChat,
    this.onTap,
    this.statusShowDot = false,
  });

  final String sellerName;
  final String? timeLabel;
  final String? sellerAvatar;
  final String statusLabel;
  final StatusChipType statusType;
  final bool statusShowDot;
  final String productName;
  final String? productImage;
  final String? productImageUrl;
  final String variant;
  final String quantityLabel;
  final String unitPriceLabel;
  final String totalLabel;
  final String primaryActionLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onProof;
  final VoidCallback? onChat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.borderFaint),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _thumb(
                    asset: sellerAvatar,
                    width: 28,
                    height: 28,
                    fallback: Icons.storefront,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sellerName,
                          style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                      if (timeLabel != null && timeLabel!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          timeLabel!,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusChip(
                  label: statusLabel,
                  type: statusType,
                  showDot: statusShowDot,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: _thumb(
                    asset: productImage,
                    url: productImageUrl,
                    width: 64,
                    height: 64,
                    fallback: Icons.set_meal,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName,
                          style:
                              AppTypography.itemTitle.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        'Phân loại: $variant',
                        style: AppTypography.caption.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(quantityLabel,
                              style: AppTypography.caption
                                  .copyWith(fontSize: 12)),
                          const Spacer(),
                          Text(unitPriceLabel,
                              style: AppTypography.itemTitle
                                  .copyWith(fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text('Tổng thanh toán:',
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
                const Spacer(),
                Text(
                  totalLabel,
                  style: AppTypography.heading.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (onChat != null) ...[
                  PressableScale(
                    onTap: onChat,
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary10,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.primary30),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: _outlineBtn(
                    label: 'BẰNG CHỨNG',
                    icon: Icons.verified_outlined,
                    onTap: onProof,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _filledBtn(
                    label: primaryActionLabel,
                    primary: primaryActionLabel == 'MUA LẠI',
                    onTap: onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb({
    String? asset,
    String? url,
    required double width,
    required double height,
    required IconData fallback,
  }) {
    Widget child;
    if (asset != null && asset.isNotEmpty) {
      child = Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(width, height, fallback),
      );
    } else if (url != null && url.isNotEmpty) {
      child = AppSmartImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      child = _placeholder(width, height, fallback);
    }
    return SizedBox(width: width, height: height, child: child);
  }

  Widget _placeholder(double w, double h, IconData icon) {
    return Container(
      width: w,
      height: h,
      color: AppColors.imagePlaceholder,
      child: Icon(icon, size: w * 0.4, color: AppColors.primary30),
    );
  }

  Widget _outlineBtn({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.primary30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.chip.copyWith(
                letterSpacing: 0.6,
                color: AppColors.onPrimaryDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filledBtn({
    required String label,
    required bool primary,
    VoidCallback? onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(
            letterSpacing: 0.6,
            color: primary ? AppColors.onPrimary : AppColors.textStrong,
          ),
        ),
      ),
    );
  }
}
