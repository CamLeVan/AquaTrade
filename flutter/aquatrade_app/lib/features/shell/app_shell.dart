import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// Khung bottom nav + vùng tab (StatefulNavigationShell).
/// Guest được vào mọi tab; Chat / Account / AI tự render AuthGate trên màn đích.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final notif = chatProvider.latestNotification;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          navigationShell,
          // Banner Thông Báo Tin Nhắn Đến Nổi Trên Màn Hình
          if (notif != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _InAppNotificationBanner(
                notification: notif,
                onTap: () {
                  final convId = notif.conversationId;
                  chatProvider.clearNotification();
                  context.push('/chat/detail/$convId');
                },
                onDismiss: () => chatProvider.clearNotification(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        chatBadgeCount: chatProvider.totalUnreadCount,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        onScanTap: () => context.push(AppRoutes.aiScan),
      ),
    );
  }
}

class _InAppNotificationBanner extends StatelessWidget {
  const _InAppNotificationBanner({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final ChatNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: const Color(0xF0111827), // Dark Glassmorphism
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble, size: 16, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: AppTypography.itemTitle.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Giữ tên cũ nếu còn tham chiếu preview.
class ChatPlaceholderScreen extends StatelessWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppTopBar.subPage(title: 'Tin nhắn', centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Hộp thoại đàm phán giá sẽ có ở bước sau.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
