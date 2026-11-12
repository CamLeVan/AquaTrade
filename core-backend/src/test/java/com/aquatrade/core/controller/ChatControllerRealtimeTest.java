package com.aquatrade.core.controller;

import com.aquatrade.core.domain.ChatMessage;
import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.MessageType;
import com.aquatrade.core.dto.ChatDto;
import com.aquatrade.core.realtime.ChatRealtimePublisher;
import com.aquatrade.core.repository.ChatMessageRepository;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class ChatControllerRealtimeTest {

    @Mock private ChatMessageRepository chatMessageRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private UserRepository userRepository;
    @Mock private ChatRealtimePublisher chatRealtimePublisher;

    private ChatController controller;
    private UUID orderId;
    private UUID senderId;

    @BeforeEach
    void setUp() {
        controller = new ChatController(chatMessageRepository, orderRepository, userRepository, chatRealtimePublisher);
        orderId = UUID.randomUUID();
        senderId = UUID.randomUUID();

        Authentication auth = mock(Authentication.class);
        SecurityContext securityContext = mock(SecurityContext.class);
        given(securityContext.getAuthentication()).willReturn(auth);
        given(auth.getPrincipal()).willReturn(senderId);
        SecurityContextHolder.setContext(securityContext);
    }

    @Test
    void sendMessageApiPublishesRealtimeEventAfterSaving() {
        Order order = new Order();
        order.setId(orderId);
        User sender = User.builder().fullName("Sender").build();
        sender.setId(senderId);
        ChatMessage saved = ChatMessage.builder()
                .order(order)
                .sender(sender)
                .content("hello")
                .messageType(MessageType.TEXT)
                .build();
        saved.setId(UUID.randomUUID());

        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(userRepository.findById(senderId)).willReturn(Optional.of(sender));
        given(chatMessageRepository.save(any(ChatMessage.class))).willReturn(saved);

        ChatDto.ChatMessage payload = new ChatDto.ChatMessage();
        payload.setContent("hello");
        payload.setMessageType(MessageType.TEXT);
        controller.sendMessageApi(orderId, payload);

        verify(chatRealtimePublisher).publishMessageCreated(orderId, saved);
    }
}
