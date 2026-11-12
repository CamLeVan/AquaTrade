import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../../widgets/segmented_control.dart';
import '../auth/auth_navigation.dart';
import 'widgets/onboarding_stepper.dart';
import 'widgets/upload_box.dart';

/// Bước 2 luồng đăng ký người bán: xác thực giấy tờ (Cá nhân / Doanh nghiệp).
class SellerRegisterVerifyScreen extends StatefulWidget {
  const SellerRegisterVerifyScreen({super.key});

  @override
  State<SellerRegisterVerifyScreen> createState() =>
      _SellerRegisterVerifyScreenState();
}

class _SellerRegisterVerifyScreenState
    extends State<SellerRegisterVerifyScreen> {
  int _identityType = 0; // 0 Cá nhân, 1 Doanh nghiệp

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(title: 'Xác thực'),
        body: const AuthGateView(
          reason: LoginReasons.seller,
          from: AppRoutes.sellerRegisterVerify,
          title: 'Đăng nhập để đăng ký bán',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.subPage(title: 'Xác thực'),
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
            currentStep: 1,
            circleSize: 32,
          ),
          const SizedBox(height: AppSpacing.xl),
          SegmentedControl(
            labels: const ['Cá nhân', 'Doanh nghiệp'],
            selectedIndex: _identityType,
            style: SegmentedStyle.card,
            onChanged: (i) => setState(() => _identityType = i),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_identityType == 0) ..._individualDocs() else ..._businessDocs(),
        ],
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  List<Widget> _individualDocs() {
    return [
      Text('Giấy tờ tùy thân',
          style: AppTypography.cardValue.copyWith(letterSpacing: -0.5)),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        'Hình ảnh cần rõ nét, không bị lóa sáng để camera có thể nhận diện chính xác nhất.',
        style: AppTypography.body.copyWith(height: 22.75 / 14),
      ),
      const SizedBox(height: AppSpacing.md),
      const UploadBox(
        title: 'Mặt trước CCCD',
        subtitle: 'PNG, JPG tối đa 5MB',
      ),
      const SizedBox(height: AppSpacing.md),
      const UploadBox(
        title: 'Mặt sau CCCD',
        subtitle: 'PNG, JPG tối đa 5MB',
      ),
      const SizedBox(height: AppSpacing.md),
      _guidanceCard(),
    ];
  }

  List<Widget> _businessDocs() {
    return [
      Text('Pháp nhân kinh doanh',
          style: AppTypography.cardValue.copyWith(letterSpacing: -0.5)),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        'Vui lòng đính kèm bản quét màu của giấy phép đăng ký kinh doanh còn hiệu lực.',
        style: AppTypography.body.copyWith(height: 22.75 / 14),
      ),
      const SizedBox(height: AppSpacing.md),
      const UploadBox(
        title: 'GIẤY PHÉP KINH DOANH',
        subtitle: 'Kéo thả hoặc nhấp để chọn tệp tin',
        actionLabel: 'Tải lên tệp PDF/Image',
        height: 220,
      ),
    ];
  }

  Widget _guidanceCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primary05,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lưu ý về tính hợp lệ',
                    style: AppTypography.itemTitle
                        .copyWith(fontSize: 13, height: 19.5 / 13)),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Hệ thống sẽ tự động từ chối các hình ảnh bị mờ, lóa sáng hoặc mất góc. '
                  'Đảm bảo ánh sáng tự nhiên để rút ngắn thời gian xét duyệt xuống còn 24 giờ.',
                  style: AppTypography.caption.copyWith(fontSize: 12, height: 18 / 12),
                ),
              ],
            ),
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
        border: Border(top: BorderSide(color: AppColors.stepInactive)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: AppButton(
              label: 'Quay lại',
              variant: AppButtonVariant.secondary,
              height: 49,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Tiếp tục',
              height: 49,
              onPressed: () {
                context.push(AppRoutes.sellerRegisterTerms);
              },
            ),
          ),
        ],
      ),
    );
  }
}
