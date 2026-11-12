import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';

/// Màn Rút tiền — Seller only.
/// BE chưa có withdraw API → nút xác nhận chỉ hiện snackbar "Chưa hỗ trợ".
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  static const _available = 10000000;
  int _amount = 5000000;
  bool _isSubmitting = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(_amount));
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
    final clamped = v.clamp(0, _available);
    setState(() {
      _amount = clamped;
      _ctrl.text = _format(clamped);
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Rút tiền',
          centerTitle: true,
        ),
        body: const AuthGateView(
          reason: LoginReasons.wallet,
          from: AppRoutes.walletWithdraw,
          title: 'Đăng nhập để rút tiền',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Rút tiền',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Bảo mật bởi AI Guard',
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.onPrimaryDeep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: _isSubmitting ? 'Đang xử lý...' : 'Xác nhận rút tiền',
                uppercase: true,
                onPressed: (_amount > 0 && !_isSubmitting)
                    ? () async {
                        setState(() => _isSubmitting = true);
                        await Future.delayed(const Duration(milliseconds: 1500));
                        if (!mounted) return;
                        setState(() => _isSubmitting = false);
                        context.push(
                          '${AppRoutes.walletWithdrawSuccess}?amount=${_format(_amount)}',
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        children: [
          _balanceCard(),
          const SizedBox(height: AppSpacing.sm),
          _escrowBox(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'TÀI KHOẢN THỤ HƯỞNG',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 1.1,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _bankCard(),
          const SizedBox(height: AppSpacing.sm),
          PressableScale(
            onTap: () {},
            child: Row(
              children: [
                const Icon(Icons.add_circle, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'THÊM TÀI KHOẢN MỚI',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 0.8,
                    color: AppColors.onPrimaryDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'SỐ TIỀN MUỐN RÚT',
            style: AppTypography.overline.copyWith(
              fontSize: 11,
              letterSpacing: 1.1,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _amountField(),
          const SizedBox(height: AppSpacing.md),
          _feeCard(),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primary10,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SỐ DƯ KHẢ DỤNG',
                style: AppTypography.chip.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _format(_available),
                    style: AppTypography.heading.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'VND',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _escrowBox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'SỐ DƯ ĐANG TẠM GIỮ (ESCROW)',
                  style: AppTypography.chip.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '2.500.000 VND',
                style: AppTypography.itemTitle.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tiền từ đơn hàng chưa hoàn tất, sẽ được giải ngân sau khi khách xác nhận nhận hàng.',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
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
                size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vietcombank',
                    style: AppTypography.itemTitle.copyWith(fontSize: 14)),
                Text('**** 8899',
                    style: AppTypography.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }

  Widget _amountField() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.heading.copyWith(fontSize: 24),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _amount = _parse(v)),
            ),
          ),
          PressableScale(
            onTap: () => _setAmount(_available),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary10,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'RÚT TỐI ĐA',
                style: AppTypography.chip.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: AppColors.onPrimaryDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        children: [
          _feeRow(
            'Phí rút tiền',
            Text(
              'MIỄN PHÍ',
              style: AppTypography.chip.copyWith(
                letterSpacing: 0.8,
                color: AppColors.onPrimaryDeep,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _feeRow(
            'Thời gian xử lý',
            Text('24 - 48h',
                style: AppTypography.itemTitle.copyWith(fontSize: 14)),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderFaint),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Số tiền thực nhận',
                  style: AppTypography.itemTitle.copyWith(fontSize: 14)),
              const Spacer(),
              Text(
                _format(_amount),
                style: AppTypography.heading.copyWith(fontSize: 20),
              ),
              const SizedBox(width: 4),
              Text(
                'VND',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, Widget trailing) {
    return Row(
      children: [
        Text(label,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
        const Spacer(),
        trailing,
      ],
    );
  }
}
