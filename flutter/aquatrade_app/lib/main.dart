import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'shared_providers/role_provider.dart';

import 'data/services/remote/api_service.dart';
import 'data/services/local/local_service.dart';
import 'data/repositories/listing_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/post_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/seller_repository.dart';

import 'data/repositories/chat_repository.dart';

import 'providers/listing_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/post_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/chat_provider.dart';

void main() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final apiService = ApiService();
  final localService = LocalService();

  final authRepository = AuthRepository(apiService);
  final listingRepository = ListingRepository(apiService, localService);
  final orderRepository = OrderRepository(apiService, localService);
  final walletRepository = WalletRepository(apiService);
  final postRepository = PostRepository(apiService, localService);
  final cartRepository = CartRepository();
  final sellerRepository = SellerRepository(apiService);
  final chatRepository = ChatRepository(apiService);

  final authProvider = AuthProvider(authRepository);
  // 401 / refresh fail → AuthProvider unauthenticated → GoRouter redirect.
  apiService.onSessionExpired = authProvider.handleSessionExpired;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider(listingRepository)),
        ChangeNotifierProvider(create: (_) => OrderProvider(orderRepository)),
        ChangeNotifierProvider(create: (_) => WalletProvider(walletRepository)),
        ChangeNotifierProvider(create: (_) => PostProvider(postRepository)),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => CartProvider(cartRepository)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(sellerRepository)),
        ChangeNotifierProvider(create: (_) => ChatProvider(repository: chatRepository)),
      ],
      child: AquaTradeApp(authProvider: authProvider),
    ),
  );
}

class AquaTradeApp extends StatefulWidget {
  const AquaTradeApp({super.key, required this.authProvider});

  final AuthProvider authProvider;

  @override
  State<AquaTradeApp> createState() => _AquaTradeAppState();
}

class _AquaTradeAppState extends State<AquaTradeApp> {
  late final GoRouter _router = createAppRouter(
    auth: widget.authProvider,
    initialLocation: AppRoutes.splash,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final roles = context.read<RoleProvider>();
      widget.authProvider.restoreSession(roles: roles);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AquaTrade AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
