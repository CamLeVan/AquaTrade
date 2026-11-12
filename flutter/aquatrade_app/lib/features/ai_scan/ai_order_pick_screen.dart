import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../../widgets/empty_state.dart';
import '../auth/auth_navigation.dart';
import '../orders/widgets/order_history_card.dart';
import 'ai_scan_eligibility.dart';

/// Danh sách đơn đủ điều kiện quét AI xác nhận.
class AiOrderPickScreen extends StatefulWidget {
  const AiOrderPickScreen({super.key});

  @override
  State<AiOrderPickScreen> createState() => _AiOrderPickScreenState();
}

class _AiOrderPickScreenState extends State<AiOrderPickScreen> {
  List<OrderModel> _eligible = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = context.read<RoleProvider>();
      final orders = await context.read<OrderProvider>().fetchOrdersForAiScan(
            includeSellerOrders: role.canSell,
          );
      final userId = auth.currentUser?.id ?? '';
      if (!mounted) return;
      setState(() {
        _eligible = filterAiEligibleOrders(orders: orders, userId: userId);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Chọn đơn hàng',
          centerTitle: true,
        ),
        body: const AuthGateView(
          reason: LoginReasons.ai,
          from: AppRoutes.aiScanOrders,
          title: 'Đăng nhập để quét AI',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar.subPage(
        title: 'Chọn đơn hàng',
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          EmptyState(
            icon: Icons.error_outline,
            title: 'Không tải được đơn',
            message: _error!,
            art: EmptyStateArt.card,
            child: AppButton(
              label: 'Thử lại',
              onPressed: _load,
            ),
          ),
        ],
      );
    }

    if (_eligible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const SizedBox(height: AppSpacing.xl),
          EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Bạn chưa có đơn hàng nào cần quét AI xác nhận',
            message:
                'Đơn đủ điều kiện gồm trạng thái đang chuẩn bị / ký quỹ / đang đếm AI. '
                'Đặt hàng từ Chợ hoặc mở Lịch sử đơn để theo dõi.',
            art: EmptyStateArt.card,
            child: Column(
              children: [
                AppButton(
                  label: 'Đến Chợ',
                  onPressed: () => context.go(AppRoutes.market),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Lịch sử đơn hàng',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(AppRoutes.orders),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final userId = context.read<AuthProvider>().currentUser?.id ?? '';

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      itemCount: _eligible.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            '${_eligible.length} đơn có thể quét xác nhận',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          );
        }
        final order = _eligible[index - 1];
        final role = proofRoleForUser(order, userId);
        final counted = role == 'SELLER'
            ? (order.sellerAiTotalCount > 0
                ? order.sellerAiTotalCount
                : sumSuccessfulCounts(order, role))
            : (order.buyerAiTotalCount > 0
                ? order.buyerAiTotalCount
                : sumSuccessfulCounts(order, role));
        final expected = expectedQuantity(order);

        return PressableScale(
          onTap: () => context.push(AppRoutes.aiScanOrderPath(order.id)),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderFaint),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.listingTitle.isNotEmpty
                            ? order.listingTitle
                            : 'Đơn AquaTrade',
                        style: AppTypography.itemTitle.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      order.status.historyLabel,
                      style: AppTypography.chip.copyWith(
                        color: AppColors.onPrimaryDeep,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  role == 'SELLER'
                      ? 'Vai trò: Người bán · KH: ${order.buyerName}'
                      : 'Vai trò: Người mua · Shop: ${order.sellerName}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI: $counted / $expected con · '
                  '${AppFormatters.formatCurrency(order.totalPrice)}',
                  style: AppTypography.body.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
