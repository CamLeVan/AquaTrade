package com.aquatrade.realtime.service;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.aquatrade.realtime.dto.EventType;
import com.aquatrade.realtime.dto.RealtimeEvent;
import com.aquatrade.realtime.dto.dev.AiCountDoneDevRequest;
import com.aquatrade.realtime.dto.dev.AiCountFailedDevRequest;
import com.aquatrade.realtime.dto.dev.ChatMessageDevRequest;
import com.aquatrade.realtime.dto.dev.DisputeCreatedDevRequest;
import com.aquatrade.realtime.dto.dev.OrderStatusDevRequest;
import com.aquatrade.realtime.dto.dev.UserNotificationDevRequest;
import com.aquatrade.realtime.support.InvalidRealtimeEventException;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class RealtimeEventFactory {

    public RealtimeEvent orderStatusChanged(OrderStatusDevRequest request) {
        RealtimeEvent event = baseOrderEvent(
                EventType.ORDER_STATUS_CHANGED,
                request.orderId(),
                request.actorUserId(),
                request.targetUserIds()
        );
        put(event.getPayload(), "previousStatus", request.previousStatus());
        put(event.getPayload(), "newStatus", request.newStatus());
        put(event.getPayload(), "message", request.message());
        return event;
    }

    public RealtimeEvent aiCountDone(AiCountDoneDevRequest request) {
        RealtimeEvent event = baseOrderEvent(
                EventType.AI_COUNT_DONE,
                request.orderId(),
                textOrDefault(request.actorUserId(), "system-ai"),
                request.targetUserIds()
        );
        put(event.getPayload(), "proofId", request.proofId());
        put(event.getPayload(), "proofRole", request.proofRole());
        put(event.getPayload(), "aiFishCount", request.aiFishCount());
        put(event.getPayload(), "healthScore", request.healthScore());
        put(event.getPayload(), "qualityStatus", request.qualityStatus());
        put(event.getPayload(), "aiImageUrl", request.aiImageUrl());
        put(event.getPayload(), "message", request.message());
        return event;
    }

    public RealtimeEvent aiCountFailed(AiCountFailedDevRequest request) {
        RealtimeEvent event = baseOrderEvent(
                EventType.AI_COUNT_FAILED,
                request.orderId(),
                textOrDefault(request.actorUserId(), "system-ai"),
                request.targetUserIds()
        );
        put(event.getPayload(), "proofId", request.proofId());
        put(event.getPayload(), "reason", request.reason());
        put(event.getPayload(), "message", request.message());
        return event;
    }

    public RealtimeEvent chatMessageCreated(ChatMessageDevRequest request) {
        RealtimeEvent event = baseOrderEvent(
                EventType.CHAT_MESSAGE_CREATED,
                request.orderId(),
                request.senderId(),
                request.targetUserIds()
        );
        put(event.getPayload(), "messageId", textOrDefault(request.messageId(), UUID.randomUUID().toString()));
        put(event.getPayload(), "senderId", request.senderId());
        put(event.getPayload(), "senderName", request.senderName());
        put(event.getPayload(), "messageType", textOrDefault(request.messageType(), "TEXT"));
        put(event.getPayload(), "content", request.content());
        put(event.getPayload(), "offerPrice", request.offerPrice());
        put(event.getPayload(), "offerStatus", request.offerStatus());
        return event;
    }

    public RealtimeEvent userNotification(UserNotificationDevRequest request) {
        List<String> targetUserIds = normalizeTargets(request.targetUserIds());
        if (StringUtils.hasText(request.userId()) && !targetUserIds.contains(request.userId())) {
            targetUserIds.add(request.userId());
        }
        if (targetUserIds.isEmpty()) {
            throw new InvalidRealtimeEventException("Invalid realtime event: user notification needs userId or targetUserIds");
        }

        RealtimeEvent event = base(
                EventType.USER_NOTIFICATION,
                "USER",
                targetUserIds.get(0),
                null,
                "system",
                targetUserIds
        );
        put(event.getPayload(), "title", request.title());
        put(event.getPayload(), "message", request.message());
        put(event.getPayload(), "level", textOrDefault(request.level(), "INFO"));
        put(event.getPayload(), "actionUrl", request.actionUrl());
        return event;
    }

    public RealtimeEvent disputeCreated(DisputeCreatedDevRequest request) {
        RealtimeEvent event = baseOrderEvent(
                EventType.DISPUTE_CREATED,
                request.orderId(),
                request.actorUserId(),
                request.targetUserIds()
        );
        put(event.getPayload(), "reason", request.reason());
        put(event.getPayload(), "severity", request.severity());
        put(event.getPayload(), "message", request.message());
        return event;
    }

    public void fillMissingDevEnvelope(RealtimeEvent event) {
        if (event == null) {
            throw new InvalidRealtimeEventException("Invalid realtime event: body is required");
        }
        if (!StringUtils.hasText(event.getEventId())) {
            event.setEventId(UUID.randomUUID().toString());
        }
        if (event.getVersion() == null) {
            event.setVersion(1);
        }
        if (event.getOccurredAt() == null) {
            event.setOccurredAt(OffsetDateTime.now());
        }
        if (!StringUtils.hasText(event.getCorrelationId())) {
            event.setCorrelationId(UUID.randomUUID().toString());
        }
        if (event.getPayload() == null) {
            event.setPayload(new LinkedHashMap<>());
        }
        if (event.getTargetUserIds() == null) {
            event.setTargetUserIds(new ArrayList<>());
        }
        if (!StringUtils.hasText(event.getAggregateType()) && event.getEventType() != null) {
            event.setAggregateType(defaultAggregateType(event.getEventType()));
        }
        if (!StringUtils.hasText(event.getAggregateId())) {
            if (StringUtils.hasText(event.getOrderId())) {
                event.setAggregateId(event.getOrderId());
            } else if (event.getTargetUserIds() != null && event.getTargetUserIds().size() == 1) {
                event.setAggregateId(event.getTargetUserIds().get(0));
            }
        }
    }

    private RealtimeEvent baseOrderEvent(
            EventType eventType,
            String orderId,
            String actorUserId,
            List<String> targetUserIds
    ) {
        return base(eventType, "ORDER", orderId, orderId, actorUserId, targetUserIds);
    }

    private RealtimeEvent base(
            EventType eventType,
            String aggregateType,
            String aggregateId,
            String orderId,
            String actorUserId,
            List<String> targetUserIds
    ) {
        RealtimeEvent event = new RealtimeEvent();
        event.setEventId(UUID.randomUUID().toString());
        event.setEventType(eventType);
        event.setVersion(1);
        event.setOccurredAt(OffsetDateTime.now());
        event.setCorrelationId(UUID.randomUUID().toString());
        event.setAggregateType(aggregateType);
        event.setAggregateId(aggregateId);
        event.setOrderId(orderId);
        event.setActorUserId(actorUserId);
        event.setTargetUserIds(normalizeTargets(targetUserIds));
        event.setPayload(new LinkedHashMap<>());
        return event;
    }

    private List<String> normalizeTargets(List<String> targetUserIds) {
        List<String> result = new ArrayList<>();
        if (targetUserIds == null) {
            return result;
        }
        for (String targetUserId : targetUserIds) {
            if (StringUtils.hasText(targetUserId)) {
                result.add(targetUserId);
            }
        }
        return result;
    }

    private String defaultAggregateType(EventType eventType) {
        if (eventType == EventType.USER_NOTIFICATION) {
            return "USER";
        }
        return "ORDER";
    }

    private void put(Map<String, Object> payload, String key, Object value) {
        if (value != null) {
            payload.put(key, value);
        }
    }

    private String textOrDefault(String value, String fallback) {
        return StringUtils.hasText(value) ? value : fallback;
    }
}
