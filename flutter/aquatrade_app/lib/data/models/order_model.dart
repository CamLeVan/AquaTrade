enum OrderStatus {
  PENDING,
  IN_VIDEO_CALL,
  COUNTING_AI,
  ESCROW_LOCKED,
  PENDING_ADMIN_REVIEW,
  PREPARING,
  SHIPPING,
  DELIVERED,
  AI_VERIFIED,
  READY_TO_PAYOUT,
  COMPLETED,
  DISPUTED,
  CANCELLED,
}

class DigitalProofSummary {
  final String id;
  final String proofRole;
  final String batchName;
  final int batchIndex;
  final int batchExpectedQuantity;
  final int aiFishCount;
  final String status;
  final String errorMessage;
  final String videoUrl;
  final String videoPublicId;
  final String aiImageUrl;
  final String proofHash;
  final DateTime createdAt;

  DigitalProofSummary({
    required this.id,
    required this.proofRole,
    required this.batchName,
    required this.batchIndex,
    required this.batchExpectedQuantity,
    required this.aiFishCount,
    required this.status,
    required this.errorMessage,
    required this.videoUrl,
    required this.videoPublicId,
    required this.aiImageUrl,
    required this.proofHash,
    required this.createdAt,
  });

  factory DigitalProofSummary.fromJson(Map<String, dynamic> json) {
    return DigitalProofSummary(
      id: json['id'] ?? '',
      proofRole: json['proofRole'] ?? '',
      batchName: json['batchName'] ?? '',
      batchIndex: json['batchIndex'] ?? 0,
      batchExpectedQuantity: json['batchExpectedQuantity'] ?? 0,
      aiFishCount: json['aiFishCount'] ?? 0,
      status: json['status'] ?? 'PENDING',
      errorMessage: json['errorMessage'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      videoPublicId: json['videoPublicId'] ?? '',
      aiImageUrl: json['aiImageUrl'] ?? '',
      proofHash: json['proofHash'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proofRole': proofRole,
      'batchName': batchName,
      'batchIndex': batchIndex,
      'batchExpectedQuantity': batchExpectedQuantity,
      'aiFishCount': aiFishCount,
      'status': status,
      'errorMessage': errorMessage,
      'videoUrl': videoUrl,
      'videoPublicId': videoPublicId,
      'aiImageUrl': aiImageUrl,
      'proofHash': proofHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class OrderModel {
  final String id;
  final String listingTitle;
  final String buyerName;
  final String buyerId;
  final String sellerName;
  final String sellerId;
  final double unitPriceAtPurchase;
  final int finalQuantity;
  final double totalPrice;
  final String shippingAddress;
  final OrderStatus status;
  final DateTime createdAt;
  final List<DigitalProofSummary> proofs;
  final int aiExpectedQuantity;
  final int aiTolerancePercent;
  final int sellerAiTotalCount;
  final int sellerAiSuccessfulBatchCount;
  final int sellerAiProgressPercent;
  final int sellerAiDiscrepancyPercent;
  final String sellerAiVerificationStatus;
  final int buyerAiTotalCount;
  final int buyerAiSuccessfulBatchCount;
  final int buyerAiProgressPercent;
  final int buyerAiDiscrepancyPercent;
  final String buyerAiVerificationStatus;
  final String disputeReason;
  final String sellerResponse;

  OrderModel({
    required this.id,
    required this.listingTitle,
    required this.buyerName,
    this.buyerId = '',
    required this.sellerName,
    this.sellerId = '',
    required this.unitPriceAtPurchase,
    required this.finalQuantity,
    required this.totalPrice,
    required this.shippingAddress,
    required this.status,
    required this.createdAt,
    required this.proofs,
    this.aiExpectedQuantity = 0,
    this.aiTolerancePercent = 0,
    this.sellerAiTotalCount = 0,
    this.sellerAiSuccessfulBatchCount = 0,
    this.sellerAiProgressPercent = 0,
    this.sellerAiDiscrepancyPercent = 0,
    this.sellerAiVerificationStatus = 'UNVERIFIED',
    this.buyerAiTotalCount = 0,
    this.buyerAiSuccessfulBatchCount = 0,
    this.buyerAiProgressPercent = 0,
    this.buyerAiDiscrepancyPercent = 0,
    this.buyerAiVerificationStatus = 'UNVERIFIED',
    this.disputeReason = '',
    this.sellerResponse = '',
  });

  DigitalProofSummary? get digitalProof => proofs.isNotEmpty ? proofs.first : null;

  OrderModel copyWith({
    String? id,
    String? listingTitle,
    String? buyerName,
    String? buyerId,
    String? sellerName,
    String? sellerId,
    double? unitPriceAtPurchase,
    int? finalQuantity,
    double? totalPrice,
    String? shippingAddress,
    OrderStatus? status,
    DateTime? createdAt,
    List<DigitalProofSummary>? proofs,
    int? aiExpectedQuantity,
    int? aiTolerancePercent,
    int? sellerAiTotalCount,
    int? sellerAiSuccessfulBatchCount,
    int? sellerAiProgressPercent,
    int? sellerAiDiscrepancyPercent,
    String? sellerAiVerificationStatus,
    int? buyerAiTotalCount,
    int? buyerAiSuccessfulBatchCount,
    int? buyerAiProgressPercent,
    int? buyerAiDiscrepancyPercent,
    String? buyerAiVerificationStatus,
    String? disputeReason,
    String? sellerResponse,
  }) {
    return OrderModel(
      id: id ?? this.id,
      listingTitle: listingTitle ?? this.listingTitle,
      buyerName: buyerName ?? this.buyerName,
      buyerId: buyerId ?? this.buyerId,
      sellerName: sellerName ?? this.sellerName,
      sellerId: sellerId ?? this.sellerId,
      unitPriceAtPurchase: unitPriceAtPurchase ?? this.unitPriceAtPurchase,
      finalQuantity: finalQuantity ?? this.finalQuantity,
      totalPrice: totalPrice ?? this.totalPrice,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      proofs: proofs ?? this.proofs,
      aiExpectedQuantity: aiExpectedQuantity ?? this.aiExpectedQuantity,
      aiTolerancePercent: aiTolerancePercent ?? this.aiTolerancePercent,
      sellerAiTotalCount: sellerAiTotalCount ?? this.sellerAiTotalCount,
      sellerAiSuccessfulBatchCount: sellerAiSuccessfulBatchCount ?? this.sellerAiSuccessfulBatchCount,
      sellerAiProgressPercent: sellerAiProgressPercent ?? this.sellerAiProgressPercent,
      sellerAiDiscrepancyPercent: sellerAiDiscrepancyPercent ?? this.sellerAiDiscrepancyPercent,
      sellerAiVerificationStatus: sellerAiVerificationStatus ?? this.sellerAiVerificationStatus,
      buyerAiTotalCount: buyerAiTotalCount ?? this.buyerAiTotalCount,
      buyerAiSuccessfulBatchCount: buyerAiSuccessfulBatchCount ?? this.buyerAiSuccessfulBatchCount,
      buyerAiProgressPercent: buyerAiProgressPercent ?? this.buyerAiProgressPercent,
      buyerAiDiscrepancyPercent: buyerAiDiscrepancyPercent ?? this.buyerAiDiscrepancyPercent,
      buyerAiVerificationStatus: buyerAiVerificationStatus ?? this.buyerAiVerificationStatus,
      disputeReason: disputeReason ?? this.disputeReason,
      sellerResponse: sellerResponse ?? this.sellerResponse,
    );
  }


  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      listingTitle: json['listingTitle'] ?? '',
      buyerName: json['buyerName'] ?? '',
      buyerId: json['buyerId']?.toString() ?? '',
      sellerName: json['sellerName'] ?? '',
      sellerId: json['sellerId']?.toString() ?? '',
      unitPriceAtPurchase: (json['unitPriceAtPurchase'] as num?)?.toDouble() ?? 0.0,
      finalQuantity: json['finalQuantity'] ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: json['shippingAddress'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? json['orderStatus']),
        orElse: () => OrderStatus.PENDING,
      ),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      proofs: (json['proofs'] as List?)?.map((e) => DigitalProofSummary.fromJson(e)).toList() ?? [],
      aiExpectedQuantity: json['aiExpectedQuantity'] ?? 0,
      aiTolerancePercent: json['aiTolerancePercent'] ?? 0,
      sellerAiTotalCount: json['sellerAiTotalCount'] ?? 0,
      sellerAiSuccessfulBatchCount: json['sellerAiSuccessfulBatchCount'] ?? 0,
      sellerAiProgressPercent: json['sellerAiProgressPercent'] ?? 0,
      sellerAiDiscrepancyPercent: json['sellerAiDiscrepancyPercent'] ?? 0,
      sellerAiVerificationStatus: json['sellerAiVerificationStatus'] ?? 'UNVERIFIED',
      buyerAiTotalCount: json['buyerAiTotalCount'] ?? 0,
      buyerAiSuccessfulBatchCount: json['buyerAiSuccessfulBatchCount'] ?? 0,
      buyerAiProgressPercent: json['buyerAiProgressPercent'] ?? 0,
      buyerAiDiscrepancyPercent: json['buyerAiDiscrepancyPercent'] ?? 0,
      buyerAiVerificationStatus: json['buyerAiVerificationStatus'] ?? 'UNVERIFIED',
      disputeReason: json['disputeReason'] ?? '',
      sellerResponse: json['sellerResponse'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingTitle': listingTitle,
      'buyerName': buyerName,
      'buyerId': buyerId,
      'sellerName': sellerName,
      'sellerId': sellerId,
      'unitPriceAtPurchase': unitPriceAtPurchase,
      'finalQuantity': finalQuantity,
      'totalPrice': totalPrice,
      'shippingAddress': shippingAddress,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'proofs': proofs.map((e) => e.toJson()).toList(),
      'aiExpectedQuantity': aiExpectedQuantity,
      'aiTolerancePercent': aiTolerancePercent,
      'sellerAiTotalCount': sellerAiTotalCount,
      'sellerAiSuccessfulBatchCount': sellerAiSuccessfulBatchCount,
      'sellerAiProgressPercent': sellerAiProgressPercent,
      'sellerAiDiscrepancyPercent': sellerAiDiscrepancyPercent,
      'sellerAiVerificationStatus': sellerAiVerificationStatus,
      'buyerAiTotalCount': buyerAiTotalCount,
      'buyerAiSuccessfulBatchCount': buyerAiSuccessfulBatchCount,
      'buyerAiProgressPercent': buyerAiProgressPercent,
      'buyerAiDiscrepancyPercent': buyerAiDiscrepancyPercent,
      'buyerAiVerificationStatus': buyerAiVerificationStatus,
      'disputeReason': disputeReason,
      'sellerResponse': sellerResponse,
    };
  }
}


