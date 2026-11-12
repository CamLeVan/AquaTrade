package com.aquatrade.core.dto;

import lombok.Builder;
import lombok.Data;

/**
 * DTO thống kê tổng quan — dùng cho Dashboard Admin/User.
 * 🔜 Implement khi có dữ liệu thực (query aggregate từ các bảng hiện có).
 */
@Data
@Builder
public class DashboardStatsDto {
    private UserStats totalUsers;
    private Integer activeSellers;
    private Integer activeBuyers;
    private Integer totalListings;
    private Integer lowStockAlertCount;
    private Integer aiNetworkHealth; // 0-100
    private java.math.BigDecimal totalRevenue;
    private java.math.BigDecimal totalVolume;
    private java.math.BigDecimal pendingLiabilities;

    @Data
    @Builder
    public static class UserStats {
        private Integer total;
        private Double growthPercent; // % tăng trưởng so với tháng trước
    }
}
