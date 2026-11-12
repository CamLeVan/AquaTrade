package com.aquatrade.core.realtime;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

class RealtimeEventPublisherTest {

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();
    private final RealtimeEventFactory factory = new RealtimeEventFactory();

    @Test
    void publishDoesNothingWhenDisabled() {
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        RealtimeEventPublisher publisher = new RealtimeEventPublisher(redisTemplate, objectMapper, false, "aquatrade.events");
        RealtimeEvent event = factory.orderEvent(RealtimeEventType.AI_COUNT_DONE, UUID.randomUUID(), null, Map.of());

        publisher.publish(event);

        verify(redisTemplate, never()).convertAndSend(eq("aquatrade.events"), contains("AI_COUNT_DONE"));
    }

    @Test
    void publishSerializesAndSendsToConfiguredChannelWhenEnabled() {
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        RealtimeEventPublisher publisher = new RealtimeEventPublisher(redisTemplate, objectMapper, true, "aquatrade.events");
        RealtimeEvent event = factory.orderEvent(RealtimeEventType.AI_COUNT_DONE, UUID.randomUUID(), null, Map.of("proofId", "proof-001"));

        publisher.publish(event);

        verify(redisTemplate).convertAndSend(eq("aquatrade.events"), contains("\"eventType\":\"AI_COUNT_DONE\""));
        verify(redisTemplate).convertAndSend(eq("aquatrade.events"), contains("\"proofId\":\"proof-001\""));
    }

    @Test
    void publishWaitsForTransactionCommitWhenTransactionIsActive() {
        StringRedisTemplate redisTemplate = mock(StringRedisTemplate.class);
        RealtimeEventPublisher publisher = new RealtimeEventPublisher(redisTemplate, objectMapper, true, "aquatrade.events");
        RealtimeEvent event = factory.orderEvent(RealtimeEventType.ORDER_STATUS_CHANGED, UUID.randomUUID(), null, Map.of());

        TransactionSynchronizationManager.initSynchronization();
        try {
            publisher.publish(event);

            verify(redisTemplate, never()).convertAndSend(eq("aquatrade.events"), contains("ORDER_STATUS_CHANGED"));
            TransactionSynchronizationManager.getSynchronizations().forEach(synchronization -> synchronization.afterCommit());
            verify(redisTemplate).convertAndSend(eq("aquatrade.events"), contains("\"eventType\":\"ORDER_STATUS_CHANGED\""));
        } finally {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }
}
