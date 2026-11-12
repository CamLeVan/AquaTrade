import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'animations.dart';

/// Bộ tăng/giảm số lượng (-, nhập số trực tiếp, +) dùng chung.
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    this.onChanged,
    this.dense = false,
    this.min = 1,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final bool dense;
  final int min;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final currentTextVal = int.tryParse(_controller.text) ?? widget.min;
      if (currentTextVal != widget.value) {
        _controller.text = '${widget.value}';
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitted(String valStr) {
    int parsed = int.tryParse(valStr) ?? widget.min;
    if (parsed < widget.min) parsed = widget.min;
    _controller.text = '$parsed';
    widget.onChanged?.call(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final btnSize = widget.dense ? 22.0 : 32.0;
    final iconSize = widget.dense ? 14.0 : 16.0;

    return Container(
      height: widget.dense ? 30 : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.dense ? 2 : 5,
        vertical: widget.dense ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: widget.dense ? AppColors.imagePlaceholder : AppColors.segmentTrack,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: widget.dense ? null : Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            icon: Icons.remove,
            size: btnSize,
            iconSize: iconSize,
            color: AppColors.textSecondary,
            onTap: widget.value > widget.min
                ? () {
                    final newVal = widget.value - 1;
                    _controller.text = '$newVal';
                    widget.onChanged?.call(newVal);
                  }
                : null,
          ),
          SizedBox(
            width: widget.dense ? 28 : 64,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: widget.dense
                  ? AppTypography.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    )
                  : AppTypography.itemTitle
                      .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed >= widget.min) {
                  widget.onChanged?.call(parsed);
                }
              },
              onSubmitted: _onSubmitted,
            ),
          ),
          _btn(
            icon: Icons.add,
            size: btnSize,
            iconSize: iconSize,
            color: widget.dense ? AppColors.textSecondary : AppColors.primary,
            onTap: () {
              final newVal = widget.value + 1;
              _controller.text = '$newVal';
              widget.onChanged?.call(newVal);
            },
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required double size,
    required double iconSize,
    required Color color,
    VoidCallback? onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
