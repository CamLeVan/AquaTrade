import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';

class CartRepository {
  static const _cartKey = 'local_cart';

  Future<List<CartItemModel>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString(_cartKey);
      if (cartString == null || cartString.isEmpty) {
        return [];
      }
      final List<dynamic> decodedList = json.decode(cartString);
      return decodedList
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCartItems(List<CartItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, encodedList);
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
