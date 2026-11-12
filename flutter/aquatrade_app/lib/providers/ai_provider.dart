import 'package:flutter/material.dart';

enum AiAnalysisState { initial, analyzing, success, error }

class AiProvider with ChangeNotifier {
  AiAnalysisState _state = AiAnalysisState.initial;
  String _errorMessage = '';
  Map<String, dynamic>? _analysisResult;

  AiAnalysisState get state => _state;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  Future<void> analyzeMarketData(String symbol) async {
    _state = AiAnalysisState.analyzing;
    _errorMessage = '';
    notifyListeners();

    try {
      // TODO: Connect to actual AiRepository when available
      await Future.delayed(const Duration(seconds: 2)); // Mocking delay
      
      _analysisResult = {
        'symbol': symbol,
        'sentiment': 'Bullish',
        'healthScore': 95,
        'recommendation': 'Strong Buy',
        'confidence': 0.88,
      };
      
      _state = AiAnalysisState.success;
    } catch (e) {
      _state = AiAnalysisState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _state = AiAnalysisState.initial;
    _errorMessage = '';
    _analysisResult = null;
    notifyListeners();
  }
}
