package com.aquatrade.realtime.dto.dev;

import java.util.List;

import jakarta.validation.constraints.NotBlank;

public record OrderStatusDevRequest(
        @NotBlank String orderId,
        @NotBlank String previousStatus,
        @NotBlank String newStatus,
        String message,
        String actorUserId,
        List<String> targetUserIds
) {
}
