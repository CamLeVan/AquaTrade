package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;

public class DisputeDto {

    @Data
    public static class CreateDisputeRequest {
        @NotBlank(message = "Lý do khiếu nại không được để trống")
        private String reason;
    }

    @Data
    @Builder
    public static class DisputeResponse {
        private String id;
        private String orderId;
        private String status; // OPEN, RESOLVED, REJECTED
        private String reasonText;
        private LocalDateTime createdAt;
    }
}
