package com.aquatrade.core.controller;

import com.aquatrade.core.dto.ChatDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.time.LocalDateTime;
import com.aquatrade.core.repository.ChatMessageRepository;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.realtime.ChatRealtimePublisher;
import com.aquatrade.core.domain.ChatMessage;
import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.User;

@Slf4j
@Controller
@RequiredArgsConstructor
public class ChatWebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatMessageRepository chatMessageRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final ChatRealtimePublisher chatRealtimePublisher;

    @MessageMapping("/chat/{orderId}/send")
    @Transactional
    public void sendMessage(@DestinationVariable UUID orderId, @Payload ChatDto.ChatMessage payload, java.security.Principal principal) {
        log.info("Nhận tin nhắn socket vào room Order {}: {}", orderId, payload.getContent());

        try {
            // Security Fix: Prevent spoofing by getting sender ID directly from authenticated Principal
            if (principal == null) {
                throw new org.springframework.security.access.AccessDeniedException("Unauthenticated request");
            }
            UUID senderId = UUID.fromString(principal.getName());

            Order order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));
            User sender = userRepository.findById(senderId)
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người gửi"));

            ChatMessage chatMessage = ChatMessage.builder()
                    .order(order)
                    .sender(sender)
                    .content(payload.getContent())
                    .messageType(payload.getMessageType())
                    .offerPrice(payload.getOfferPrice())
                    .offerStatus(payload.getOfferStatus())
                    .aiRecommendedPrice(payload.getAiRecommendedPrice())
                    .build();

            chatMessage = chatMessageRepository.save(chatMessage);
            chatRealtimePublisher.publishMessageCreated(orderId, chatMessage);
            
            // Set timestamp back to payload
            payload.setTimestamp(chatMessage.getCreatedAt() != null ? chatMessage.getCreatedAt() : LocalDateTime.now());

            messagingTemplate.convertAndSend("/topic/orders/" + orderId, payload);
        } catch (Exception e) {
            log.error("Lỗi khi lưu tin nhắn chat: {}", e.getMessage());
            // Optionally, we could send an error message back to the user via a separate topic
        }
    }

    @MessageMapping("/chat/{orderId}/preview")
    public void handleTypingPreview(@DestinationVariable UUID orderId, @Payload ChatDto.ChatMessage payload) {
        // Chỉ chuyển tiếp (broadcast), không lưu DB để đảm bảo hiệu năng
        messagingTemplate.convertAndSend("/topic/orders/" + orderId, payload);
    }
}
