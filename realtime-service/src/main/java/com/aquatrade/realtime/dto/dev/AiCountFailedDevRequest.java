package com.aquatrade.realtime.dto.dev;

import java.util.List;

import jakarta.validation.constraints.NotBlank;

public record AiCountFailedDevRequest(
        @NotBlank String orderId,
        String proofId,
        String reason,
        String message,
        String actorUserId,
        List<String> targetUserIds
) {
}
