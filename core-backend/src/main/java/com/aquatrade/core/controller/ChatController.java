package com.aquatrade.core.controller;

import com.aquatrade.core.dto.response.ApiResponse;
import com.aquatrade.core.dto.ChatDto;
import com.aquatrade.core.repository.ChatMessageRepository;
import com.aquatrade.core.domain.ChatMessage;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.realtime.ChatRealtimePublisher;
import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatMessageRepository chatMessageRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final ChatRealtimePublisher chatRealtimePublisher;

    @PostMapping("/{orderId}/send-api")
    public ResponseEntity<ApiResponse<Void>> sendMessageApi(@PathVariable UUID orderId, @RequestBody ChatDto.ChatMessage payload) {
        UUID senderId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
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
        return ResponseEntity.ok(ApiResponse.success(null, "Gửi tin nhắn thành công"));
    }

    @GetMapping("/{orderId}/history")
    public ResponseEntity<ApiResponse<List<ChatDto.ChatMessage>>> getChatHistory(@PathVariable UUID orderId) {
        List<ChatMessage> messages = chatMessageRepository.findByOrderIdOrderByCreatedAtAsc(orderId);
        
        List<ChatDto.ChatMessage> dtos = messages.stream().map(m -> {
            ChatDto.ChatMessage dto = new ChatDto.ChatMessage();
            dto.setSenderId(m.getSender().getId().toString());
            dto.setSenderName(m.getSender().getFullName());
            dto.setContent(m.getContent());
            dto.setMessageType(m.getMessageType());
            dto.setOfferPrice(m.getOfferPrice());
            dto.setOfferStatus(m.getOfferStatus());
            dto.setAiRecommendedPrice(m.getAiRecommendedPrice());
            dto.setTimestamp(m.getCreatedAt());
            return dto;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success(dtos, "Tải lịch sử chat thành công"));
    }
}
