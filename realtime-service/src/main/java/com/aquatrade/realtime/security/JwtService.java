package com.aquatrade.realtime.security;

import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.Set;

import com.aquatrade.realtime.config.RealtimeProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class JwtService {

    private final RealtimeProperties properties;

    public JwtService(RealtimeProperties properties) {
        this.properties = properties;
    }

    public RealtimePrincipal authenticate(String authorizationHeader) {
        if (!StringUtils.hasText(authorizationHeader) || !authorizationHeader.startsWith("Bearer ")) {
            throw new IllegalArgumentException("Missing Bearer token");
        }

        String token = authorizationHeader.substring("Bearer ".length()).trim();
        Claims claims = Jwts.parser()
                .verifyWith(secretKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

        String userId = claims.get(properties.getSecurity().getUserIdClaim(), String.class);
        if (!StringUtils.hasText(userId)) {
            userId = claims.getSubject();
        }
        if (!StringUtils.hasText(userId)) {
            throw new IllegalArgumentException("JWT does not contain a user id");
        }

        return new RealtimePrincipal(userId, rolesFrom(claims));
    }

    private SecretKey secretKey() {
        String secret = properties.getSecurity().getJwtSecret();
        if (!StringUtils.hasText(secret) || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("JWT_SECRET must be set and contain at least 32 bytes when realtime auth is enabled");
        }
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    private Set<String> rolesFrom(Claims claims) {
        Set<String> roles = new LinkedHashSet<>();
        addRole(roles, claims.get(properties.getSecurity().getRoleClaim()));
        addRole(roles, claims.get(properties.getSecurity().getRolesClaim()));
        return roles;
    }

    private void addRole(Set<String> roles, Object value) {
        if (value == null) {
            return;
        }
        if (value instanceof String roleText) {
            for (String role : roleText.split(",")) {
                if (StringUtils.hasText(role)) {
                    roles.add(role.trim());
                }
            }
            return;
        }
        if (value instanceof Collection<?> collection) {
            for (Object item : collection) {
                addRole(roles, item);
            }
        }
    }
}
