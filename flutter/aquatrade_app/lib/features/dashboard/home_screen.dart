import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/seller_stats_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/animations.dart';
import '../../widgets/status_chip.dart';
import 'widgets/activity_item.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/featured_product_card.dart';
import 'widgets/market_trend_chart.dart';
import 'widgets/stat_card.dart';

/// Trang chủ / Tổng quan (role-aware Buyer/Seller).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.userName = 'Gia Huy'});

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _productsController =
      PageController(viewportFraction: 0.52);
  int _productPage = 0;
  late String _displayName;
  bool _hydrating = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  @override
  void dispose() {
    _productsController.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    if (!mounted || _hydrating) return;
    _hydrating = true;

    final auth = context.read<AuthProvider>();
    final roles = context.read<RoleProvider>();
    final wallet = context.read<WalletProvider>();
    final listings = context.read<ListingProvider>();
    final dashboard = context.read<DashboardProvider>();

    final user = await auth.loadProfile(roles: roles);
    if (!mounted) return;

    if (user != null && user.fullName.trim().isNotEmpty) {
      setState(() => _displayName = user.fullName.trim());
    }

    await Future.wait<void>([
      wallet.fetchWallet(),
      listings.fetchListings(),
    ]);
    if (!mounted) return;

    if (roles.showSellerDashboard && user != null && user.id.isNotEmpty) {
      await dashboard.fetchSellerStats(user.id);
    }

    _hydrating = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showSellerDashboard =
        context.watch<RoleProvider>().showSellerDashboard;
    final sellerStats = context.watch<DashboardProvider>().sellerStats;
    final listings = context.watch<ListingProvider>().listings;
    final cartCount = context.watch<CartProvider>().totalItemCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        cartBadgeCount: cartCount,
        hasNotification: true,
        onCart: () => context.push(AppRoutes.cart),
      ),
      body: RefreshIndicator(
        onRefresh: _hydrate,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 61 + AppSpacing.md,
            bottom: 40,
          ),
          children: [
            _buildHero(showSellerDashboard, sellerStats),
            const SizedBox(height: AppSpacing.xl),
            _buildFeatured(listings),
            const SizedBox(height: AppSpacing.xl),
            _buildRecentActivity(showSellerDashboard),
            const SizedBox(height: AppSpacing.xl),
            _buildMarketTrend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool showSellerDashboard, SellerStatsModel? stats) {
    final auth = context.watch<AuthProvider>();
    final isAuthenticated = auth.isAuthenticated;
    final fromAuth = auth.currentUser?.fullName.trim();
    final displayName = !isAuthenticated
        ? 'Khách'
        : (fromAuth != null && fromAuth.isNotEmpty)
            ? fromAuth
            : (_displayName.isNotEmpty ? _displayName : 'Khách');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TỔNG QUAN', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.xxs),
          RichText(
            text: TextSpan(
              style: AppTypography.heading,
              children: [
                const TextSpan(text: 'Xin chào, '),
                TextSpan(
                  text: displayName,
                  style:
                      AppTypography.heading.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            !isAuthenticated
                ? 'Sàn giao dịch thủy sản tươi sống và đếm cá AI hàng đầu Việt Nam.'
                : showSellerDashboard
                    ? 'Theo dõi thị trường thủy sản và tối ưu hoạt động kinh doanh.'
                    : 'Theo dõi thị trường và quản lý các đơn mua của bạn.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          AiInsightCard(
            message: showSellerDashboard
                ? 'Nguồn cung tôm thẻ chân trắng dự kiến giảm 15% tuần tới. Cân nhắc nhập hàng sớm.'
                : 'Giá tôm thẻ chân trắng dự kiến giảm 15% tuần tới. Đây là thời điểm tốt để đặt mua.',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatsGrid(showSellerDashboard, stats, isAuthenticated),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool showSellerDashboard, SellerStatsModel? stats, bool isAuthenticated) {
    final List<StatCard> cards = !isAuthenticated
        ? const [
            StatCard(
              icon: Icons.storefront,
              iconColor: AppColors.tertiary,
              label: 'Thủy sản niêm yết',
              value: '1.250+',
            ),
            StatCard(
              icon: Icons.verified_user,
              label: 'Trại nuôi xác thực',
              value: '85+',
            ),
            StatCard(
              icon: Icons.auto_awesome,
              label: 'Độ chính xác AI',
              value: '99.8%',
            ),
          ]
        : showSellerDashboard
            ? [
                StatCard(
                  icon: Icons.payments,
                  label: 'Tổng doanh số',
                  value: stats != null
                      ? AppFormatters.formatCurrency(stats.totalSales)
                      : '3.562.500.000đ',
                ),
                StatCard(
                  icon: Icons.dynamic_feed,
                  iconColor: AppColors.tertiary,
                  label: 'Giao dịch đang hoạt động',
                  value: stats != null ? '${stats.pendingOrders}' : '248',
                  delta: stats == null ? '+12%' : null,
                ),
                StatCard(
                  icon: Icons.star_rate_rounded,
                  label: 'Đánh giá shop',
                  value: stats != null
                      ? stats.shopRating.toStringAsFixed(1)
                      : '4.8',
                ),
              ]
            : const [
                StatCard(
                  icon: Icons.local_shipping,
                  iconColor: AppColors.tertiary,
                  label: 'Đơn đang giao',
                  value: '3',
                ),
                StatCard(
                  icon: Icons.account_balance_wallet,
                  label: 'Chi tiêu tháng này',
                  value: '12.500.000đ',
                ),
                StatCard(
                  icon: Icons.bookmark,
                  label: 'Sản phẩm đã lưu',
                  value: '18',
                ),
              ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: AppSpacing.md),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatured(List<ListingModel> listings) {
    const dir = 'assets/images/dashboard';
    
    // Sắp xếp các mặt hàng theo số lượt mua nhiều nhất (Top Best Sellers)
    final sortedListings = List<ListingModel>.from(listings);
    sortedListings.sort((a, b) {
      final aScore = a.purchaseCount > 0 ? a.purchaseCount : a.soldQuantity;
      final bScore = b.purchaseCount > 0 ? b.purchaseCount : b.soldQuantity;
      if (bScore != aScore) {
        return bScore.compareTo(aScore);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    final featured = sortedListings.take(6).toList();

    final items = featured.isNotEmpty
        ? featured.asMap().entries.map((entry) {
            final idx = entry.key;
            final l = entry.value;
            final img = l.thumbnailUrl.isNotEmpty
                ? l.thumbnailUrl
                : (l.imageUrls.isNotEmpty ? l.imageUrls.first : null);
            return _FeaturedItem(
              name: l.title,
              price: '${AppFormatters.formatCurrency(l.pricePerFish)} / con',
              badgeIcon: l.aiVerified ? Icons.verified : Icons.water_drop,
              badgeColor:
                  l.aiVerified ? AppColors.primary : AppColors.tertiary,
              imageUrl: img,
              assetPath: img == null ? '$dir/tom_cop_xanh.jpg' : null,
              listingId: l.id,
              purchaseCount: l.purchaseCount,
              soldQuantity: l.soldQuantity,
              rank: idx + 1,
            );
          }).toList()
        : const [
            _FeaturedItem(
              name: 'Tôm Cọp Xanh',
              price: '312.500đ / con',
              badgeIcon: Icons.water_drop,
              badgeColor: AppColors.primary,
              assetPath: '$dir/tom_cop_xanh.jpg',
              purchaseCount: 142,
              rank: 1,
            ),
            _FeaturedItem(
              name: 'Cá Xiêm Vàng',
              price: '2.125.000đ / con',
              badgeIcon: Icons.set_meal,
              badgeColor: AppColors.tertiary,
              assetPath: '$dir/ca_xiem_vang.jpg',
              purchaseCount: 98,
              rank: 2,
            ),
            _FeaturedItem(
              name: 'Cá Hồi Cao Cấp',
              price: '550.000đ / con',
              badgeIcon: Icons.inventory_2,
              badgeColor: AppColors.textTertiary,
              assetPath: '$dir/ca_hoi.jpg',
              purchaseCount: 65,
              rank: 3,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Color(0xFFFB8500), size: 20),
                  const SizedBox(width: 4),
                  Text('TOP BÁN CHẠY NHẤT', style: AppTypography.sectionTitle),
                ],
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.market),
                child: Text(
                  'XEM TẤT CẢ',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _productsController,
            padEnds: false,
            onPageChanged: (i) => setState(() => _productPage = i),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? AppSpacing.screenPadding : AppSpacing.xs,
                  right: AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FeaturedProductCard(
                    name: item.name,
                    price: item.price,
                    badgeIcon: item.badgeIcon,
                    badgeColor: item.badgeColor,
                    assetPath: item.assetPath,
                    imageUrl: item.imageUrl,
                    purchaseCount: item.purchaseCount,
                    soldQuantity: item.soldQuantity,
                    rank: item.rank,
                    onAdd: () {
                      final id = item.listingId;
                      if (id != null && id.isNotEmpty) {
                        context.push(AppRoutes.productOf(id));
                      } else {
                        context.push(AppRoutes.product);
                      }
                    },
                    onTap: () {
                      final id = item.listingId;
                      if (id != null && id.isNotEmpty) {
                        context.push(AppRoutes.productOf(id));
                      } else {
                        context.push(AppRoutes.product);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = i == _productPage;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.primary20,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool showSellerDashboard) {
    final auth = context.watch<AuthProvider>();
    final isAuthenticated = auth.isAuthenticated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOẠT ĐỘNG GẦN ĐÂY', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          if (!isAuthenticated)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary10,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đăng nhập tài khoản', style: AppTypography.itemTitle),
                        const SizedBox(height: 2),
                        Text(
                          'Đăng nhập để theo dõi lịch sử giao dịch và đơn hàng của bạn.',
                          style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  PressableScale(
                    onTap: () => context.push(AppRoutes.login),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Text(
                        'VÀO NAY',
                        style: AppTypography.chip.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const ActivityItem(
              icon: Icons.shopping_cart,
              iconBg: AppColors.primary10,
              iconColor: AppColors.primary,
              title: 'Mua Sỉ Tôm Thẻ',
              subtitle: '2 phút trước • Đơn hàng #7821',
              statusLabel: 'Hoàn thành',
              statusType: StatusChipType.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (showSellerDashboard)
              const ActivityItem(
                icon: Icons.account_balance_wallet,
                iconBg: AppColors.infoBg,
                iconColor: AppColors.infoText,
                title: 'Yêu cầu Rút tiền',
                subtitle: '1 giờ trước • TXN_99012',
                statusLabel: 'Chờ duyệt',
                statusType: StatusChipType.info,
              )
            else
              const ActivityItem(
                icon: Icons.local_shipping,
                iconBg: AppColors.infoBg,
                iconColor: AppColors.infoText,
                title: 'Đơn hàng đang giao',
                subtitle: '1 giờ trước • Đơn hàng #7830',
                statusLabel: 'Đang giao',
                statusType: StatusChipType.info,
              ),
            const SizedBox(height: AppSpacing.sm),
            const ActivityItem(
              icon: Icons.query_stats,
              iconBg: AppColors.neutralBg,
              iconColor: AppColors.textTertiary,
              title: 'Báo cáo Thị trường AI',
              subtitle: '3 giờ trước • Dự báo đã sẵn sàng',
              showChevron: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarketTrend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XU HƯỚNG THỊ TRƯỜNG', style: AppTypography.sectionTitle),
              Row(
                children: const [
                  StatusChip(label: 'Trực tiếp', type: StatusChipType.success),
                  SizedBox(width: AppSpacing.xs),
                  StatusChip(label: '24G', type: StatusChipType.neutral),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const MarketTrendChart(
            value: '1.284',
            delta: '↑ 3.2% so với tuần trước',
            bars: [0.36, 0.49, 0.40, 0.62, 0.53, 0.76, 0.67, 1.0],
            labels: ['T2', 'T4', 'T6', 'CN'],
          ),
        ],
      ),
    );
  }
}

class _FeaturedItem {
  const _FeaturedItem({
    required this.name,
    required this.price,
    required this.badgeIcon,
    required this.badgeColor,
    this.imageUrl,
    this.assetPath,
    this.listingId,
    this.purchaseCount = 0,
    this.soldQuantity = 0,
    this.rank,
  });

  final String name;
  final String price;
  final IconData badgeIcon;
  final Color badgeColor;
  final String? imageUrl;
  final String? assetPath;
  final String? listingId;
  final int purchaseCount;
  final int soldQuantity;
  final int? rank;
}
