import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';

/// Màn Nạp tiền vào ví.
/// Wire: `POST /users/me/wallet/deposit` — DEMO: BE cộng số dư ngay (không chờ Admin).
class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  static const _presets = [
    (500000, '500k'),
    (1000000, '1M'),
    (2000000, '2M'),
    (5000000, '5M'),
    (10000000, '10M'),
  ];

  int _amount = 1000000;
  int _method = 0; // 0 BANK_TRANSFER, 1 VNPAY (QR), 2 MOMO
  bool _submitting = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(_amount));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<WalletProvider>().fetchWallet();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }

  int _parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _setAmount(int v) {
    setState(() {
      _amount = v;
      _ctrl.text = _format(v);
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  PaymentMethod get _beMethod {
    switch (_method) {
      case 1:
        return PaymentMethod.VNPAY;
      case 2:
        return PaymentMethod.MOMO;
      case 0:
      default:
        return PaymentMethod.BANK_TRANSFER;
    }
  }

  String get _methodLabel {
    switch (_method) {
      case 1:
        return 'Quét mã QR';
      case 2:
        return 'Ví điện tử';
      default:
        return 'Chuyển khoản';
    }
  }

  Future<void> _submit() async {
    if (_amount <= 0 || _submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<WalletProvider>().deposit(
            amount: _amount.toDouble(),
            paymentMethod: _beMethod.name,
          );
      if (!mounted) return;
      // Refresh số dư trước khi sang màn success.
      await context.read<WalletProvider>().fetchWallet();
      if (!mounted) return;
      context.push(
        '${AppRoutes.walletTopupSuccess}'
        '?amount=${Uri.encodeComponent(_format(_amount))}'
        '&method=${Uri.encodeComponent(_methodLabel)}'
        '&pending=1',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Nạp tiền vào ví',
          centerTitle: true,
        ),
        body: const AuthGateView(
          reason: LoginReasons.wallet,
          from: AppRoutes.walletTopup,
          title: 'Đăng nhập để nạp tiền',
        ),
      );
    }

    final balance = context.watch<WalletProvider>().wallet?.balance;
    final balanceText = balance != null
        ? AppFormatters.formatNumber(balance.round())
        : '0';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Nạp tiền vào ví',
        centerTitle: true,
        trailing: PressableScale(
          onTap: () {},
          child: const SizedBox(
            width: 48,
            child: Icon(Icons.history, size: 22, color: AppColors.primary),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
          child: AppButton(
            label: _submitting ? 'Đang gửi...' : 'Xác nhận nạp tiền',
            uppercase: true,
            onPressed: (_amount > 0 && !_submitting) ? _submit : null,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        children: [
          _balanceBanner(balanceText),
          const SizedBox(height: AppSpacing.lg),
          Text('Số tiền cần nạp',
              style: AppTypography.itemTitle.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.xxs),
          Text('Hạn mức: 500.000.000đ',
              style: AppTypography.caption.copyWith(fontSize: 11)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.heading.copyWith(fontSize: 30),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixText: 'VND',
                suffixStyle: AppTypography.body
                    .copyWith(color: AppColors.textSecondary),
              ),
              onChanged: (v) => setState(() => _amount = _parse(v)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in _presets) ...[
                  _presetChip(p.$1, p.$2),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Phương thức thanh toán',
              style: AppTypography.itemTitle.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          _bankMethod(),
          const SizedBox(height: AppSpacing.sm),
          _simpleMethod(
            index: 1,
            icon: Icons.qr_code_2,
            title: 'Quét mã QR (VietQR)',
            subtitle: 'Thanh toán qua ứng dụng ngân hàng',
          ),
          const SizedBox(height: AppSpacing.sm),
          _simpleMethod(
            index: 2,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Ví điện tử',
            subtitle: 'Momo, ZaloPay',
          ),
          const SizedBox(height: AppSpacing.md),
          _infoNote(),
        ],
      ),
    );
  }

  Widget _balanceBanner(String balanceText) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bannerDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SỐ DƯ HIỆN TẠI',
              style: AppTypography.chip.copyWith(
                letterSpacing: 1.2,
                color: AppColors.primary.withValues(alpha: 0.8),
              )),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(balanceText,
                  style: AppTypography.heading
                      .copyWith(fontSize: 28, color: AppColors.onDark)),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('VND',
                    style: AppTypography.body.copyWith(
                        color: AppColors.onDark.withValues(alpha: 0.6))),
              ),
              const Spacer(),
              Row(
                children: [
                  const PulseDot(size: 8, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('AI Verified Wallet',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int value, String label) {
    final selected = _amount == value;
    return PressableScale(
      onTap: () => _setAmount(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary10 : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: selected ? Border.all(color: AppColors.primary20) : null,
        ),
        child: Text(
          label,
          style: AppTypography.chip.copyWith(
            fontSize: 12,
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _bankMethod() {
    final selected = _method == 0;
    return PressableScale(
      onTap: () => setState(() => _method = 0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderFaint,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.account_balance,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chuyển khoản ngân hàng',
                          style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                      Text('Chờ Admin duyệt (theo BE)',
                          style: AppTypography.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                _radio(selected),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.borderFaint),
              const SizedBox(height: AppSpacing.sm),
              _copyRow('Số tài khoản:', '0987654321'),
              _copyRow('Ngân hàng:', 'Techcombank', copyable: false),
              _copyRow('Nội dung:', 'AQ NAPTIEN'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _simpleMethod({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _method == index;
    return PressableScale(
      onTap: () => setState(() => _method = index),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderFaint,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                  Text(subtitle,
                      style: AppTypography.caption.copyWith(fontSize: 11)),
                ],
              ),
            ),
            _radio(selected),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.primary20,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _copyRow(String label, String value, {bool copyable = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(label, style: AppTypography.caption.copyWith(fontSize: 12)),
          const Spacer(),
          Text(value, style: AppTypography.itemTitle.copyWith(fontSize: 13)),
          if (copyable) ...[
            const SizedBox(width: AppSpacing.xxs),
            PressableScale(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép')),
                );
              },
              child: const Icon(Icons.content_copy,
                  size: 14, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoNote() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary05,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'BE tạo yêu cầu nạp ở trạng thái CHỜ DUYỆT — số dư chỉ tăng sau khi Admin duyệt. Không cộng tiền tức thì.',
              style:
                  AppTypography.caption.copyWith(fontSize: 12, height: 18 / 12),
            ),
          ),
        ],
      ),
    );
  }
}
