package com.aquatrade.realtime;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Type;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import com.aquatrade.realtime.dto.EventType;
import com.aquatrade.realtime.dto.RealtimeEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.converter.MappingJackson2MessageConverter;
import org.springframework.messaging.simp.stomp.StompFrameHandler;
import org.springframework.messaging.simp.stomp.StompHeaders;
import org.springframework.messaging.simp.stomp.StompSession;
import org.springframework.messaging.simp.stomp.StompSessionHandlerAdapter;
import org.springframework.web.socket.client.standard.StandardWebSocketClient;
import org.springframework.web.socket.messaging.WebSocketStompClient;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class RealtimeSmokeTest {

    @LocalServerPort
    private int port;

    private final TestRestTemplate restTemplate = new TestRestTemplate();

    @Test
    void devEventBroadcastsToSubscribedOrderTopic() throws Exception {
        WebSocketStompClient stompClient = new WebSocketStompClient(new StandardWebSocketClient());
        MappingJackson2MessageConverter messageConverter = new MappingJackson2MessageConverter();
        messageConverter.setObjectMapper(new ObjectMapper().registerModule(new JavaTimeModule()));
        stompClient.setMessageConverter(messageConverter);

        CompletableFuture<RealtimeEvent> received = new CompletableFuture<>();
        StompSession session = stompClient
                .connectAsync("ws://localhost:" + port + "/ws", new StompSessionHandlerAdapter() {
                })
                .get(5, TimeUnit.SECONDS);

        session.subscribe("/topic/orders/test-order-001", new StompFrameHandler() {
            @Override
            public Type getPayloadType(StompHeaders headers) {
                return RealtimeEvent.class;
            }

            @Override
            public void handleFrame(StompHeaders headers, Object payload) {
                received.complete((RealtimeEvent) payload);
            }
        });

        ResponseEntity<String> response = restTemplate.postForEntity(
                "http://localhost:" + port + "/dev/events/ai-count-done",
                Map.of(
                        "orderId", "test-order-001",
                        "proofId", "proof-001",
                        "proofRole", "SELLER",
                        "aiFishCount", 5050,
                        "healthScore", 92,
                        "qualityStatus", "NORMAL",
                        "message", "AI da dem xong"
                ),
                String.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);

        RealtimeEvent event = received.get(5, TimeUnit.SECONDS);
        assertThat(event.getEventType()).isEqualTo(EventType.AI_COUNT_DONE);
        assertThat(event.getOrderId()).isEqualTo("test-order-001");
        assertThat(event.getPayload()).containsEntry("aiFishCount", 5050);

        session.disconnect();
    }
}
