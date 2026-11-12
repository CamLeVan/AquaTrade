import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:aquatrade_app/features/market/create_listing_screen.dart';
import 'package:aquatrade_app/providers/auth_provider.dart';
import 'package:aquatrade_app/providers/listing_provider.dart';
import 'package:aquatrade_app/data/repositories/auth_repository.dart';
import 'package:aquatrade_app/data/services/remote/api_service.dart';
import 'package:aquatrade_app/data/models/listing_model.dart';

class _MockApiService extends Mock implements ApiService {}

class MockListingProvider extends Mock implements ListingProvider {
  @override
  Future<void> createListing(ListingModel? listing) {
    return super.noSuchMethod(
      Invocation.method(#createListing, [listing]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Mock implements HttpClient {}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  late MockListingProvider mockProvider;

  setUp(() {
    mockProvider = MockListingProvider();
  });

  testWidgets('CreateListingScreen loads correctly in features/market', (WidgetTester tester) async {
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
          ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository(_MockApiService()))),
          ChangeNotifierProvider<ListingProvider>.value(value: mockProvider),
        ],
        child: const MaterialApp(
          home: CreateListingScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CreateListingScreen), findsOneWidget);
  });
}
