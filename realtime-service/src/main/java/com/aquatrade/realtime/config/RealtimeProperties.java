package com.aquatrade.realtime.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "aquatrade.realtime")
public class RealtimeProperties {

    private List<String> allowedOrigins = new ArrayList<>(List.of(
            "http://localhost:3000",
            "http://localhost:5173",
            "http://localhost:8090"
    ));

    private Redis redis = new Redis();
    private Security security = new Security();
    private Core core = new Core();

    public List<String> getAllowedOrigins() {
        return allowedOrigins;
    }

    public void setAllowedOrigins(List<String> allowedOrigins) {
        this.allowedOrigins = allowedOrigins;
    }

    public Redis getRedis() {
        return redis;
    }

    public void setRedis(Redis redis) {
        this.redis = redis;
    }

    public Security getSecurity() {
        return security;
    }

    public void setSecurity(Security security) {
        this.security = security;
    }

    public Core getCore() {
        return core;
    }

    public void setCore(Core core) {
        this.core = core;
    }

    public static class Redis {
        private boolean enabled;
        private String channel = "aquatrade.events";

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getChannel() {
            return channel;
        }

        public void setChannel(String channel) {
            this.channel = channel;
        }
    }

    public static class Security {
        private boolean authEnabled;
        private boolean subscriptionGuardEnabled;
        private String jwtSecret = "";
        private String userIdClaim = "sub";
        private String roleClaim = "role";
        private String rolesClaim = "roles";

        public boolean isAuthEnabled() {
            return authEnabled;
        }

        public void setAuthEnabled(boolean authEnabled) {
            this.authEnabled = authEnabled;
        }

        public boolean isSubscriptionGuardEnabled() {
            return subscriptionGuardEnabled;
        }

        public void setSubscriptionGuardEnabled(boolean subscriptionGuardEnabled) {
            this.subscriptionGuardEnabled = subscriptionGuardEnabled;
        }

        public String getJwtSecret() {
            return jwtSecret;
        }

        public void setJwtSecret(String jwtSecret) {
            this.jwtSecret = jwtSecret;
        }

        public String getUserIdClaim() {
            return userIdClaim;
        }

        public void setUserIdClaim(String userIdClaim) {
            this.userIdClaim = userIdClaim;
        }

        public String getRoleClaim() {
            return roleClaim;
        }

        public void setRoleClaim(String roleClaim) {
            this.roleClaim = roleClaim;
        }

        public String getRolesClaim() {
            return rolesClaim;
        }

        public void setRolesClaim(String rolesClaim) {
            this.rolesClaim = rolesClaim;
        }
    }

    public static class Core {
        private boolean accessCheckEnabled;
        private String baseUrl = "http://localhost:8080";
        private String internalSecret = "";

        public boolean isAccessCheckEnabled() {
            return accessCheckEnabled;
        }

        public void setAccessCheckEnabled(boolean accessCheckEnabled) {
            this.accessCheckEnabled = accessCheckEnabled;
        }

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public String getInternalSecret() {
            return internalSecret;
        }

        public void setInternalSecret(String internalSecret) {
            this.internalSecret = internalSecret;
        }
    }
}
