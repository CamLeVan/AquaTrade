package com.aquatrade.realtime.dto.dev;

import java.util.List;

import jakarta.validation.constraints.NotBlank;

public record DisputeCreatedDevRequest(
        @NotBlank String orderId,
        String reason,
        String severity,
        String message,
        String actorUserId,
        List<String> targetUserIds
) {
}
