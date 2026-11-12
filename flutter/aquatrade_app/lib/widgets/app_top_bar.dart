import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'animations.dart';

/// Top App Bar dùng chung.
/// - [AppTopBar] mặc định: logo AQUATRADE AI + các action (tìm kiếm, giỏ, thông báo)
/// - [AppTopBar.subPage]: có nút back + tiêu đề, dùng cho màn con
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.cartBadgeCount = 0,
    this.hasNotification = false,
    this.onSearch,
    this.onCart,
    this.onNotification,
  })  : _isSubPage = false,
        title = null,
        onBack = null,
        trailing = null,
        centerTitle = false;

  const AppTopBar.subPage({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.centerTitle = false,
  })  : _isSubPage = true,
        cartBadgeCount = 0,
        hasNotification = false,
        onSearch = null,
        onCart = null,
        onNotification = null;

  final bool _isSubPage;
  final String? title;
  final VoidCallback? onBack;

  /// Action bên phải của sub-page (VD nút "Sửa", icon chia sẻ).
  final Widget? trailing;

  /// Title căn giữa, style teal in hoa (VD "CHI TIẾT SẢN PHẨM").
  final bool centerTitle;
  final int cartBadgeCount;
  final bool hasNotification;
  final VoidCallback? onSearch;
  final VoidCallback? onCart;
  final VoidCallback? onNotification;

  @override
  Size get preferredSize => const Size.fromHeight(61);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            17,
          ),
          decoration: const BoxDecoration(
            color: Color(0xB3F6F8F8), // surface 70%
            border: Border(
              bottom: BorderSide(color: AppColors.borderSoft),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: _isSubPage ? _buildSubPage(context) : _buildHome(),
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.hub, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'AQUATRADE AI',
              style: AppTypography.chip.copyWith(
                fontSize: 18,
                letterSpacing: 1.8,
                height: 28 / 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _IconButton(icon: Icons.search, onTap: onSearch),
            const SizedBox(width: AppSpacing.md),
            _CartButton(count: cartBadgeCount, onTap: onCart),
            const SizedBox(width: AppSpacing.md),
            _NotificationButton(hasDot: hasNotification, onTap: onNotification),
          ],
        ),
      ],
    );
  }

  Widget _buildSubPage(BuildContext context) {
    final titleStyle = centerTitle
        ? AppTypography.chip.copyWith(
            fontSize: 16,
            height: 24 / 16,
            letterSpacing: -0.4,
            color: AppColors.primary,
          )
        : AppTypography.cardValue;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.textPrimary,
          tooltip: 'Quay lại',
          onPressed: onBack ?? () => _defaultBack(context),
        ),
        if (!centerTitle) const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            centerTitle ? (title ?? '').toUpperCase() : (title ?? ''),
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: titleStyle,
          ),
        ),
        // Giữ title cân giữa khi không có action bên phải.
        if (trailing != null)
          trailing!
        else if (centerTitle)
          const SizedBox(width: 48),
      ],
    );
  }

  /// go_router: ưu tiên [GoRouter.pop]; nếu không còn stack (VD vào bằng `go`) → Home.
  static void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Icon(icon, size: 20, color: AppColors.textSecondary),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 20, color: AppColors.textSecondary),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: AppTypography.chip.copyWith(
                    fontSize: 8,
                    height: 12 / 8,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.hasDot, this.onTap});
  final bool hasDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none,
              size: 20, color: AppColors.textSecondary),
          if (hasDot)
            const Positioned(
              right: -1,
              top: 0,
              child: PulseDot(size: 8, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
