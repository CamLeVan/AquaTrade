package com.aquatrade.realtime.controller;

import com.aquatrade.realtime.dto.RealtimeEvent;
import com.aquatrade.realtime.dto.RouteResult;
import com.aquatrade.realtime.dto.dev.AiCountDoneDevRequest;
import com.aquatrade.realtime.dto.dev.AiCountFailedDevRequest;
import com.aquatrade.realtime.dto.dev.ChatMessageDevRequest;
import com.aquatrade.realtime.dto.dev.DisputeCreatedDevRequest;
import com.aquatrade.realtime.dto.dev.OrderStatusDevRequest;
import com.aquatrade.realtime.dto.dev.UserNotificationDevRequest;
import com.aquatrade.realtime.service.EventRouter;
import com.aquatrade.realtime.service.RealtimeEventFactory;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/dev/events")
@Validated
public class DevEventController {

    private final RealtimeEventFactory eventFactory;
    private final EventRouter eventRouter;

    public DevEventController(RealtimeEventFactory eventFactory, EventRouter eventRouter) {
        this.eventFactory = eventFactory;
        this.eventRouter = eventRouter;
    }

    @PostMapping
    public RouteResult publishGeneric(@RequestBody RealtimeEvent event) {
        eventFactory.fillMissingDevEnvelope(event);
        return eventRouter.route(event);
    }

    @PostMapping("/order-status")
    public RouteResult publishOrderStatus(@Valid @RequestBody OrderStatusDevRequest request) {
        return eventRouter.route(eventFactory.orderStatusChanged(request));
    }

    @PostMapping("/ai-count-done")
    public RouteResult publishAiCountDone(@Valid @RequestBody AiCountDoneDevRequest request) {
        return eventRouter.route(eventFactory.aiCountDone(request));
    }

    @PostMapping("/ai-count-failed")
    public RouteResult publishAiCountFailed(@Valid @RequestBody AiCountFailedDevRequest request) {
        return eventRouter.route(eventFactory.aiCountFailed(request));
    }

    @PostMapping("/chat-message")
    public RouteResult publishChatMessage(@Valid @RequestBody ChatMessageDevRequest request) {
        return eventRouter.route(eventFactory.chatMessageCreated(request));
    }

    @PostMapping("/user-notification")
    public RouteResult publishUserNotification(@RequestBody UserNotificationDevRequest request) {
        return eventRouter.route(eventFactory.userNotification(request));
    }

    @PostMapping("/dispute-created")
    public RouteResult publishDisputeCreated(@Valid @RequestBody DisputeCreatedDevRequest request) {
        return eventRouter.route(eventFactory.disputeCreated(request));
    }
}
