class DisputeModel {
  final String id;
  final String orderId;
  final String status;
  final String reasonText;
  final DateTime? createdAt;

  DisputeModel({
    required this.id,
    required this.orderId,
    required this.status,
    required this.reasonText,
    this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      reasonText: json['reasonText']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
