import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/listing_model.dart';
import '../data/repositories/cart_repository.dart';

class CartProvider with ChangeNotifier {
  final CartRepository _repo;
  List<CartItemModel> _items = [];
  bool _isLoading = false;

  CartProvider(this._repo) {
    loadCart();
  }

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;

  int get totalItemCount => _items.length;
  
  int get selectedItemCount => _items.where((e) => e.isSelected).length;

  List<CartItemModel> get selectedItems => _items.where((e) => e.isSelected).toList();

  /// Tiền hàng đã chọn (không cộng phí ship / VAT ảo).
  int get selectTotalPrice => _items
      .where((e) => e.isSelected)
      .fold<double>(
        0.0,
        (sum, item) => sum + (item.listing.pricePerFish * item.quantity),
      )
      .toInt();

  /// Phí ship ước tính — chỉ dùng ở màn checkout confirm, không cộng vào footer giỏ.
  int get totalShipFee => selectedItemCount > 0 ? 50000 : 0;

  /// Tổng hiển thị ở footer Giỏ = tiền hàng đã chọn (khớp Figma TỔNG CỘNG).
  int get grandTotal => selectTotalPrice;

  double get totalAmount => selectTotalPrice.toDouble();

  Future<void> clearSelected() async {
    _items.removeWhere((e) => e.isSelected);
    await _repo.saveCartItems(_items);
    notifyListeners();
  }

  bool get isAllSelected =>
      _items.isNotEmpty && _items.every((e) => e.isSelected);

  bool isSellerAllSelected(String sellerName) {
    final group = itemsBySeller[sellerName] ?? const [];
    return group.isNotEmpty && group.every((e) => e.isSelected);
  }

  Future<void> toggleSeller(String sellerName, bool selected) async {
    for (final item in _items) {
      final name = item.listing.sellerName.isNotEmpty
          ? item.listing.sellerName
          : 'Người bán';
      if (name == sellerName) {
        item.isSelected = selected;
      }
    }
    await _repo.saveCartItems(_items);
    notifyListeners();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repo.getCartItems();
      bool needSave = false;
      // Gỡ item demo cũ (id mock_*) — tránh lỗi Invalid UUID lúc checkout.
      final before = _items.length;
      _items.removeWhere((e) => e.listing.isDemoListing);
      if (_items.length != before) needSave = true;

      for (var item in _items) {
        if (item.quantity < 1) {
          item.quantity = 1;
          needSave = true;
        }
      }
      if (needSave) {
        await _repo.saveCartItems(_items);
      }
    } catch (e) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Trả về `false` nếu listing demo / không checkout được với BE.
  Future<bool> addToCart(ListingModel listing, int quantity) async {
    if (listing.isDemoListing) {
      return false;
    }

    final maxAvailable = listing.availableQuantity > 0 
        ? listing.availableQuantity 
        : (listing.estimatedQuantity > 0 ? listing.estimatedQuantity : 999999);

    final existingIndex = _items.indexWhere((item) => item.listing.id == listing.id);
    if (existingIndex != -1) {
      final newQty = _items[existingIndex].quantity + quantity;
      _items[existingIndex].quantity = newQty > maxAvailable ? maxAvailable : newQty;
    } else {
      _items.add(CartItemModel(
        listing: listing,
        quantity: quantity > maxAvailable ? maxAvailable : quantity,
      ));
    }
    await _repo.saveCartItems(_items);
    notifyListeners();
    return true;
  }

  Future<void> removeFromCart(String listingId) async {
    _items.removeWhere((item) => item.listing.id == listingId);
    await _repo.saveCartItems(_items);
    notifyListeners();
  }

  Future<void> updateQuantity(String listingId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.listing.id == listingId);
    if (index != -1) {
      final listing = _items[index].listing;
      final maxAvailable = listing.availableQuantity > 0 
          ? listing.availableQuantity 
          : (listing.estimatedQuantity > 0 ? listing.estimatedQuantity : 999999);
      _items[index].quantity = newQuantity < 1 
          ? 1 
          : (newQuantity > maxAvailable ? maxAvailable : newQuantity);
      await _repo.saveCartItems(_items);
      notifyListeners();
    }
  }

  Future<void> toggleSelection(String listingId) async {
    final index = _items.indexWhere((item) => item.listing.id == listingId);
    if (index != -1) {
      _items[index].isSelected = !_items[index].isSelected;
      await _repo.saveCartItems(_items);
      notifyListeners();
    }
  }

  Future<void> toggleAll(bool selected) async {
    for (var item in _items) {
      item.isSelected = selected;
    }
    await _repo.saveCartItems(_items);
    notifyListeners();
  }

  Map<String, List<CartItemModel>> get itemsBySeller {
    final Map<String, List<CartItemModel>> groups = {};
    for (var item in _items) {
      final seller = item.listing.sellerName.isNotEmpty
          ? item.listing.sellerName
          : 'Người bán';
      groups.putIfAbsent(seller, () => []).add(item);
    }
    return groups;
  }

  Future<void> removePurchasedItems(List<String> listingIds) async {
    _items.removeWhere((item) => listingIds.contains(item.listing.id));
    await _repo.saveCartItems(_items);
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _repo.clearCart();
    notifyListeners();
  }
}
