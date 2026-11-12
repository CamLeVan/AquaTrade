package com.aquatrade.core.realtime;

import com.aquatrade.core.domain.ChatMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ChatRealtimePublisher {

    private final RealtimeEventFactory realtimeEventFactory;
    private final RealtimeEventPublisher realtimeEventPublisher;

    public void publishMessageCreated(UUID orderId, ChatMessage chatMessage) {
        Map<String, Object> payload = new HashMap<>();
        putIfNotNull(payload, "messageId", chatMessage.getId());
        putIfNotNull(payload, "senderId", chatMessage.getSender() != null ? chatMessage.getSender().getId() : null);
        putIfNotNull(payload, "senderName", chatMessage.getSender() != null ? chatMessage.getSender().getFullName() : null);
        putIfNotNull(payload, "messageType", chatMessage.getMessageType() != null ? chatMessage.getMessageType().name() : null);
        putIfNotNull(payload, "content", chatMessage.getContent());
        putIfNotNull(payload, "offerPrice", chatMessage.getOfferPrice());
        putIfNotNull(payload, "offerStatus", chatMessage.getOfferStatus() != null ? chatMessage.getOfferStatus().name() : null);
        putIfNotNull(payload, "aiRecommendedPrice", chatMessage.getAiRecommendedPrice());
        putIfNotNull(payload, "createdAt", chatMessage.getCreatedAt());

        UUID actorUserId = chatMessage.getSender() != null ? chatMessage.getSender().getId() : null;
        RealtimeEvent event = realtimeEventFactory.orderEvent(
                RealtimeEventType.CHAT_MESSAGE_CREATED,
                orderId,
                actorUserId,
                payload
        );
        realtimeEventPublisher.publish(event);
    }

    private void putIfNotNull(Map<String, Object> payload, String key, Object value) {
        if (value != null) {
            payload.put(key, value);
        }
    }
}
