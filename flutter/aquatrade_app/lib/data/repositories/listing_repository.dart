import '../models/listing_model.dart';
import '../services/remote/api_service.dart';
import '../services/local/local_service.dart';

class ListingRepository {
  final ApiService _apiService;
  final LocalService _localService;

  ListingRepository(this._apiService, this._localService);

  Future<List<ListingModel>> getListings({
    String? province,
    String? species,
    String? sellerId,
    bool forceRefresh = true,
  }) async {
    // Mặc định luôn gọi BE — cache SQLite stale dễ làm Chợ “mất tin” sau hot restart.
    if (!forceRefresh && sellerId == null) {
      final cachedJson = await _localService.getCachedListings();
      if (cachedJson.isNotEmpty) {
        return cachedJson.map((json) => ListingModel.fromJson(json)).toList();
      }
    }

    final response = await _apiService.get(
      '/listings',
      queryParameters: {
        if (province != null && province.isNotEmpty) 'province': province,
        if (species != null && species.isNotEmpty) 'species': species,
        if (sellerId != null && sellerId.isNotEmpty) 'sellerId': sellerId,
      },
    );
    final List<dynamic> data = _apiService.parseData<List<dynamic>>(response);
    final listings = data.map((json) => ListingModel.fromJson(json)).toList();

    if (sellerId == null) {
      try {
        await _localService.replaceListings(
          listings.map(_cacheRow).toList(),
        );
      } catch (_) {
        // Cache lỗi không được làm fail cả lần tải Chợ.
      }
    }

    return listings;
  }

  Map<String, dynamic> _cacheRow(ListingModel l) => {
        'id': l.id,
        'title': l.title,
        'category': l.category.name,
        'species': l.species,
        'province': l.province,
        'pricePerFish': l.pricePerFish,
        'availableQuantity': l.availableQuantity,
        'thumbnailUrl': l.thumbnailUrl,
        'status': l.status.name,
        'sellerName': l.sellerName,
        'aiVerified': l.aiVerified,
        'qualityLabel': l.qualityLabel,
        'isFavorite': l.isFavorite,
        'createdAt': l.createdAt.toIso8601String(),
      };

  Future<ListingModel> getListingDetail(String id) async {
    final response = await _apiService.get('/listings/$id');
    final data = _apiService.parseData<Map<String, dynamic>>(response);
    return ListingModel.fromJson(data);
  }

  Future<ListingModel> createListing(ListingModel listing) async {
    try {
      final requestData = {
        'title': listing.title,
        'category': listing.category.name,
        'species': listing.species,
        'province': listing.province,
        'sizeMin': listing.sizeMin,
        'sizeMax': listing.sizeMax,
        'pricePerFish': listing.pricePerFish,
        'estimatedQuantity': listing.estimatedQuantity,
        'description': listing.description,
        'imageUrls': listing.imageUrls,
        'thumbnailUrl': listing.thumbnailUrl,
      };
      final response = await _apiService.post('/listings', data: requestData);
      if (response.data['status'] == 'success') {
        return ListingModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create listing');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ListingModel>> getSellerListings({String? sellerId}) async {
    // Ưu tiên my-listings (mọi status trừ DELETED). Public ?sellerId= chỉ AVAILABLE.
    try {
      final response = await _apiService.get('/listings/my-listings');
      final List<dynamic> data = _apiService.parseData<List<dynamic>>(response);
      return data.map((json) => ListingModel.fromJson(json)).toList();
    } catch (_) {
      if (sellerId != null && sellerId.isNotEmpty) {
        return getListings(sellerId: sellerId, forceRefresh: true);
      }
      rethrow;
    }
  }

  Future<ListingModel> updatePrice(String id, double price) async {
    final response = await _apiService.patch('/listings/$id/price', data: {'price': price});
    final data = _apiService.parseData<Map<String, dynamic>>(response);
    return ListingModel.fromJson(data);
  }

  Future<ListingModel> updateListing(String id, ListingModel listing) async {
    final requestData = {
      'title': listing.title,
      'category': listing.category.name,
      'species': listing.species,
      'province': listing.province,
      'sizeMin': listing.sizeMin,
      'sizeMax': listing.sizeMax,
      'pricePerFish': listing.pricePerFish,
      'estimatedQuantity': listing.estimatedQuantity,
      'description': listing.description,
      'imageUrls': listing.imageUrls,
      'thumbnailUrl': listing.thumbnailUrl,
    };
    final response = await _apiService.put('/listings/$id', data: requestData);
    final data = _apiService.parseData<Map<String, dynamic>>(response);
    return ListingModel.fromJson(data);
  }

  Future<void> deleteListing(String id) async {
    final response = await _apiService.delete('/listings/$id');
    _apiService.parseData<dynamic>(response);
  }

  Future<List<ListingModel>> getPendingListings() async {
    try {
      final response = await _apiService.get('/admin/listings/pending');
      final List<dynamic> data = _apiService.parseData<List<dynamic>>(response);
      return data.map((json) => ListingModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> moderateListing(String id, ListingStatus status, String note) async {
    final response = await _apiService.put('/admin/listings/$id/moderate', data: {
      'moderationStatus': status.name,
      'moderationNote': note,
    });
    _apiService.parseData<dynamic>(response);
  }
}
