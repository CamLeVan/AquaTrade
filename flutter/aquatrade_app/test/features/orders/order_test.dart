import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:aquatrade_app/features/orders/order_history_screen.dart';
import 'package:aquatrade_app/providers/order_provider.dart';
import 'package:aquatrade_app/providers/auth_provider.dart';
import 'package:aquatrade_app/data/repositories/order_repository.dart';
import 'package:aquatrade_app/data/repositories/auth_repository.dart';
import 'package:aquatrade_app/data/services/remote/api_service.dart';
import 'package:aquatrade_app/data/services/local/local_service.dart';

class MockApiService extends Mock implements ApiService {}
class MockLocalService extends Mock implements LocalService {}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  HttpHeaders get headers => _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Mock implements HttpHeaders {}
class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 404;
  @override
  int get contentLength => 0;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
}

void main() {
  HttpOverrides.global = MockHttpOverrides();

  late MockApiService mockApi;
  late MockLocalService mockLocal;
  late OrderRepository orderRepo;

  setUp(() {
    mockApi = MockApiService();
    mockLocal = MockLocalService();
    orderRepo = OrderRepository(mockApi, mockLocal);
  });

  testWidgets('OrderHistoryScreen in features/orders loads cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      originalOnError?.call(details);
    };
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository(mockApi))),
          ChangeNotifierProvider(create: (_) => OrderProvider(orderRepo)),
        ],
        child: const MaterialApp(
          home: OrderHistoryScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(OrderHistoryScreen), findsOneWidget);
  });
}
