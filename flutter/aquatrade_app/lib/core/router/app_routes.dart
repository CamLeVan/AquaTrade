/// Path constants — nguồn duy nhất cho go_router.
abstract final class AppRoutes {
  static const preview = '/preview';

  // Shell tabs
  static const home = '/home';
  static const market = '/market';
  static const chat = '/chat';
  static const account = '/account';
  static const profile = '/account/profile';

  // Full-screen (ngoài shell — không hiện bottom nav)
  static const aiScan = '/ai-scan';
  static const aiScanOrders = '/ai-scan/orders';
  static String aiScanOrderPath(String orderId) =>
      '/ai-scan/orders/${Uri.encodeComponent(orderId)}';
  static const product = '/product';
  static String productOf(String listingId) => '$product/$listingId';
  static const createListing = '/listings/create';
  static const cart = '/cart';

  static const login = '/login';
  static const register = '/register';
  static const splash = '/splash';

  /// Deep-link tab Gian hàng (cần login).
  static const marketShop = '/market?tab=shop';

  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout/success';
  static const checkoutErrorBalance = '/checkout/error-balance';
  static const checkoutErrorSystem = '/checkout/error-system';

  static const wallet = '/wallet';
  static const walletTopup = '/wallet/topup';
  static const walletTopupSuccess = '/wallet/topup/success';
  static const walletWithdraw = '/wallet/withdraw';
  static const walletWithdrawSuccess = '/wallet/withdraw/success';

  static const orders = '/orders';
  static const orderDetail = '/orders/detail';
  static String orderDetailPath(String orderId) =>
      '/orders/detail?orderId=${Uri.encodeComponent(orderId)}';

  static const sellerRegisterInfo = '/seller/register/info';
  static const sellerRegisterVerify = '/seller/register/verify';
  static const sellerRegisterTerms = '/seller/register/terms';

  static const adminConsole = '/admin/console';
}
