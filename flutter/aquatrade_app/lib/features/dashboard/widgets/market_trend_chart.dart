import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../widgets/animations.dart';
import '../../../widgets/app_card.dart';

/// Card biểu đồ cột "Xu hướng thị trường" trên dashboard.
/// Có hiệu ứng cột mọc dần khi hiển thị (thay cho animation Stitch).
class MarketTrendChart extends StatefulWidget {
  const MarketTrendChart({
    super.key,
    required this.value,
    required this.delta,
    required this.bars,
    required this.labels,
  });

  final String value;
  final String delta;

  /// Tỉ lệ chiều cao 0..1 cho từng cột (cột cuối = 1.0 là cao nhất).
  final List<double> bars;
  final List<String> labels;

  @override
  State<MarketTrendChart> createState() => _MarketTrendChartState();
}

class _MarketTrendChartState extends State<MarketTrendChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.value,
                style: AppTypography.cardValue.copyWith(fontSize: 24, height: 32 / 24),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  widget.delta,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 144,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(widget.bars.length, (i) {
                    final isLast = i == widget.bars.length - 1;
                    final t = widget.bars.length == 1
                        ? 1.0
                        : (i / (widget.bars.length - 1));
                    final bar = Container(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          AppColors.primary10,
                          AppColors.primary,
                          t,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                    );
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomCenter,
                          heightFactor: widget.bars[i] * _controller.value,
                          // Cột cuối (CN) "live" → nhấp nháy như Stitch.
                          child: isLast ? PulseFade(child: bar) : bar,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.labels.length, (i) {
              final isLast = i == widget.labels.length - 1;
              return Text(
                widget.labels[i],
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLast ? AppColors.primary : AppColors.textSecondary,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
