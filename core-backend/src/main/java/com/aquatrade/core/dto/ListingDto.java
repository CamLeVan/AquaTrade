package com.aquatrade.core.dto;

import lombok.*;
import com.aquatrade.core.domain.enums.ListingCategory;
import com.aquatrade.core.domain.enums.ListingStatus;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ListingDto {
    private String id;
    private String title;
    private ListingCategory category;
    private String species;
    private String province;
    private BigDecimal sizeMin;
    private BigDecimal sizeMax;
    private BigDecimal pricePerFish;
    private Integer estimatedQuantity;
    private Integer availableQuantity;
    private String thumbnailUrl;
    private ListingStatus status;
    private String sellerName;
    private String sellerId;
    private Boolean aiVerified;
    private Integer aiHealthScore;
    private String qualityLabel;
    private Boolean isFavorite;
    private String description;
    private java.util.List<String> imageUrls;
    private LocalDateTime createdAt;
    private Integer purchaseCount; // Số lượt mua
    private Integer soldQuantity;  // Tổng số lượng con đã bán

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CreateListingRequest {
        private String title;
        private ListingCategory category;
        private String species;
        private String province;
        private BigDecimal sizeMin;
        private BigDecimal sizeMax;
        private BigDecimal pricePerFish;
        private Integer estimatedQuantity;
        private String description;
        private java.util.List<String> imageUrls;
        private String thumbnailUrl;
    }
}
