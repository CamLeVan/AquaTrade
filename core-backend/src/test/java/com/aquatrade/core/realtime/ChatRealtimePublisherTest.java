package com.aquatrade.core.realtime;

import com.aquatrade.core.domain.ChatMessage;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.MessageType;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class ChatRealtimePublisherTest {

    @Test
    void publishMessageCreatedBuildsChatEventEnvelope() {
        RealtimeEventPublisher eventPublisher = mock(RealtimeEventPublisher.class);
        ChatRealtimePublisher publisher = new ChatRealtimePublisher(new RealtimeEventFactory(), eventPublisher);
        UUID orderId = UUID.randomUUID();
        UUID senderId = UUID.randomUUID();
        UUID messageId = UUID.randomUUID();
        User sender = User.builder().fullName("Sender").build();
        sender.setId(senderId);
        ChatMessage chatMessage = ChatMessage.builder()
                .sender(sender)
                .messageType(MessageType.TEXT)
                .content("hello")
                .build();
        chatMessage.setId(messageId);

        publisher.publishMessageCreated(orderId, chatMessage);

        ArgumentCaptor<RealtimeEvent> captor = ArgumentCaptor.forClass(RealtimeEvent.class);
        verify(eventPublisher).publish(captor.capture());
        RealtimeEvent event = captor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.CHAT_MESSAGE_CREATED);
        assertThat(event.getOrderId()).isEqualTo(orderId.toString());
        assertThat(event.getActorUserId()).isEqualTo(senderId.toString());
        assertThat(event.getPayload()).containsEntry("messageId", messageId);
        assertThat(event.getPayload()).containsEntry("senderId", senderId);
        assertThat(event.getPayload()).containsEntry("senderName", "Sender");
        assertThat(event.getPayload()).containsEntry("messageType", "TEXT");
        assertThat(event.getPayload()).containsEntry("content", "hello");
    }
}
