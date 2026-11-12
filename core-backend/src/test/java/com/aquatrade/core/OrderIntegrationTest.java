package com.aquatrade.core;

import com.aquatrade.core.domain.*;
import com.aquatrade.core.domain.enums.*;
import com.aquatrade.core.repository.*;
import com.aquatrade.core.service.OrderService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@Transactional
@ActiveProfiles("test")
public class OrderIntegrationTest {

    @Autowired private OrderService orderService;
    @Autowired private OrderRepository orderRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ListingRepository listingRepository;

    @Test
    @DisplayName("Luồng tích hợp: Lưu trữ dữ liệu thật và kiểm tra trạng thái Order")
    void fullOrderLifecycle_Integration() {
        // Arrange
        User seller = User.builder().username("seller_test").walletBalance(BigDecimal.ZERO).role(Role.SELLER).build();
        userRepository.save(seller);
        
        User buyer = User.builder().username("buyer_test").walletBalance(new BigDecimal("1000000")).role(Role.BUYER).build();
        userRepository.save(buyer);
        
        Listing listing = Listing.builder()
                .seller(seller)
                .pricePerFish(new BigDecimal("1000"))
                .availableQuantity(100)
                .title("Cá Tra Integration Test")
                .status(ListingStatus.AVAILABLE)
                .build();
        listingRepository.save(listing);

        Order order = Order.builder()
                .buyer(buyer)
                .listing(listing)
                .totalPrice(new BigDecimal("100000"))
                .status(OrderStatus.ESCROW_LOCKED)
                .unitPriceAtPurchase(new BigDecimal("1000"))
                .finalQuantity(100)
                .build();
        
        // Act
        order = orderRepository.save(order);

        // Assert
        Order savedOrder = orderRepository.findById(order.getId()).orElseThrow();
        assertThat(savedOrder.getStatus()).isEqualTo(OrderStatus.ESCROW_LOCKED);
        assertThat(savedOrder.getListing().getSeller().getUsername()).isEqualTo("seller_test");
    }
}
