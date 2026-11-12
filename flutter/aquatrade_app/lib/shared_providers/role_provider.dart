import 'package:flutter/material.dart';

/// Vai trò tài khoản trong AquaTrade — CỐ ĐỊNH theo loại tài khoản.
/// KHÔNG chứa trạng thái đăng ký bán (xem [SellerStatus]).
enum UserRole {
  buyer, // người mua (mặc định của mọi tài khoản)
  seller, // đã là người bán được duyệt
  admin, // quản trị hệ thống
}

/// Trạng thái hồ sơ đăng ký người bán — TÁCH RIÊNG khỏi [UserRole].
/// Dùng cho UI onboarding (intro / chờ duyệt). Không dùng làm điều kiện
/// [canSell] tạm thời — chờ BE có SellerStatus model riêng.
enum SellerStatus {
  none, // chưa đăng ký bán
  pending, // đã gửi hồ sơ, chờ duyệt
  active, // hồ sơ được duyệt → bán được
}

/// Nguồn DUY NHẤT cho logic ẩn/hiện theo vai trò (role-aware).
class RoleProvider with ChangeNotifier {
  RoleProvider({
    UserRole role = UserRole.buyer,
    SellerStatus sellerStatus = SellerStatus.none,
  })  : _role = role,
        _sellerStatus = sellerStatus;

  UserRole _role;
  SellerStatus _sellerStatus;

  UserRole get currentRole => _role;
  SellerStatus get sellerStatus => _sellerStatus;

  /// Tạm: tin Role.SELLER từ BE — không ép verificationStatus.
  /// My Shop / FAB đăng bán / quyền bán dựa vào đây.
  /// (Rút tiền vẫn chặn riêng vì BE chưa có endpoint.)
  bool get canSell => _role == UserRole.seller;

  /// Dashboard bento/hero Seller vs Buyer.
  bool get showSellerDashboard => _role == UserRole.seller;

  /// Đang chờ duyệt hồ sơ (onboarding UI) — không chặn canSell.
  bool get isPending => _sellerStatus == SellerStatus.pending;

  /// Người mua thuần túy (chưa đăng ký bán).
  bool get isBuyerOnly =>
      _role == UserRole.buyer && _sellerStatus == SellerStatus.none;

  void setRole(UserRole role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

  /// Hydrate từ `GET /users/me` / sau login-register.
  /// Role = nguồn canSell. SellerStatus chỉ phản ánh UI onboarding tạm.
  void syncFromAccount({
    required UserRole role,
    String? userStatus,
    String? verificationStatus,
  }) {
    _role = role;
    if (role == UserRole.buyer || role == UserRole.admin) {
      _sellerStatus = SellerStatus.none;
    } else if (role == UserRole.seller) {
      // Role.SELLER = đã là seller hợp lệ. Không map verification → pending
      // (pending chỉ dành buyer nộp hồ sơ — tránh chặn MyShop).
      _sellerStatus = SellerStatus.active;
    }
    notifyListeners();
  }

  void syncAccountRoleOnly(UserRole role) {
    syncFromAccount(role: role);
  }

  void setSellerStatus(SellerStatus status) {
    if (_sellerStatus == status) return;
    _sellerStatus = status;
    notifyListeners();
  }

  /// Buyer nộp hồ sơ bán → pending UI; role vẫn buyer cho đến BE đổi SELLER.
  void submitSellerApplication() {
    setSellerStatus(SellerStatus.pending);
  }

  void applyPreview(UserRole role, SellerStatus status) {
    if (_role == role && _sellerStatus == status) return;
    _role = role;
    _sellerStatus = status;
    notifyListeners();
  }
}
