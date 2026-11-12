package com.aquatrade.core.domain;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import com.aquatrade.core.domain.base.BaseObject;
import com.aquatrade.core.domain.enums.ListingCategory;
import com.aquatrade.core.domain.enums.ListingStatus;

@Entity
@Table(name = "listings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Listing extends BaseObject {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "seller_id", nullable = false)
    private User seller;

    @Column(name = "title", nullable = false)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false)
    private ListingCategory category;

    @Column(name = "species", nullable = false)
    private String species;

    @Column(name = "size_min", precision = 5, scale = 2)
    private BigDecimal sizeMin;

    @Column(name = "size_max", precision = 5, scale = 2)
    private BigDecimal sizeMax;

    @Column(name = "price_per_fish", nullable = false, precision = 15, scale = 2)
    private BigDecimal pricePerFish;

    @Column(name = "estimated_quantity")
    private Integer estimatedQuantity;

    @Column(name = "available_quantity")
    private Integer availableQuantity;

    @Column(name = "province", nullable = false)
    private String province;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    // [THÊM MỚI] Ghi chú của Admin khi từ chối hoặc yêu cầu Seller chỉnh sửa tin đăng
    @Column(name = "moderation_note", columnDefinition = "TEXT")
    private String moderationNote;

    @Column(name = "thumbnail_url", columnDefinition = "TEXT")
    private String thumbnailUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ListingStatus status;

    @OneToMany(mappedBy = "listing", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<ListingImage> images = new ArrayList<>();

    public void addImage(ListingImage image) {
        images.add(image);
        image.setListing(this);
    }
}
