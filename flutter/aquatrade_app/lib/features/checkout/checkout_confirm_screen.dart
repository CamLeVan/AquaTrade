import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/cart_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import 'widgets/checkout_seller_group.dart';
import '../../widgets/location_map_picker_modal.dart';

/// Xác nhận thanh toán — data từ giỏ đã chọn + profile/wallet API.
class CheckoutConfirmScreen extends StatefulWidget {
  const CheckoutConfirmScreen({super.key});

  @override
  State<CheckoutConfirmScreen> createState() => _CheckoutConfirmScreenState();
}

class _CheckoutConfirmScreenState extends State<CheckoutConfirmScreen> {
  static const _shipPerSeller = 25000;

  bool _isSubmitting = false;
  bool _editingAddress = false;
  bool _savingAddress = false;
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _addressCtrl = TextEditingController(
      text: (user?.address != null && user!.address!.trim().isNotEmpty)
          ? user.address!.trim()
          : '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (auth.isAuthenticated) {
        context.read<WalletProvider>().fetchWallet();
        // Đồng bộ địa chỉ mới nhất từ GET /users/me.
        final profile = await auth.loadProfile();
        if (!mounted || profile == null) return;
        final addr = profile.address?.trim() ?? '';
        if (addr.isNotEmpty && _addressCtrl.text.trim().isEmpty) {
          _addressCtrl.text = addr;
          setState(() {});
        } else if (addr.isNotEmpty && _addressCtrl.text.trim() != addr) {
          // Profile có địa chỉ đã lưu — ưu tiên BE nếu user chưa đang sửa.
          if (!_editingAddress) {
            _addressCtrl.text = addr;
            setState(() {});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshShippingFromProfile() async {
    final profile = await context.read<AuthProvider>().loadProfile();
    if (!mounted || profile == null) return;
    final addr = profile.address?.trim() ?? '';
    if (!_editingAddress) {
      _addressCtrl.text = addr;
      setState(() {});
    }
  }

  Future<void> _openProfileForShipping() async {
    await context.push(AppRoutes.profile);
    if (!mounted) return;
    await _refreshShippingFromProfile();
  }

  String _money(num v) => '${AppFormatters.formatNumber(v)}đ';

  Map<String, List<CartItemModel>> _selectedBySeller(CartProvider cart) {
    final map = <String, List<CartItemModel>>{};
    for (final item in cart.selectedItems) {
      final seller = item.listing.sellerName.isNotEmpty
          ? item.listing.sellerName
          : 'Người bán';
      map.putIfAbsent(seller, () => []).add(item);
    }
    return map;
  }

  int _shippingTotal(int sellerGroups) =>
      sellerGroups > 0 ? sellerGroups * _shipPerSeller : 0;

  String? _itemImage(CartItemModel item) {
    if (item.listing.thumbnailUrl.isNotEmpty) return item.listing.thumbnailUrl;
    if (item.listing.imageUrls.isNotEmpty) return item.listing.imageUrls.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Xác nhận thanh toán',
          centerTitle: true,
        ),
        body: const AuthGateView(
          reason: LoginReasons.checkout,
          from: AppRoutes.checkout,
          title: 'Đăng nhập để thanh toán',
        ),
      );
    }

    final cart = context.watch<CartProvider>();
    final order = context.watch<OrderProvider>();
    final wallet = context.watch<WalletProvider>().wallet;
    final user = auth.currentUser;
    final groups = _selectedBySeller(cart);
    final merchandise = cart.selectTotalPrice;
    final shipping = _shippingTotal(groups.length);
    final total = merchandise + shipping;

    if (cart.selectedItems.isEmpty && !_isSubmitting) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Xác nhận thanh toán',
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Chưa chọn sản phẩm nào',
                  style: AppTypography.heading.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Quay lại giỏ hàng và chọn sản phẩm để thanh toán.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Về giỏ hàng',
                  onPressed: () => context.go(AppRoutes.cart),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final contactName = (user?.fullName.isNotEmpty == true)
        ? user!.fullName
        : (user?.email.isNotEmpty == true ? user!.email : 'Người nhận');
    final phone = (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
        ? user.phoneNumber!
        : 'Chưa có SĐT';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar.subPage(
        title: 'Xác nhận thanh toán',
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      cart.selectedItems.length <= 1
                          ? 'Thanh toán sẽ tạo 1 đơn cho sản phẩm này.'
                          : 'Thanh toán sẽ tạo ${cart.selectedItems.length} đơn riêng (mỗi sản phẩm / listing = 1 đơn).',
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: _isSubmitting || order.isLoading
                    ? 'Đang xử lý...'
                    : 'Đặt hàng (${_money(total)})',
                icon: Icons.chevron_right,
                onPressed: _isSubmitting || order.isLoading
                    ? null
                    : () => _submit(cart, order),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        children: [
          _addressCard(contactName, phone),
          const SizedBox(height: AppSpacing.md),
          for (final entry in groups.entries) ...[
            CheckoutSellerGroup(
              sellerName: entry.key,
              badge: 'Người bán AquaTrade',
              shippingLabel: _money(_shipPerSeller),
              items: [
                for (final item in entry.value)
                  CheckoutLineItem(
                    productName: item.listing.title,
                    quantity: item.quantity,
                    priceLabel: _money(item.listing.pricePerFish),
                    imageUrl: _itemImage(item),
                    subtitle: item.listing.province.isNotEmpty
                        ? 'Nguồn: ${item.listing.province}'
                            '${item.listing.species.isNotEmpty ? ' · ${item.listing.species}' : ''}'
                        : (item.listing.species.isNotEmpty
                            ? 'Loài: ${item.listing.species}'
                            : null),
                    chipLabel: item.listing.qualityLabel.trim().isNotEmpty
                        ? item.listing.qualityLabel.trim().toUpperCase()
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _paymentCard(wallet?.balance),
          const SizedBox(height: AppSpacing.md),
          _summaryCard(merchandise, shipping, total),
        ],
      ),
    );
  }

  Future<void> _submit(CartProvider cart, OrderProvider order) async {
    final role = context.read<RoleProvider>();
    if (role.currentRole == UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tài khoản Quản trị viên không được phép thực hiện giao dịch mua bán.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final address = _addressCtrl.text.trim();
    final phone = context.read<AuthProvider>().currentUser?.phoneNumber?.trim() ?? '';
    if (phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            phone.isEmpty && address.isEmpty
                ? 'Cập nhật SĐT và địa chỉ trong hồ sơ trước khi đặt hàng'
                : phone.isEmpty
                    ? 'Cập nhật số điện thoại trong hồ sơ trước khi đặt hàng'
                    : 'Vui lòng nhập địa chỉ nhận hàng',
          ),
          action: SnackBarAction(
            label: 'Hồ sơ',
            onPressed: _openProfileForShipping,
          ),
        ),
      );
      if (address.isEmpty) setState(() => _editingAddress = true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final demo = cart.selectedItems
          .where((e) => e.listing.isDemoListing)
          .toList();
      if (demo.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Giỏ còn ${demo.length} sản phẩm demo (không có UUID thật). '
              'Hãy xóa chúng và thêm tin đăng từ server trước khi đặt hàng.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final created = await order.checkoutCart(
        selectedItems: cart.selectedItems,
        shippingAddress: address,
      );
      await cart.clearSelected();
      if (!mounted) return;
      context.push(
        AppRoutes.checkoutSuccess,
        extra: created.map((o) => o.id).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt hàng: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _onAddressAction() async {
    if (!_editingAddress) {
      setState(() => _editingAddress = true);
      return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ nhận hàng')),
      );
      return;
    }

    setState(() => _savingAddress = true);
    final ok = await context.read<AuthProvider>().updateProfile(address: address);
    if (!mounted) return;
    setState(() {
      _savingAddress = false;
      if (ok) _editingAddress = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã lưu địa chỉ vào hồ sơ'
              : 'Không lưu được địa chỉ: ${context.read<AuthProvider>().errorMessage}',
        ),
        backgroundColor: ok ? null : Colors.red,
      ),
    );
  }

  Widget _addressCard(String name, String phone) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'ĐỊA CHỈ NHẬN HÀNG',
                  style: AppTypography.chip.copyWith(
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PressableScale(
                onTap: () async {
                  final res = await LocationMapPickerModal.show(
                    context,
                    initialAddress: _addressCtrl.text.trim(),
                  );
                  if (res != null && mounted) {
                    setState(() {
                      _addressCtrl.text = res['fullAddress'] ?? _addressCtrl.text;
                      _editingAddress = true;
                    });
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Bản đồ',
                      style: AppTypography.chip.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PressableScale(
                onTap: _savingAddress ? null : () => _onAddressAction(),
                child: Text(
                  _savingAddress
                      ? 'Đang lưu...'
                      : (_editingAddress ? 'Lưu' : 'Thay đổi'),
                  style: AppTypography.chip.copyWith(
                    color: AppColors.onPrimaryDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$name | $phone',
            style: AppTypography.itemTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 2),
          if (_editingAddress)
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ nhận hàng',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            )
          else
            Text(
              _addressCtrl.text.trim().isNotEmpty
                  ? _addressCtrl.text.trim()
                  : 'Chưa có địa chỉ — bấm Thay đổi hoặc cập nhật hồ sơ',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: _addressCtrl.text.trim().isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          if (phone == 'Chưa có SĐT' || _addressCtrl.text.trim().isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            PressableScale(
              onTap: _openProfileForShipping,
              child: Text(
                'Cập nhật hồ sơ (SĐT & địa chỉ)',
                style: AppTypography.chip.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentCard(double? balance) {
    final balanceLabel =
        balance != null ? _money(balance) : 'Đang tải...';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Phương thức thanh toán',
                  style: AppTypography.itemTitle.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary10,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop,
                      size: 20, color: AppColors.onPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ví AquaTrade',
                          style:
                              AppTypography.itemTitle.copyWith(fontSize: 14)),
                      Text('Số dư: $balanceLabel',
                          style:
                              AppTypography.caption.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(int merchandise, int shipping, int total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.borderFaint),
      ),
      child: Column(
        children: [
          _row('Tổng tiền hàng', _money(merchandise)),
          const SizedBox(height: AppSpacing.sm),
          _row('Phí vận chuyển (ước tính)', _money(shipping)),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderFaint),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Tổng thanh toán',
                  style: AppTypography.itemTitle.copyWith(fontSize: 15)),
              const Spacer(),
              Text(
                _money(total),
                style: AppTypography.heading.copyWith(
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: AppTypography.itemTitle.copyWith(fontSize: 14)),
      ],
    );
  }
}
