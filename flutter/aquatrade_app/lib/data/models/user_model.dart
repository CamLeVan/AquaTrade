import 'auth_model.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? username;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? companyName;
  final String? address;
  final Role role;
  final String? status;
  final String? verificationStatus;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.username,
    this.phoneNumber,
    this.avatarUrl,
    this.companyName,
    this.address,
    required this.role,
    this.status,
    this.verificationStatus,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      companyName: json['companyName']?.toString(),
      address: json['address']?.toString(),
      role: Role.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => Role.BUYER,
      ),
      status: json['status']?.toString(),
      verificationStatus: json['verificationStatus']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
