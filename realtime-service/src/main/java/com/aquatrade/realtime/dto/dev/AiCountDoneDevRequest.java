package com.aquatrade.realtime.dto.dev;

import java.util.List;

import jakarta.validation.constraints.NotBlank;

public record AiCountDoneDevRequest(
        @NotBlank String orderId,
        String proofId,
        String proofRole,
        Integer aiFishCount,
        Integer healthScore,
        String qualityStatus,
        String aiImageUrl,
        String message,
        String actorUserId,
        List<String> targetUserIds
) {
}
