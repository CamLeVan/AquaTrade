package com.aquatrade.core.config;

import com.aquatrade.core.security.JwtAuthenticationFilter;
import com.aquatrade.core.security.InternalApiKeyFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final InternalApiKeyFilter internalApiKeyFilter;
    private final org.springframework.web.cors.CorsConfigurationSource corsConfigurationSource;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            // Bật CORS với CorsConfig
            .cors(cors -> cors.configurationSource(corsConfigurationSource))
            // Tắt CSRF (REST API stateless không cần)
            .csrf(csrf -> csrf.disable())
            
            // Stateless session (dùng JWT, không lưu session trên server)
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            
            // Phân quyền endpoint
            .authorizeHttpRequests(auth -> auth
                // === PUBLIC (không cần token) ===
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/api/v1/test/**").permitAll()
                    .requestMatchers("/api/v1/files/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/listings/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/v1/posts/**").permitAll()
                .requestMatchers("/uploads/**").permitAll()

                // === INTERNAL (API Key Auth, không dùng JWT) ===
                .requestMatchers("/api/v1/internal/**").permitAll()

                // === ADMIN ONLY ===
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")

                // === Tất cả endpoint còn lại phải authenticated ===
                .anyRequest().authenticated()
            )
            
            // Gắn JWT Filter chạy TRƯỚC filter mặc định của Spring
            // InternalApiKeyFilter chạy TRƯỚC JWT → chặn /internal/ bằng API Key
            .addFilterBefore(internalApiKeyFilter, UsernamePasswordAuthenticationFilter.class)
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
