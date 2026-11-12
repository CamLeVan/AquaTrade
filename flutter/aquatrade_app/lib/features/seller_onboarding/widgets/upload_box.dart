import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';

/// Ô tải tệp dạng viền đứt (upload ảnh CCCD / giấy phép kinh doanh).
class UploadBox extends StatelessWidget {
  const UploadBox({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.cloud_upload_outlined,
    this.actionLabel,
    this.height = 160,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// Nếu có → hiển thị nút chip nhỏ (VD "Tải lên tệp PDF/Image").
  final String? actionLabel;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.99,
      child: _DashedBorder(
        radius: AppSpacing.radiusLg,
        color: AppColors.primary20,
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTypography.chip.copyWith(
                      fontSize: 12,
                      height: 18 / 12,
                      color: AppColors.onPrimaryDeep,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Viền đứt bo góc dùng cho ô upload.
class _DashedBorder extends StatelessWidget {
  const _DashedBorder({
    required this.child,
    required this.color,
    required this.radius,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, dist + dashWidth),
          paint,
        );
        dist += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
