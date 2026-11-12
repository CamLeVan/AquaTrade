import 'listing_model.dart';

class CartItemModel {
  final ListingModel listing;
  int quantity;
  bool isSelected;

  CartItemModel({
    required this.listing,
    int quantity = 1,
    this.isSelected = true,
  }) : quantity = quantity < 1 ? 1 : quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawQty = (json['quantity'] as num?)?.toInt() ?? 1;
    return CartItemModel(
      listing: ListingModel.fromJson(json['listing']),
      quantity: rawQty < 1 ? 1 : rawQty,
      isSelected: json['isSelected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing': listing.toJson(),
      'quantity': quantity,
      'isSelected': isSelected,
    };
  }

  CartItemModel copyWith({
    ListingModel? listing,
    int? quantity,
    bool? isSelected,
  }) {
    return CartItemModel(
      listing: listing ?? this.listing,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
