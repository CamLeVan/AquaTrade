import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';
import '../../../widgets/status_chip.dart';

/// Thẻ đơn hàng (đơn bán) trên màn Quản lý gian hàng.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.orderCode,
    required this.customer,
    required this.status,
    required this.statusType,
    required this.timeAgo,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.actionLabel,
    this.actionPrimary = false,
    this.statusPulse = false,
    this.assetPath,
    this.onDetail,
    this.onAction,
  });

  final String orderCode;
  final String customer;
  final String status;
  final StatusChipType statusType;
  final bool statusPulse;
  final String timeAgo;
  final String productName;
  final String quantity;
  final String price;
  final String actionLabel;
  final bool actionPrimary;
  final String? assetPath;
  final VoidCallback? onDetail;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã đơn: $orderCode'.toUpperCase(),
                      style: AppTypography.chip.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        height: 15 / 10,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(customer,
                      style: AppTypography.itemTitle
                          .copyWith(fontSize: 16, height: 20 / 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(label: status, type: statusType, showDot: statusPulse),
                  const SizedBox(height: AppSpacing.xs),
                  Text(timeAgo,
                      style: AppTypography.caption.copyWith(
                          fontSize: 10, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderFaint),
                bottom: BorderSide(color: AppColors.borderFaint),
              ),
            ),
            child: Row(
              children: [
                _thumb(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productName,
                          style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Số lượng: $quantity',
                          style: AppTypography.caption.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Text(price,
                    style: AppTypography.itemTitle.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onDetail,
                child: Text('Xem chi tiết',
                    style: AppTypography.chip.copyWith(
                        fontSize: 12, height: 16 / 12, color: AppColors.primary)),
              ),
              _actionButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumb() {
    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: assetPath != null
          ? Image.asset(assetPath!, fit: BoxFit.cover)
          : const Icon(Icons.set_meal, color: AppColors.primary30),
    );
  }

  Widget _actionButton() {
    final bg = actionPrimary ? AppColors.primary : AppColors.inputFill;
    final fg = actionPrimary ? AppColors.onPrimary : AppColors.textSecondary;
    return PressableScale(
      onTap: onAction,
      pressedScale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Text(actionLabel,
            style: AppTypography.chip.copyWith(
                fontSize: 12, height: 16 / 12, color: fg)),
      ),
    );
  }
}
