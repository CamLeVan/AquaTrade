import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../features/auth/auth_navigation.dart';
import 'app_button.dart';

/// Bottom sheet mời đăng nhập (Hướng 1) — giữ ngữ cảnh, 2 nút, vuốt xuống = huỷ.
class AuthRequiredSheet extends StatelessWidget {
  const AuthRequiredSheet({
    super.key,
    required this.reason,
    this.from,
  });

  final String reason;
  final String? from;

  void _goAuth(BuildContext context, String path) {
    final fromPath = from ?? GoRouterState.of(context).uri.toString();
    final target = Uri(
      path: path,
      queryParameters: {
        'reason': reason,
        if (fromPath.isNotEmpty) 'from': fromPath,
      },
    ).toString();
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    navigator.pop();
    router.push(target);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Đăng nhập để tiếp tục',
            textAlign: TextAlign.center,
            style: AppTypography.heading.copyWith(
              fontSize: 20,
              letterSpacing: -0.4,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            LoginReasons.messageFor(reason),
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              height: 22 / 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Đăng nhập',
            onPressed: () => _goAuth(context, AppRoutes.login),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Đăng ký',
            variant: AppButtonVariant.secondary,
            onPressed: () => _goAuth(context, AppRoutes.register),
          ),
        ],
      ),
    );
  }
}

/// Hiện sheet Hướng 1 (không redirect, không SnackBar).
Future<void> showAuthRequiredSheet(
  BuildContext context, {
  required String reason,
  String? from,
}) {
  final fromPath = from ?? GoRouterState.of(context).uri.toString();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) => AuthRequiredSheet(reason: reason, from: fromPath),
  );
}
