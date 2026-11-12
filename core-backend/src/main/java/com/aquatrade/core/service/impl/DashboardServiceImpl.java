package com.aquatrade.core.service.impl;

import com.aquatrade.core.dto.DashboardStatsDto;
import com.aquatrade.core.repository.ListingRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.domain.enums.UserStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl {

    private final UserRepository userRepository;
    private final ListingRepository listingRepository;
    private final com.aquatrade.core.repository.TransactionRepository transactionRepository;
    private final com.aquatrade.core.repository.OrderRepository orderRepository;

    @Transactional(readOnly = true)
    public DashboardStatsDto getSystemStats() {
        long activeSellers = userRepository.countByRoleAndStatus(Role.SELLER, UserStatus.ACTIVE);
        long activeBuyers = userRepository.countByRoleAndStatus(Role.BUYER, UserStatus.ACTIVE);
        long totalListings = listingRepository.count();

        // Thống kê tài chính nâng cao (SQL Queue)
        java.math.BigDecimal totalRevenue = transactionRepository.sumAmountByType(com.aquatrade.core.domain.enums.TransactionType.PLATFORM_COMMISSION);
        if (totalRevenue == null) totalRevenue = java.math.BigDecimal.ZERO;

        java.math.BigDecimal totalVolume = orderRepository.sumTotalPriceByStatus(com.aquatrade.core.domain.enums.OrderStatus.COMPLETED);
        if (totalVolume == null) totalVolume = java.math.BigDecimal.ZERO;

        java.math.BigDecimal pendingLiabilities = orderRepository.sumTotalPriceByStatus(com.aquatrade.core.domain.enums.OrderStatus.ESCROW_LOCKED);
        if (pendingLiabilities == null) pendingLiabilities = java.math.BigDecimal.ZERO;

        return DashboardStatsDto.builder()
                .activeSellers((int) activeSellers)
                .activeBuyers((int) activeBuyers)
                .totalListings((int) totalListings)
                .aiNetworkHealth(98)
                .totalRevenue(totalRevenue)
                .totalVolume(totalVolume)
                .pendingLiabilities(pendingLiabilities)
                .build();
    }
}
