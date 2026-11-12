package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.dto.RealtimeAccessDto;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.service.OrderAccessService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OrderAccessServiceImpl implements OrderAccessService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public RealtimeAccessDto.OrderAccessResponse canAccessOrder(UUID orderId, UUID userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            return RealtimeAccessDto.OrderAccessResponse.denied();
        }
        if (user.getRole() == Role.ADMIN) {
            return RealtimeAccessDto.OrderAccessResponse.allowed("ADMIN");
        }

        Order order = orderRepository.findById(orderId).orElse(null);
        if (order == null) {
            return RealtimeAccessDto.OrderAccessResponse.denied();
        }
        if (order.getBuyer() != null && userId.equals(order.getBuyer().getId())) {
            return RealtimeAccessDto.OrderAccessResponse.allowed("BUYER");
        }
        if (
                order.getListing() != null
                        && order.getListing().getSeller() != null
                        && userId.equals(order.getListing().getSeller().getId())
        ) {
            return RealtimeAccessDto.OrderAccessResponse.allowed("SELLER");
        }

        return RealtimeAccessDto.OrderAccessResponse.denied();
    }
}
