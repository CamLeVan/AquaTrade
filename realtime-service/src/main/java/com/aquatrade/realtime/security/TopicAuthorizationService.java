package com.aquatrade.realtime.security;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.aquatrade.realtime.client.CoreBackendClient;
import com.aquatrade.realtime.config.RealtimeProperties;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class TopicAuthorizationService {

    private static final Pattern ORDER_TOPIC = Pattern.compile("^/topic/orders/([^/]+)$");
    private static final Pattern USER_NOTIFICATION_TOPIC = Pattern.compile("^/topic/users/([^/]+)/notifications$");
    private static final String ADMIN_DISPUTES_TOPIC = "/topic/admin/disputes";

    private final RealtimeProperties properties;
    private final CoreBackendClient coreBackendClient;

    public TopicAuthorizationService(RealtimeProperties properties, CoreBackendClient coreBackendClient) {
        this.properties = properties;
        this.coreBackendClient = coreBackendClient;
    }

    public boolean canSubscribe(String destination, RealtimePrincipal principal) {
        if (!properties.getSecurity().isSubscriptionGuardEnabled()) {
            return true;
        }
        if (!StringUtils.hasText(destination) || principal == null) {
            return false;
        }
        if (principal.hasRole("ADMIN")) {
            return true;
        }
        if (ADMIN_DISPUTES_TOPIC.equals(destination)) {
            return false;
        }

        Matcher userTopicMatcher = USER_NOTIFICATION_TOPIC.matcher(destination);
        if (userTopicMatcher.matches()) {
            return userTopicMatcher.group(1).equals(principal.getName());
        }

        Matcher orderTopicMatcher = ORDER_TOPIC.matcher(destination);
        if (orderTopicMatcher.matches()) {
            return coreBackendClient.canAccessOrder(orderTopicMatcher.group(1), principal.getName());
        }

        return false;
    }
}
