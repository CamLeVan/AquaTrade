package com.aquatrade.core.controller;

import com.aquatrade.core.dto.RealtimeAccessDto;
import com.aquatrade.core.security.JwtProvider;
import com.aquatrade.core.service.OrderAccessService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(InternalRealtimeController.class)
@AutoConfigureMockMvc(addFilters = false)
class InternalRealtimeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderAccessService orderAccessService;

    @MockBean
    private JwtProvider jwtProvider;

    @MockBean
    private com.aquatrade.core.repository.UserRepository userRepository;

    @Test
    void canAccessOrderReturnsAllowedResponse() throws Exception {
        UUID orderId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        given(orderAccessService.canAccessOrder(orderId, userId))
                .willReturn(RealtimeAccessDto.OrderAccessResponse.allowed("BUYER"));

        mockMvc.perform(get("/api/v1/internal/realtime/orders/{orderId}/access", orderId)
                        .queryParam("userId", userId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.allowed").value(true))
                .andExpect(jsonPath("$.roleInOrder").value("BUYER"));
    }
}
