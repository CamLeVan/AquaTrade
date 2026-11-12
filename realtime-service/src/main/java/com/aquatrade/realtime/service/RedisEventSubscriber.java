package com.aquatrade.realtime.service;

import java.nio.charset.StandardCharsets;

import com.aquatrade.realtime.config.RealtimeProperties;
import com.aquatrade.realtime.dto.RealtimeEvent;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.connection.Message;
import org.springframework.data.redis.connection.MessageListener;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "aquatrade.realtime.redis", name = "enabled", havingValue = "true")
public class RedisEventSubscriber implements MessageListener {

    private static final Logger log = LoggerFactory.getLogger(RedisEventSubscriber.class);

    private final ObjectMapper objectMapper;
    private final EventRouter eventRouter;
    private final RealtimeProperties properties;

    public RedisEventSubscriber(ObjectMapper objectMapper, EventRouter eventRouter, RealtimeProperties properties) {
        this.objectMapper = objectMapper;
        this.eventRouter = eventRouter;
        this.properties = properties;
    }

    @Override
    public void onMessage(Message message, byte[] pattern) {
        String body = new String(message.getBody(), StandardCharsets.UTF_8);
        try {
            RealtimeEvent event = objectMapper.readValue(body, RealtimeEvent.class);
            eventRouter.route(event);
        } catch (Exception ex) {
            log.error(
                    "Invalid realtime event from Redis channel={} error={} body={}",
                    properties.getRedis().getChannel(),
                    ex.getMessage(),
                    body
            );
        }
    }
}
