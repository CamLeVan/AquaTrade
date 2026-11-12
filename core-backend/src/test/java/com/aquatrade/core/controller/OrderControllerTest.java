package com.aquatrade.core.controller;

import com.aquatrade.core.dto.OrderDto;
import com.aquatrade.core.service.OrderService;
import com.aquatrade.core.domain.enums.OrderStatus;
import com.aquatrade.core.security.JwtProvider;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(OrderController.class)
@AutoConfigureMockMvc
public class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private OrderService orderService;

    @MockBean
    private JwtProvider jwtProvider; // Mock Security dependency

    @MockBean
    private com.aquatrade.core.repository.UserRepository userRepository; // Cần thiết cho JwtAuthenticationFilter

    @MockBean
    private com.aquatrade.core.repository.OrderRepository orderRepository;

    @MockBean
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    private OrderDto.OrderResponse mockResponse;
    private UUID orderId;

    @BeforeEach
    void setUp() {
        orderId = UUID.randomUUID();
        mockResponse = OrderDto.OrderResponse.builder()
                .id(orderId.toString())
                .listingTitle("Lô cá Tra giống")
                .totalPrice(new BigDecimal("5000000"))
                .status(OrderStatus.ESCROW_LOCKED)
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/orders - Thành công tạo đơn hàng")
    @WithMockUser(roles = "BUYER")
    void createOrder_Success() throws Exception {
        OrderDto.CreateOrderRequest request = new OrderDto.CreateOrderRequest();
        request.setListingId(UUID.randomUUID().toString());
        request.setQuantity(100);
        request.setShippingAddress("Can Tho");

        given(orderService.createOrder(any())).willReturn(mockResponse);

        mockMvc.perform(post("/api/v1/orders")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("success"))
                .andExpect(jsonPath("$.data.status").value("ESCROW_LOCKED"));
    }

    @Test
    @DisplayName("POST /api/v1/orders - Trả về 400 khi thiếu địa chỉ giao hàng")
    @WithMockUser(roles = "BUYER")
    void createOrder_ValidationFailed() throws Exception {
        OrderDto.CreateOrderRequest request = new OrderDto.CreateOrderRequest();
        request.setListingId(UUID.randomUUID().toString());
        request.setQuantity(10);
        request.setShippingAddress(""); // Invalid

        mockMvc.perform(post("/api/v1/orders")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }
}
