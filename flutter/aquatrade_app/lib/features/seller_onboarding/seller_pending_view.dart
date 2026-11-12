import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';

/// Nội dung tab "Gian hàng của tôi" khi hồ sơ người bán ĐANG CHỜ DUYỆT.
class SellerPendingView extends StatelessWidget {
  const SellerPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        const EmptyState(
          icon: Icons.hourglass_empty,
          art: EmptyStateArt.card,
          title: 'Hồ sơ của bạn đang được xét duyệt',
          message:
              'Chúng tôi sẽ hoàn tất xác thực thông tin gian hàng trong vòng 24h tới. '
              'Cảm ơn bạn đã kiên nhẫn.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TIẾN TRÌNH XÁC THỰC',
                    style: AppTypography.overline.copyWith(height: 18 / 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary10,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Đang xử lý',
                      style: AppTypography.chip.copyWith(
                        fontSize: 12,
                        height: 16 / 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(height: 1, color: AppColors.borderFaint),
              ),
              const _StatusStep(
                state: _TrackState.done,
                title: 'Đã gửi hồ sơ',
                subtitle: '10:00, 24/05',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _StatusStep(
                state: _TrackState.current,
                title: 'Đang xét duyệt',
                subtitle: 'Hiện tại',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _StatusStep(
                state: _TrackState.pending,
                title: 'Hoàn tất',
                subtitle: 'Dự kiến: Sau 24h',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cần hỗ trợ? Liên hệ ngay',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.arrow_forward,
                  size: 14, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TrackState { done, current, pending }

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.state,
    required this.title,
    required this.subtitle,
  });

  final _TrackState state;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _circle(),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.itemTitle.copyWith(fontSize: 14, height: 20 / 14),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            fontSize: 12,
            height: 16 / 12,
            color: state == _TrackState.current
                ? AppColors.primary
                : AppColors.textSecondary,
            fontStyle: state == _TrackState.pending
                ? FontStyle.italic
                : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  Widget _circle() {
    switch (state) {
      case _TrackState.done:
        return Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 20, color: AppColors.onPrimary),
        );
      case _TrackState.current:
        return Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary10,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.sync, size: 18, color: AppColors.primary),
        );
      case _TrackState.pending:
        return Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.stepInactive,
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
        );
    }
  }
}
