import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/listing_model.dart';
import '../../providers/listing_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_smart_image.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';
import '../../core/router/app_routes.dart';

import '../../core/constants/vietnam_provinces.dart';
import '../../widgets/location_map_picker_modal.dart';

/// Form đăng / chỉnh sửa sản phẩm — field khớp BE `ListingDto.CreateListingRequest`
/// và mock web `AquaFront/.../Postings.jsx`.
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key, this.existingListing});

  final ListingModel? existingListing;

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  String _selectedProvince = 'Đà Nẵng';
  String _mapLocationDetail = '';

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _species = TextEditingController();
  final _qty = TextEditingController();
  final _sizeMin = TextEditingController();
  final _sizeMax = TextEditingController();
  final _price = TextEditingController();

  ListingCategory _category = ListingCategory.CA;
  Uint8List? _imageBytes;
  bool _submitting = false;

  static const _categories = <(ListingCategory, String)>[
    (ListingCategory.CA, 'Cá giống'),
    (ListingCategory.TOM, 'Tôm giống'),
    (ListingCategory.CUA, 'Cua, Ghẹ'),
    (ListingCategory.KHAC, 'Khác'),
  ];

  static const _qtyChips = [10, 50, 100, 500, 1000];

  @override
  void initState() {
    super.initState();
    final l = widget.existingListing;
    if (l != null) {
      _title.text = l.title;
      _species.text = l.species;
      _qty.text = '${l.availableQuantity > 0 ? l.availableQuantity : l.estimatedQuantity}';
      _sizeMin.text = '${l.sizeMin}';
      _sizeMax.text = '${l.sizeMax}';
      _price.text = l.pricePerFish.toInt().toString();
      _category = l.category;
      if (VietnamProvinces.provinces.contains(l.province)) {
        _selectedProvince = l.province;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _species.dispose();
    _qty.dispose();
    _sizeMin.dispose();
    _sizeMax.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      String thumbnailUrl = widget.existingListing?.thumbnailUrl ?? '';
      if (_imageBytes != null && _imageBytes!.isNotEmpty) {
        thumbnailUrl = 'data:image/png;base64,${base64Encode(_imageBytes!)}';
      }

      final isEditing = widget.existingListing != null;
      final listing = ListingModel(
        id: widget.existingListing?.id ?? '',
        title: _title.text.trim(),
        species: _species.text.trim(),
        category: _category,
        province: _selectedProvince,
        sizeMin: double.tryParse(_sizeMin.text) ?? 10.0,
        sizeMax: double.tryParse(_sizeMax.text) ?? 20.0,
        pricePerFish: double.tryParse(_price.text) ?? 5000,
        estimatedQuantity: int.tryParse(_qty.text) ?? 10,
        availableQuantity: int.tryParse(_qty.text) ?? 10,
        thumbnailUrl: thumbnailUrl,
        imageUrls: thumbnailUrl.isNotEmpty ? [thumbnailUrl] : (widget.existingListing?.imageUrls ?? []),
        status: widget.existingListing?.status ?? ListingStatus.PENDING_REVIEW,
        sellerId: widget.existingListing?.sellerId ?? '',
        sellerName: widget.existingListing?.sellerName ?? '',
        aiVerified: widget.existingListing?.aiVerified ?? false,
        aiHealthScore: widget.existingListing?.aiHealthScore ?? 90,
        qualityLabel: widget.existingListing?.qualityLabel ?? 'TƯƠI SỐNG',
        isFavorite: widget.existingListing?.isFavorite ?? false,
        createdAt: widget.existingListing?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await context.read<ListingProvider>().updateListing(listing.id, listing);
      } else {
        await context.read<ListingProvider>().createListing(listing);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Đã cập nhật sản phẩm thành công!'
                : 'Đã đăng tin thành công! Tin đăng đang ở trạng thái CHỜ DUYỆT và sẽ hiển thị lên Chợ sau khi được Quản trị viên phê duyệt.',
          ),
          backgroundColor: isEditing ? AppColors.primary : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(title: 'Đăng sản phẩm'),
        body: const AuthGateView(
          reason: LoginReasons.listing,
          from: AppRoutes.createListing,
          title: 'Đăng nhập để đăng bán',
        ),
      );
    }

    final isEditing = widget.existingListing != null;
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar.subPage(title: isEditing ? 'Chỉnh sửa sản phẩm' : 'Đăng sản phẩm'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 61 + AppSpacing.lg,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
          ),
          children: [
            _header(),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imagePicker(),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: 'Tiêu đề bài đăng',
                    hint: 'Ví dụ: Cá Tra Xuất Khẩu Loại 1',
                    controller: _title,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _categoryField(),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Chủng loại',
                    hint: 'Tên loài cá/tôm',
                    controller: _species,
                    validator: _required,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _provinceField(),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Số lượng ước tính (con)',
                    hint: 'Ví dụ: 5000',
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    validator: _requiredPositiveInt,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _qtyQuickAdd(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Kích thước Min (cm)',
                          hint: '0.5',
                          controller: _sizeMin,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _requiredPositiveNum,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          label: 'Kích thước Max (cm)',
                          hint: '1.5',
                          controller: _sizeMax,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _requiredPositiveNum,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Giá mỗi con (₫)',
                    hint: 'Ví dụ: 1200',
                    controller: _price,
                    keyboardType: TextInputType.number,
                    validator: _requiredPositiveNum,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _submitting
                  ? 'Đang xử lý...'
                  : (isEditing ? 'Lưu thay đổi' : 'Đăng bài ngay'),
              leadingIcon: _submitting ? Icons.sync : (isEditing ? Icons.check_circle_outline : Icons.cloud_upload),
              uppercase: true,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'ĐĂNG TIN MỚI',
            style: AppTypography.sectionTitle.copyWith(fontSize: 14),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'AI ACTIVE',
          style: AppTypography.chip.copyWith(
            fontSize: 10,
            letterSpacing: 1.2,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _imagePicker() {
    final existingUrl = widget.existingListing?.thumbnailUrl;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageBytes != null
            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
            : (existingUrl != null && existingUrl.isNotEmpty)
                ? AppSmartImage(imageUrl: existingUrl, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo,
                          size: 36, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'NHẤN ĐỂ TẢI ẢNH SẢN PHẨM',
                        style: AppTypography.chip.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chạm để chọn ảnh từ thư viện thiết bị',
                        style: AppTypography.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _categoryField() {
    final labelStyle = AppTypography.chip.copyWith(
      fontSize: 11,
      letterSpacing: 1.1,
      height: 16.5 / 11,
      color: AppColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DANH MỤC', style: labelStyle),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ListingCategory>(
              value: _category,
              isExpanded: true,
              style: AppTypography.body.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c.$1, child: Text(c.$2)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _qtyQuickAdd() {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final amt in _qtyChips)
          GestureDetector(
            onTap: () {
              final current = int.tryParse(_qty.text) ?? 0;
              setState(() => _qty.text = '${current + amt}');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.segmentTrack,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                '+$amt',
                style: AppTypography.chip.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null;

  String? _requiredPositiveInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Bắt buộc';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) return 'Nhập số nguyên > 0';
    return null;
  }

  String? _requiredPositiveNum(String? v) {
    if (v == null || v.trim().isEmpty) return 'Bắt buộc';
    final n = double.tryParse(v.trim());
    if (n == null || n <= 0) return 'Nhập số > 0';
    return null;
  }

  Widget _provinceField() {
    final labelStyle = AppTypography.chip.copyWith(
      fontSize: 11,
      letterSpacing: 1.1,
      color: AppColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'TỈNH THÀNH (CHUẨN)',
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: () async {
                final result = await LocationMapPickerModal.show(
                  context,
                  initialProvince: _selectedProvince,
                  initialAddress: _mapLocationDetail,
                );
                if (result != null && mounted) {
                  setState(() {
                    _selectedProvince = result['province'] ?? _selectedProvince;
                    _mapLocationDetail = result['fullAddress'] ?? '';
                  });
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Google Maps',
                    style: AppTypography.chip.copyWith(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: VietnamProvinces.provinces.contains(_selectedProvince)
                  ? _selectedProvince
                  : VietnamProvinces.provinces.first,
              isExpanded: true,
              style: AppTypography.body.copyWith(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              items: [
                for (final p in VietnamProvinces.provinces)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedProvince = v);
              },
            ),
          ),
        ),
        if (_mapLocationDetail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '📍 Đã đính kèm GPS: $_mapLocationDetail',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
