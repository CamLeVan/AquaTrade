import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../../widgets/animations.dart';
import '../auth/auth_navigation.dart';

/// Hub FAB Quét AI — 2 lựa chọn (Phase 1C: Quét nhanh disabled).
class AiScanHubScreen extends StatelessWidget {
  const AiScanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar.subPage(
        title: 'Quét AI đếm cá',
        centerTitle: true,
      ),
      body: auth.isAuthenticated
          ? ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  'Chọn loại quét phù hợp. Kết quả xác nhận đơn hàng mới dùng cho giao dịch.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _ScanOptionCard(
                  icon: Icons.photo_camera_outlined,
                  title: 'Quét nhanh (tham khảo)',
                  subtitle:
                      'Đếm số lượng ngay bằng ảnh, không cần đơn hàng.',
                  actionLabel: 'Sắp ra mắt',
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                _ScanOptionCard(
                  icon: Icons.videocam_outlined,
                  title: 'Quét xác nhận đơn hàng',
                  subtitle:
                      'Quay video xác nhận số lượng cho đơn đã đặt (theo mẻ).',
                  actionLabel: 'Chọn',
                  enabled: true,
                  onTap: () => context.push(AppRoutes.aiScanOrders),
                ),
              ],
            )
          : const AuthGateView(
              reason: LoginReasons.ai,
              from: AppRoutes.aiScan,
              title: 'Đăng nhập để quét AI',
            ),
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: enabled ? AppColors.borderFaint : AppColors.stepInactive,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary10,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.itemTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      actionLabel,
                      style: AppTypography.chip.copyWith(
                        color: enabled
                            ? AppColors.onPrimaryDeep
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!enabled || onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}
