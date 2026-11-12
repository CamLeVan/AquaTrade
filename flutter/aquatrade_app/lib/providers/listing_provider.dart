import 'package:flutter/material.dart';
import '../data/models/listing_model.dart';
import '../data/repositories/listing_repository.dart';

enum ListingState { initial, loading, success, error }

class ListingProvider with ChangeNotifier {
  final ListingRepository _repository;

  ListingProvider(this._repository);

  List<ListingModel> _listings = [];
  List<ListingModel> get listings => _listings;

  List<ListingModel> _sellerListings = [];
  List<ListingModel> get sellerListings => _sellerListings;

  ListingState _state = ListingState.initial;
  ListingState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> fetchListings({String? province, String? species}) async {
    _state = ListingState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _listings = await _repository.getListings(
        province: province,
        species: species,
      );
      _listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _state = ListingState.success;
    } catch (e) {
      _state = ListingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<ListingModel?> fetchListingDetail(String id) async {
    try {
      return await _repository.getListingDetail(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> createListing(ListingModel listing) async {
    _state = ListingState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final newListing = await _repository.createListing(listing);
      _sellerListings.insert(0, newListing);
      // DEMO: tin AVAILABLE → đẩy Chợ + invalidate bằng fetch lại từ BE.
      if (newListing.status == ListingStatus.AVAILABLE) {
        await fetchListings();
      }
      _state = ListingState.success;
    } catch (e) {
      _state = ListingState.error;
      _errorMessage = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<ListingModel> updatePrice(String id, double price) async {
    try {
      final updated = await _repository.updatePrice(id, price);
      final idx = _listings.indexWhere((element) => element.id == id);
      if (idx != -1) {
        _listings[idx] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<ListingModel> updateListing(String id, ListingModel listing) async {
    try {
      final updated = await _repository.updateListing(id, listing);
      
      final idx = _listings.indexWhere((element) => element.id == id);
      if (idx != -1) {
        _listings[idx] = updated;
      }
      final sellerIdx = _sellerListings.indexWhere((element) => element.id == id);
      if (sellerIdx != -1) {
        _sellerListings[sellerIdx] = updated;
      }
      
      // Đồng bộ làm tươi danh sách từ BE
      await fetchListings();
      await fetchSellerListings();

      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> deleteListing(String id) async {
    try {
      await _repository.deleteListing(id);
      _listings.removeWhere((element) => element.id == id);
      _sellerListings.removeWhere((element) => element.id == id);
      _pendingListings.removeWhere((element) => element.id == id);
      await fetchListings();
      await fetchSellerListings();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> moderateListing(String id, ListingStatus status, String note) async {
    try {
      await _repository.moderateListing(id, status, note);
      final idx = _listings.indexWhere((element) => element.id == id);
      if (idx != -1) {
        _listings.removeAt(idx);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  List<ListingModel> _pendingListings = [];
  List<ListingModel> get pendingListings => _pendingListings;

  Future<void> fetchSellerListings({String? sellerId}) async {
    try {
      _sellerListings = await _repository.getSellerListings(sellerId: sellerId);
      _sellerListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchPendingListings() async {
    try {
      _pendingListings = await _repository.getPendingListings();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> approveOrRejectListing(String id, bool approve, {String note = 'Admin Action'}) async {
    try {
      final status = approve ? ListingStatus.AVAILABLE : ListingStatus.REJECTED;
      await _repository.moderateListing(id, status, note);
      _pendingListings.removeWhere((l) => l.id == id);
      await fetchListings();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
