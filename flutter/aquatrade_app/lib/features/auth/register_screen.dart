import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/auth_model.dart';
import '../../providers/auth_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/segmented_control.dart';
import 'widgets/auth_brand_header.dart';
import 'widgets/auth_text_field.dart';
import 'auth_navigation.dart';

/// Màn Register — Figma node `2008:75`.
///
/// ## Map BE (`AuthDto.RegisterRequest`)
/// - fullName, email, password, role (BUYER | SELLER)
/// - companyName (optional) — hiện khi chọn Seller (Figma không có; thêm để khớp BE)
///
/// ## Chỉ trên UI (không gửi BE)
/// - phone — RegisterRequest không có field
/// - confirmPassword — validate client
/// - Terms checkbox — bắt buộc trước submit
///
/// Sau register thành công: BE trả JWT → lưu token → `GET /users/me` → Home.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(); // UI-only
  final _company = TextEditingController(); // Seller → BE companyName
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _roleIndex = 0; // 0 Buyer → Role.BUYER, 1 Seller → Role.SELLER
  bool _obscure = true;
  bool _agreed = false;

  late final AnimationController _enter;
  late final Animation<double> _fade;

  Role get _beRole => _roleIndex == 0 ? Role.BUYER : Role.SELLER;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _company.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý Điều khoản & Chính sách.')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final roles = context.read<RoleProvider>();
    final ok = await auth.register(
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: _beRole,
      companyName: _roleIndex == 1 ? _company.text.trim() : null,
      roles: roles,
    );
    if (!mounted) return;

    if (ok) {
      // JWT đã lưu; vào Home — Dashboard phân UI theo role.
      goPostAuthHome(context, roles);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auth.errorMessage.isNotEmpty
              ? auth.errorMessage
              : 'Đăng ký thất bại. Kiểm tra BE hoặc email đã tồn tại.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: PressableScale(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.authLink),
        ),
        centerTitle: true,
        title: Text(
          'TẠO TÀI KHOẢN',
          style: AppTypography.cardValue.copyWith(
            fontSize: 20,
            letterSpacing: -1,
            color: AppColors.authLink,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  48,
                ),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AuthBrandHeader(compact: true),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tham gia hệ sinh thái',
                    style: AppTypography.heading.copyWith(
                      fontSize: 28,
                      height: 36 / 28,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Giao dịch thủy sản thông minh với hỗ trợ AI.',
                    style: AppTypography.body.copyWith(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Vai trò → BE Role
                  Text(
                    'CHỌN VAI TRÒ',
                    style: AppTypography.chip.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: AppColors.textStrong,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedControl(
                    labels: const ['Người mua', 'Người bán'],
                    selectedIndex: _roleIndex,
                    onChanged: (i) => setState(() => _roleIndex = i),
                    style: SegmentedStyle.pill,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AuthTextField(
                    label: 'Họ và tên',
                    hint: 'Nhập họ tên đầy đủ',
                    controller: _fullName,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AuthTextField(
                    label: 'Email',
                    hint: 'ten@congty.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                      if (!v.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Phone: Figma có — BE RegisterRequest không có → không gửi.
                  AuthTextField(
                    label: 'Số điện thoại',
                    hint: '+84 ...',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Chỉ hiển thị UI — BE chưa nhận SĐT lúc đăng ký.',
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_roleIndex == 1) ...[
                    AuthTextField(
                      label: 'Tên công ty (tuỳ chọn)',
                      hint: 'Công ty / hộ kinh doanh',
                      controller: _company,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  AuthTextField(
                    label: 'Mật khẩu',
                    hint: '••••••••',
                    controller: _password,
                    obscureText: _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Bắt buộc';
                      if (v.length < 6) return 'Tối thiểu 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AuthTextField(
                    label: 'Xác nhận mật khẩu',
                    hint: '••••••••',
                    controller: _confirm,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v != _password.text) return 'Mật khẩu không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _termsRow(),
                  const SizedBox(height: AppSpacing.lg),

                  AppButton(
                    label: loading ? 'Đang tạo...' : 'Tạo tài khoản',
                    uppercase: true,
                    icon: Icons.arrow_forward,
                    onPressed: loading ? null : _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _loginFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.body.copyWith(fontSize: 14, height: 1.35),
              children: [
                const TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'Điều khoản dịch vụ',
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authLink,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' và '),
                TextSpan(
                  text: 'Chính sách bảo mật',
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.authLink,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _loginFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: AppTypography.body.copyWith(fontSize: 14),
        ),
        PressableScale(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
          child: Text(
            'Đăng nhập',
            style: AppTypography.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.authLink,
            ),
          ),
        ),
      ],
    );
  }
}
