import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import 'widgets/auth_brand_header.dart';
import 'widgets/auth_text_field.dart';
import 'auth_navigation.dart';

/// Màn Login — Figma node `2008:3`.
///
/// ## Map BE (`AuthDto.LoginRequest`)
/// - email ← ô "EMAIL OR USERNAME" (BE chỉ nhận email, không có username)
/// - password
/// - rememberMe ← checkbox
///
/// ## Chưa có trên BE (giữ UI, không gọi API)
/// - Forgot password → snackbar
/// - Continue with Google → snackbar
///
/// Animation: fade + slide-up card khi mở màn (PressableScale trên CTA).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _rememberMe = false;

  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _noticeShown = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _noticeShown) return;
      final reason =
          GoRouterState.of(context).uri.queryParameters['reason'];
      if (reason == null || reason.isEmpty) return;
      _noticeShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LoginReasons.messageFor(reason)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.onPrimaryDeep,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final roles = context.read<RoleProvider>();
    final ok = await auth.login(
      _email.text.trim(),
      _password.text,
      rememberMe: _rememberMe,
      roles: roles,
    );
    if (!mounted) return;

    if (ok) {
      // Cả Buyer/Seller → Home (Dashboard phân UI theo role).
      goPostAuthHome(context, roles);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auth.errorMessage.isNotEmpty
              ? auth.errorMessage
              : 'Đăng nhập thất bại. Kiểm tra BE / email / mật khẩu.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Atmospheric blobs (Figma 2008:4–6)
          Positioned(
            left: -40,
            top: -180,
            child: _blob(AppColors.authBlob, 234, 520),
          ),
          Positioned(
            right: -20,
            top: 340,
            child: _blob(AppColors.authBlobAccent.withValues(alpha: 0.45), 156, 434),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          _loginCard(loading),
                          const SizedBox(height: AppSpacing.lg),
                          _secureBadge(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double w, double h) {
    return IgnorePointer(
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
    );
  }

  Widget _loginNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary10,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                height: 1.35,
                color: AppColors.onPrimaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginCard(bool loading) {
    final reason =
        GoRouterState.of(context).uri.queryParameters['reason'];
    final notice = reason != null && reason.isNotEmpty
        ? LoginReasons.messageFor(reason)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(33),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 50,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const AuthBrandHeader(),
            if (notice != null) ...[
              const SizedBox(height: AppSpacing.md),
              _loginNotice(notice),
            ],
            const SizedBox(height: AppSpacing.xl),
            AuthTextField(
              label: 'Email',
              // BE chỉ nhận email (không có username).
              hint: 'vd: ban@aquatrade.ai',
              controller: _email,
              leadingIcon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                if (!v.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthTextField(
              label: 'Mật khẩu',
              hint: '••••••••••••',
              controller: _password,
              leadingIcon: Icons.lock_outline,
              obscureText: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              textInputAction: TextInputAction.done,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _optionsRow(),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: loading ? 'Đang đăng nhập...' : 'Đăng nhập',
              uppercase: true,
              onPressed: loading ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.xl),
            _orDivider(),
            const SizedBox(height: AppSpacing.lg),
            // Google: chưa có endpoint OAuth trên core-backend.
            _googleButton(),
            const SizedBox(height: AppSpacing.xl),
            _registerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _optionsRow() {
    return Row(
      children: [
        PressableScale(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          pressedScale: 0.96,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Ghi nhớ đăng nhập',
                style: AppTypography.body.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
        const Spacer(),
        PressableScale(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quên mật khẩu — chưa có API trên BE.'),
              ),
            );
          },
          child: Text(
            'Quên mật khẩu?',
            style: AppTypography.chip.copyWith(
              fontSize: 12,
              letterSpacing: 0.6,
              color: AppColors.authLink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _orDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderFaint)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'HOẶC',
            style: AppTypography.chip.copyWith(
              fontSize: 12,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderFaint)),
      ],
    );
  }

  Widget _googleButton() {
    return PressableScale(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập Google — chưa tích hợp BE.'),
          ),
        );
      },
      pressedScale: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.g_mobiledata, size: 28, color: Colors.red.shade400),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Tiếp tục với Google',
              style: AppTypography.itemTitle.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registerFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: AppTypography.body.copyWith(fontSize: 14),
        ),
        PressableScale(
          onTap: () => context.push(AppRoutes.register),
          child: Text(
            'Đăng ký ngay',
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

  Widget _secureBadge() {
    return Opacity(
      opacity: 0.6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined,
              size: 14, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'MÔI TRƯỜNG AN TOÀN · KIỂM DUYỆT BẰNG AI',
            style: AppTypography.chip.copyWith(
              fontSize: 11,
              letterSpacing: 0.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
