import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

String _defaultApiBaseUrl() {
  if (kIsWeb) return 'http://localhost:8080/api/v1';
  return 'http://192.168.1.24:8080/api/v1';
}

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _defaultApiBaseUrl(),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;
  List<void Function(String?)> _refreshQueue = [];

  /// AuthProvider gắn callback — refresh fail / session chết → đá login.
  VoidCallback? onSessionExpired;

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (_shouldRefresh(e)) {
          if (_isRefreshing) {
            // Add to queue and wait
            _refreshQueue.add((newToken) {
              if (newToken != null) {
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                _dio.fetch<dynamic>(e.requestOptions).then(
                      (res) => handler.resolve(res),
                      onError: (err) => handler.next(err),
                    );
              } else {
                handler.next(e);
              }
            });
            return;
          }

          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final newToken = await _storage.read(key: 'jwt_token');
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            
            // Retry current request
            try {
              final response = await _dio.fetch<dynamic>(e.requestOptions);
              return handler.resolve(response);
            } catch (err) {
              return handler.next(e);
            }
          }
        }
        handler.next(e);
      },
    ));
  }

  bool _shouldRefresh(DioException e) {
    final path = e.requestOptions.path;
    final isAuthPath =
        path.contains('/auth/login') || path.contains('/auth/refresh');
    if (isAuthPath) return false;

    final code = e.response?.statusCode;
    // BE (Spring) thường trả 403 khi JWT hết hạn / không parse được
    // (anonymous bị chặn .authenticated()) — không chỉ 401.
    // Chỉ thử refresh nếu request đã gửi Bearer (tránh loop endpoint thật sự cấm role).
    final auth = e.requestOptions.headers['Authorization']?.toString() ?? '';
    final hadBearer = auth.startsWith('Bearer ');
    return (code == 401 || (code == 403 && hadBearer));
  }

  Future<bool> _tryRefreshToken() async {
    _isRefreshing = true;

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        _onRefreshFailed();
        return false;
      }

      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      final payload = response.data;
      if (payload['status'] != 'success') {
        _onRefreshFailed();
        return false;
      }
      
      final data = payload['data'];
      final newToken = data['token'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      
      if (newToken == null || newToken.isEmpty) {
        _onRefreshFailed();
        return false;
      }

      await _storage.write(key: 'jwt_token', value: newToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }

      _onRefreshSuccess(newToken);
      return true;
    } catch (_) {
      _onRefreshFailed();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _onRefreshSuccess(String token) {
    for (var callback in _refreshQueue) {
      callback(token);
    }
    _refreshQueue.clear();
  }

  void _onRefreshFailed() {
    for (var callback in _refreshQueue) {
      callback(null);
    }
    _refreshQueue.clear();
    // Token không cứu được → xoá local + báo AuthProvider.
    clearAuthTokens().then((_) {
      onSessionExpired?.call();
    });
  }

  Future<bool> hasAccessToken() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> saveAuthTokens({
    required String token,
    String? refreshToken,
  }) async {
    await _storage.write(key: 'jwt_token', value: token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<void> clearAuthTokens() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  String _mapError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối quá thời gian. Vui lòng thử lại.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ. Hãy kiểm tra mạng.';
    }
    if (e.type == DioExceptionType.cancel) {
      return 'Yêu cầu đã bị hủy.';
    }

    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    switch (statusCode) {
      case 400:
        return 'Dữ liệu gửi lên không hợp lệ.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        // Thường gặp khi JWT hết hạn (BE trả 403) hoặc sai role.
        return 'Phiên đăng nhập hết hạn hoặc không đủ quyền. Hãy đăng nhập lại rồi thử.';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu.';
      case 409:
        return 'Dữ liệu bị xung đột. Vui lòng thử lại.';
      case 500:
      case 502:
      case 503:
        return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
      default:
        return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  T parseData<T>(Response response) {
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const ApiException('Phản hồi từ máy chủ không hợp lệ.');
    }
    if (payload['status'] != 'success') {
      throw ApiException(
        (payload['message'] as String?) ?? 'Yêu cầu không thành công.',
        statusCode: response.statusCode,
      );
    }
    return payload['data'] as T;
  }

  Future<Response<dynamic>> _requestWithRetry(Future<Response<dynamic>> Function() request) async {
    // Preview: 1 retry ngắn — tránh spinner Chợ kẹt ~30s khi BE chưa chạy.
    const maxRetries = 2;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        return await request();
      } on DioException catch (e) {
        attempt++;
        final isNetworkError = e.type == DioExceptionType.connectionTimeout || 
                               e.type == DioExceptionType.connectionError ||
                               e.type == DioExceptionType.receiveTimeout;
                               
        if (isNetworkError && attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        throw ApiException(_mapError(e), statusCode: e.response?.statusCode);
      } catch (e) {
        throw ApiException('Lỗi hệ thống: ${e.toString()}');
      }
    }
    throw const ApiException('Không thể kết nối sau nhiều lần thử.');
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _requestWithRetry(() => _dio.get<dynamic>(path, queryParameters: queryParameters));
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) async {
    return _requestWithRetry(() => _dio.post<dynamic>(path, data: data));
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _requestWithRetry(() => _dio.put<dynamic>(path, data: data, queryParameters: queryParameters));
  }

  Future<Response<dynamic>> delete(String path) async {
    return _requestWithRetry(() => _dio.delete<dynamic>(path));
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) async {
    return _requestWithRetry(() => _dio.patch<dynamic>(path, data: data));
  }
}
