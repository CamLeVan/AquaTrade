import 'package:flutter/material.dart';

import '../data/models/seller_stats_model.dart';
import '../data/repositories/seller_repository.dart';

/// State riêng Dashboard (seller stats). Không đụng canSell / withdraw.
class DashboardProvider with ChangeNotifier {
  DashboardProvider(this._sellerRepo);

  final SellerRepository _sellerRepo;

  SellerStatsModel? _sellerStats;
  bool _isLoadingStats = false;
  String _statsError = '';

  SellerStatsModel? get sellerStats => _sellerStats;
  bool get isLoadingStats => _isLoadingStats;
  String get statsError => _statsError;

  /// Chỉ gọi khi Dashboard cần view Seller (`showSellerDashboard`).
  Future<void> fetchSellerStats(String sellerId) async {
    if (sellerId.isEmpty) return;
    _isLoadingStats = true;
    _statsError = '';
    notifyListeners();
    try {
      _sellerStats = await _sellerRepo.getSellerStats(sellerId);
    } catch (e) {
      _statsError = e.toString();
      // Giữ null → HomeScreen fallback mock, không giả AI %.
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  void clearSellerStats() {
    _sellerStats = null;
    _statsError = '';
    notifyListeners();
  }
}
