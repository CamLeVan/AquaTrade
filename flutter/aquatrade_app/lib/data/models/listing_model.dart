enum ListingCategory { CA, TOM, CUA, KHAC }

enum ListingStatus { PENDING_REVIEW, AVAILABLE, SOLD, HIDDEN, REJECTED, DELETED }

class ListingModel {
  final String id;
  final String title;
  final ListingCategory category;
  final String species;
  final String province;
  final double sizeMin;
  final double sizeMax;
  final double pricePerFish;
  final int estimatedQuantity;
  final int availableQuantity;
  final String thumbnailUrl;
  final ListingStatus status;
  final String sellerName;
  final String sellerId;
  final bool aiVerified;
  final int aiHealthScore;
  final String qualityLabel;
  final bool isFavorite;
  final String description;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int purchaseCount;
  final int soldQuantity;

  ListingModel({
    required this.id,
    required this.title,
    required this.category,
    required this.species,
    required this.province,
    required this.sizeMin,
    required this.sizeMax,
    required this.pricePerFish,
    required this.estimatedQuantity,
    required this.availableQuantity,
    required this.thumbnailUrl,
    required this.status,
    required this.sellerName,
    this.sellerId = '',
    required this.aiVerified,
    required this.aiHealthScore,
    required this.qualityLabel,
    required this.isFavorite,
    required this.createdAt,
    this.description = '',
    this.imageUrls = const [],
    this.purchaseCount = 0,
    this.soldQuantity = 0,
  });

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Tin demo UI (`mock_…`) hoặc id không phải UUID — không gửi được checkout BE.
  bool get isDemoListing =>
      id.startsWith('mock_') || id.isEmpty || !_uuidPattern.hasMatch(id);

  /// Có thể gọi `POST /orders/checkout-cart`.
  bool get isCheckoutable => !isDemoListing;

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: ListingCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ListingCategory.KHAC,
      ),
      species: json['species'] ?? '',
      province: json['province'] ?? '',
      sizeMin: (json['sizeMin'] as num?)?.toDouble() ?? 0.0,
      sizeMax: (json['sizeMax'] as num?)?.toDouble() ?? 0.0,
      pricePerFish: (json['pricePerFish'] as num?)?.toDouble() ?? 0.0,
      estimatedQuantity: json['estimatedQuantity'] ?? 0,
      availableQuantity: json['availableQuantity'] ?? 0,
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      status: ListingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ListingStatus.PENDING_REVIEW,
      ),
      sellerName: json['sellerName'] ?? '',
      sellerId: json['sellerId'] ?? '',
      aiVerified: json['aiVerified'] ?? false,
      aiHealthScore: json['aiHealthScore'] ?? 0,
      qualityLabel: json['qualityLabel'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      description: json['description'] ?? '',
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
      soldQuantity: (json['soldQuantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.toString().split('.').last,
      'species': species,
      'province': province,
      'sizeMin': sizeMin,
      'sizeMax': sizeMax,
      'pricePerFish': pricePerFish,
      'estimatedQuantity': estimatedQuantity,
      'availableQuantity': availableQuantity,
      'thumbnailUrl': thumbnailUrl,
      'status': status.toString().split('.').last,
      'sellerName': sellerName,
      'sellerId': sellerId,
      'aiVerified': aiVerified,
      'aiHealthScore': aiHealthScore,
      'qualityLabel': qualityLabel,
      'isFavorite': isFavorite,
      'description': description,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'purchaseCount': purchaseCount,
      'soldQuantity': soldQuantity,
    };
  }
}
