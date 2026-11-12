package com.aquatrade.realtime.service;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.aquatrade.realtime.dto.EventType;
import com.aquatrade.realtime.dto.RealtimeEvent;
import com.aquatrade.realtime.dto.RouteResult;
import com.aquatrade.realtime.support.InvalidRealtimeEventException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class EventRouter {

    private static final Logger log = LoggerFactory.getLogger(EventRouter.class);

    private static final EnumSet<EventType> ORDER_EVENTS = EnumSet.of(
            EventType.ORDER_CREATED,
            EventType.ORDER_STATUS_CHANGED,
            EventType.AI_COUNT_STARTED,
            EventType.AI_COUNT_DONE,
            EventType.AI_COUNT_FAILED,
            EventType.CHAT_MESSAGE_CREATED,
            EventType.PAYOUT_APPROVED
    );

    private final RealtimeBroadcastService broadcastService;

    public EventRouter(RealtimeBroadcastService broadcastService) {
        this.broadcastService = broadcastService;
    }

    public RouteResult route(RealtimeEvent event) {
        validateEnvelope(event);
        List<String> destinations = destinationsFor(event);
        if (destinations.isEmpty()) {
            throw new InvalidRealtimeEventException("Invalid realtime event: no route for eventType=" + event.getEventType());
        }

        for (String destination : destinations) {
            log.info(
                    "route realtime eventId={} eventType={} orderId={} userIds={} destination={} correlationId={}",
                    event.getEventId(),
                    event.getEventType(),
                    event.getOrderId(),
                    event.getTargetUserIds(),
                    destination,
                    event.getCorrelationId()
            );
            broadcastService.broadcast(destination, event);
        }

        return new RouteResult(event, destinations);
    }

    private void validateEnvelope(RealtimeEvent event) {
        if (event == null) {
            throw new InvalidRealtimeEventException("Invalid realtime event: body is required");
        }
        if (!StringUtils.hasText(event.getEventId())) {
            throw new InvalidRealtimeEventException("Invalid realtime event: missing eventId");
        }
        if (event.getEventType() == null) {
            throw new InvalidRealtimeEventException("Invalid realtime event: missing eventType");
        }
        if (!StringUtils.hasText(event.getAggregateId())) {
            throw new InvalidRealtimeEventException("Invalid realtime event: missing aggregateId");
        }
    }

    private List<String> destinationsFor(RealtimeEvent event) {
        Set<String> destinations = new LinkedHashSet<>();
        if (ORDER_EVENTS.contains(event.getEventType())) {
            requireOrderId(event);
            destinations.add(orderTopic(event.getOrderId()));
            destinations.add("/topic/admin/orders");
        }
        if (event.getEventType() == EventType.DISPUTE_CREATED) {
            requireOrderId(event);
            destinations.add(orderTopic(event.getOrderId()));
            destinations.add("/topic/admin/disputes");
            destinations.add("/topic/admin/orders");
        }
        if (event.getEventType() == EventType.USER_NOTIFICATION) {
            List<String> userIds = normalizedUserTargets(event);
            if (userIds.isEmpty()) {
                throw new InvalidRealtimeEventException("Invalid realtime event: USER_NOTIFICATION needs targetUserIds or aggregateId");
            }
            for (String userId : userIds) {
                destinations.add("/topic/users/" + userId + "/notifications");
            }
        }
        return new ArrayList<>(destinations);
    }

    private void requireOrderId(RealtimeEvent event) {
        if (!StringUtils.hasText(event.getOrderId())) {
            throw new InvalidRealtimeEventException("Invalid realtime event: " + event.getEventType() + " needs orderId");
        }
    }

    private List<String> normalizedUserTargets(RealtimeEvent event) {
        List<String> userIds = new ArrayList<>();
        if (event.getTargetUserIds() != null) {
            for (String userId : event.getTargetUserIds()) {
                if (StringUtils.hasText(userId)) {
                    userIds.add(userId);
                }
            }
        }
        if (userIds.isEmpty() && StringUtils.hasText(event.getAggregateId())) {
            userIds.add(event.getAggregateId());
        }
        return userIds;
    }

    private String orderTopic(String orderId) {
        return "/topic/orders/" + orderId;
    }
}
