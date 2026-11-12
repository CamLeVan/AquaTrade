import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:aquatrade_app/features/account/account_screen.dart';
import 'package:aquatrade_app/features/admin/admin_console_screen.dart';
import 'package:aquatrade_app/providers/auth_provider.dart';
import 'package:aquatrade_app/providers/listing_provider.dart';
import 'package:aquatrade_app/providers/order_provider.dart';
import 'package:aquatrade_app/shared_providers/role_provider.dart';
import 'package:aquatrade_app/data/repositories/auth_repository.dart';
import 'package:aquatrade_app/data/repositories/listing_repository.dart';
import 'package:aquatrade_app/data/repositories/order_repository.dart';
import 'package:aquatrade_app/data/services/remote/api_service.dart';
import 'package:aquatrade_app/data/services/local/local_service.dart';

import 'package:aquatrade_app/providers/wallet_provider.dart';
import 'package:aquatrade_app/data/repositories/wallet_repository.dart';

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
  late MockLocalService mockLocal;
  late AuthRepository authRepo;
  late ListingRepository listingRepo;
  late OrderRepository orderRepo;
  late WalletRepository walletRepo;

  setUp(() {
    mockApi = MockApiService();
    mockLocal = MockLocalService();
    authRepo = AuthRepository(mockApi);
    listingRepo = ListingRepository(mockApi, mockLocal);
    orderRepo = OrderRepository(mockApi, mockLocal);
    walletRepo = WalletRepository(mockApi);
  });

  testWidgets('AccountScreen loads cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
          ChangeNotifierProvider(create: (_) => RoleProvider()),
          ChangeNotifierProvider(create: (_) => ListingProvider(listingRepo)),
          ChangeNotifierProvider(create: (_) => OrderProvider(orderRepo)),
          ChangeNotifierProvider(create: (_) => WalletProvider(walletRepo)),
        ],
        child: const MaterialApp(
          home: AccountScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AccountScreen), findsOneWidget);
  });

  testWidgets('AdminConsoleScreen loads cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
          ChangeNotifierProvider(create: (_) => RoleProvider()),
          ChangeNotifierProvider(create: (_) => ListingProvider(listingRepo)),
          ChangeNotifierProvider(create: (_) => OrderProvider(orderRepo)),
        ],
        child: const MaterialApp(
          home: AdminConsoleScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AdminConsoleScreen), findsOneWidget);
  });
}
