package com.aquatrade.core.service;

import com.aquatrade.core.dto.RealtimeAccessDto;

import java.util.UUID;

public interface OrderAccessService {

    RealtimeAccessDto.OrderAccessResponse canAccessOrder(UUID orderId, UUID userId);
}
