import 'package:flutter/foundation.dart';

enum ChatType { aiAssistant, directSeller }

class ChatMessageItem {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final bool isMe;
  final DateTime timestamp;
  final String? productTitle;
  final String? productPrice;

  ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.isMe,
    required this.timestamp,
    this.productTitle,
    this.productPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'isMe': isMe,
    'timestamp': timestamp.toIso8601String(),
    'productTitle': productTitle,
    'productPrice': productPrice,
  };

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) => ChatMessageItem(
    id: json['id'] as String,
    senderId: json['senderId'] as String,
    senderName: json['senderName'] as String,
    content: json['content'] as String,
    isMe: json['isMe'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    productTitle: json['productTitle'] as String?,
    productPrice: json['productPrice'] as String?,
  );
}

class ChatConversation {
  final String id; // ID hội thoại (VD: buyerId_sellerId_listingId hoặc orderId)
  final String? orderId; // UUID của đơn hàng nếu là chat P2P theo đơn
  final String partnerId; // ID người đối thoại
  final String partnerName; // Tên người đối thoại
  final String? partnerAvatar;
  final String lastMessage;
  final DateTime lastUpdated;
  final int unreadCount;
  final String? listingId;
  final String? listingTitle;
  final String? listingPrice;
  final String? listingThumbnail;
  final ChatType type;

  ChatConversation({
    required this.id,
    this.orderId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatar,
    required this.lastMessage,
    required this.lastUpdated,
    this.unreadCount = 0,
    this.listingId,
    this.listingTitle,
    this.listingPrice,
    this.listingThumbnail,
    this.type = ChatType.directSeller,
  });
}
