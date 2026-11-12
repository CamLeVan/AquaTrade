enum Role { BUYER, SELLER, ADMIN }

class AuthResponse {
  final String token;
  final String? refreshToken;
  final Role role;
  final String userId;

  AuthResponse({
    required this.token,
    this.refreshToken,
    required this.role,
    required this.userId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'],
      role: Role.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => Role.BUYER,
      ),
      userId: json['userId'] ?? '',
    );
  }
}
