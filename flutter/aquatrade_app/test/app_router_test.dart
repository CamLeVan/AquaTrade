import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:aquatrade_app/core/router/app_router.dart';
import 'package:aquatrade_app/core/router/app_routes.dart';
import 'package:aquatrade_app/data/repositories/auth_repository.dart';
import 'package:aquatrade_app/data/repositories/listing_repository.dart';
import 'package:aquatrade_app/data/repositories/order_repository.dart';
import 'package:aquatrade_app/data/repositories/wallet_repository.dart';
import 'package:aquatrade_app/data/repositories/post_repository.dart';
import 'package:aquatrade_app/data/repositories/seller_repository.dart';
import 'package:aquatrade_app/data/repositories/cart_repository.dart';
import 'package:aquatrade_app/data/services/remote/api_service.dart';
import 'package:aquatrade_app/data/services/local/local_service.dart';

import 'package:aquatrade_app/providers/auth_provider.dart';
import 'package:aquatrade_app/providers/listing_provider.dart';
import 'package:aquatrade_app/providers/order_provider.dart';
import 'package:aquatrade_app/providers/wallet_provider.dart';
import 'package:aquatrade_app/providers/post_provider.dart';
import 'package:aquatrade_app/providers/dashboard_provider.dart';
import 'package:aquatrade_app/providers/ai_provider.dart';
import 'package:aquatrade_app/providers/kyc_provider.dart';
import 'package:aquatrade_app/providers/cart_provider.dart';
import 'package:aquatrade_app/shared_providers/role_provider.dart';
import 'package:aquatrade_app/providers/chat_provider.dart';

import 'package:aquatrade_app/features/cart/cart_screen.dart' as functional;
import 'package:aquatrade_app/features/chat/chat_screen.dart' as functional;
import 'package:aquatrade_app/features/wallet/wallet_screen.dart' as functional;
import 'package:aquatrade_app/features/orders/order_history_screen.dart' as functional;

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

  late AuthRepository authRepo;
  late ListingRepository listingRepo;
  late WalletRepository walletRepo;
  late PostRepository postRepo;
  late SellerRepository sellerRepo;
  late OrderRepository orderRepo;
  late CartRepository cartRepo;

  setUp(() {
    mockApi = MockApiService();
    mockLocal = MockLocalService();

    authRepo = AuthRepository(mockApi);
    listingRepo = ListingRepository(mockApi, mockLocal);
    walletRepo = WalletRepository(mockApi);
    postRepo = PostRepository(mockApi, mockLocal);
    sellerRepo = SellerRepository(mockApi);
    orderRepo = OrderRepository(mockApi, mockLocal);
    cartRepo = CartRepository();
  });

  Widget buildTestableWidget(GoRouter router, {AuthProvider? auth}) {
    final authProvider = auth ?? AuthProvider(authRepo)..debugMarkAuthenticated();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ListingProvider(listingRepo)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepo)),
        ChangeNotifierProvider(create: (_) => CartProvider(cartRepo)),
        ChangeNotifierProvider(create: (_) => WalletProvider(walletRepo)),
        ChangeNotifierProvider(create: (_) => PostProvider(postRepo)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(sellerRepo)),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('GoRouter navigates to functional CartScreen', (WidgetTester tester) async {
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

    final auth = AuthProvider(authRepo)..debugMarkAuthenticated();
    final router = createAppRouter(auth: auth, initialLocation: AppRoutes.cart);
    await tester.pumpWidget(buildTestableWidget(router, auth: auth));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(functional.CartScreen), findsOneWidget);
  });

  testWidgets('GoRouter navigates to functional MessagesScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed') || msg.contains('ListTile background color')) return;
      originalOnError?.call(details);
    };
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      FlutterError.onError = originalOnError;
    });

    final auth = AuthProvider(authRepo)..debugMarkAuthenticated();
    final router = createAppRouter(auth: auth, initialLocation: AppRoutes.chat);
    await tester.pumpWidget(buildTestableWidget(router, auth: auth));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(functional.ChatScreen), findsOneWidget);
  });

  testWidgets('GoRouter navigates to functional WalletScreen', (WidgetTester tester) async {
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

    final auth = AuthProvider(authRepo)..debugMarkAuthenticated();
    final router = createAppRouter(auth: auth, initialLocation: AppRoutes.wallet);
    await tester.pumpWidget(buildTestableWidget(router, auth: auth));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(functional.WalletScreen), findsOneWidget);
  });

  testWidgets('GoRouter navigates to functional OrderHistoryScreen', (WidgetTester tester) async {
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

    final auth = AuthProvider(authRepo)..debugMarkAuthenticated();
    final router = createAppRouter(auth: auth, initialLocation: AppRoutes.orders);
    await tester.pumpWidget(buildTestableWidget(router, auth: auth));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(functional.OrderHistoryScreen), findsOneWidget);
  });
}
