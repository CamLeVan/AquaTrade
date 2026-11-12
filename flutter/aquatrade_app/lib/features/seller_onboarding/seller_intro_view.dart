import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import 'widgets/benefit_card.dart';

/// Nội dung tab "Gian hàng của tôi" khi người dùng CHƯA có gian hàng.
/// Lấp đầy chiều cao khả dụng, ghim CTA "Đăng ký làm người bán" ở đáy như Figma
/// (không phải cuộn mới thấy nút). Tự cuộn nếu màn quá thấp.
class SellerIntroView extends StatelessWidget {
  const SellerIntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  EmptyState(
                    icon: Icons.storefront,
                    title: 'Bạn chưa có gian hàng',
                    message:
                        'Bắt đầu kinh doanh thủy sản chuyên nghiệp với hệ thống xác thực AI. '
                        'Tiếp cận hàng nghìn người mua tin cậy trong mạng lưới AquaTrade.',
                    child: _benefits(),
                  ),
                  const Spacer(),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Đăng ký làm người bán',
                    uppercase: true,
                    icon: Icons.arrow_forward,
                    onPressed: () =>
                        context.push(AppRoutes.sellerRegisterInfo),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _benefits() {
    return Column(
      children: const [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: BenefitCard(
                  icon: Icons.bolt,
                  label: 'Hiệu suất cao',
                  value: 'Bán hàng tồn nhanh chóng',
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: BenefitCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Công nghệ AI',
                  value: 'Quản lý kho bằng AI',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        BenefitCard(
          icon: Icons.verified_user_outlined,
          label: 'An toàn tuyệt đối',
          value: 'Thanh toán bảo mật',
          note: 'Tiền của bạn được đảm bảo an toàn bởi hệ thống Escrow.',
        ),
      ],
    );
  }
}
