import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

enum KycState { unverified, submitting, pending, verified, rejected }

class KycProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  KycState _state = KycState.unverified;
  String _errorMessage = '';

  KycProvider(this._authRepository);

  KycState get state => _state;
  String get errorMessage => _errorMessage;

  bool get isVerified => _state == KycState.verified;

  Future<void> submitKycData(Map<String, dynamic> formData) async {
    _state = KycState.submitting;
    _errorMessage = '';
    notifyListeners();

    try {
      final phone = formData['phoneNumber']?.toString() ?? '';
      final address = formData['address']?.toString() ?? '';
      final company = formData['companyName']?.toString();
      
      await _authRepository.updateProfile(
        phoneNumber: phone,
        address: address,
        companyName: company,
      );

      await _authRepository.requestVerification();
      
      _state = KycState.pending;
    } catch (e) {
      _state = KycState.unverified;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Helper method to mock approval
  void mockApprove() {
    _state = KycState.verified;
    notifyListeners();
  }
}
