package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

/**
 * DTO phân tích AI nâng cao — Admin Analytics.
 * 🔜 Cần AI model hỗ trợ + dữ liệu tổng hợp từ DigitalProof.
 */
@Data
@Builder
public class AIAnalyticsDto {
    private Double healthForecast;          // % dự báo sức khỏe lô hàng
    private Double qualityConsistency;      // Điểm đồng nhất (0-10)
    private BigDecimal predictivePriceIndex; // Chỉ số giá dự báo
    private Integer gradingEfficiency;       // Số lô đã phân loại tự động
    private QualityDistribution qualityDistribution;
    private List<AnomalyLog> anomalyLogs;

    @Data
    @Builder
    public static class QualityDistribution {
        private Double gradeAPercent;  // VD: 82.0
        private Double gradeBPercent;  // VD: 14.0
        private Double gradeCPercent;  // VD: 4.0
    }

    @Data
    @Builder
    public static class AnomalyLog {
        private String batchId;      // Mã lô
        private String warning;       // Nội dung cảnh báo
        private String severity;      // LOW, MEDIUM, HIGH
    }
}
