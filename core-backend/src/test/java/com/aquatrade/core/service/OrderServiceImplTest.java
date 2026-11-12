package com.aquatrade.core.service;

import com.aquatrade.core.domain.*;
import com.aquatrade.core.domain.enums.*;
import com.aquatrade.core.dto.OrderDto;
import com.aquatrade.core.repository.*;
import com.aquatrade.core.service.impl.OrderServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class OrderServiceImplTest {

    @Mock private OrderRepository orderRepository;
    @Mock private ListingRepository listingRepository;
    @Mock private UserRepository userRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private DigitalProofRepository digitalProofRepository;
    @Mock private SystemTreasuryRepository systemTreasuryRepository;
    @Mock private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private OrderServiceImpl orderService;

    private User buyer;
    private Listing listing;
    private UUID buyerId;
    private UUID listingId;

    @BeforeEach
    void setUp() {
        buyerId = UUID.randomUUID();
        listingId = UUID.randomUUID();

        buyer = User.builder()
                .walletBalance(new BigDecimal("10000000"))
                .fullName("Người mua mẫu")
                .build();
        buyer.setId(buyerId);

        listing = Listing.builder()
                .pricePerFish(new BigDecimal("50000"))
                .availableQuantity(100)
                .status(ListingStatus.AVAILABLE)
                .title("Lô cá mẫu")
                .seller(User.builder().walletBalance(BigDecimal.ZERO).build())
                .build();
        listing.setId(listingId);
        listing.getSeller().setId(UUID.randomUUID());

        Authentication auth = mock(Authentication.class);
        SecurityContext securityContext = mock(SecurityContext.class);
        given(securityContext.getAuthentication()).willReturn(auth);
        given(auth.getPrincipal()).willReturn(buyerId);
        SecurityContextHolder.setContext(securityContext);

        // Inject commission rate manually since it's @Value
        org.springframework.test.util.ReflectionTestUtils.setField(orderService, "commissionRate", new BigDecimal("0.05"));
    }

    @Test
    @DisplayName("Tạo đơn hàng thành công - Trừ tiền ví và khóa Escrow")
    void createOrder_Success() {
        // Arrange
        OrderDto.CreateOrderRequest request = new OrderDto.CreateOrderRequest();
        request.setListingId(listingId.toString());
        request.setQuantity(10);
        request.setShippingAddress("Cần Thơ");

        given(listingRepository.findById(listingId)).willReturn(Optional.of(listing));
        given(userRepository.findById(buyerId)).willReturn(Optional.of(buyer));
        given(orderRepository.save(any(Order.class))).willAnswer(i -> {
            Order o = i.getArgument(0);
            o.setId(UUID.randomUUID());
            return o;
        });

        // Act
        OrderDto.OrderResponse response = orderService.createOrder(request);

        // Assert
        assertThat(buyer.getWalletBalance()).isEqualByComparingTo("9425000");
        assertThat(listing.getAvailableQuantity()).isEqualTo(90);
        assertThat(response.getStatus()).isEqualTo(OrderStatus.ESCROW_LOCKED);
        verify(transactionRepository, times(1)).save(any(Transaction.class));
    }

    @Test
    @DisplayName("Thất bại khi tạo đơn hàng - Số dư ví không đủ")
    void createOrder_InsufficientBalance() {
        // Arrange
        buyer.setWalletBalance(BigDecimal.ZERO); // Ví trống rỗng
        OrderDto.CreateOrderRequest request = new OrderDto.CreateOrderRequest();
        request.setListingId(listingId.toString());
        request.setQuantity(10); // 10 * 50k = 500k > 0

        given(listingRepository.findById(listingId)).willReturn(Optional.of(listing));
        given(userRepository.findById(buyerId)).willReturn(Optional.of(buyer));

        // Act & Assert
        assertThatThrownBy(() -> orderService.createOrder(request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Số dư trong ví không đủ");
    }
}
