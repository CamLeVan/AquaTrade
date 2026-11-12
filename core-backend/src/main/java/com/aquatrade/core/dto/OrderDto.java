package com.aquatrade.core.dto;

import com.aquatrade.core.domain.enums.OrderStatus;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class OrderDto {

    @Data
    public static class CreateOrderRequest {
        @NotBlank(message = "Thiếu Listing ID")
        private String listingId;

        @NotBlank(message = "Thiếu địa chỉ giao hàng")
        private String shippingAddress;

        @jakarta.validation.constraints.NotNull(message = "Phải nhập số lượng muốn mua")
        @jakarta.validation.constraints.Positive(message = "Số lượng mua phải lớn hơn 0")
        private Integer quantity;

        private Boolean isPrecheckOnly;
    }

    @Data
    public static class CartCheckoutRequest {
        @jakarta.validation.constraints.NotEmpty(message = "Giỏ hàng không được để trống")
        @jakarta.validation.Valid
        private java.util.List<CartItemRequest> items;
    }

    @Data
    public static class CartItemRequest {
        @NotBlank(message = "Thiếu Listing ID")
        private String listingId;

        @NotBlank(message = "Thiếu địa chỉ giao hàng")
        private String shippingAddress;

        @jakarta.validation.constraints.NotNull(message = "Phải nhập số lượng muốn mua")
        @jakarta.validation.constraints.Positive(message = "Số lượng mua phải lớn hơn 0")
        private Integer quantity;

        private Boolean isPrecheckOnly;
    }

    @Data
    @NoArgsConstructor
    public static class ConfirmOrderRequest {
        // Không bắt Buyer nhập tay nữa, chỉ gọi API để đối soát AI
    }

    @Data
    public static class StartAiRequest {
        @jakarta.validation.constraints.NotBlank(message = "Video URL không được để trống")
        private String videoUrl;

        private String videoPublicId;

        private Integer batchExpectedQuantity;
        
        private String batchName; // VD: "Thùng 1", "Mẻ 2"
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OrderResponse {
        private String id;
        private String listingTitle;
        private String listingThumbnailUrl;
        private String buyerName;
        private String buyerId;
        private String sellerName;
        private String sellerId;
        private BigDecimal unitPriceAtPurchase;

        // [THỐNG NHẤT v2] Số CON cá — không phải kg. FE gốc gọi là "weight" → đổi thành finalQuantity
        private Integer finalQuantity;
        private BigDecimal totalPrice;
        private String shippingAddress;
        private OrderStatus status;
        private LocalDateTime createdAt;

        // [FIX] Hỗ trợ danh sách Bằng chứng số cho Đếm AI Hai Chiều
        private java.util.List<DigitalProofSummary> proofs;
        private Integer aiExpectedQuantity;
        private Integer aiTolerancePercent;
        private Integer sellerAiTotalCount;
        private Integer sellerAiSuccessfulBatchCount;
        private Integer sellerAiProgressPercent;
        private Integer sellerAiDiscrepancyPercent;
        private String sellerAiVerificationStatus;
        private Integer buyerAiTotalCount;
        private Integer buyerAiSuccessfulBatchCount;
        private Integer buyerAiProgressPercent;
        private Integer buyerAiDiscrepancyPercent;
        private String buyerAiVerificationStatus;

        // [THÊM MỚI] Thông tin khiếu nại
        private String disputeReason;
        private String sellerResponse;
    }

    /**
     * Bản tóm tắt bằng chứng số nhúng vào OrderResponse.
     * Toàn bộ chi tiết (GPS, hash...) trả về qua WebSocket /ws/orders/{id}/count-ai khi DONE.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DigitalProofSummary {
        private String id;
        private String proofRole;           // "SELLER" hoặc "BUYER"
        private String batchName;           // "Thùng 1", "Mẻ 2"
        private Integer batchIndex;
        private Integer batchExpectedQuantity;
        private Integer aiFishCount;
        private String status;
        private String errorMessage;
        private String videoUrl;
        private String videoPublicId;
        private String aiImageUrl;
        private String proofHash;           // SHA-256 chống giả mạo (hiển thị 8 ký tự đầu)
        private LocalDateTime createdAt;
    }
}
