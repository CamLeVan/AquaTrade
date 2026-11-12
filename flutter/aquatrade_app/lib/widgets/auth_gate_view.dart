import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../core/theme/app_spacing.dart';
import '../features/auth/auth_navigation.dart';
import 'app_button.dart';
import 'empty_state.dart';

/// Trang khoá toàn màn (Hướng 2) — EmptyState + Đăng nhập / Đăng ký.
/// Dùng khi guest vào đúng URL (`/account`, `/wallet`…) thay vì redirect Login.
class AuthGateView extends StatelessWidget {
  const AuthGateView({
    super.key,
    required this.reason,
    this.from,
    this.icon,
    this.title = 'Đăng nhập để xem tiếp',
    this.art = EmptyStateArt.card,
  });

  final String reason;

  /// Sau login/register quay lại URL này (mặc định: route hiện tại).
  final String? from;

  final IconData? icon;
  final String title;
  final EmptyStateArt art;

  IconData get _icon => icon ?? _iconFor(reason);

  static IconData _iconFor(String reason) {
    switch (reason) {
      case LoginReasons.account:
        return Icons.person_outline;
      case LoginReasons.chat:
        return Icons.chat_bubble_outline;
      case LoginReasons.ai:
        return Icons.document_scanner_outlined;
      case LoginReasons.cart:
      case LoginReasons.checkout:
        return Icons.shopping_cart_outlined;
      case LoginReasons.wallet:
        return Icons.account_balance_wallet_outlined;
      case LoginReasons.orders:
        return Icons.receipt_long_outlined;
      case LoginReasons.shop:
      case LoginReasons.listing:
        return Icons.storefront_outlined;
      case LoginReasons.seller:
        return Icons.badge_outlined;
      default:
        return Icons.lock_outline;
    }
  }

  void _goAuth(BuildContext context, String path) {
    final fromPath = from ?? GoRouterState.of(context).uri.toString();
    final target = Uri(
      path: path,
      queryParameters: {
        'reason': reason,
        if (fromPath.isNotEmpty) 'from': fromPath,
      },
    ).toString();
    context.push(target);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: EmptyState(
              icon: _icon,
              title: title,
              message: LoginReasons.messageFor(reason),
              art: art,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
            ),
          ),
        ),
      ),
    );
  }
}
