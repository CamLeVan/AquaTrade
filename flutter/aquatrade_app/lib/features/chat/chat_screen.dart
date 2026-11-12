import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../shared_providers/role_provider.dart';
import '../../widgets/animations.dart';
import '../../widgets/app_smart_image.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/auth_gate_view.dart';
import '../auth/auth_navigation.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedFilter = 0; // 0: Tất cả, 1: Người bán / Khách mua, 2: Trợ lý AI

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      bool isSeller = false;
      try {
        final role = context.read<RoleProvider>().currentRole;
        isSeller = role == UserRole.seller;
      } catch (_) {}
      final userId = auth.currentUser?.id ?? (isSeller ? 'seller_device' : 'buyer_device');

      try {
        context.read<ChatProvider>().subscribeGlobalRealtimeChat(currentUserId: userId);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar.subPage(
          title: 'Tin nhắn',
          centerTitle: true,
        ),
        body: const AuthGateView(
          reason: LoginReasons.chat,
          from: AppRoutes.chat,
          title: 'Đăng nhập để xem tin nhắn',
        ),
      );
    }

    final role = context.watch<RoleProvider>().currentRole;
    final isSeller = role == UserRole.seller;

    final chatProvider = context.watch<ChatProvider>();
    final allConversations = chatProvider.conversations;

    final filteredList = allConversations.where((c) {
      if (_selectedFilter == 1) return c.type == ChatType.directSeller;
      if (_selectedFilter == 2) return c.type == ChatType.aiAssistant;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      appBar: const AppTopBar.subPage(
        title: 'Tin nhắn & Trò chuyện',
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 61 + AppSpacing.sm,
          bottom: 40,
        ),
        children: [
          _buildFilterTabs(isSeller),
          const SizedBox(height: AppSpacing.sm),
          if (filteredList.isEmpty)
            _buildEmptyState(isSeller)
          else
            ...filteredList.map((conv) => _buildConversationItem(conv, isSeller)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(bool isSeller) {
    final tabs = [
      'Tất cả',
      isSeller
          ? 'Khách mua (${context.watch<ChatProvider>().conversations.where((c) => c.type == ChatType.directSeller).length})'
          : 'Người bán (${context.watch<ChatProvider>().conversations.where((c) => c.type == ChatType.directSeller).length})',
      'Trợ lý AI'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedFilter == idx;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: PressableScale(
              onTap: () => setState(() => _selectedFilter = idx),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSoft,
                  ),
                ),
                child: Text(
                  tabs[idx],
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConversationItem(ChatConversation conv, bool isSeller) {
    final isAi = conv.type == ChatType.aiAssistant;
    final partnerBadge = isAi
        ? '🤖 Trợ lý AI'
        : (isSeller ? '🛒 Khách mua' : '🏪 Người bán');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () {
          context.push('/chat/detail/${conv.id}');
        },
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isAi ? AppColors.primary10 : AppColors.secondary10,
              child: isAi
                  ? Icon(Icons.auto_awesome, color: AppColors.primary, size: 24)
                  : conv.listingThumbnail != null
                      ? ClipOval(
                          child: AppSmartImage(
                            imageUrl: conv.listingThumbnail,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: Icon(
                              isSeller ? Icons.person : Icons.store,
                              color: AppColors.secondary,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
                          isSeller ? Icons.person : Icons.store,
                          color: AppColors.secondary,
                          size: 24,
                        ),
            ),
            if (conv.unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${conv.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      conv.partnerName,
                      style: AppTypography.itemTitle.copyWith(
                        fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isAi
                          ? AppColors.primary10
                          : (isSeller ? AppColors.infoBg : AppColors.primary10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      partnerBadge,
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isAi
                            ? AppColors.primary
                            : (isSeller ? AppColors.infoText : AppColors.onPrimaryDeep),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _formatTime(conv.lastUpdated),
              style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conv.listingTitle != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '🐟 ${conv.listingTitle}',
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              conv.lastMessage,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                color: conv.unreadCount > 0 ? AppColors.textStrong : AppColors.textSecondary,
                fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSeller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline, size: 54, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isSeller
                ? 'Khi khách mua nhắn tin quan tâm sản phẩm trong shop của bạn, tin nhắn sẽ hiển thị tại đây để bạn phản hồi và chốt đơn.'
                : 'Hãy nhấn vào bất kỳ sản phẩm nào trên Chợ và chọn "Trò chuyện" để nhắn tin trực tiếp với người bán.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${time.day}/${time.month}';
  }
}
