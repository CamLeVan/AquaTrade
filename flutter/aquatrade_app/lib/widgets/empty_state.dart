import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Kiểu icon minh hoạ cho [EmptyState].
/// - [EmptyStateArt.rings] : 2 vòng tròn teal đồng tâm (VD "Bạn chưa có gian hàng").
/// - [EmptyStateArt.card]  : icon trong thẻ trắng bo tròn + quầng sáng (VD "Đang chờ duyệt").
enum EmptyStateArt { rings, card }

/// Trạng thái rỗng / thông báo dùng chung: icon minh hoạ + tiêu đề + mô tả.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.art = EmptyStateArt.rings,
    this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final EmptyStateArt art;

  /// Nội dung bổ sung bên dưới mô tả (VD nút CTA, danh sách lợi ích).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: art == EmptyStateArt.rings ? _rings() : _card(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.heading.copyWith(
            fontSize: 24,
            letterSpacing: -0.6,
            height: 32 / 24,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(height: 22.75 / 14),
        ),
        if (child != null) ...[
          const SizedBox(height: AppSpacing.lg),
          child!,
        ],
      ],
    );
  }

  Widget _rings() {
    return Container(
      width: 128,
      height: 128,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary05,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary10,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 44, color: AppColors.primary),
      ),
    );
  }

  Widget _card() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.primary10,
            borderRadius: BorderRadius.circular(90),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        Container(
          width: 128,
          height: 128,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 8),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 48, color: AppColors.primary),
        ),
      ],
    );
  }
}
