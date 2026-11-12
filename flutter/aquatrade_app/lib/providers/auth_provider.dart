import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/auth_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../shared_providers/role_provider.dart';

/// Trạng thái phiên lúc bootstrap / giữa phiên.
/// `unknown` = đang kiểm tra token — router hiện Splash, chưa quyết định route.
enum SessionStatus {
  unknown,
  authenticated,
  unauthenticated,
}

/// Auth + JWT.
/// - [restoreSession] → unknown → authenticated | unauthenticated
/// - [login] / [register] → BE `/auth/*`
/// - [loadProfile] → `GET /users/me` (fail → unauthenticated)
class AuthProvider with ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  bool _isLoading = false;
  UserModel? _currentUser;
  SessionStatus _sessionStatus = SessionStatus.unknown;
  String _errorMessage = '';

  SessionStatus get sessionStatus => _sessionStatus;
  bool get isSessionReady => _sessionStatus != SessionStatus.unknown;
  bool get isAuthenticated => _sessionStatus == SessionStatus.authenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  /// Gọi khi app start / hot restart. Không vào shell cho đến khi xong.
  Future<void> restoreSession({RoleProvider? roles}) async {
    _sessionStatus = SessionStatus.unknown;
    _errorMessage = '';
    notifyListeners();

    try {
      final hasToken = await _repo.hasAccessToken();
      if (!hasToken) {
        _currentUser = null;
        _sessionStatus = SessionStatus.unauthenticated;
        return;
      }

      final user = await _repo.getCurrentUser();
      _currentUser = user;
      _sessionStatus = SessionStatus.authenticated;
      roles?.syncFromAccount(
        role: _mapRole(user.role),
        userStatus: user.status,
        verificationStatus: user.verificationStatus,
      );
    } catch (e) {
      await _repo.clearLocalSession();
      _currentUser = null;
      _sessionStatus = SessionStatus.unauthenticated;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  /// `GET /users/me`. Fail → clear session (token chết / 401).
  Future<UserModel?> loadProfile({RoleProvider? roles}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final user = await _repo.getCurrentUser();
      _currentUser = user;
      _sessionStatus = SessionStatus.authenticated;
      roles?.syncFromAccount(
        role: _mapRole(user.role),
        userStatus: user.status,
        verificationStatus: user.verificationStatus,
      );
      return user;
    } catch (e) {
      _errorMessage = e.toString();
      await _markUnauthenticated(clearTokens: true);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ApiService gọi khi refresh token thất bại / 401 không cứu được.
  void handleSessionExpired() {
    if (_sessionStatus == SessionStatus.unauthenticated) return;
    _currentUser = null;
    _sessionStatus = SessionStatus.unauthenticated;
    _errorMessage = 'Phiên đăng nhập đã hết hạn';
    notifyListeners();
  }

  Future<void> _markUnauthenticated({required bool clearTokens}) async {
    if (clearTokens) {
      try {
        await _repo.clearLocalSession();
      } catch (_) {}
    }
    _currentUser = null;
    _sessionStatus = SessionStatus.unauthenticated;
  }

  static UserRole _mapRole(Role role) {
    switch (role) {
      case Role.SELLER:
        return UserRole.seller;
      case Role.ADMIN:
        return UserRole.admin;
      case Role.BUYER:
        return UserRole.buyer;
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = false,
    RoleProvider? roles,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final res = await _repo.login(
        email,
        password,
        rememberMe: rememberMe,
      );
      if (res.token.isEmpty) {
        await _markUnauthenticated(clearTokens: true);
        return false;
      }
      _currentUser = UserModel(
        id: res.userId,
        fullName: '',
        email: email,
        role: res.role,
      );
      _sessionStatus = SessionStatus.authenticated;
      roles?.syncAccountRoleOnly(_mapRole(res.role));
      notifyListeners();
      await loadProfile(roles: roles);
      return isAuthenticated;
    } catch (e) {
      _errorMessage = e.toString();
      await _markUnauthenticated(clearTokens: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required Role role,
    String? companyName,
    RoleProvider? roles,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final res = await _repo.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        companyName: companyName,
      );
      if (res.token.isEmpty) {
        await _markUnauthenticated(clearTokens: true);
        return false;
      }
      _currentUser = UserModel(
        id: res.userId,
        fullName: fullName,
        email: email,
        role: role,
        companyName: companyName,
      );
      _sessionStatus = SessionStatus.authenticated;
      roles?.syncAccountRoleOnly(_mapRole(role));
      notifyListeners();
      await loadProfile(roles: roles);
      return isAuthenticated;
    } catch (e) {
      _errorMessage = e.toString();
      await _markUnauthenticated(clearTokens: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      await _repo.clearLocalSession();
    }
    _currentUser = null;
    _sessionStatus = SessionStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? fullName,
    required String address,
    String? phoneNumber,
    String? companyName,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final updated = await _repo.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber ?? _currentUser?.phoneNumber ?? '',
        address: address,
        companyName: companyName ?? _currentUser?.companyName,
      );
      _currentUser = updated;
      _sessionStatus = SessionStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chỉ dùng trong test — bỏ qua bootstrap splash.
  @visibleForTesting
  void debugMarkAuthenticated() {
    _sessionStatus = SessionStatus.authenticated;
    notifyListeners();
  }

  @visibleForTesting
  void debugMarkUnauthenticated() {
    _currentUser = null;
    _sessionStatus = SessionStatus.unauthenticated;
    notifyListeners();
  }
}
