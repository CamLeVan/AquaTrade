package com.aquatrade.core.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

public class SellerDto {

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class SellerStatsSummary {
        private BigDecimal totalSales;
        private long totalListings;
        private long pendingOrders;
        private double shopRating;
    }
}
