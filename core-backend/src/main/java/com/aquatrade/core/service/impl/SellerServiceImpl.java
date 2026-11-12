package com.aquatrade.core.service.impl;

import com.aquatrade.core.dto.SellerDto;
import com.aquatrade.core.repository.ListingRepository;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.service.SellerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SellerServiceImpl implements SellerService {

    private final ListingRepository listingRepository;
    private final OrderRepository orderRepository;

    @Override
    public SellerDto.SellerStatsSummary getSellerStats(UUID sellerId) {
        BigDecimal sales = orderRepository.sumRevenueBySellerId(sellerId);
        long listings = listingRepository.countBySeller_Id(sellerId);
        
        // Giả lập số đơn hàng chờ xử lý và đánh giá shop
        long pendingOrders = orderRepository.countByListingSellerId(sellerId); 
        
        return new SellerDto.SellerStatsSummary(
                sales,
                listings,
                pendingOrders,
                4.9 // Default rating for now
        );
    }
}
