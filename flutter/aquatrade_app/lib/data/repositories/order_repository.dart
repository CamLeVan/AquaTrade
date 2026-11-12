import 'dart:io';

import '../models/order_model.dart';
import '../models/dispute_model.dart';
import '../services/remote/api_service.dart';
import '../services/remote/cloudinary_service.dart';
import '../services/local/local_service.dart';

class OrderRepository {
  final ApiService _api;
  final LocalService _local;
  late final CloudinaryService _cloudinary = CloudinaryService(_api);

  OrderRepository(this._api, this._local);

  Future<CloudinaryUploadResult> uploadAiVideo(File file) =>
      _cloudinary.uploadVideo(file);

  Future<List<OrderModel>> getMyOrders({bool forceRefresh = true}) async {
    // Mặc định luôn gọi BE — cache SQLite cũ dễ làm "mất đơn" sau hot restart
    // (checkout cập nhật memory nhưng không ghi cache; hoặc cache stale chặn API).
    if (!forceRefresh) {
      final cached = await _local.getCachedOrders();
      if (cached.isNotEmpty) {
        return cached.map(OrderModel.fromJson).toList();
      }
    }

    final response = await _api.get('/orders/my');
    final data = _api.parseData<List<dynamic>>(response);
    final orders = data
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();

    try {
      await _local.replaceOrders(orders.map(_cacheRow).toList());
    } catch (_) {
      // Cache lỗi không được làm fail cả lần tải đơn.
    }
    return orders;
  }

  Map<String, dynamic> _cacheRow(OrderModel o) => {
        'id': o.id,
        'listingTitle': o.listingTitle,
        'buyerName': o.buyerName,
        'sellerName': o.sellerName,
        'unitPriceAtPurchase': o.unitPriceAtPurchase,
        'finalQuantity': o.finalQuantity,
        'totalPrice': o.totalPrice,
        'shippingAddress': o.shippingAddress,
        'status': o.status.name,
        'createdAt': o.createdAt.toIso8601String(),
      };

  Future<List<OrderModel>> getSellerOrders() async {
    final response = await _api.get('/orders/seller');
    final data = _api.parseData<List<dynamic>>(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<OrderModel> getOrderDetail(String id) async {
    final response = await _api.get('/orders/$id');
    final data = _api.parseData<Map<String, dynamic>>(response);
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> createOrder(String listingId, String address, int quantity) async {
    final response = await _api.post('/orders', data: {
      'listingId': listingId,
      'shippingAddress': address,
      'quantity': quantity,
    });
    final data = _api.parseData<Map<String, dynamic>>(response);
    return OrderModel.fromJson(data);
  }

  Future<void> completeOrder(String id) async {
    final response = await _api.post('/orders/$id/complete');
    _api.parseData<dynamic>(response);
  }

  Future<void> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final response = await _api.post('/orders/$orderId/reviews', data: {
      'rating': rating,
      'comment': comment,
    });
    _api.parseData<dynamic>(response);
  }

  Future<DisputeModel> createDispute({
    required String orderId,
    required String reason,
  }) async {
    final response = await _api.post('/orders/$orderId/disputes', data: {
      'reason': reason,
    });
    final data = _api.parseData<Map<String, dynamic>>(response);
    return DisputeModel.fromJson(data);
  }

  Future<void> lockEscrow(String orderId) async {
    final response = await _api.post('/orders/$orderId/lock-escrow');
    _api.parseData<dynamic>(response);
  }

  Future<void> startAi({
    required String orderId,
    required String videoUrl,
    required String videoPublicId,
    String? batchName,
    int? batchExpectedQuantity,
  }) async {
    final response = await _api.post('/orders/$orderId/start-ai', data: {
      'videoUrl': videoUrl,
      'videoPublicId': videoPublicId,
      if (batchName != null && batchName.isNotEmpty) 'batchName': batchName,
      if (batchExpectedQuantity != null) 'batchExpectedQuantity': batchExpectedQuantity,
    });
    _api.parseData<dynamic>(response);
  }

  Future<void> confirmAi(String orderId) async {
    final response = await _api.post('/orders/$orderId/confirm');
    _api.parseData<dynamic>(response);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final response = await _api.put('/orders/$orderId/status', queryParameters: {
      'status': status,
    });
    _api.parseData<dynamic>(response);
  }

  Future<void> approvePayout(String orderId) async {
    final response = await _api.post('/orders/$orderId/approve-payout');
    _api.parseData<dynamic>(response);
  }

  Future<List<OrderModel>> getAdminOrders() async {
    final response = await _api.get('/admin/orders');
    final data = _api.parseData<List<dynamic>>(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }

  Future<List<OrderModel>> checkoutCart({
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _api.post('/orders/checkout-cart', data: {
      'items': items,
    });
    final data = _api.parseData<List<dynamic>>(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();
  }
}
