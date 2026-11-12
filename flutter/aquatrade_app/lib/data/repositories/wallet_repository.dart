import '../models/wallet_model.dart';
import '../services/remote/api_service.dart';

class WalletRepository {
  final ApiService _api;

  WalletRepository(this._api);

  Future<WalletModel> getMyWallet() async {
    // BE: WalletController @GetMapping("/users/me/wallet")
    final response = await _api.get('/users/me/wallet');
    final data = _api.parseData<Map<String, dynamic>>(response);
    return WalletModel.fromJson(data);
  }

  Future<void> deposit(double amount, String method) async {
    final response = await _api.post('/users/me/wallet/deposit', data: {
      'amount': amount,
      'paymentMethod': method,
    });
    _api.parseData<dynamic>(response);
  }

  Future<List<TransactionModel>> getPendingDeposits() async {
    final response = await _api.get('/users/me/wallet/admin/pending');
    final list = _api.parseData<List<dynamic>>(response);
    return list.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<void> approveDeposit(String id) async {
    final response = await _api.post('/users/me/wallet/admin/approve/$id');
    _api.parseData<dynamic>(response);
  }

  Future<void> rejectDeposit(String id) async {
    final response = await _api.post('/users/me/wallet/admin/reject/$id');
    _api.parseData<dynamic>(response);
  }

  /// BE chưa có endpoint withdraw — UI hiện snackbar, không gọi API.
  Future<void> withdraw(double amount, String bankAccount) async {
    throw UnsupportedError(
      'Rút tiền chưa được hỗ trợ (thiếu POST /users/me/wallet/withdraw).',
    );
  }
}
