package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public class AIDetectionDto {

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProcessingPayload {
        private String status;
        private String orderId;
        private Integer batchIndex;
        private String batchName;
        private Integer currentCount;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DonePayload {
        private String status;
        private String orderId;
        private String errorMessage;
        private Integer aiFishCount;
        private Integer batchIndex;
        private String batchName;
        private Integer healthScore;
        private String qualityStatus;
        private String aiImageUrl;
        private String proofHash;

        private Integer expectedQuantity;
        private Integer aiTolerancePercent;
        private Integer sellerAiTotalCount;
        private Integer sellerAiSuccessfulBatchCount;
        private Integer aiProgressPercent;
        private Integer aiDiscrepancyPercent;
        private String aiVerificationStatus;

        private BigDecimal averageSize;
        private Integer impuritiesCount;
        private Integer colorUniformity;
        private String aiNotes;

        private LocalDateTime createdAt;
    }
}
