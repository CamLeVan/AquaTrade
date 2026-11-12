import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared_providers/role_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import 'widgets/onboarding_stepper.dart';

/// Bước 3 luồng đăng ký người bán: xác nhận điều khoản & gửi hồ sơ.
class SellerRegisterTermsScreen extends StatefulWidget {
  const SellerRegisterTermsScreen({super.key});

  @override
  State<SellerRegisterTermsScreen> createState() =>
      _SellerRegisterTermsScreenState();
}

class _SellerRegisterTermsScreenState extends State<SellerRegisterTermsScreen> {
  bool _agreed = false;

  static const _terms = [
    ('Tính chính xác:',
        ' Mọi thông tin cung cấp về sản phẩm và nguồn gốc thủy hải sản phải được xác thực qua hệ thống AquaTrack.'),
    ('Cam kết bền vững:',
        ' Người bán không được phép giao dịch các loài nằm trong danh mục cấm hoặc khai thác trái phép.'),
    ('Bảo mật:',
        ' Tuyệt đối bảo mật thông tin khách hàng và dữ liệu thị trường được cung cấp riêng tư qua bảng điều khiển.'),
    ('Phí dịch vụ:',
        ' Mức phí duy trì gian hàng và hoa hồng giao dịch sẽ được tự động khấu trừ theo biểu phí hiện hành của AquaTrade AI.'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(title: 'Cam kết & Hoàn tất'),
        body: const AuthGateView(
          reason: LoginReasons.seller,
          from: AppRoutes.sellerRegisterTerms,
          title: 'Đăng nhập để đăng ký bán',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.subPage(title: 'Cam kết & Hoàn tất'),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 61 + AppSpacing.xl,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xl,
        ),
        children: [
          const OnboardingStepper(
            steps: ['Hồ sơ', 'Xác thực', 'Cam kết'],
            currentStep: 2,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xác nhận thỏa thuận',
                    style: AppTypography.heading
                        .copyWith(fontSize: 24, height: 32 / 24)),
                const SizedBox(height: AppSpacing.lg),
                _termsBox(),
                const SizedBox(height: AppSpacing.lg),
                _acceptanceRow(),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Gửi đăng ký',
                  variant: AppButtonVariant.softTeal,
                  icon: Icons.send,
                  onPressed: _agreed ? () => _submit(context) : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Quay lại',
                  variant: AppButtonVariant.ghost,
                  leadingIcon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsBox() {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Điều khoản dành cho Người bán của AquaTrade AI',
                style: AppTypography.itemTitle
                    .copyWith(fontSize: 14, height: 20 / 14)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Bằng việc đăng ký tài khoản người bán, bạn cam kết tuân thủ các quy chuẩn '
              'về chất lượng hàng hóa và bảo mật dữ liệu giao dịch do hệ thống AI quản lý.',
              style: AppTypography.body.copyWith(height: 22.75 / 14),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _terms.length; i++) ...[
              RichText(
                text: TextSpan(
                  style: AppTypography.body.copyWith(height: 22.75 / 14),
                  children: [
                    TextSpan(text: '${i + 1}. '),
                    TextSpan(
                      text: _terms[i].$1,
                      style: AppTypography.body.copyWith(
                        height: 22.75 / 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(text: _terms[i].$2),
                  ],
                ),
              ),
              if (i != _terms.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _acceptanceRow() {
    return InkWell(
      onTap: () => setState(() => _agreed = !_agreed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _agreed ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: _agreed ? AppColors.primary : AppColors.primary20,
              ),
            ),
            child: _agreed
                ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.body.copyWith(height: 19.25 / 14),
                children: [
                  const TextSpan(text: 'Tôi đồng ý với '),
                  TextSpan(
                    text: 'Điều khoản dành cho Người bán',
                    style: AppTypography.body.copyWith(
                      height: 19.25 / 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const TextSpan(
                      text:
                          ' của AquaTrade AI và cam kết cung cấp thông tin trung thực.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
    // Chỉ đổi SellerStatus → pending, KHÔNG động vào UserRole (2 khái niệm tách biệt).
    context.read<RoleProvider>().submitSellerApplication();
    context.go(AppRoutes.market);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi hồ sơ — hồ sơ của bạn đang chờ duyệt.'),
      ),
    );
  }
}
