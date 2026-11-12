import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import 'widgets/account_menu_item.dart';
import 'widgets/wallet_summary_card.dart';

/// Hub Tài khoản — `GET /users/me` + `GET /users/me/wallet`.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<WalletProvider>().fetchWallet();
        context.read<OrderProvider>().fetchMyOrders();
      }
    });
  }

  String _roleLabel(RoleProvider role, bool isAuthenticated) {
    if (!isAuthenticated) return 'Chưa đăng nhập';
    if (role.canSell) return 'Người bán';
    if (role.isPending) return 'Chờ duyệt';
    return 'Người mua';
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>();
    final auth = context.watch<AuthProvider>();
    final wallet = context.watch<WalletProvider>().wallet;
    final user = auth.currentUser;
    final balanceLabel = !auth.isAuthenticated
        ? '0'
        : AppFormatters.formatNumber(wallet?.balance ?? 0);

    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            _topBar(context),
            const Expanded(
              child: AuthGateView(
                reason: LoginReasons.account,
                from: AppRoutes.account,
                title: 'Đăng nhập để xem hồ sơ',
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _topBar(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                _profileHeader(
                  role,
                  isAuthenticated: auth.isAuthenticated,
                  name: auth.isAuthenticated
                      ? (user?.fullName.isNotEmpty == true ? user!.fullName : 'Tài khoản AquaTrade')
                      : 'Khách vãng lai',
                  email: auth.isAuthenticated
                      ? (user?.email.isNotEmpty == true ? user!.email : 'user@aquatrade.ai')
                      : 'Chưa đăng nhập tài khoản',
                ),
                const SizedBox(height: AppSpacing.xl),
                WalletSummaryCard(
                  balanceLabel: balanceLabel,
                  // Buyer-only: ẩn Rút tiền. Seller: snackbar (BE chưa có withdraw).
                  showWithdraw: auth.isAuthenticated && role.canSell,
                  onDeposit: () => context.push(AppRoutes.walletTopup),
                  onWithdraw: () => context.push(AppRoutes.walletWithdraw),
                  onTap: () => context.push(AppRoutes.wallet),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'QUẢN LÝ ỨNG DỤNG',
                  style: AppTypography.overline.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _menuGroup(context),
                const SizedBox(height: AppSpacing.lg),
                _logoutButton(context, auth),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'AQUATRADE AI V2.4.1 PREMIUM',
                  textAlign: TextAlign.center,
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 2,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header riêng màn Tài khoản: waves + title + chuông (khác home / subPage).
  Widget _topBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            MediaQuery.of(context).padding.top + AppSpacing.md,
            AppSpacing.xl,
            17,
          ),
          decoration: const BoxDecoration(
            color: Color(0xB3F6F8F8),
            border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
          ),
          child: Row(
            children: [
              const Icon(Icons.waves, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'TÀI KHOẢN',
                style: AppTypography.chip.copyWith(
                  fontSize: 20,
                  height: 30 / 20,
                  letterSpacing: -0.5,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              PressableScale(
                onTap: () {},
                child: const Icon(Icons.notifications_none,
                    size: 22, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(
    RoleProvider role, {
    required bool isAuthenticated,
    required String name,
    required String email,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Image.asset(
                    'assets/images/account/avatar.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              // Badge verified — chỉ hiện khi authenticated
              if (isAuthenticated)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Icon(Icons.verified,
                        size: 14, color: AppColors.onPrimary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.cardValue.copyWith(
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                email,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary10,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.primary20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulseDot(size: 6, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _roleLabel(role, isAuthenticated).toUpperCase(),
                      style: AppTypography.chip.copyWith(
                        letterSpacing: 1,
                        color: AppColors.onPrimaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuGroup(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = context.watch<RoleProvider>();
    final orderCount = context.watch<OrderProvider>().orders.length;
    final isAdmin = role.currentRole == UserRole.admin || auth.currentUser?.role.name == 'ADMIN';
    final isSeller = auth.isAuthenticated && (role.canSell || role.showSellerDashboard || role.currentRole == UserRole.seller);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        children: [
          if (isAdmin)
            AccountMenuItem(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Bảng quản trị Admin Console',
              subtitle: 'Duyệt tin đăng chờ & xử lý tranh chấp',
              onTap: () => context.push(AppRoutes.adminConsole),
            ),
          AccountMenuItem(
            icon: Icons.person_outline,
            title: 'Hồ sơ cá nhân',
            subtitle: 'Họ tên, SĐT, địa chỉ nhận hàng',
            onTap: () => context.push(AppRoutes.profile),
          ),
          const AccountMenuItem(
            icon: Icons.settings_outlined,
            title: 'Cài đặt',
            subtitle: 'Tùy chọn hiển thị và thông báo',
          ),
          if (isSeller)
            AccountMenuItem(
              icon: Icons.add_circle_outline,
              title: 'Đăng tin bán thủy sản mới',
              subtitle: 'Đăng cá, tôm giống từ trang trại của bạn',
              onTap: () => context.push(AppRoutes.createListing),
            ),
          AccountMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Lịch sử đơn hàng',
            subtitle: orderCount > 0
                ? 'Theo dõi $orderCount đơn hàng gần nhất'
                : 'Theo dõi đơn hàng của bạn',
            badgeCount: orderCount > 0 ? orderCount : null,
            onTap: () => context.push(AppRoutes.orders),
          ),
          const AccountMenuItem(
            icon: Icons.help_outline,
            title: 'Hỗ trợ',
            subtitle: 'Trung tâm trợ giúp và CSKH',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context, AuthProvider auth) {
    return PressableScale(
      onTap: () async {
        if (auth.isAuthenticated) {
          await auth.logout();
        }
        if (context.mounted) context.push(AppRoutes.login);
      },
      pressedScale: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 18, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(
              auth.isAuthenticated ? 'Đăng xuất' : 'Đăng nhập',
              style: AppTypography.itemTitle.copyWith(
                fontSize: 14,
                height: 20 / 14,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
