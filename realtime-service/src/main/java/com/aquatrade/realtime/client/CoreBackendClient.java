package com.aquatrade.realtime.client;

import com.aquatrade.realtime.config.RealtimeProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestClient;

@Component
public class CoreBackendClient {

    private static final Logger log = LoggerFactory.getLogger(CoreBackendClient.class);

    private final RealtimeProperties properties;
    private final RestClient restClient;

    public CoreBackendClient(RealtimeProperties properties, RestClient.Builder restClientBuilder) {
        this.properties = properties;
        this.restClient = restClientBuilder
                .baseUrl(properties.getCore().getBaseUrl())
                .build();
    }

    public boolean canAccessOrder(String orderId, String userId) {
        if (!properties.getCore().isAccessCheckEnabled()) {
            return false;
        }
        if (!StringUtils.hasText(properties.getCore().getInternalSecret())) {
            log.warn("core access check is enabled but INTERNAL_API_KEY is empty");
            return false;
        }

        try {
            OrderAccessResponse response = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/api/v1/internal/realtime/orders/{orderId}/access")
                            .queryParam("userId", userId)
                            .build(orderId))
                    .header("X-Internal-Secret", properties.getCore().getInternalSecret())
                    .retrieve()
                    .body(OrderAccessResponse.class);
            return response != null && response.allowed();
        } catch (Exception ex) {
            log.warn("core access check failed orderId={} userId={} error={}", orderId, userId, ex.getMessage());
            return false;
        }
    }

    public record OrderAccessResponse(boolean allowed, String roleInOrder) {
    }
}
