package com.aquatrade.core.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Slf4j
@Component
public class JwtProvider {

    private final SecretKey key;
    private final long defaultExpiration;
    private final long rememberExpiration;

    public JwtProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration.default}") long defaultExpiration,
            @Value("${jwt.expiration.remember}") long rememberExpiration) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.defaultExpiration = defaultExpiration;
        this.rememberExpiration = rememberExpiration;
    }

    /**
     * Tạo JWT Access Token (Mặc định siêu ngắn: 15 phút).
     * @param userId UUID của user
     * @param role   Role string (BUYER/SELLER/ADMIN)
     */
    public String generateAccessToken(UUID userId, String role) {
        return Jwts.builder()
                .subject(userId.toString())
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + defaultExpiration)) // ~15 phút
                .signWith(key)
                .compact();
    }

    /**
     * Xác thực token hợp lệ hay không.
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true;
        } catch (ExpiredJwtException e) {
            log.warn("JWT đã hết hạn: {}", e.getMessage());
        } catch (JwtException e) {
            log.warn("JWT không hợp lệ: {}", e.getMessage());
        }
        return false;
    }

    /**
     * Lấy userId từ token payload.
     */
    public UUID getUserIdFromToken(String token) {
        Claims claims = Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload();
        return UUID.fromString(claims.getSubject());
    }

    /**
     * Lấy role từ token payload.
     */
    public String getRoleFromToken(String token) {
        Claims claims = Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload();
        return claims.get("role", String.class);
    }
}
