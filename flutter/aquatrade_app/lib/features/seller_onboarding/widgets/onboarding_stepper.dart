import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Thanh tiến trình 3 bước cho luồng đăng ký gian hàng.
/// [currentStep] 0-based: bước đã qua hiển thị dấu ✓, bước hiện tại có vòng sáng.
class OnboardingStepper extends StatelessWidget {
  const OnboardingStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.circleSize = 40,
  });

  final List<String> steps;
  final int currentStep;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      children.add(_StepNode(
        label: steps[i],
        index: i,
        state: i < currentStep
            ? _StepState.done
            : (i == currentStep ? _StepState.active : _StepState.inactive),
        size: circleSize,
      ));
      if (i != steps.length - 1) {
        children.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Container(
              height: 2,
              margin: EdgeInsets.only(bottom: circleSize > 34 ? 23 : 20),
              color: i < currentStep ? AppColors.primary : AppColors.primary10,
            ),
          ),
        ));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

enum _StepState { done, active, inactive }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.label,
    required this.index,
    required this.state,
    required this.size,
  });

  final String label;
  final int index;
  final _StepState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool teal = state != _StepState.inactive;
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: teal ? AppColors.primary : AppColors.stepInactive,
        shape: BoxShape.circle,
        boxShadow: state == _StepState.active
            ? const [
                BoxShadow(
                  color: AppColors.primary20,
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : const [],
      ),
      child: state == _StepState.done
          ? Icon(Icons.check, size: size * 0.4, color: AppColors.onPrimary)
          : Text(
              '${index + 1}',
              style: AppTypography.chip.copyWith(
                fontSize: size > 34 ? 16 : 14,
                height: 1,
                color: teal ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(height: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: AppTypography.chip.copyWith(
            fontSize: size > 34 ? 10 : 9,
            letterSpacing: size > 34 ? 1 : 0.9,
            height: 15 / 10,
            color: teal ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
