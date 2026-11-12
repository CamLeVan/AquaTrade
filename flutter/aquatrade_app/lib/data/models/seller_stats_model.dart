/// Mirror of BE `SellerDto.SellerStatsSummary`.
class SellerStatsModel {
  const SellerStatsModel({
    required this.totalSales,
    required this.totalListings,
    required this.pendingOrders,
    required this.shopRating,
  });

  final double totalSales;
  final int totalListings;
  final int pendingOrders;

  /// User shop rating (stars), NOT an AI confidence metric.
  final double shopRating;

  factory SellerStatsModel.fromJson(Map<String, dynamic> json) {
    return SellerStatsModel(
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
      totalListings: (json['totalListings'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      shopRating: (json['shopRating'] as num?)?.toDouble() ?? 0,
    );
  }
}
