import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import 'animations.dart';

/// Định nghĩa DUY NHẤT cho bottom navigation của app.
/// Nút giữa "QUÉT AI" là FAB nổi (teal). Mọi màn có tab bar phải dùng lại widget này.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onScanTap,
    this.chatBadgeCount = 0,
  });

  /// 0: Trang chủ, 1: Chợ, 2: Tin nhắn, 3: Tài khoản
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onScanTap;
  final int chatBadgeCount;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      // nội dung gọn + vùng an toàn dưới
      height: 54 + bottomSafe,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Thanh nền
          Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
          ),
          // Hàng item (label căn đều 1 baseline)
          Padding(
            padding: EdgeInsets.only(top: 8, bottom: bottomSafe),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'TRANG CHỦ',
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront,
                  label: 'CHỢ',
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                // Chừa chỗ cho FAB, chỉ hiện label để căn thẳng hàng
                const _ScanLabelSlot(),
                _NavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'TIN NHẮN',
                  selected: currentIndex == 2,
                  badgeCount: chatBadgeCount,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'TÀI KHOẢN',
                  selected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
          // FAB Quét AI nổi lên trên
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(child: _ScanFab(onTap: onScanTap)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return SizedBox(
      width: 64,
      child: PressableScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, size: 22, color: color),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.chip.copyWith(
                fontSize: 9,
                letterSpacing: -0.45,
                height: 13.5 / 9,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô giữ chỗ dưới FAB: chỉ có label "QUÉT AI" để căn thẳng hàng với các label khác.
class _ScanLabelSlot extends StatelessWidget {
  const _ScanLabelSlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 22 + 4), // chiều cao icon + gap của item thường
          Text(
            'QUÉT AI',
            style: AppTypography.chip.copyWith(
              fontSize: 9,
              letterSpacing: -0.45,
              height: 13.5 / 9,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  const _ScanFab({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.center_focus_strong,
            color: AppColors.onPrimary, size: 24),
      ),
    );
  }
}
