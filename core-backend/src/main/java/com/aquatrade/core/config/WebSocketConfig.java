package com.aquatrade.core.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // Tái tạo RabbitMQ/ActiveMQ trên RAM local: Kênh bắt đầu bằng /topic
        config.enableSimpleBroker("/topic");
        // API Frontend publish tin nhắn gửi lên backend sẽ có tiền tố /app
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // Điểm móc nối WebSocket cho ReactJS/Frontend
        registry.addEndpoint("/ws-chat")
                .setAllowedOriginPatterns("http://localhost:3000", "http://localhost:5173")
                .withSockJS(); // Fallback nếu Browser mất kết nối
    }
}
