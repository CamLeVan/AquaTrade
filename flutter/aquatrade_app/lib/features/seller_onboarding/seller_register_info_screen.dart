import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import 'widgets/onboarding_stepper.dart';

/// Bước 1 luồng đăng ký người bán: thông tin gian hàng + tài khoản nhận tiền.
class SellerRegisterInfoScreen extends StatefulWidget {
  const SellerRegisterInfoScreen({super.key});

  @override
  State<SellerRegisterInfoScreen> createState() =>
      _SellerRegisterInfoScreenState();
}

class _SellerRegisterInfoScreenState extends State<SellerRegisterInfoScreen> {
  int _bizType = 1; // 0 Cá nhân, 1 Hộ kinh doanh, 2 Doanh nghiệp
  final Set<String> _categories = {'Cá'};

  static const _bizOptions = [
    (Icons.person_outline, 'Cá nhân'),
    (Icons.storefront_outlined, 'Hộ kinh doanh'),
    (Icons.apartment, 'Doanh nghiệp'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(title: 'Đăng ký người bán'),
        body: const AuthGateView(
          reason: LoginReasons.seller,
          from: AppRoutes.sellerRegisterInfo,
          title: 'Đăng nhập để đăng ký bán',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.subPage(title: 'Đăng ký người bán'),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 61 + AppSpacing.lg,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        children: [
          const OnboardingStepper(
            steps: ['Thông tin', 'Xác thực', 'Hoàn tất'],
            currentStep: 0,
          ),
          const SizedBox(height: AppSpacing.xl),
          _shopInfoCard(),
          const SizedBox(height: AppSpacing.lg),
          _bankCard(),
        ],
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  Widget _shopInfoCard() {
    return AppCard(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bước 1: Thông tin gian hàng',
              style: AppTypography.cardValue.copyWith(
                  fontSize: 18, height: 28 / 18, letterSpacing: -0.45)),
          const SizedBox(height: AppSpacing.xxs),
          Text('Vui lòng cung cấp thông tin cơ bản về gian hàng của bạn.',
              style: AppTypography.body),
          const SizedBox(height: AppSpacing.lg),
          const AppTextField(
            label: 'Tên gian hàng',
            hint: 'Nhập tên gian hàng công khai',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('LOẠI HÌNH KINH DOANH', style: _fieldLabel),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < _bizOptions.length; i++) ...[
            _BizTypeRow(
              icon: _bizOptions[i].$1,
              label: _bizOptions[i].$2,
              selected: _bizType == i,
              onTap: () => setState(() => _bizType = i),
            ),
            if (i != _bizOptions.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('DANH MỤC SẢN PHẨM CHÍNH', style: _fieldLabel),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final c in const ['Tôm', 'Cá', 'Cua']) ...[
                _CategoryChip(
                  label: c,
                  selected: _categories.contains(c),
                  onTap: () => setState(() {
                    _categories.contains(c)
                        ? _categories.remove(c)
                        : _categories.add(c);
                  }),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppTextField(
            label: 'Địa chỉ kho/vựa',
            hint: 'Nhập địa chỉ lấy hàng',
            leadingIcon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _bankCard() {
    return AppCard(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin ngân hàng nhận tiền',
              style: AppTypography.cardValue.copyWith(
                  fontSize: 18, height: 28 / 18, letterSpacing: -0.45)),
          const SizedBox(height: AppSpacing.xxs),
          Text('Cung cấp tài khoản để AquaTrade thanh toán doanh thu cho bạn.',
              style: AppTypography.body),
          const SizedBox(height: AppSpacing.lg),
          const AppTextField(
            label: 'Tên ngân hàng',
            hint: 'Chọn ngân hàng',
            readOnly: true,
            trailing: Icon(Icons.keyboard_arrow_down,
                size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Số tài khoản',
            hint: 'Nhập số tài khoản',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Tên chủ tài khoản',
            initialValue: 'VIET THE NGUYEN',
            uppercaseValue: true,
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.borderFaint)),
      ),
      child: AppButton(
        label: 'Tiếp tục xác thực',
        icon: Icons.arrow_forward,
        onPressed: () {
          context.push(AppRoutes.sellerRegisterVerify);
        },
      ),
    );
  }

  static final TextStyle _fieldLabel = AppTypography.chip.copyWith(
    fontSize: 11,
    letterSpacing: 1.1,
    height: 16.5 / 11,
    color: AppColors.textSecondary,
  );
}

class _BizTypeRow extends StatelessWidget {
  const _BizTypeRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary10 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderFaint,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 17, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderFaint),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.primary20,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: AppColors.onPrimary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppTypography.itemTitle.copyWith(
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
