package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO cho Module Chat & Thương lượng giá trong Phòng giao dịch.
 * 🔜 Cần thêm bảng `messages`, `negotiations` trong DB.
 * Kênh: WebSocket (orderId làm roomId, không cần chatId riêng)
 */
import com.aquatrade.core.domain.enums.MessageType;
import com.aquatrade.core.domain.enums.OfferStatus;

public class ChatDto {

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChatMessage {
        // [v2] chatId bỏ — dùng orderId làm room WebSocket
        private String senderId;       // UUID người gửi
        private String senderName;     // Tên hiển thị
        private String content;
        private MessageType messageType;
        private LocalDateTime timestamp;

        // Chỉ có giá trị khi messageType = OFFER
        private BigDecimal offerPrice;
        private OfferStatus offerStatus;

        // 🔜 Thêm sau khi AI hỗ trợ gợi ý giá thị trường
        private BigDecimal aiRecommendedPrice;
    }

}
