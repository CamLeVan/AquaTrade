package com.aquatrade.core.domain;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.List;

import com.aquatrade.core.domain.base.BaseObject;
import com.aquatrade.core.domain.enums.OrderStatus;

@Entity
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order extends BaseObject {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "buyer_id", nullable = false)
    private User buyer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "listing_id", nullable = false)
    private Listing listing;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private OrderStatus status;

    // Giá chốt tại thời điểm đặt hàng — chống gian lận Seller tự sửa giá sau khi đặt cọc
    @Column(name = "unit_price_at_purchase", precision = 15, scale = 2, nullable = false)
    private BigDecimal unitPriceAtPurchase;

    // Số lượng CON cá thực tế do AI đếm được (chốt sau khi Buyer xác nhận)
    @Column(name = "final_quantity")
    private Integer finalQuantity;

    @Column(name = "total_price", precision = 15, scale = 2)
    private BigDecimal totalPrice;

    // [THÊM MỚI] Địa chỉ giao nhận cá giống vật lý
    @Column(name = "shipping_address", columnDefinition = "TEXT")
    private String shippingAddress;

    // Liên kết 1-N với bằng chứng số do AI xuất ra
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<DigitalProof> proofs;

    // [THÊM MỚI] Thông tin khiếu nại & đối thoại
    @Column(name = "dispute_reason", columnDefinition = "TEXT")
    private String disputeReason;

    @Column(name = "seller_response", columnDefinition = "TEXT")
    private String sellerResponse;

    // [SECURITY] Optimistic Locking — chặn Double Refund / Double Complete race condition
    @Version
    @Column(name = "version")
    private Integer version;
}

