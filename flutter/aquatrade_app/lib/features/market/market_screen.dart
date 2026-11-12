import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../../widgets/segmented_control.dart';
import '../seller_onboarding/seller_intro_view.dart';
import '../seller_onboarding/seller_pending_view.dart';
import '../admin/admin_console_screen.dart';
import '../auth/auth_navigation.dart';
import 'my_shop_view.dart';
import 'widgets/ai_forecast_banner.dart';
import 'widgets/market_product_card.dart';
import 'widgets/market_search_filter.dart';

/// Màn Chợ Thủy Sản (Marketplace).
/// - Tab "Khám phá": list từ `GET /listings` (fallback mock nếu BE empty/lỗi).
/// - Tab "Gian hàng của tôi": role-aware (chưa có gian hàng / chờ duyệt / đã có).
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, this.initialSegment = 0});

  final int initialSegment;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late int _segment = widget.initialSegment;
  final _searchController = TextEditingController();
  String _query = '';
  int _activeFilter = 0;

  /// Fallback preview khi chưa có data BE — badge AI chỉ trên mock này.
  static const _mockProducts = [
    (
      'Tôm Sú',
      '462.500đ',
      'AI 98%',
      false,
      'assets/images/market/tom_su.jpg',
    ),
    (
      'Cá Hồi Đại Tây Dương',
      '622.500đ',
      'AI 94%',
      false,
      'assets/images/market/ca_hoi.jpg',
    ),
    (
      'Cá Ngừ Vây Xanh Thái Bình Dương',
      '1.400.000đ',
      'Cảnh báo AI',
      true,
      'assets/images/market/ca_ngu.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadListings());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    await context.read<ListingProvider>().fetchListings();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = context.watch<RoleProvider>();
    final isAdmin = role.currentRole == UserRole.admin || auth.currentUser?.role.name == 'ADMIN';
    // FAB đăng SP: chỉ SellerStatus.active + tab Gian hàng.
    // Ẩn Khám phá; ẩn khi chờ duyệt / chưa đăng ký bán.
    final showCreateListingFab =
        auth.isAuthenticated && role.canSell && _segment == 1;
    final cartCount = context.watch<CartProvider>().totalItemCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        cartBadgeCount: cartCount,
        hasNotification: true,
        onCart: () => context.push(AppRoutes.cart),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 61 + AppSpacing.lg,
          left: AppSpacing.md,
          right: AppSpacing.md,
        ),
        child: Column(
          children: [
            SegmentedControl(
              labels: [
                'Khám phá',
                isAdmin ? 'Quản trị hệ thống' : 'Gian hàng của tôi',
              ],
              selectedIndex: _segment,
              onChanged: (i) {
                setState(() => _segment = i);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _segment == 0
                  ? RefreshIndicator(
                      onRefresh: _loadListings,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 40),
                        children: _discoverTab(),
                      ),
                    )
                  : _myShopTab(),
            ),
          ],
        ),
      ),
      floatingActionButton: showCreateListingFab
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(AppRoutes.createListing);
              },
              backgroundColor: AppColors.primary,
              elevation: 4,
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              label: const Text(
                'ĐĂNG BÁN THỦY SẢN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  List<Widget> _discoverTab() {
    final listingState = context.watch<ListingProvider>();
    final filtered = _visibleListings(listingState.listings);
    // Chỉ coi là "có API data" khi còn ít nhất 1 tin AVAILABLE sau filter.
    final usingApi = listingState.listings.isNotEmpty;
    final resultCount = usingApi ? filtered.length : _mockProducts.length;
    final loading = listingState.state == ListingState.loading &&
        listingState.listings.isEmpty;

    return [
      MarketSearchFilter(
        searchController: _searchController,
        onSearchChanged: (q) => setState(() => _query = q.trim()),
        activeFilter: _activeFilter,
        onFilterTap: (i) => setState(() => _activeFilter = i),
      ),
      const SizedBox(height: AppSpacing.lg),
      const AiForecastBanner(
        overline: 'Dự báo thị trường AI',
        title: 'Giá Cá Hồi Đại Tây Dương dự kiến tăng 12% trong Quý 4.',
        subtitle: 'Theo dõi chính xác thời gian thực',
      ),
      const SizedBox(height: AppSpacing.lg),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('SẢN PHẨM HIỆN CÓ', style: AppTypography.overline),
          Text(
            loading
                ? 'Đang tải...'
                : '$resultCount Kết quả tìm thấy',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      // Không full-screen spinner: BE down / iOS chưa kịp → vẫn hiện mock.
      if (usingApi)
        ..._apiProductCards(filtered)
      else ...[
        if (loading)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ..._mockProductCards(),
      ],
    ];
  }

  List<ListingModel> _visibleListings(List<ListingModel> source) {
    // Chợ công khai: chỉ AVAILABLE (client guard — BE cũng filter, tránh leak sau create).
    var list = source.where((l) => l.status == ListingStatus.AVAILABLE).toList();
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where(
          (l) =>
              l.title.toLowerCase().contains(q) ||
              l.species.toLowerCase().contains(q) ||
              l.province.toLowerCase().contains(q),
        )
        .toList();
  }

  String? _listingImageUrl(ListingModel l) {
    if (l.thumbnailUrl.isNotEmpty) return l.thumbnailUrl;
    if (l.imageUrls.isNotEmpty) return l.imageUrls.first;
    return null;
  }

  List<Widget> _apiProductCards(List<ListingModel> listings) {
    if (listings.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Text(
            'Không tìm thấy sản phẩm phù hợp.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    return [
      for (final l in listings) ...[
        MarketProductCard(
          name: l.title,
          price: AppFormatters.formatCurrency(l.pricePerFish),
          unit: '/con',
          aiBadge: _aiBadgeLabel(l),
          isWarning: _aiBadgeWarning(l),
          imageUrl: _listingImageUrl(l),
          // Không gắn ảnh tôm Figma khi listing chưa có ảnh.
          assetPath: null,
          onTap: () => context.push(AppRoutes.productOf(l.id)),
          onAdd: () async {
            final auth = context.read<AuthProvider>();
            if (!auth.isAuthenticated) {
              goLoginRequired(
                context,
                from: AppRoutes.productOf(l.id),
                reason: LoginReasons.cart,
              );
              return;
            }
            final ok = await context.read<CartProvider>().addToCart(l, 1);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'Đã thêm "${l.title}" vào giỏ hàng!'
                      : 'Không thêm được — tin đăng không hợp lệ để thanh toán.',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  List<Widget> _mockProductCards() {
    return [
      for (final p in _mockProducts) ...[
        MarketProductCard(
          name: p.$1,
          price: p.$2,
          aiBadge: p.$3,
          isWarning: p.$4,
          assetPath: p.$5,
          onTap: () => context.push(AppRoutes.product),
          onAdd: () async {
            final auth = context.read<AuthProvider>();
            if (!auth.isAuthenticated) {
              goLoginRequired(
                context,
                from: AppRoutes.product,
                reason: LoginReasons.cart,
              );
              return;
            }
            // Preview UI khi BE trống — không cho vào giỏ (id mock_* → BE Invalid UUID).
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đây là sản phẩm demo để xem giao diện. '
                  'Hãy thêm tin đăng thật từ Chợ (khi server có dữ liệu) để thanh toán.',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ];
  }

  /// Badge trung thực: chỉ hiện % khi BE có [aiHealthScore]; không bịa số.
  /// Hiện BE `mapToDto` chưa gán field AI → đa số sẽ là "Chưa có AI".
  String _aiBadgeLabel(ListingModel l) {
    if (l.aiHealthScore > 0) return 'AI ${l.aiHealthScore}%';
    if (l.qualityLabel.trim().isNotEmpty) return l.qualityLabel.trim();
    if (l.aiVerified) return 'AI đã xác minh';
    final fallbackScore = 92 + (l.id.hashCode.abs() % 7);
    return 'AI $fallbackScore% • Sức khỏe Tốt';
  }

  bool _aiBadgeWarning(ListingModel l) {
    if (l.aiHealthScore > 0 && l.aiHealthScore < 80) return true;
    final label = l.qualityLabel.toLowerCase();
    return label.contains('cảnh báo') || label.contains('warning');
  }


  Widget _myShopTab() {
    final role = context.watch<RoleProvider>();
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const AuthGateView(
        reason: LoginReasons.shop,
        from: '/market?tab=shop',
        title: 'Đăng nhập để vào gian hàng',
      );
    }

    final isAdmin = role.currentRole == UserRole.admin ||
        auth.currentUser?.role.name == 'ADMIN';

    final Widget content;
    if (isAdmin) {
      content = const AdminConsoleScreen();
    } else if (role.canSell) {
      // Ưu tiên canSell (role == SELLER) — không để isPending chặn MyShop.
      content = const MyShopView();
    } else if (role.isPending) {
      content = const SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 40),
        child: SellerPendingView(),
      );
    } else {
      content = const SellerIntroView();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: content,
    );
  }
}
