import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';

/// Tab "Phân tích AI" của màn Chi tiết sản phẩm:
/// card Bioscan (vòng điểm sức khỏe) + thanh độ tươi giảm dần.
class AiAnalysisPanel extends StatelessWidget {
  const AiAnalysisPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary05,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.primary20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BIOSCAN THỜI GIAN THỰC',
                    style: AppTypography.overline
                        .copyWith(color: AppColors.onPrimaryDeep),
                  ),
                  const PulseDot(size: 8, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const _ScoreRing(score: 92),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Điểm Sức Khỏe: Tối Ưu',
                            style: AppTypography.itemTitle
                                .copyWith(fontSize: 14)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Phân tích AI cho thấy độ tươi 98% và không phát hiện '
                          'dư lượng hóa chất. Phù hợp chế biến ngay.',
                          style: AppTypography.caption
                              .copyWith(fontSize: 12, height: 18 / 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ĐỘ TƯƠI GIẢM DẦN',
                      style: AppTypography.overline
                          .copyWith(color: AppColors.textPrimary)),
                  Text('Còn 4.2 ngày',
                      style: AppTypography.caption.copyWith(fontSize: 12)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 85,
                        child: Container(color: AppColors.primary),
                      ),
                      Expanded(
                        flex: 15,
                        child: Container(color: AppColors.surfaceHigh),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vòng tròn điểm số (92/100) — port từ SVG stroke-dashoffset của Stitch.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _RingPainter(progress: score / 100),
        child: Center(
          child: Text(
            '$score',
            style: AppTypography.heading.copyWith(fontSize: 18, height: 1),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - 6) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppColors.primary10;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
