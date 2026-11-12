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

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.markAsRead(widget.conversationId);

      final auth = context.read<AuthProvider>();
      final role = context.read<RoleProvider>().currentRole;
      final isSeller = role == UserRole.seller;
      final userId = auth.currentUser?.id ?? (isSeller ? 'seller_device' : 'buyer_device');

      final convs = chatProvider.conversations;
      final idx = convs.indexWhere((c) => c.id == widget.conversationId);
      final conv = idx != -1 ? convs[idx] : null;
      final orderId = conv?.orderId ?? (conv?.listingId != null && conv!.listingId!.length > 20 ? conv.listingId : null);

      chatProvider.subscribeRealtimeRoom(
        conversationId: widget.conversationId,
        orderId: orderId,
        currentUserId: userId,
      );

      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().leaveRealtimeRoom();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onSend(ChatConversation conv, bool isSeller) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final senderId = user?.id ?? (isSeller ? 'seller_device' : 'buyer_device');
    final senderName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : (isSeller ? 'Chủ Shop' : 'Người mua');

    context.read<ChatProvider>().sendMessage(
      conversationId: widget.conversationId,
      content: text,
      senderId: senderId,
      senderName: senderName,
      productTitle: conv.listingTitle,
      productPrice: conv.listingPrice,
      isSeller: isSeller,
    );

    _textController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>().currentRole;
    final isSeller = role == UserRole.seller;

    final chatProvider = context.watch<ChatProvider>();
    final conv = chatProvider.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => ChatConversation(
        id: widget.conversationId,
        partnerId: 'unknown',
        partnerName: 'Hội thoại',
        lastMessage: '',
        lastUpdated: DateTime.now(),
      ),
    );

    final messages = chatProvider.getMessages(widget.conversationId);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar.subPage(
        title: conv.partnerName,
        centerTitle: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conv.listingId != null)
              PressableScale(
                onTap: () => context.push(AppRoutes.productOf(conv.listingId!)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Xem SP',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner đính kèm Sản phẩm
          if (conv.listingTitle != null && conv.listingTitle!.isNotEmpty)
            _buildProductBanner(conv, isSeller),

          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageBubble(msg, conv, isSeller);
              },
            ),
          ),

          // Thanh nhập tin nhắn
          _buildInputBar(conv, isSeller),
        ],
      ),
    );
  }

  Widget _buildProductBanner(ChatConversation conv, bool isSeller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSoft),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 44,
              height: 44,
              color: AppColors.imagePlaceholder,
              child: AppSmartImage(
                imageUrl: conv.listingThumbnail,
                fit: BoxFit.cover,
                placeholder: const Icon(Icons.set_meal, size: 20, color: AppColors.primary30),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.listingTitle ?? '',
                  style: AppTypography.itemTitle.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  conv.listingPrice ?? '',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          PressableScale(
            onTap: () {
              if (isSeller) {
                _textController.text = 'Chào bạn! Mẻ "${conv.listingTitle}" đang sẵn hàng tại ao, bạn dự kiến lấy bao nhiêu con?';
              } else {
                _textController.text = 'Chào bạn, sản phẩm "${conv.listingTitle}" có sẵn giao ngay không ạ?';
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                isSeller ? 'Gợi ý báo giá' : 'Hỏi nhanh',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg, ChatConversation conv, bool isSeller) {
    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: conv.type == ChatType.aiAssistant ? AppColors.primary10 : AppColors.secondary10,
              child: Icon(
                conv.type == ChatType.aiAssistant
                    ? Icons.auto_awesome
                    : (isSeller ? Icons.person : Icons.store),
                size: 16,
                color: conv.type == ChatType.aiAssistant ? AppColors.primary : AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSpacing.radiusMd),
                  topRight: const Radius.circular(AppSpacing.radiusMd),
                  bottomLeft: Radius.circular(isMe ? AppSpacing.radiusMd : 2),
                  bottomRight: Radius.circular(isMe ? 2 : AppSpacing.radiusMd),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      msg.senderName,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    msg.content,
                    style: AppTypography.body.copyWith(
                      color: isMe ? AppColors.onPrimary : AppColors.textStrong,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg.timestamp),
                    style: AppTypography.caption.copyWith(
                      fontSize: 9,
                      color: isMe ? AppColors.onPrimary.withValues(alpha: 0.7) : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatConversation conv, bool isSeller) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.sm, 8),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.borderSoft)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: isSeller ? 'Nhập phản hồi báo giá cho khách...' : 'Nhập tin nhắn trao đổi...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _onSend(conv, isSeller),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            PressableScale(
              onTap: () => _onSend(conv, isSeller),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
