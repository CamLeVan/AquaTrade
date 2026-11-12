import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/auth_required_sheet.dart';

/// Lý do guest bị yêu cầu đăng nhập — map query `reason=`.
abstract final class LoginReasons {
  static const product = 'product';
  static const cart = 'cart';
  static const checkout = 'checkout';
  static const wallet = 'wallet';
  static const shop = 'shop';
  static const listing = 'listing';
  static const orders = 'orders';
  static const seller = 'seller';
  static const account = 'account';
  static const chat = 'chat';
  static const ai = 'ai';
  static const generic = 'generic';

  static String messageFor(String? reason) {
    switch (reason) {
      case product:
        return 'Đăng nhập để tiếp tục mua sắm hoặc đàm phán giá.';
      case cart:
        return 'Đăng nhập để lưu giỏ hàng và thanh toán.';
      case checkout:
        return 'Đăng nhập để tiến hành thanh toán.';
      case wallet:
        return 'Đăng nhập để sử dụng ví AquaTrade.';
      case shop:
        return 'Đăng nhập để vào gian hàng của bạn.';
      case listing:
        return 'Đăng nhập để đăng bán sản phẩm.';
      case orders:
        return 'Đăng nhập để xem lịch sử đơn hàng.';
      case seller:
        return 'Đăng nhập để tiếp tục đăng ký bán.';
      case account:
        return 'Đăng nhập để xem hồ sơ và quản lý tài khoản.';
      case chat:
        return 'Đăng nhập để xem và gửi tin nhắn.';
      case ai:
        return 'Đăng nhập để sử dụng Quét AI / phân tích thủy sản.';
      default:
        return 'Đăng nhập để tiếp tục sử dụng tính năng này.';
    }
  }

  static String fromLocation(String loc, {String? tab}) {
    if (loc.startsWith('/product')) return product;
    if (loc == AppRoutes.cart) return cart;
    if (loc.startsWith('/checkout')) return checkout;
    if (loc.startsWith('/wallet')) return wallet;
    if (loc == AppRoutes.createListing) return listing;
    if (loc == AppRoutes.market && tab == 'shop') return shop;
    if (loc.startsWith('/orders')) return orders;
    if (loc.startsWith('/seller')) return seller;
    if (loc == AppRoutes.account) return account;
    if (loc == AppRoutes.chat) return chat;
    if (loc.startsWith(AppRoutes.aiScan)) return ai;
    return generic;
  }
}

/// Hướng 1: bottom sheet tại chỗ (không redirect, không tự làm lại hành động sau login).
Future<void> goLoginRequired(
  BuildContext context, {
  String? from,
  String reason = LoginReasons.generic,
  bool showSnackBar = false,
}) {
  return showAuthRequiredSheet(
    context,
    reason: reason,
    from: from,
  );
}

/// Điều hướng sau login/register thành công.
/// Ưu tiên `?from=` (route đang đứng / hành động trước đó), không thì [AppRoutes.home].
void goPostAuthHome(BuildContext context, RoleProvider roles) {
  final from = GoRouterState.of(context).uri.queryParameters['from'];
  if (from != null && from.isNotEmpty) {
    context.go(from);
    return;
  }
  context.go(AppRoutes.home);
}
