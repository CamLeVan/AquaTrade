package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;

/**
 * DTO giám sát hệ thống — Admin monitoring.
 * 🔜 Tích hợp Spring Boot Actuator sau.
 */
@Data
@Builder
public class SystemHealthDto {
    private Double serverHealth;   // % sức khỏe server
    private Integer latencyMs;     // Độ trễ trung bình (ms)
    private String lastSyncAt;     // Thời điểm đồng bộ cuối (ISO Date)
}
