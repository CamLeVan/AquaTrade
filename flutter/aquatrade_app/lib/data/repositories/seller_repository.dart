import '../models/seller_stats_model.dart';
import '../services/remote/api_service.dart';

class SellerRepository {
  SellerRepository(this._api);

  final ApiService _api;

  Future<SellerStatsModel> getSellerStats(String sellerId) async {
    final response = await _api.get('/seller/$sellerId/stats');
    final data = _api.parseData<Map<String, dynamic>>(response);
    return SellerStatsModel.fromJson(data);
  }
}
