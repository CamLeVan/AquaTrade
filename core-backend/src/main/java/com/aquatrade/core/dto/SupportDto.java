package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO quản lý ticket hỗ trợ — Support Center.
 * 🔜 Cần thêm bảng `support_tickets` trong DB.
 */
public class SupportDto {

    @Data
    @Builder
    public static class TicketResponse {
        private String ticketId;
        private String subject;
        private TicketStatus ticketStatus;
        private List<TicketMessage> messageHistory;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    public static class CreateTicketRequest {
        private String subject;
        private String message;
    }

    @Data
    @Builder
    public static class TicketMessage {
        private String senderName;
        private String content;
        private LocalDateTime sentAt;
    }

    public enum TicketStatus {
        OPEN, RESOLVED, CLOSED
    }
}
