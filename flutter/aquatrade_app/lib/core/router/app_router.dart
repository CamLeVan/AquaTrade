import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/account/account_screen.dart';
import '../../features/account/profile_screen.dart';
import '../../features/ai_scan/ai_scan_hub_screen.dart';
import '../../features/ai_scan/ai_order_pick_screen.dart';
import '../../features/ai_scan/ai_order_count_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_confirm_screen.dart';
import '../../features/checkout/checkout_error_balance_screen.dart';
import '../../features/checkout/checkout_error_system_screen.dart';
import '../../features/checkout/checkout_success_screen.dart';
import '../../features/dashboard/home_screen.dart';
import '../../data/models/listing_model.dart';
import '../../features/market/create_listing_screen.dart';
import '../../features/market/market_screen.dart';
import '../../features/market/product_detail_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/seller_onboarding/seller_register_info_screen.dart';
import '../../features/seller_onboarding/seller_register_terms_screen.dart';
import '../../features/seller_onboarding/seller_register_verify_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/wallet/topup_screen.dart';
import '../../features/wallet/topup_success_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/chat/chat_detail_screen.dart';
import '../../features/wallet/withdraw_screen.dart';
import '../../features/wallet/withdraw_success_screen.dart';
import '../../features/admin/admin_console_screen.dart';
import '../../providers/auth_provider.dart';
import 'app_routes.dart';
import 'preview_catalog_screen.dart';

/// Redirect chỉ lo splash + tránh Login khi đã auth.
/// Guest vào được các route cần login; UI khoá (AuthGateView) / sheet (goLoginRequired).
String? _authRedirect(AuthProvider auth, GoRouterState state) {
  final loc = state.matchedLocation;
  final isSplash = loc == AppRoutes.splash;
  final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;

  if (auth.sessionStatus == SessionStatus.unknown) {
    return isSplash ? null : AppRoutes.splash;
  }

  if (isSplash) {
    return AppRoutes.home;
  }

  if (auth.isAuthenticated && isAuthRoute) {
    final from = state.uri.queryParameters['from'];
    if (from != null && from.isNotEmpty) return from;
    return AppRoutes.home;
  }

  return null;
}

/// GoRouter tập trung. [auth] dùng cho redirect + [refreshListenable].
GoRouter createAppRouter({
  required AuthProvider auth,
  String initialLocation = AppRoutes.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: auth,
    redirect: (context, state) => _authRedirect(auth, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.preview,
        builder: (context, state) => const PreviewCatalogScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.market,
                builder: (context, state) {
                  final tab = state.uri.queryParameters['tab'];
                  final segment = tab == 'shop' ? 1 : 0;
                  return MarketScreen(initialSegment: segment);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.aiScan,
        builder: (context, state) => const AiScanHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiScanOrders,
        builder: (context, state) => const AiOrderPickScreen(),
      ),
      GoRoute(
        path: '/ai-scan/orders/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return AiOrderCountScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/chat/detail/:conversationId',
        builder: (context, state) {
          final convId = state.pathParameters['conversationId'] ?? 'system_ai_assistant';
          return ChatDetailScreen(conversationId: convId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.product}/:listingId',
        builder: (context, state) => ProductDetailScreen(
          listingId: state.pathParameters['listingId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.product,
        builder: (context, state) => const ProductDetailScreen(),
      ),
      GoRoute(
        path: AppRoutes.createListing,
        builder: (context, state) => CreateListingScreen(
          existingListing: state.extra is ListingModel ? (state.extra as ListingModel) : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminConsole,
        builder: (context, state) => const AdminConsoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutConfirmScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkoutSuccess,
        builder: (context, state) {
          final extra = state.extra;
          final ids = extra is List
              ? extra.map((e) => e.toString()).toList()
              : const <String>[];
          return CheckoutSuccessScreen(orderIds: ids);
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutErrorBalance,
        builder: (context, state) => const CheckoutErrorBalanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkoutErrorSystem,
        builder: (context, state) => const CheckoutErrorSystemScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.walletTopup,
        builder: (context, state) => const TopupScreen(),
      ),
      GoRoute(
        path: AppRoutes.walletTopupSuccess,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return TopupSuccessScreen(
            amountLabel: q['amount'] ?? '1.000.000',
            methodLabel: q['method'] ?? 'Chuyển khoản',
            pendingApproval: q['pending'] != '0',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.walletWithdraw,
        builder: (context, state) => const WithdrawScreen(),
      ),
      GoRoute(
        path: AppRoutes.walletWithdrawSuccess,
        builder: (context, state) {
          final amount = state.uri.queryParameters['amount'] ?? '5.000.000';
          return WithdrawSuccessScreen(amountLabel: amount);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.sellerRegisterInfo,
        builder: (context, state) => const SellerRegisterInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerRegisterVerify,
        builder: (context, state) => const SellerRegisterVerifyScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerRegisterTerms,
        builder: (context, state) => const SellerRegisterTermsScreen(),
      ),
    ],
  );
}
