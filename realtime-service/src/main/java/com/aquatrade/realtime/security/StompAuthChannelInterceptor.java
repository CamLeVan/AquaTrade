package com.aquatrade.realtime.security;

import java.security.Principal;
import java.util.LinkedHashMap;
import java.util.Map;

import com.aquatrade.realtime.config.RealtimeProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class StompAuthChannelInterceptor implements ChannelInterceptor {

    private static final Logger log = LoggerFactory.getLogger(StompAuthChannelInterceptor.class);

    private final RealtimeProperties properties;
    private final JwtService jwtService;
    private final TopicAuthorizationService topicAuthorizationService;

    public StompAuthChannelInterceptor(
            RealtimeProperties properties,
            JwtService jwtService,
            TopicAuthorizationService topicAuthorizationService
    ) {
        this.properties = properties;
        this.jwtService = jwtService;
        this.topicAuthorizationService = topicAuthorizationService;
    }

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null || accessor.getCommand() == null) {
            return message;
        }

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            handleConnect(accessor);
        }
        if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
            handleSubscribe(accessor);
        }
        if (StompCommand.SEND.equals(accessor.getCommand())) {
            handleSend(accessor);
        }
        return message;
    }

    private void handleConnect(StompHeaderAccessor accessor) {
        if (!properties.getSecurity().isAuthEnabled()) {
            return;
        }

        String authorization = accessor.getFirstNativeHeader("Authorization");
        RealtimePrincipal principal = jwtService.authenticate(authorization);
        accessor.setUser(principal);
        sessionAttributes(accessor).put("userId", principal.getName());
        sessionAttributes(accessor).put("roles", principal.getRoles());
        log.info("stomp connect authenticated userId={} roles={}", principal.getName(), principal.getRoles());
    }

    private void handleSubscribe(StompHeaderAccessor accessor) {
        String destination = accessor.getDestination();
        RealtimePrincipal principal = principalFrom(accessor);
        if (!topicAuthorizationService.canSubscribe(destination, principal)) {
            String userId = principal != null ? principal.getName() : "anonymous";
            throw new IllegalArgumentException("Subscription denied destination=" + destination + " userId=" + userId);
        }
    }

    private void handleSend(StompHeaderAccessor accessor) {
        if (!properties.getSecurity().isAuthEnabled()) {
            return;
        }
        if (principalFrom(accessor) == null) {
            throw new IllegalArgumentException("SEND requires authenticated STOMP session");
        }
    }

    private RealtimePrincipal principalFrom(StompHeaderAccessor accessor) {
        Principal principal = accessor.getUser();
        if (principal instanceof RealtimePrincipal realtimePrincipal) {
            return realtimePrincipal;
        }
        Object userId = sessionAttributes(accessor).get("userId");
        if (userId instanceof String userIdText && StringUtils.hasText(userIdText)) {
            return new RealtimePrincipal(userIdText, SetReader.roles(sessionAttributes(accessor).get("roles")));
        }
        return null;
    }

    private Map<String, Object> sessionAttributes(StompHeaderAccessor accessor) {
        Map<String, Object> attributes = accessor.getSessionAttributes();
        if (attributes == null) {
            attributes = new LinkedHashMap<>();
            accessor.setSessionAttributes(attributes);
        }
        return attributes;
    }

    private static final class SetReader {
        private SetReader() {
        }

        static java.util.Set<String> roles(Object raw) {
            java.util.Set<String> roles = new java.util.LinkedHashSet<>();
            if (raw instanceof Iterable<?> iterable) {
                for (Object item : iterable) {
                    if (item != null) {
                        roles.add(item.toString());
                    }
                }
            }
            return roles;
        }
    }
}
