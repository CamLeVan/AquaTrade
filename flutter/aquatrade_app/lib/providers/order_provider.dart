import 'dart:io';

import 'package:flutter/material.dart';

import '../data/models/dispute_model.dart';
import '../data/models/order_model.dart';
import '../data/models/cart_item_model.dart';
import '../data/repositories/order_repository.dart';
import '../data/services/remote/cloudinary_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepository _repo;
  OrderProvider(this._repo);

  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  DisputeModel? _latestDispute;
  bool _isLoading = false;
  String _error = '';

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  DisputeModel? get latestDispute => _latestDispute;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchOrderById(String orderId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _currentOrder = await _repo.getOrderDetail(orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyOrders({bool isSeller = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      if (isSeller) {
        _orders = await _repo.getSellerOrders();
      } else {
        _orders = await _repo.getMyOrders();
      }
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOrder(String listingId, String address, int quantity) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _currentOrder = await _repo.createOrder(listingId, address, quantity);
      _orders.insert(0, _currentOrder!);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmCompletion(String orderId) async {
    try {
      await _repo.completeOrder(orderId);
      _currentOrder = await _repo.getOrderDetail(orderId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _repo.submitReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> raiseDispute({
    required String orderId,
    required String reason,
  }) async {
    try {
      _latestDispute = await _repo.createDispute(
        orderId: orderId,
        reason: reason,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> lockEscrow(String orderId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      await _repo.lockEscrow(orderId);
      await fetchOrderById(orderId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startAiAnalysis({
    required String orderId,
    required String videoUrl,
    required String videoPublicId,
    String? batchName,
    int? expectedQuantity,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      await _repo.startAi(
        orderId: orderId,
        videoUrl: videoUrl,
        videoPublicId: videoPublicId,
        batchName: batchName,
        batchExpectedQuantity: expectedQuantity,
      );
      await fetchOrderById(orderId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CloudinaryUploadResult> uploadAiVideo(File file) =>
      _repo.uploadAiVideo(file);

  /// Đơn buyer + seller (nếu có), gộp theo id.
  Future<List<OrderModel>> fetchOrdersForAiScan({
    required bool includeSellerOrders,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      final buyerOrders = await _repo.getMyOrders(forceRefresh: true);
      final byId = <String, OrderModel>{
        for (final o in buyerOrders) o.id: o,
      };
      if (includeSellerOrders) {
        try {
          final sellerOrders = await _repo.getSellerOrders();
          for (final o in sellerOrders) {
            byId[o.id] = o;
          }
        } catch (_) {
          // Buyer-only account: /orders/seller có thể 403 — bỏ qua.
        }
      }
      _orders = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return _orders;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmAi(String orderId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      await _repo.confirmAi(orderId);
      await fetchOrderById(orderId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approvePayout(String orderId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      await _repo.approvePayout(orderId);
      await fetchAdminOrders();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminOrders() async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _orders = await _repo.getAdminOrders();
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      await _repo.updateOrderStatus(orderId, status.name);
      await fetchOrderById(orderId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<OrderModel>> checkoutCart({
    required List<CartItemModel> selectedItems,
    required String shippingAddress,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      final itemsJson = selectedItems.map((item) {
        return {
          'listingId': item.listing.id,
          'shippingAddress': shippingAddress,
          'quantity': item.quantity,
          'isPrecheckOnly': false,
        };
      }).toList();

      final createdOrders = await _repo.checkoutCart(items: itemsJson);
      // Reload từ BE + ghi cache đúng — tránh mất đơn sau hot restart.
      _orders = await _repo.getMyOrders(forceRefresh: true);
      if (_orders.isEmpty && createdOrders.isNotEmpty) {
        _orders = List.of(createdOrders);
      }
      return createdOrders;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateLocalOrderStatus(String orderId, OrderStatus status) {
    if (_currentOrder != null && _currentOrder!.id == orderId) {
      _currentOrder = _currentOrder!.copyWith(status: status);
    }
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: status);
    }
    notifyListeners();
  }
}

