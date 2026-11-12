package com.aquatrade.core.realtime;

import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class RealtimeEventFactory {

    public RealtimeEvent orderEvent(RealtimeEventType eventType, UUID orderId, UUID actorUserId, Map<String, Object> payload) {
        return orderEvent(eventType, orderId, actorUserId, List.of(), payload);
    }

    public RealtimeEvent orderEvent(
            RealtimeEventType eventType,
            UUID orderId,
            UUID actorUserId,
            List<UUID> targetUserIds,
            Map<String, Object> payload
    ) {
        RealtimeEvent event = base(eventType, "ORDER", orderId.toString(), actorUserId, targetUserIds);
        event.setOrderId(orderId.toString());
        event.setPayload(copyPayload(payload));
        return event;
    }

    public RealtimeEvent userNotification(UUID userId, UUID actorUserId, Map<String, Object> payload) {
        RealtimeEvent event = base(RealtimeEventType.USER_NOTIFICATION, "USER", userId.toString(), actorUserId, List.of(userId));
        event.setPayload(copyPayload(payload));
        return event;
    }

    private RealtimeEvent base(
            RealtimeEventType eventType,
            String aggregateType,
            String aggregateId,
            UUID actorUserId,
            List<UUID> targetUserIds
    ) {
        RealtimeEvent event = new RealtimeEvent();
        event.setEventId(UUID.randomUUID().toString());
        event.setEventType(eventType);
        event.setVersion(1);
        event.setOccurredAt(OffsetDateTime.now());
        event.setCorrelationId(UUID.randomUUID().toString());
        event.setAggregateType(aggregateType);
        event.setAggregateId(aggregateId);
        if (actorUserId != null) {
            event.setActorUserId(actorUserId.toString());
        }
        event.setTargetUserIds(targetUserIds.stream().map(UUID::toString).toList());
        return event;
    }

    private Map<String, Object> copyPayload(Map<String, Object> payload) {
        if (payload == null) {
            return new LinkedHashMap<>();
        }
        return new LinkedHashMap<>(payload);
    }
}
