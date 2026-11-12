package com.aquatrade.realtime.service;

import com.aquatrade.realtime.dto.RealtimeEvent;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
public class RealtimeBroadcastService {

    private final SimpMessagingTemplate messagingTemplate;

    public RealtimeBroadcastService(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    public void broadcast(String destination, RealtimeEvent event) {
        messagingTemplate.convertAndSend(destination, event);
    }
}
