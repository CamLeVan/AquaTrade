import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';

/// Hồ sơ cá nhân — map `PUT /users/profile` + `GET /users/me`.
/// Field chỉnh sửa: fullName, phoneNumber, address, companyName (seller).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _company;
  bool _hydrated = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _company = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    await auth.loadProfile();
    if (!mounted) return;
    final u = auth.currentUser;
    _fullName.text = u?.fullName ?? '';
    _phone.text = u?.phoneNumber ?? '';
    _address.text = u?.address ?? '';
    _company.text = u?.companyName ?? '';
    setState(() => _hydrated = true);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _address.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final canSell = context.read<RoleProvider>().canSell;
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile(
          fullName: _fullName.text.trim(),
          phoneNumber: _phone.text.trim(),
          address: _address.text.trim(),
          companyName: canSell ? _company.text.trim() : null,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã lưu hồ sơ — địa chỉ & SĐT sẽ dùng khi đặt hàng.'
              : 'Không lưu được: ${context.read<AuthProvider>().errorMessage}',
        ),
        backgroundColor: ok ? null : Colors.red,
      ),
    );
    if (ok && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppTopBar.subPage(
          title: 'Hồ sơ cá nhân',
          centerTitle: true,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.account);
            }
          },
        ),
        body: const AuthGateView(
          reason: LoginReasons.account,
          from: AppRoutes.profile,
          title: 'Đăng nhập để xem hồ sơ',
        ),
      );
    }

    final role = context.watch<RoleProvider>();
    final showCompany = role.canSell;
    final email = auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: 'Hồ sơ cá nhân',
        centerTitle: true,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.account);
          }
        },
      ),
      body: !_hydrated && auth.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    'Thông tin dùng khi đặt hàng và xác thực tài khoản.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Họ và tên',
                    hint: 'Nguyễn Văn A',
                    controller: _fullName,
                    leadingIcon: Icons.badge_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Email',
                    hint: email.isEmpty ? '—' : email,
                    initialValue: email.isEmpty ? '—' : email,
                    leadingIcon: Icons.mail_outline,
                    readOnly: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Số điện thoại',
                    hint: '09xxxxxxxx',
                    controller: _phone,
                    leadingIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Vui lòng nhập số điện thoại';
                      if (t.length < 9) return 'Số điện thoại chưa hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'ĐỊA CHỈ NHẬN HÀNG',
                    style: AppTypography.chip.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _address,
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vui lòng nhập địa chỉ nhận hàng';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Số nhà, đường, phường/xã, tỉnh/thành',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                    style: AppTypography.body.copyWith(fontSize: 16),
                  ),
                  if (showCompany) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Tên công ty / trại giống',
                      hint: 'Trang trại Thủy sản…',
                      controller: _company,
                      leadingIcon: Icons.storefront_outlined,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: _saving ? 'Đang lưu...' : 'Lưu hồ sơ',
                    onPressed: _saving ? null : _save,
                    leadingIcon: Icons.save_outlined,
                  ),
                ],
              ),
            ),
    );
  }
}
