import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../models/chat_model.dart';
import '../services/remote/api_service.dart';

class ChatRepository {
  final ApiService _apiService;
  StompClient? _stompClient;
  final Map<String, Function(Map<String, dynamic>)> _activeSubscriptions = {};

  ChatRepository(this._apiService);

  /// Tải lịch sử chat từ REST API (/api/v1/chat/{orderId}/history)
  Future<List<ChatMessageItem>> getChatHistory(String orderId) async {
    debugPrint('🌐 [ChatRepo] GET Lịch sử Chat orderId: $orderId');
    try {
      final response = await _apiService.get('/chat/$orderId/history');
      final data = response.data;
      debugPrint('📥 [ChatRepo] Lịch sử Chat trả về: ${response.statusCode} | data: $data');
      if (data is Map<String, dynamic> && data['status'] == 'success') {
        final list = data['data'] as List?;
        if (list != null) {
          return list.map((item) {
            final map = item as Map<String, dynamic>;
            final timestampStr = map['timestamp'] as String?;
            DateTime time = DateTime.now();
            if (timestampStr != null) {
              time = DateTime.tryParse(timestampStr) ?? DateTime.now();
            }
            return ChatMessageItem(
              id: 'msg_${time.millisecondsSinceEpoch}_${map['senderId']}',
              senderId: map['senderId']?.toString() ?? '',
              senderName: map['senderName']?.toString() ?? 'Người dùng',
              content: map['content']?.toString() ?? '',
              isMe: false,
              timestamp: time,
              productTitle: map['productTitle']?.toString(),
              productPrice: map['productPrice']?.toString(),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [ChatRepo] Lỗi khi tải lịch sử chat từ Server: $e');
      return [];
    }
  }

  /// Gửi tin nhắn qua REST API (/api/v1/chat/{orderId}/send-api)
  Future<bool> sendMessageApi({
    required String orderId,
    required String content,
    String messageType = 'CHAT',
  }) async {
    debugPrint('📤 [ChatRepo] Gửi REST API orderId: $orderId | content: "$content"');
    try {
      final res = await _apiService.post('/chat/$orderId/send-api', data: {
        'content': content,
        'messageType': messageType,
      });
      debugPrint('✅ [ChatRepo] REST API gửi thành công status: ${res.statusCode}');
      return true;
    } catch (e) {
      debugPrint('❌ [ChatRepo] Lỗi khi gửi tin nhắn API: $e');
      return false;
    }
  }

  /// Khởi tạo và duy trì kết nối STOMP WebSocket thời gian thực liên tục không bị ngắt
  void _ensureStompConnected(VoidCallback onConnectedCallback) {
    if (_stompClient != null && _stompClient!.connected) {
      onConnectedCallback();
      return;
    }

    if (_stompClient != null) {
      _stompClient?.activate();
      return;
    }

    const wsUrl = 'ws://192.168.1.24:8090/ws';
    debugPrint('🚀 [ChatRepo STOMP] Đang kích hoạt kết nối WebSocket liên tục: $wsUrl');

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: (StompFrame frame) {
          debugPrint('✅ [ChatRepo STOMP] KHỞI TẠO KẾT NỐI WEBSOCKET THÀNH CÔNG! Frame: ${frame.command}');
          onConnectedCallback();

          // Tái đăng ký tất cả các kênh chủ đề active
          _activeSubscriptions.forEach((destination, callback) {
            debugPrint('🔄 [ChatRepo STOMP] Subscribing lại kênh: $destination');
            _stompClient?.subscribe(
              destination: destination,
              callback: (StompFrame subFrame) {
                if (subFrame.body != null) {
                  try {
                    final jsonMap = jsonDecode(subFrame.body!) as Map<String, dynamic>;
                    callback(jsonMap);
                  } catch (err) {
                    debugPrint('❌ [ChatRepo STOMP] Lỗi decode JSON WebSocket: $err');
                  }
                }
              },
            );
          });
        },
        onWebSocketError: (dynamic error) => debugPrint('❌ [ChatRepo STOMP] LỖI WEBSOCKET ERROR: $error'),
        onDisconnect: (StompFrame frame) => debugPrint('⚠️ [ChatRepo STOMP] BỊ NGẮT KẾT NỐI DISCONNECTED'),
        onStompError: (StompFrame frame) => debugPrint('❌ [ChatRepo STOMP] LỖI STOMP ERROR: ${frame.body}'),
      ),
    );

    _stompClient?.activate();
  }

  /// Đăng ký kênh WebSocket STOMP
  void subscribeRealtimeChat({
    required String conversationId,
    required Function(Map<String, dynamic> payload) onEventReceived,
  }) {
    final destination = '/topic/orders/$conversationId';
    _activeSubscriptions[destination] = onEventReceived;

    _ensureStompConnected(() {
      debugPrint('📌 [ChatRepo STOMP] Đăng ký kênh STOMP: $destination');
      _stompClient?.subscribe(
        destination: destination,
        callback: (StompFrame subFrame) {
          debugPrint('📩 [ChatRepo STOMP] NHẬN FRAME MỚI từ $destination: ${subFrame.body}');
          if (subFrame.body != null) {
            try {
              final jsonMap = jsonDecode(subFrame.body!) as Map<String, dynamic>;
              onEventReceived(jsonMap);
            } catch (err) {
              debugPrint('❌ [ChatRepo STOMP] Lỗi decode JSON WebSocket: $err');
            }
          }
        },
      );
    });
  }

  /// Gửi tin nhắn trực tiếp qua STOMP WebSocket
  void sendStompMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required String senderName,
  }) {
    final topicDestination = '/topic/orders/$conversationId';

    _ensureStompConnected(() {
      final payloadMap = {
        'eventType': 'CHAT_MESSAGE_CREATED',
        'payload': {
          'conversationId': conversationId,
          'senderId': senderId,
          'senderName': senderName,
          'content': content,
          'messageType': 'CHAT',
          'timestamp': DateTime.now().toIso8601String(),
        }
      };
      final jsonBody = jsonEncode(payloadMap);
      debugPrint('📤 [ChatRepo STOMP] Đang BẮN STOMP tới $topicDestination và /topic/orders/global_chat: $jsonBody');

      _stompClient!.send(
        destination: topicDestination,
        body: jsonBody,
      );
      _stompClient!.send(
        destination: '/topic/orders/global_chat',
        body: jsonBody,
      );
      debugPrint('✅ [ChatRepo STOMP] Bắn STOMP thành công!');
    });
  }

  void disconnectWebSocket() {
    // Không ngắt WebSocket hoàn toàn để giữ kết nối liên tục giữa các màn hình
    debugPrint('ℹ️ [ChatRepo STOMP] Giữ nguyên WebSocket kết nối liên tục.');
  }
}
