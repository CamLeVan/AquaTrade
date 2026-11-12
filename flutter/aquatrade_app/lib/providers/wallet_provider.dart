import 'package:flutter/material.dart';
import '../data/models/wallet_model.dart';
import '../data/repositories/wallet_repository.dart';

class WalletProvider with ChangeNotifier {
  final WalletRepository _repo;
  WalletProvider(this._repo);

  WalletModel? _wallet;
  bool _isLoading = false;
  String _errorMessage = '';

  List<TransactionModel> _pendingDeposits = [];

  WalletModel? get wallet => _wallet;
  List<TransactionModel> get pendingDeposits => _pendingDeposits;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchWallet() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _wallet = await _repo.getMyWallet();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPendingDeposits() async {
    try {
      _pendingDeposits = await _repo.getPendingDeposits();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<bool> approveDeposit(String id) async {
    try {
      await _repo.approveDeposit(id);
      await fetchPendingDeposits();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> rejectDeposit(String id) async {
    try {
      await _repo.rejectDeposit(id);
      await fetchPendingDeposits();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> deposit({
    required double amount,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _repo.deposit(amount, paymentMethod);
      await fetchWallet();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> withdraw({
    required double amount,
    required String bankAccount,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _repo.withdraw(amount, bankAccount);
      await fetchWallet();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
