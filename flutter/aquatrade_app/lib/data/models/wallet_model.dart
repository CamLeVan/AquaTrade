enum TransactionType {
  ESCROW_LOCK,
  ESCROW_RELEASE,
  REFUND,
  TOP_UP,
  WITHDRAW,
  ORDER_PAYOUT,
  SELL_PAYOUT,
  DISPUTE_REFUND,
  PLATFORM_COMMISSION,
  CANCELLED,
}

enum TransactionStatus { SUCCESS, FAILED, PENDING }
enum PaymentMethod { VNPAY, MOMO, BANK_TRANSFER }

class TransactionModel {
  final String id;
  final String? orderId;
  final String? userName;
  final String? userEmail;
  final double amount;
  final double postBalance;
  final TransactionType type;
  final PaymentMethod? paymentMethod;
  final TransactionStatus status;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    this.orderId,
    this.userName,
    this.userEmail,
    required this.amount,
    required this.postBalance,
    required this.type,
    this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      orderId: json['orderId'],
      userName: json['userName'],
      userEmail: json['userEmail'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      postBalance: (json['postBalance'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.TOP_UP,
      ),
      paymentMethod: json['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == json['paymentMethod'],
              orElse: () => PaymentMethod.BANK_TRANSFER,
            )
          : null,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.PENDING,
      ),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class WalletModel {
  final double balance;
  final String? userLevel;
  final List<TransactionModel> recentTransactions;

  WalletModel({
    required this.balance,
    this.userLevel,
    required this.recentTransactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      userLevel: json['userLevel']?.toString(),
      recentTransactions: (json['recentTransactions'] as List?)
              ?.map((e) => TransactionModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
