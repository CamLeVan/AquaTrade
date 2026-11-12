import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/chat_model.dart';
import '../data/models/listing_model.dart';
import '../data/models/order_model.dart';

import '../data/repositories/chat_repository.dart';

class ChatNotification {
  final String title;
  final String message;
  final String conversationId;
  final DateTime time;

  ChatNotification({
    required this.title,
    required this.message,
    required this.conversationId,
    required this.time,
  });
}

class ChatProvider extends ChangeNotifier {
  ChatRepository? _chatRepository;

  void updateRepository(ChatRepository repo) {
    _chatRepository = repo;
  }

  // Danh sách các cuộc trò chuyện
  final Map<String, List<ChatMessageItem>> _messagesByConversation = {};
  final List<ChatConversation> _conversations = [];
  
  // Stream / Banner thông báo tin nhắn mới
  ChatNotification? _latestNotification;
  ChatNotification? get latestNotification => _latestNotification;

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);

  int get totalUnreadCount =>
      _conversations.fold(0, (sum, item) => sum + item.unreadCount);

  ChatProvider({ChatRepository? repository}) : _chatRepository = repository {
    _initSampleData();
  }

  void _initSampleData() {
    // Cuộc trò chuyện mẫu 1: Trợ lý AI Hệ Thống
    const aiConvId = 'system_ai_assistant';
    _conversations.add(
      ChatConversation(
        id: aiConvId,
        partnerId: 'system_ai',
        partnerName: 'Trợ lý AI AquaTrade (Hệ Thống)',
        lastMessage: 'Báo cáo AI Bioscan hiển thị điểm sức khỏe 98/100, chỉ số bơi đều 99%.',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 0,
        type: ChatType.aiAssistant,
      ),
    );

    _messagesByConversation[aiConvId] = [
      ChatMessageItem(
        id: 'msg_ai_1',
        senderId: 'system_ai',
        senderName: 'Trợ lý AI AquaTrade',
        content: 'Xin chào! Tôi là Trợ lý AI của sàn AquaTrade. Tôi có thể hỗ trợ bạn tra cứu giá thị trường, phân tích sức khỏe thủy sản và giải đáp thắc mắc.',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessageItem(
        id: 'msg_ai_2',
        senderId: 'user',
        senderName: 'Tôi',
        content: 'Tôi muốn xem báo cáo phân tích sức khỏe cá AI cho mã tin #1024',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessageItem(
        id: 'msg_ai_3',
        senderId: 'system_ai',
        senderName: 'Trợ lý AI AquaTrade',
        content: 'Báo cáo AI Bioscan hiển thị điểm sức khỏe 98/100, chỉ số bơi đều 99%. Môi trường nước ổn định, không phát hiện mầm bệnh.',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  List<ChatMessageItem> getMessages(String conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  /// Bắt đầu hoặc mở cuộc trò chuyện về 1 Đơn hàng cụ thể (P2P có lưu DB và Real-time)
  String startConversationWithOrder({
    required OrderModel order,
    required String currentUserId,
    required bool isSeller,
  }) {
    final partnerId = isSeller ? order.buyerName : (order.sellerName.isNotEmpty ? order.sellerName : 'Đối tác');
    final partnerName = isSeller
        ? (order.buyerName.isNotEmpty ? order.buyerName : 'Khách mua')
        : (order.sellerName.isNotEmpty ? order.sellerName : 'Người bán');
    
    final convId = 'order_${order.id}';
    final existingIndex = _conversations.indexWhere((c) => c.id == convId || c.orderId == order.id);

    if (existingIndex == -1) {
      final newConv = ChatConversation(
        id: convId,
        orderId: order.id,
        partnerId: partnerId,
        partnerName: partnerName,
        lastMessage: 'Đơn hàng #${order.id.length > 8 ? order.id.substring(0, 8) : order.id} (${order.listingTitle})',
        lastUpdated: order.createdAt,
        unreadCount: 0,
        listingId: order.id,
        listingTitle: order.listingTitle,
        listingPrice: '${order.totalPrice.toStringAsFixed(0)}đ',
        listingThumbnail: order.digitalProof?.aiImageUrl,
        type: ChatType.directSeller,
      );

      _conversations.insert(0, newConv);
      _messagesByConversation[convId] = [
        ChatMessageItem(
          id: 'welcome_${order.id}',
          senderId: 'system',
          senderName: 'Hệ thống AquaTrade',
          content: 'Đã kết nối phòng chat cho đơn hàng "${order.listingTitle}".',
          isMe: false,
          timestamp: order.createdAt,
          productTitle: order.listingTitle,
          productPrice: '${order.totalPrice.toStringAsFixed(0)}đ',
        ),
      ];
    }

    notifyListeners();
    return convId;
  }

  /// Bắt đầu hoặc mở cuộc trò chuyện với Người bán về 1 sản phẩm cụ thể
  String startConversationWithSeller({
    required ListingModel listing,
    required String currentUserId,
    required String currentUserName,
  }) {
    // ID hội thoại liên kết giữa User và Seller cho sản phẩm này
    final partnerId = listing.sellerId.isNotEmpty ? listing.sellerId : 'seller_demo';
    final partnerName = listing.sellerName.isNotEmpty ? listing.sellerName : 'Người bán Thủy sản';
    final convId = 'conv_${partnerId}_${listing.id}';

    final existingIndex = _conversations.indexWhere((c) => c.id == convId);

    if (existingIndex == -1) {
      final newConv = ChatConversation(
        id: convId,
        partnerId: partnerId,
        partnerName: partnerName,
        lastMessage: 'Đang quan tâm sản phẩm "${listing.title}"',
        lastUpdated: DateTime.now(),
        unreadCount: 0,
        listingId: listing.id,
        listingTitle: listing.title,
        listingPrice: '${listing.pricePerFish.toStringAsFixed(0)}đ',
        listingThumbnail: listing.thumbnailUrl.isNotEmpty
            ? listing.thumbnailUrl
            : (listing.imageUrls.isNotEmpty ? listing.imageUrls.first : null),
        type: ChatType.directSeller,
      );

      _conversations.insert(0, newConv);
      _messagesByConversation[convId] = [
        ChatMessageItem(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          senderId: partnerId,
          senderName: partnerName,
          content: 'Xin chào! Cảm ơn bạn đã quan tâm đến "${listing.title}". Bạn muốn hỏi thêm về số lượng hay phương thức vận chuyển?',
          isMe: false,
          timestamp: DateTime.now(),
          productTitle: listing.title,
          productPrice: '${listing.pricePerFish.toStringAsFixed(0)}đ',
        ),
      ];
    }

    notifyListeners();
    return convId;
  }

  /// Gửi tin nhắn
  void sendMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required String senderName,
    String? productTitle,
    String? productPrice,
    bool isSeller = false,
  }) {
    final text = content.trim();
    if (text.isEmpty) return;

    final newMsg = ChatMessageItem(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      content: text,
      isMe: true,
      timestamp: DateTime.now(),
      productTitle: productTitle,
      productPrice: productPrice,
    );

    if (!_messagesByConversation.containsKey(conversationId)) {
      _messagesByConversation[conversationId] = [];
    }
    _messagesByConversation[conversationId]!.add(newMsg);

    // Cập nhật hoặc tạo mới Conversation trong danh sách hiển thị
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      final conv = _conversations[convIndex];
      _conversations.removeAt(convIndex);
      _conversations.insert(
        0,
        ChatConversation(
          id: conv.id,
          orderId: conv.orderId,
          partnerId: conv.partnerId,
          partnerName: conv.partnerName,
          partnerAvatar: conv.partnerAvatar,
          lastMessage: text,
          lastUpdated: DateTime.now(),
          unreadCount: 0,
          listingId: conv.listingId,
          listingTitle: conv.listingTitle ?? productTitle,
          listingPrice: conv.listingPrice ?? productPrice,
          listingThumbnail: conv.listingThumbnail,
          type: conv.type,
        ),
      );
    } else {
      _conversations.insert(
        0,
        ChatConversation(
          id: conversationId,
          partnerId: isSeller ? 'buyer_partner' : 'seller_partner',
          partnerName: isSeller ? 'Khách mua' : 'Người bán Thủy sản',
          lastMessage: text,
          lastUpdated: DateTime.now(),
          unreadCount: 0,
          listingTitle: productTitle,
          listingPrice: productPrice,
          type: ChatType.directSeller,
        ),
      );
    }

    notifyListeners();

    debugPrint('💬 [ChatProvider] sendMessage called | convId: $conversationId | senderId: $senderId | text: "$text"');

    // 1. Luôn phát sóng tin nhắn qua STOMP WebSocket theo conversationId để các thiết bị cùng phòng nhận được tức thì
    if (_chatRepository != null) {
      debugPrint('➡️ [ChatProvider] Gọi _chatRepository.sendStompMessage...');
      _chatRepository!.sendStompMessage(
        conversationId: conversationId,
        content: text,
        senderId: senderId,
        senderName: senderName,
      );
    } else {
      debugPrint('⚠️ [ChatProvider] _chatRepository is NULL!');
    }

    // 2. Nếu có orderId thực tế trong DB ➔ Gửi lưu trữ lâu dài vào PostgreSQL
    final targetConv = convIndex != -1 ? _conversations[0] : null;
    final effectiveOrderId = targetConv?.orderId ?? (targetConv?.listingId != null && targetConv!.listingId!.length > 20 ? targetConv.listingId : null);

    if (_chatRepository != null && effectiveOrderId != null && effectiveOrderId.isNotEmpty) {
      debugPrint('➡️ [ChatProvider] Gọi _chatRepository.sendMessageApi cho effectiveOrderId: $effectiveOrderId');
      _chatRepository!.sendMessageApi(
        orderId: effectiveOrderId,
        content: text,
      );
    }

    // 3. Chỉ kích hoạt Bot tự động nếu là Chat với Trợ lý AI Hệ Thống
    if (conversationId == 'system_ai_assistant') {
      debugPrint('🤖 [ChatProvider] Kích hoạt Trợ lý AI Hệ Thống...');
      _handleAutoReplyAndNotification(conversationId, text, senderName, isSeller);
    }
  }

  Timer? _pollingTimer;

  /// Đăng ký lắng nghe tin nhắn Realtime qua WebSocket STOMP theo conversationId & Tải lịch sử chat từ Server nếu có orderId
  void subscribeRealtimeRoom({
    required String conversationId,
    required String? orderId,
    required String currentUserId,
  }) async {
    debugPrint('🔌 [ChatProvider] subscribeRealtimeRoom | convId: $conversationId | orderId: $orderId | currentUserId: $currentUserId');
    if (_chatRepository == null) {
      debugPrint('⚠️ [ChatProvider] _chatRepository is NULL trong subscribeRealtimeRoom');
      return;
    }

    // 1. Tải lịch sử chat ban đầu từ Backend PostgreSQL nếu có orderId
    if (orderId != null && orderId.isNotEmpty) {
      debugPrint('🌐 [ChatProvider] Tải lịch sử chat và bật Polling fallback cho orderId: $orderId');
      _fetchAndUpdateMessages(conversationId, orderId, currentUserId);
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        _fetchAndUpdateMessages(conversationId, orderId, currentUserId);
      });
    }

    // 2. Lắng nghe qua WebSocket STOMP thời gian thực theo conversationId
    _chatRepository!.subscribeRealtimeChat(
      conversationId: conversationId,
      onEventReceived: (payload) {
        debugPrint('📩 [ChatProvider] NHẬN PAYLOAD WEBSOCKET: $payload');
        if (payload['eventType'] == 'CHAT_MESSAGE_CREATED') {
          final data = payload['payload'] as Map<String, dynamic>? ?? {};
          final senderId = data['senderId']?.toString() ?? '';
          if (senderId == currentUserId) {
            debugPrint('⏩ [ChatProvider] Bỏ qua tin nhắn do chính mình ($currentUserId) gửi.');
            return;
          }

          final content = data['content']?.toString() ?? '';
          final senderName = data['senderName']?.toString() ?? 'Đối tác';
          debugPrint('✨ [ChatProvider] THÊM TIN NHẮN MỚI TỪ NGUỜI KHÁC: "$content" từ $senderName ($senderId)');

          final newMsg = ChatMessageItem(
            id: 'ws_${DateTime.now().millisecondsSinceEpoch}',
            senderId: senderId,
            senderName: senderName,
            content: content,
            isMe: false,
            timestamp: DateTime.now(),
          );

          if (!_messagesByConversation.containsKey(conversationId)) {
            _messagesByConversation[conversationId] = [];
          }
          final exists = _messagesByConversation[conversationId]!.any(
            (m) => m.content == content && m.senderId == senderId && (m.timestamp.difference(newMsg.timestamp).inSeconds.abs() < 5),
          );
          if (!exists) {
            _messagesByConversation[conversationId]!.add(newMsg);
            _updateOrAddConversationOnIncomingMsg(
              conversationId: conversationId,
              senderId: senderId,
              senderName: senderName,
              content: content,
            );
            debugPrint('✅ [ChatProvider] Đã thêm tin nhắn mới vào giao diện và notifyListeners()!');
          }

          _latestNotification = ChatNotification(
            title: '💬 $senderName',
            message: content,
            conversationId: conversationId,
            time: DateTime.now(),
          );

          notifyListeners();
        }
      },
    );
  }

  /// Đăng ký lắng nghe tin nhắn Realtime toàn ứng dụng cho Seller (kênh global_chat)
  void subscribeGlobalRealtimeChat({required String currentUserId}) {
    if (_chatRepository == null) return;
    _chatRepository!.subscribeRealtimeChat(
      conversationId: 'global_chat',
      onEventReceived: (payload) {
        debugPrint('📩 [ChatProvider Global] NHẬN PAYLOAD GLOBAL WEBSOCKET: $payload');
        if (payload['eventType'] == 'CHAT_MESSAGE_CREATED') {
          final data = payload['payload'] as Map<String, dynamic>? ?? {};
          final senderId = data['senderId']?.toString() ?? '';
          if (senderId == currentUserId) return;

          final conversationId = data['conversationId']?.toString() ?? 'global_chat';
          final content = data['content']?.toString() ?? '';
          final senderName = data['senderName']?.toString() ?? 'Khách mua';

          _updateOrAddConversationOnIncomingMsg(
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            content: content,
          );

          final newMsg = ChatMessageItem(
            id: 'ws_g_${DateTime.now().millisecondsSinceEpoch}',
            senderId: senderId,
            senderName: senderName,
            content: content,
            isMe: false,
            timestamp: DateTime.now(),
          );

          if (!_messagesByConversation.containsKey(conversationId)) {
            _messagesByConversation[conversationId] = [];
          }
          _messagesByConversation[conversationId]!.add(newMsg);

          _latestNotification = ChatNotification(
            title: '💬 $senderName',
            message: content,
            conversationId: conversationId,
            time: DateTime.now(),
          );

          notifyListeners();
        }
      },
    );
  }

  void _updateOrAddConversationOnIncomingMsg({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
  }) {
    final convIdx = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIdx == -1) {
      _conversations.insert(
        0,
        ChatConversation(
          id: conversationId,
          partnerId: senderId,
          partnerName: senderName,
          lastMessage: content,
          lastUpdated: DateTime.now(),
          unreadCount: 1,
          type: ChatType.directSeller,
        ),
      );
    } else {
      final existing = _conversations[convIdx];
      _conversations.removeAt(convIdx);
      _conversations.insert(
        0,
        ChatConversation(
          id: existing.id,
          orderId: existing.orderId,
          partnerId: existing.partnerId,
          partnerName: existing.partnerName,
          partnerAvatar: existing.partnerAvatar,
          lastMessage: content,
          lastUpdated: DateTime.now(),
          unreadCount: existing.unreadCount + 1,
          listingId: existing.listingId,
          listingTitle: existing.listingTitle,
          listingPrice: existing.listingPrice,
          listingThumbnail: existing.listingThumbnail,
          type: existing.type,
        ),
      );
    }
  }

  Future<void> _fetchAndUpdateMessages(String conversationId, String orderId, String currentUserId) async {
    if (_chatRepository == null) return;
    final history = await _chatRepository!.getChatHistory(orderId);
    if (history.isNotEmpty) {
      final currentList = _messagesByConversation[conversationId] ?? [];
      final isDifferent = currentList.length != history.length;
      
      if (isDifferent) {
        _messagesByConversation[conversationId] = history.map((m) {
          return ChatMessageItem(
            id: m.id,
            senderId: m.senderId,
            senderName: m.senderName,
            content: m.content,
            isMe: m.senderId == currentUserId,
            timestamp: m.timestamp,
          );
        }).toList();
        notifyListeners();
      }
    }
  }

  void leaveRealtimeRoom() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _chatRepository?.disconnectWebSocket();
  }

  void _handleAutoReplyAndNotification(
    String conversationId,
    String userText,
    String senderName,
    bool isSeller,
  ) {
    final conv = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => _conversations.first,
    );

    // Nếu người gửi là Người mua nhắn tới Người bán: Tạo thông báo nổi lập tức trên màn hình
    if (!isSeller && conv.type == ChatType.directSeller) {
      _latestNotification = ChatNotification(
        title: 'Tin nhắn mới từ $senderName',
        message: userText,
        conversationId: conversationId,
        time: DateTime.now(),
      );
      notifyListeners();

      // Giả lập Người bán hoặc Bot tự động rep sau 2.5 giây nếu người dùng test 1 mình
      Timer(const Duration(milliseconds: 2500), () {
        if (!_messagesByConversation.containsKey(conversationId)) return;

        String replyText = 'Dạ vâng, tôi đã nhận được thông tin từ bạn. Sản phẩm hiện đang có sẵn tại ao nuôi, bạn có cần giao hàng hỏa tốc trong ngày không ạ?';
        if (userText.toLowerCase().contains('giá') || userText.toLowerCase().contains('bớt') || userText.toLowerCase().contains('giảm')) {
          replyText = 'Về giá cả: Nếu bạn lấy số lượng lớn từ 5.000 con trở lên, trại mình sẽ chiết khấu thêm 5% và hỗ trợ 50% phí vận chuyển sục khí nhé!';
        } else if (userText.toLowerCase().contains('chất lượng') || userText.toLowerCase().contains('ai') || userText.toLowerCase().contains('sức khỏe')) {
          replyText = 'Toàn bộ mẻ cá này đã được quét qua AI Bioscan đạt tỷ lệ sống 99.2%, cá bơi khỏe và kích thước đồng đều ạ!';
        }

        final autoReply = ChatMessageItem(
          id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
          senderId: conv.partnerId,
          senderName: conv.partnerName,
          content: replyText,
          isMe: false,
          timestamp: DateTime.now(),
          productTitle: conv.listingTitle,
          productPrice: conv.listingPrice,
        );

        _messagesByConversation[conversationId]!.add(autoReply);

        final cIdx = _conversations.indexWhere((c) => c.id == conversationId);
        if (cIdx != -1) {
          final old = _conversations[cIdx];
          _conversations.removeAt(cIdx);
          _conversations.insert(
            0,
            ChatConversation(
              id: old.id,
              partnerId: old.partnerId,
              partnerName: old.partnerName,
              partnerAvatar: old.partnerAvatar,
              lastMessage: replyText,
              lastUpdated: DateTime.now(),
              unreadCount: old.unreadCount + 1,
              listingId: old.listingId,
              listingTitle: old.listingTitle,
              listingPrice: old.listingPrice,
              listingThumbnail: old.listingThumbnail,
              type: old.type,
            ),
          );
        }

        // Tạo thông báo tin nhắn đến
        _latestNotification = ChatNotification(
          title: '💬 ${conv.partnerName}',
          message: replyText,
          conversationId: conversationId,
          time: DateTime.now(),
        );

        notifyListeners();
      });
    } else if (conv.type == ChatType.aiAssistant) {
      // AI Assistant Reply
      Timer(const Duration(milliseconds: 1500), () {
        if (!_messagesByConversation.containsKey(conversationId)) return;

        String aiReply = 'AquaTrade AI đã ghi nhận yêu cầu của bạn. Hệ thống đang đối chiếu dữ liệu nuôi trồng theo thời gian thực...';
        if (userText.toLowerCase().contains('giá')) {
          aiReply = '📊 Phân tích giá AI: Giá cá tra và tôm thẻ hiện tại đang có xu hướng tăng nhẹ 3.2% trong tuần này do nhu cầu xuất khẩu tăng.';
        } else if (userText.toLowerCase().contains('đếm') || userText.toLowerCase().contains('ai scan')) {
          aiReply = '🤖 Tính năng Đếm cá AI hỗ trợ độ chính xác lên tới 99.8%. Bạn có thể vào tab "QUÉT AI" ở thanh điều hướng để chụp và đếm trực tiếp.';
        }

        final autoReply = ChatMessageItem(
          id: 'ai_rep_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'system_ai',
          senderName: 'Trợ lý AI AquaTrade',
          content: aiReply,
          isMe: false,
          timestamp: DateTime.now(),
        );

        _messagesByConversation[conversationId]!.add(autoReply);
        final cIdx = _conversations.indexWhere((c) => c.id == conversationId);
        if (cIdx != -1) {
          final old = _conversations[cIdx];
          _conversations.removeAt(cIdx);
          _conversations.insert(
            0,
            ChatConversation(
              id: old.id,
              partnerId: old.partnerId,
              partnerName: old.partnerName,
              partnerAvatar: old.partnerAvatar,
              lastMessage: aiReply,
              lastUpdated: DateTime.now(),
              unreadCount: 0,
              type: old.type,
            ),
          );
        }

        _latestNotification = ChatNotification(
          title: '🤖 Trợ lý AI AquaTrade',
          message: aiReply,
          conversationId: conversationId,
          time: DateTime.now(),
        );

        notifyListeners();
      });
    }
  }

  void clearNotification() {
    _latestNotification = null;
    notifyListeners();
  }

  void markAsRead(String conversationId) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final c = _conversations[idx];
      _conversations[idx] = ChatConversation(
        id: c.id,
        partnerId: c.partnerId,
        partnerName: c.partnerName,
        partnerAvatar: c.partnerAvatar,
        lastMessage: c.lastMessage,
        lastUpdated: c.lastUpdated,
        unreadCount: 0,
        listingId: c.listingId,
        listingTitle: c.listingTitle,
        listingPrice: c.listingPrice,
        listingThumbnail: c.listingThumbnail,
        type: c.type,
      );
      notifyListeners();
    }
  }
}
