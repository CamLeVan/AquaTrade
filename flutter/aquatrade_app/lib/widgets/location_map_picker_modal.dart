import 'package:flutter/material.dart';

import '../core/constants/vietnam_provinces.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'app_button.dart';

/// Hộp thoại chọn Tỉnh thành danh mục chuẩn & Đính kèm vị trí Google Maps.
class LocationMapPickerModal extends StatefulWidget {
  const LocationMapPickerModal({
    super.key,
    this.initialProvince = 'Đà Nẵng',
    this.initialAddress = '',
  });

  final String initialProvince;
  final String initialAddress;

  static Future<Map<String, String>?> show(
    BuildContext context, {
    String initialProvince = 'Đà Nẵng',
    String initialAddress = '',
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationMapPickerModal(
        initialProvince: initialProvince,
        initialAddress: initialAddress,
      ),
    );
  }

  @override
  State<LocationMapPickerModal> createState() => _LocationMapPickerModalState();
}

class _LocationMapPickerModalState extends State<LocationMapPickerModal> {
  late String _selectedProvince;
  late final TextEditingController _detailAddressCtrl;
  bool _includeGmapsLocation = true;

  @override
  void initState() {
    super.initState();
    _selectedProvince = VietnamProvinces.provinces.contains(widget.initialProvince)
        ? widget.initialProvince
        : 'Đà Nẵng';
    _detailAddressCtrl = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _detailAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderFaint,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'CHỌN ĐỊA CHỈ & GOOGLE MAPS',
                    style: AppTypography.sectionTitle.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderFaint),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              shrinkWrap: true,
              children: [
                Text(
                  'TỈNH / THÀNH PHỐ (DANH MỤC CHUẨN 63 TỈNH THÀNH)',
                  style: AppTypography.chip.copyWith(fontSize: 10, letterSpacing: 0.8),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: VietnamProvinces.provinces.contains(_selectedProvince)
                          ? _selectedProvince
                          : VietnamProvinces.provinces.first,
                      isExpanded: true,
                      style: AppTypography.body.copyWith(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      items: [
                        for (final p in VietnamProvinces.provinces)
                          DropdownMenuItem(value: p, child: Text(p)),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProvince = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'ĐỊA CHỈ CHI TIẾT / SỐ NHÀ / ĐƯỜNG',
                  style: AppTypography.chip.copyWith(fontSize: 10, letterSpacing: 0.8),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _detailAddressCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 123 Nguyễn Tất Thành, Quận Hải Châu',
                    isDense: true,
                    fillColor: AppColors.inputFill,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.borderSoft),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _googleMapsPreview(),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'XÁC NHẬN ĐỊA CHỈ',
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    final detail = _detailAddressCtrl.text.trim();
                    final fullAddr = detail.isNotEmpty
                        ? '$detail, $_selectedProvince'
                        : _selectedProvince;
                    final finalAddr = _includeGmapsLocation
                        ? '$fullAddr [Google Maps GPS: Verified]'
                        : fullAddr;
                    Navigator.of(context).pop({
                      'province': _selectedProvince,
                      'detail': detail,
                      'fullAddress': finalAddr,
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleMapsPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECEF),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.35,
                  child: Icon(Icons.map, size: 100, color: AppColors.primary),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 36),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.onDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Vị trí GPS: $_selectedProvince',
                        style: AppTypography.chip.copyWith(
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Checkbox(
                  value: _includeGmapsLocation,
                  onChanged: (v) => setState(() => _includeGmapsLocation = v ?? true),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(
                    'Đính kèm tọa độ GPS định vị từ Google Maps',
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
