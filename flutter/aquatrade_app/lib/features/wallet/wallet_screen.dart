import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import 'widgets/transaction_tile.dart';

/// Màn Ví AquaTrade (Stitch: Ví AquaTrade).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<WalletProvider>().fetchWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Ví AquaTrade',
          centerTitle: true,
        ),
        body: const AuthGateView(
          reason: LoginReasons.wallet,
          from: AppRoutes.wallet,
          title: 'Đăng nhập để dùng ví',
        ),
      );
    }

    final canSell = context.watch<RoleProvider>().canSell;
    final walletProvider = context.watch<WalletProvider>();
    final balance = walletProvider.wallet?.balance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Ví AquaTrade',
        centerTitle: true,
        trailing: PressableScale(
          onTap: () {},
          child: const SizedBox(
            width: 48,
            child: Icon(Icons.share_outlined,
                size: 20, color: AppColors.primary),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<WalletProvider>().fetchWallet(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          children: [
            _balanceCard(canSell, balance.toDouble()),
          const SizedBox(height: AppSpacing.lg),
          _statRow(),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text('Giao dịch gần đây',
                  style: AppTypography.cardValue.copyWith(fontSize: 20)),
              const Spacer(),
              PressableScale(
                onTap: () {},
                child: Text(
                  'TẤT CẢ',
                  style: AppTypography.chip.copyWith(
                      letterSpacing: 1.2, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._transactionTiles(walletProvider),
          const SizedBox(height: AppSpacing.lg),
          _referralBanner(),
        ],
      ),
    ),
  );
}

  List<Widget> _transactionTiles(WalletProvider walletProvider) {
    final txs = walletProvider.wallet?.recentTransactions ?? const <TransactionModel>[];
    if (walletProvider.isLoading && txs.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (txs.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Chưa có giao dịch nào',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ];
    }
    return [
      for (final tx in txs) _tileFromTx(tx),
    ];
  }

  Widget _tileFromTx(TransactionModel tx) {
    final credit = _isCredit(tx.type);
    final amountAbs = AppFormatters.formatNumber(tx.amount.abs());
    final amountLabel = '${credit ? '+' : '-'}$amountAbsđ';
    return TransactionTile(
      title: _txTitle(tx),
      timeLabel: AppFormatters.formatDate(tx.createdAt),
      amountLabel: amountLabel,
      isCredit: credit,
      statusLabel: _txStatusLabel(tx.status),
      statusProcessing: tx.status == TransactionStatus.PENDING,
      icon: credit ? Icons.south_west : Icons.north_east,
    );
  }

  bool _isCredit(TransactionType type) {
    switch (type) {
      case TransactionType.TOP_UP:
      case TransactionType.REFUND:
      case TransactionType.ESCROW_RELEASE:
      case TransactionType.ORDER_PAYOUT:
      case TransactionType.SELL_PAYOUT:
      case TransactionType.DISPUTE_REFUND:
        return true;
      case TransactionType.ESCROW_LOCK:
      case TransactionType.WITHDRAW:
      case TransactionType.PLATFORM_COMMISSION:
      case TransactionType.CANCELLED:
        return false;
    }
  }

  String _txTitle(TransactionModel tx) {
    switch (tx.type) {
      case TransactionType.TOP_UP:
        return 'Nạp tiền';
      case TransactionType.WITHDRAW:
        return 'Rút tiền';
      case TransactionType.ESCROW_LOCK:
        return tx.orderId != null && tx.orderId!.isNotEmpty
            ? 'Khoá escrow đơn #${tx.orderId!.substring(0, tx.orderId!.length.clamp(0, 8))}'
            : 'Khoá escrow';
      case TransactionType.ESCROW_RELEASE:
        return 'Giải phóng escrow';
      case TransactionType.REFUND:
      case TransactionType.DISPUTE_REFUND:
        return 'Hoàn tiền';
      case TransactionType.ORDER_PAYOUT:
      case TransactionType.SELL_PAYOUT:
        return 'Thanh toán đơn bán';
      case TransactionType.PLATFORM_COMMISSION:
        return 'Phí nền tảng';
      case TransactionType.CANCELLED:
        return 'Giao dịch đã huỷ';
    }
  }

  String _txStatusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.SUCCESS:
        return 'Hoàn thành';
      case TransactionStatus.PENDING:
        return 'Đang xử lý';
      case TransactionStatus.FAILED:
        return 'Thất bại';
    }
  }

  Widget _balanceCard(bool canSell, double balance) {
    final balanceStr = NumberFormat("#,###", "vi_VN").format(balance);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bannerDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -48,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: AppColors.primary20,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TỔNG SỐ DƯ KHẢ DỤNG',
                style: AppTypography.chip.copyWith(
                  letterSpacing: 1.5,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PressableScale(
                onTap: () => setState(() => _hidden = !_hidden),
                child: Row(
                  children: [
                    Text(
                      _hidden ? '••••••••' : balanceStr,
                      style: AppTypography.heading.copyWith(
                        fontSize: 26,
                        color: AppColors.onDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'VND',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onDark.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      _hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.onDark.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _darkBtn(
                      label: 'Nạp tiền',
                      icon: Icons.add_circle,
                      primary: true,
                      onTap: () => context.push(AppRoutes.walletTopup),
                    ),
                  ),
                  if (canSell) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _darkBtn(
                        label: 'Rút tiền',
                        icon: Icons.account_balance_wallet_outlined,
                        primary: false,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Rút tiền chưa được hỗ trợ. Vui lòng thử lại sau.',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _darkBtn({
    required String label,
    required IconData icon,
    required bool primary,
    VoidCallback? onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.onDark.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: primary
              ? null
              : Border.all(color: AppColors.onDark.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: primary ? AppColors.onPrimary : AppColors.onDark),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.itemTitle.copyWith(
                fontSize: 14,
                color: primary ? AppColors.onPrimary : AppColors.onDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow() {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            icon: Icons.trending_up,
            iconColor: AppColors.primary,
            badge: '+4.2%',
            label: 'Lợi nhuận',
            value: '520.000đ',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _miniStat(
            icon: Icons.verified_user_outlined,
            iconColor: AppColors.tertiary,
            pulse: true,
            label: 'Bảo mật AI',
            value: 'Đã bật',
          ),
        ),
      ],
    );
  }

  Widget _miniStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? badge,
    bool pulse = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge,
                      style: AppTypography.chip
                          .copyWith(color: AppColors.primary)),
                ),
              if (pulse) const PulseDot(size: 8, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label.toUpperCase(),
              style: AppTypography.overline.copyWith(fontSize: 11)),
          Text(value,
              style: AppTypography.itemTitle
                  .copyWith(fontSize: 18, height: 28 / 18)),
        ],
      ),
    );
  }

  Widget _referralBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary05,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary10,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard,
                size: 28, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Giới thiệu bạn bè',
                    style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                Text(
                  'Nhận ngay 50.000đ khi mời thành công thành viên mới.',
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1)),
              ],
            ),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
