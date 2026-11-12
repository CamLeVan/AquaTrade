import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';

/// Màn sau đặt hàng — đơn đã tạo nhưng thường còn PENDING (chờ khoá escrow).
class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key, this.orderIds = const []});

  final List<String> orderIds;

  @override
  Widget build(BuildContext context) {
    final codes = orderIds.isNotEmpty
        ? orderIds.map((id) => '#${id.length > 8 ? id.substring(0, 8) : id}').toList()
        : const <String>['—'];
    final count = orderIds.isNotEmpty ? orderIds.length : codes.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Trạng thái đơn hàng',
        centerTitle: true,
        trailing: PressableScale(
          onTap: () {},
          child: const SizedBox(
            width: 48,
            child: Icon(Icons.more_vert, color: AppColors.textSecondary),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top,
                  size: 44, color: AppColors.onPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Đơn hàng đã tạo — chờ xử lý',
            textAlign: TextAlign.center,
            style: AppTypography.heading.copyWith(fontSize: 24, height: 32 / 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            count > 1
                ? '$count đơn đã được tạo và đang ở trạng thái PENDING (chờ khoá tiền escrow / xác nhận).'
                : 'Đơn đã được tạo và đang ở trạng thái PENDING (chờ khoá tiền escrow / xác nhận).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MÃ TRA CỨU ĐƠN HÀNG',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 1.0,
                    color: AppColors.onPrimaryDeep,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final code in codes) ...[
                  _codeRow(context, code),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: PulseDot(size: 6, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Đây chưa phải thanh toán hoàn tất — theo dõi trạng thái trong Lịch sử đơn mua.',
                        style: AppTypography.caption.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Xem đơn hàng',
            icon: Icons.receipt_long,
            onPressed: () => context.go(AppRoutes.orders),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Về trang chủ',
            variant: AppButtonVariant.softTeal,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }

  Widget _codeRow(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(code,
                style: AppTypography.itemTitle.copyWith(fontSize: 14)),
          ),
          PressableScale(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép $code')),
              );
            },
            child: const Icon(Icons.content_copy,
                size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
