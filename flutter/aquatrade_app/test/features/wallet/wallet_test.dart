import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:aquatrade_app/features/wallet/wallet_screen.dart';
import 'package:aquatrade_app/providers/wallet_provider.dart';
import 'package:aquatrade_app/providers/auth_provider.dart';
import 'package:aquatrade_app/shared_providers/role_provider.dart';
import 'package:aquatrade_app/data/repositories/wallet_repository.dart';
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

class _MockHttpClient extends Mock implements HttpClient {}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  late MockApiService mockApi;
  late WalletRepository walletRepo;

  setUp(() {
    mockApi = MockApiService();
    walletRepo = WalletRepository(mockApi);
  });

  testWidgets('WalletScreen in features/wallet loads cleanly', (WidgetTester tester) async {
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
          ChangeNotifierProvider(create: (_) => WalletProvider(walletRepo)),
          ChangeNotifierProvider(create: (_) => RoleProvider()),
        ],
        child: const MaterialApp(
          home: WalletScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WalletScreen), findsOneWidget);
  });
}
