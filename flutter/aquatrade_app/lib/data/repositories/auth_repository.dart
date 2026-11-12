import '../services/remote/api_service.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  Future<AuthResponse> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    });
    final data = _api.parseData<Map<String, dynamic>>(response);
    final auth = AuthResponse.fromJson(data);
    await _api.saveAuthTokens(
      token: auth.token,
      refreshToken: auth.refreshToken,
    );
    return auth;
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    required Role role,
    String? companyName,
  }) async {
    final response = await _api.post('/auth/register', data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role.name,
      if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
    });
    final data = _api.parseData<Map<String, dynamic>>(response);
    final auth = AuthResponse.fromJson(data);
    // Register cũng trả JWT — lưu để vào app ngay (khớp web).
    await _api.saveAuthTokens(
      token: auth.token,
      refreshToken: auth.refreshToken,
    );
    return auth;
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await _api.post('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    final data = _api.parseData<Map<String, dynamic>>(response);
    return AuthResponse.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _api.clearAuthTokens();
    }
  }

  Future<bool> hasAccessToken() => _api.hasAccessToken();

  Future<void> clearLocalSession() => _api.clearAuthTokens();

  Future<UserModel> getCurrentUser() async {
    final response = await _api.get('/users/me');
    final data = _api.parseData<Map<String, dynamic>>(response);
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile({
    String? fullName,
    required String phoneNumber,
    required String address,
    String? companyName,
  }) async {
    final response = await _api.put('/users/profile', data: {
      if (fullName != null && fullName.trim().isNotEmpty) 'fullName': fullName.trim(),
      'phoneNumber': phoneNumber,
      'address': address,
      if (companyName != null) 'companyName': companyName,
    });
    final data = _api.parseData<Map<String, dynamic>>(response);
    return UserModel.fromJson(data);
  }

  Future<void> requestVerification() async {
    final response = await _api.post('/users/request-verification');
    _api.parseData<dynamic>(response);
  }
}
