import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';

/// Màn kết quả nạp tiền.
/// DEMO: deposit cộng ví ngay → `pendingApproval=false`. Production có thể bật lại PENDING.
class TopupSuccessScreen extends StatelessWidget {
  const TopupSuccessScreen({
    super.key,
    this.amountLabel = '1.000.000',
    this.methodLabel = 'Chuyển khoản',
    this.pendingApproval = true,
  });

  final String amountLabel;
  final String methodLabel;
  final bool pendingApproval;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar.subPage(
        title: 'Kết quả nạp tiền',
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.primary20,
                    shape: BoxShape.circle,
                  ),
                ),
                PulseFade(
                  child: Icon(
                    pendingApproval
                        ? Icons.hourglass_top_rounded
                        : Icons.check_circle,
                    size: 88,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            pendingApproval
                ? 'Đã gửi yêu cầu nạp tiền!'
                : 'Nạp tiền thành công!',
            textAlign: TextAlign.center,
            style: AppTypography.heading.copyWith(fontSize: 24, height: 32 / 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            pendingApproval
                ? 'Yêu cầu đang chờ Admin duyệt — số dư chưa đổi ngay.'
                : 'Số dư của bạn đã được cập nhật',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderFaint),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                  color: AppColors.primary10,
                  child: Column(
                    children: [
                      Text(
                        'SỐ TIỀN GIAO DỊCH',
                        style: AppTypography.chip.copyWith(
                          letterSpacing: 1.5,
                          color: AppColors.onPrimaryDeep,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text.rich(
                        TextSpan(
                          style: AppTypography.heading.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: AppColors.onPrimaryDeep,
                          ),
                          children: [
                            TextSpan(text: amountLabel),
                            TextSpan(
                              text: ' ₫',
                              style: AppTypography.heading.copyWith(
                                fontSize: 20,
                                color: AppColors.onPrimaryDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _row(
                        'Phương thức',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(methodLabel,
                                style: AppTypography.itemTitle
                                    .copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      _dashed(),
                      _row(
                        'Trạng thái',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary10,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const PulseDot(
                                  size: 6, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                pendingApproval ? 'CHỜ DUYỆT' : 'HOÀN TẤT',
                                style: AppTypography.chip.copyWith(
                                  letterSpacing: 0.8,
                                  color: AppColors.onPrimaryDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Về trang chủ',
            uppercase: true,
            onPressed: () => context.go(AppRoutes.home),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Xem ví của tôi',
            uppercase: true,
            variant: AppButtonVariant.softTeal,
            onPressed: () => context.go(AppRoutes.wallet),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, {required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text(label,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  Widget _dashed() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, c) {
          const dash = 4.0;
          final n = (c.maxWidth / (dash * 2)).floor();
          return Row(
            children: List.generate(
              n,
              (_) => Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  color: AppColors.borderFaint,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
