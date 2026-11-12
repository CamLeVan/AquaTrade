package com.aquatrade.core.repository;

import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.enums.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {
    @Query("SELECT SUM(o.totalPrice) FROM Order o WHERE o.status = :status")
    BigDecimal sumTotalPriceByStatus(@Param("status") OrderStatus status);

    List<Order> findByBuyerIdOrderByCreatedAtDesc(UUID buyerId);

    List<Order> findByListingSellerIdOrderByCreatedAtDesc(UUID sellerId);

    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    long countByListingSellerId(UUID sellerId);

    @Query("SELECT COALESCE(SUM(o.totalPrice), 0) FROM Order o WHERE o.listing.seller.id = :sellerId AND o.status = com.aquatrade.core.domain.enums.OrderStatus.COMPLETED")
    BigDecimal sumRevenueBySellerId(@Param("sellerId") UUID sellerId);

    @Query("SELECT COALESCE(SUM(o.totalPrice), 0) FROM Order o WHERE o.buyer.id = :userId AND o.status NOT IN (com.aquatrade.core.domain.enums.OrderStatus.COMPLETED, com.aquatrade.core.domain.enums.OrderStatus.CANCELLED)")
    BigDecimal sumEscrowByBuyerId(@Param("userId") UUID userId);

    @Query("SELECT COALESCE(SUM(o.totalPrice), 0) FROM Order o WHERE o.listing.seller.id = :userId AND o.status NOT IN (com.aquatrade.core.domain.enums.OrderStatus.COMPLETED, com.aquatrade.core.domain.enums.OrderStatus.CANCELLED)")
    BigDecimal sumEscrowBySellerId(@Param("userId") UUID userId);

    @Query("SELECT COALESCE(SUM(o.totalPrice), 0) FROM Order o WHERE o.status NOT IN (com.aquatrade.core.domain.enums.OrderStatus.COMPLETED, com.aquatrade.core.domain.enums.OrderStatus.CANCELLED)")
    BigDecimal sumTotalPlatformEscrow();

    boolean existsByListingId(UUID listingId);

    @Query("SELECT COUNT(o) FROM Order o WHERE o.listing.id = :listingId AND o.status != com.aquatrade.core.domain.enums.OrderStatus.CANCELLED")
    long countOrdersByListingId(@Param("listingId") UUID listingId);

    @Query("SELECT COALESCE(SUM(o.finalQuantity), 0) FROM Order o WHERE o.listing.id = :listingId AND o.status != com.aquatrade.core.domain.enums.OrderStatus.CANCELLED")
    long sumQuantityByListingId(@Param("listingId") UUID listingId);
}
