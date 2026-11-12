package com.aquatrade.core.realtime;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Component
public class RealtimeEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(RealtimeEventPublisher.class);

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final boolean enabled;
    private final String channel;

    public RealtimeEventPublisher(
            StringRedisTemplate redisTemplate,
            ObjectMapper objectMapper,
            @Value("${aquatrade.realtime.enabled:false}") boolean enabled,
            @Value("${aquatrade.realtime.channel:aquatrade.events}") String channel
    ) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
        this.enabled = enabled;
        this.channel = channel;
    }

    public void publish(RealtimeEvent event) {
        if (!enabled) {
            log.debug("realtime publisher disabled eventType={} aggregateId={}", event.getEventType(), event.getAggregateId());
            return;
        }

        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    publishNow(event);
                }
            });
            return;
        }

        publishNow(event);
    }

    private void publishNow(RealtimeEvent event) {
        try {
            String body = objectMapper.writeValueAsString(event);
            redisTemplate.convertAndSend(channel, body);
            log.info(
                    "published realtime eventId={} eventType={} aggregateId={} channel={}",
                    event.getEventId(),
                    event.getEventType(),
                    event.getAggregateId(),
                    channel
            );
        } catch (JsonProcessingException | RuntimeException ex) {
            log.warn(
                    "failed to publish realtime eventId={} eventType={} aggregateId={} channel={} error={}",
                    event.getEventId(),
                    event.getEventType(),
                    event.getAggregateId(),
                    channel,
                    ex.getMessage()
            );
        }
    }
}
