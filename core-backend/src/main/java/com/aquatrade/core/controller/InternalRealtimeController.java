package com.aquatrade.core.controller;

import com.aquatrade.core.dto.RealtimeAccessDto;
import com.aquatrade.core.service.OrderAccessService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/internal/realtime")
@RequiredArgsConstructor
public class InternalRealtimeController {

    private final OrderAccessService orderAccessService;

    @GetMapping("/orders/{orderId}/access")
    public RealtimeAccessDto.OrderAccessResponse canAccessOrder(
            @PathVariable UUID orderId,
            @RequestParam UUID userId
    ) {
        return orderAccessService.canAccessOrder(orderId, userId);
    }
}
