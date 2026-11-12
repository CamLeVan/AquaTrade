import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animations.dart';
import '../../../widgets/quantity_stepper.dart';

/// Khối hành động ghim đáy màn Chi tiết sản phẩm:
/// chọn số lượng + hiển thị tổng tiền + [Lưu] [Đàm phán giá] [Thêm vào giỏ].
class ProductBottomBar extends StatefulWidget {
  const ProductBottomBar({
    super.key,
    this.unitPrice = 0,
    this.onNegotiate,
    this.onAddToCart,
    this.onBookmark,
  });

  final double unitPrice;
  final VoidCallback? onNegotiate;
  final void Function(int quantity)? onAddToCart;
  final VoidCallback? onBookmark;

  @override
  State<ProductBottomBar> createState() => _ProductBottomBarState();
}

class _ProductBottomBarState extends State<ProductBottomBar> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.unitPrice > 0 ? widget.unitPrice * _quantity : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF), // trắng 95% + blur cảm giác kính
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SỐ LƯỢNG (CON/KG)',
                style: AppTypography.overline
                    .copyWith(color: AppColors.textStrong),
              ),
              QuantityStepper(
                value: _quantity,
                onChanged: (v) => setState(() => _quantity = v),
              ),
            ],
          ),
          if (widget.unitPrice > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TỔNG TẠM TÍNH:',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(totalPrice),
                  style: AppTypography.cardValue.copyWith(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              PressableScale(
                onTap: widget.onBookmark,
                pressedScale: 0.9,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.segmentTrack,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: const Icon(Icons.bookmark_border,
                      size: 20, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _compactButton(
                  label: 'TRÒ CHUYỆN',
                  bg: AppColors.surfaceHigh,
                  fg: AppColors.textStrong,
                  icon: Icons.chat_bubble_outline,
                  onTap: widget.onNegotiate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: _compactButton(
                  label: 'THÊM VÀO GIỎ',
                  bg: AppColors.primary,
                  fg: AppColors.onPrimary,
                  icon: Icons.shopping_cart,
                  onTap: widget.onAddToCart != null
                      ? () => widget.onAddToCart!(_quantity)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactButton({
    required String label,
    required Color bg,
    required Color fg,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: bg == AppColors.primary
              ? null
              : Border.all(color: AppColors.borderSoft),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.chip.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
