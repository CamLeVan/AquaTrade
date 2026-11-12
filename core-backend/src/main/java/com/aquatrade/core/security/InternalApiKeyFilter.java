package com.aquatrade.core.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * [SECURITY FIX #4] Bộ lọc xác thực Internal API Key cho Webhook AI.
 * Python AI Service phải gửi Header "X-Internal-Secret" khớp với giá trị cấu hình
 * thì mới được phép gọi /api/v1/internal/**.
 * 
 * Nếu request KHÔNG phải /internal/ → bỏ qua, để JWT Filter xử lý như bình thường.
 */
@Component
public class InternalApiKeyFilter extends OncePerRequestFilter {

    @Value("${aquatrade.internal.api-key:}")
    private String expectedApiKey;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String path = request.getRequestURI();

        // Chỉ chặn các request tới endpoint nội bộ /internal/
        if (path.startsWith("/api/v1/internal/")) {
            String providedKey = request.getHeader("X-Internal-Secret");

            if (expectedApiKey == null || expectedApiKey.isBlank()
                    || providedKey == null || !providedKey.equals(expectedApiKey)) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json");
                response.getWriter().write("{\"status\":\"error\",\"message\":\"Invalid or missing Internal API Key. Access Denied.\"}");
                return; // Chặn cứng, không cho đi tiếp
            }
        }

        // Nếu không phải /internal/ hoặc key hợp lệ → cho đi tiếp pipeline
        filterChain.doFilter(request, response);
    }
}
