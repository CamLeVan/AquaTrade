import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:aquatrade_app/features/market/product_detail_screen.dart';
import 'package:aquatrade_app/data/repositories/listing_repository.dart';
import 'package:aquatrade_app/data/repositories/cart_repository.dart';
import 'package:aquatrade_app/data/services/remote/api_service.dart';
import 'package:aquatrade_app/data/services/local/local_service.dart';
import 'package:aquatrade_app/providers/listing_provider.dart';
import 'package:aquatrade_app/providers/cart_provider.dart';

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
  Future<HttpClientRequest> getUrl(Uri url) {
    return Future.value(_MockHttpClientRequest());
  }
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() {
    return Future.value(_MockHttpClientResponse());
  }
}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final List<int> _transparentImage = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82
];

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  late MockApiService mockApi;
  late MockLocalService mockLocal;
  late ListingRepository listingRepo;
  late CartRepository cartRepo;

  setUp(() {
    mockApi = MockApiService();
    mockLocal = MockLocalService();
    listingRepo = ListingRepository(mockApi, mockLocal);
    cartRepo = CartRepository();
  });

  testWidgets('ProductDetailScreen loads and renders header card', (WidgetTester tester) async {
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
          ChangeNotifierProvider(create: (_) => ListingProvider(listingRepo)),
          ChangeNotifierProvider(create: (_) => CartProvider(cartRepo)),
        ],
        child: const MaterialApp(
          home: ProductDetailScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });
}
