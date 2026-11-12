package com.aquatrade.core.service;

import com.aquatrade.core.domain.Listing;
import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.dto.RealtimeAccessDto;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.service.impl.OrderAccessServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class OrderAccessServiceImplTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private UserRepository userRepository;

    private OrderAccessServiceImpl service;
    private UUID orderId;
    private UUID buyerId;
    private UUID sellerId;
    private UUID strangerId;
    private UUID adminId;
    private Order order;

    @BeforeEach
    void setUp() {
        service = new OrderAccessServiceImpl(orderRepository, userRepository);
        orderId = UUID.randomUUID();
        buyerId = UUID.randomUUID();
        sellerId = UUID.randomUUID();
        strangerId = UUID.randomUUID();
        adminId = UUID.randomUUID();

        User buyer = user(buyerId, Role.BUYER);
        User seller = user(sellerId, Role.SELLER);
        Listing listing = Listing.builder().seller(seller).build();
        order = Order.builder().buyer(buyer).listing(listing).build();
        order.setId(orderId);
    }

    @Test
    void buyerCanAccessOrder() {
        given(userRepository.findById(buyerId)).willReturn(Optional.of(user(buyerId, Role.BUYER)));
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));

        RealtimeAccessDto.OrderAccessResponse response = service.canAccessOrder(orderId, buyerId);

        assertThat(response.allowed()).isTrue();
        assertThat(response.roleInOrder()).isEqualTo("BUYER");
    }

    @Test
    void sellerCanAccessOrder() {
        given(userRepository.findById(sellerId)).willReturn(Optional.of(user(sellerId, Role.SELLER)));
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));

        RealtimeAccessDto.OrderAccessResponse response = service.canAccessOrder(orderId, sellerId);

        assertThat(response.allowed()).isTrue();
        assertThat(response.roleInOrder()).isEqualTo("SELLER");
    }

    @Test
    void adminCanAccessOrderWithoutLoadingOrder() {
        given(userRepository.findById(adminId)).willReturn(Optional.of(user(adminId, Role.ADMIN)));

        RealtimeAccessDto.OrderAccessResponse response = service.canAccessOrder(orderId, adminId);

        assertThat(response.allowed()).isTrue();
        assertThat(response.roleInOrder()).isEqualTo("ADMIN");
    }

    @Test
    void unrelatedUserCannotAccessOrder() {
        given(userRepository.findById(strangerId)).willReturn(Optional.of(user(strangerId, Role.BUYER)));
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));

        RealtimeAccessDto.OrderAccessResponse response = service.canAccessOrder(orderId, strangerId);

        assertThat(response.allowed()).isFalse();
        assertThat(response.roleInOrder()).isNull();
    }

    @Test
    void missingUserCannotAccessOrder() {
        given(userRepository.findById(strangerId)).willReturn(Optional.empty());

        RealtimeAccessDto.OrderAccessResponse response = service.canAccessOrder(orderId, strangerId);

        assertThat(response.allowed()).isFalse();
        assertThat(response.roleInOrder()).isNull();
    }

    private User user(UUID id, Role role) {
        User user = User.builder().role(role).build();
        user.setId(id);
        return user;
    }
}
