import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/listing_model.dart';
import '../../data/models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../../widgets/status_chip.dart';
import '../auth/auth_navigation.dart';

import '../../data/models/wallet_model.dart';
import '../../providers/wallet_provider.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<AuthProvider>().isAuthenticated) return;
      _refreshAll();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && context.read<AuthProvider>().isAuthenticated) {
          _refreshAll();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    try {
      context.read<WalletProvider>().fetchPendingDeposits();
      context.read<ListingProvider>().fetchPendingListings();
      context.read<OrderProvider>().fetchAdminOrders();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(title: 'Quản trị Admin'),
        body: const AuthGateView(
          reason: LoginReasons.generic,
          from: AppRoutes.adminConsole,
          title: 'Đăng nhập với quyền Admin',
        ),
      );
    }

    final walletProvider = context.watch<WalletProvider>();
    final listingProvider = context.watch<ListingProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final pendingDeposits = walletProvider.pendingDeposits;
    final pendingListings = listingProvider.pendingListings;
    final allOrders = orderProvider.orders;
    final readyPayoutOrders = allOrders
        .where((o) =>
            o.status == OrderStatus.READY_TO_PAYOUT ||
            o.status == OrderStatus.AI_VERIFIED ||
            o.status == OrderStatus.DELIVERED)
        .toList();
    final disputeOrders =
        allOrders.where((o) => o.status == OrderStatus.DISPUTED).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text('Trung tâm Quản trị Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Nạp tiền'),
                    if (pendingDeposits.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _badgeCount(pendingDeposits.length, Colors.orange[900]!),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Bài đăng'),
                    if (pendingListings.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _badgeCount(pendingListings.length, Colors.amber[900]!),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Duyệt chi'),
                    if (readyPayoutOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _badgeCount(readyPayoutOrders.length, Colors.green[800]!),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tranh chấp'),
                    if (disputeOrders.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _badgeCount(disputeOrders.length, Colors.red[800]!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshAll,
          child: TabBarView(
            children: [
              _buildPendingDepositsTab(walletProvider, pendingDeposits),
              _buildPendingListingsTab(listingProvider, pendingListings),
              _buildReadyPayoutTab(orderProvider, readyPayoutOrders),
              _buildDisputesTab(orderProvider, disputeOrders),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeCount(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // --- TAB 1: PENDING DEPOSITS ---
  Widget _buildPendingDepositsTab(WalletProvider provider, List<TransactionModel> deposits) {
    if (deposits.isEmpty) {
      return _emptyState('Không có yêu cầu nạp tiền nào', 'Tất cả lệnh nạp tiền từ người dùng đều đã được duyệt.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: deposits.length,
      itemBuilder: (ctx, i) => _depositCard(provider, deposits[i]),
    );
  }

  Widget _depositCard(WalletProvider provider, TransactionModel deposit) {
    final methodStr = deposit.paymentMethod != null ? deposit.paymentMethod!.name : 'BANK_TRANSFER';
    final userLabel = deposit.userName != null && deposit.userName!.isNotEmpty
        ? deposit.userName!
        : (deposit.userEmail ?? 'Người dùng');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nạp ví #${deposit.id.length >= 8 ? deposit.id.substring(0, 8).toUpperCase() : deposit.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const StatusChip(label: 'CHỜ DUYỆT NẠP', type: StatusChipType.info),
              ],
            ),
            const SizedBox(height: 4),
            Text('Khách hàng: $userLabel ${deposit.userEmail != null ? "(${deposit.userEmail})" : ""}'),
            Text('Phương thức: $methodStr'),
            Text(
              'Số tiền nạp: ₫${NumberFormat("#,###").format(deposit.amount)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final success = await provider.rejectDeposit(deposit.id);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã từ chối lệnh nạp tiền!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final success = await provider.approveDeposit(deposit.id);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã duyệt nạp tiền thành công! Tiền đã cộng vào ví người dùng.'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Duyệt nạp tiền'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: PENDING LISTINGS ---
  Widget _buildPendingListingsTab(ListingProvider provider, List<ListingModel> pendingListings) {
    if (pendingListings.isEmpty) {
      return _emptyState('Không có bài đăng nào chờ duyệt', 'Tất cả nông sản từ chủ đầm đều đã được xử lý.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: pendingListings.length,
      itemBuilder: (ctx, i) => _listingCard(provider, pendingListings[i]),
    );
  }

  Widget _listingCard(ListingProvider provider, ListingModel listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const StatusChip(label: 'CHỜ DUYỆT', type: StatusChipType.info),
              ],
            ),
            const SizedBox(height: 4),
            Text('Chủ đầm: ${listing.sellerName} | Nguồn: ${listing.province}'),
            Text(
              'Đơn giá: ₫${NumberFormat("#,###").format(listing.pricePerFish)} /con • Sản lượng: ${listing.estimatedQuantity} con',
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final success = await provider.approveOrRejectListing(listing.id, false, note: 'Từ chối bởi Admin');
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã từ chối tin đăng!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () async {
                    final success = await provider.approveOrRejectListing(listing.id, true, note: 'Duyệt bởi Admin');
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã duyệt tin đăng thành công! Tin đăng hiện đã lên Chợ.'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Duyệt lên Chợ'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: READY TO PAYOUT ---
  Widget _buildReadyPayoutTab(OrderProvider provider, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return _emptyState('Không có đơn nào chờ giải ngân', 'Khi Người mua bấm nhận đủ hàng, đơn sẽ xuất hiện tại đây.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _payoutOrderCard(provider, orders[i]),
    );
  }

  Widget _payoutOrderCard(OrderProvider provider, OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.listingTitle.isNotEmpty ? order.listingTitle : 'Đơn #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const StatusChip(label: 'CHỜ DUYỆT CHI', type: StatusChipType.success),
              ],
            ),
            const SizedBox(height: 4),
            Text('Người mua: ${order.buyerName} | Người bán: ${order.sellerName}'),
            Text(
              'Số lượng cá chốt: ${order.finalQuantity} con • Tổng Escrow: ₫${NumberFormat("#,###").format(order.totalPrice)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => _confirmApprovePayoutDialog(provider, order),
                  icon: const Icon(Icons.account_balance_wallet, size: 16),
                  label: const Text('Xác nhận Giải ngân Escrow'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmApprovePayoutDialog(OrderProvider provider, OrderModel order) async {
    final unitPrice = order.unitPriceAtPurchase;
    final sellerAmount = unitPrice * order.finalQuantity;
    const platformFee = 25000;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Giải ngân Escrow'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã đơn: #${(order.id.length >= 8 ? order.id.substring(0, 8) : order.id).toUpperCase()}'),
            const SizedBox(height: 8),
            Text('• Chuyển Ví Người bán (${order.sellerName}): ₫${NumberFormat("#,###").format(sellerAmount)}'),
            Text('• Phí Nền tảng (Phí AI): ₫${NumberFormat("#,###").format(platformFee)}'),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Hành động giải ngân này không thể hoàn tác. Bạn chắc chắn muốn chuyển tiền?',
              style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: const Text('Đồng ý giải ngân', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.approvePayout(order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã giải ngân tiền Escrow cho Người bán thành công!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi giải ngân: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- TAB 3: DISPUTES ---
  Widget _buildDisputesTab(OrderProvider provider, List<OrderModel> orders) {
    if (orders.isEmpty) {
      return _emptyState('Không có khiếu nại nào', 'Hệ thống AI hai chiều hoạt động minh bạch, chưa có đơn tranh chấp.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (ctx, i) => _disputeCard(orders[i]),
    );
  }

  Widget _disputeCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        title: Text('Khiếu nại Đơn #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        subtitle: Text('Sản phẩm: ${order.listingTitle}\nNgười mua: ${order.buyerName}'),
        trailing: const StatusChip(label: 'TRANH CHẤP', type: StatusChipType.errorSoft),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[600]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

