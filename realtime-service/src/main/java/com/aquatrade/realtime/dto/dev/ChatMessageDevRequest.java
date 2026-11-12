package com.aquatrade.realtime.dto.dev;

import java.math.BigDecimal;
import java.util.List;

import jakarta.validation.constraints.NotBlank;

public record ChatMessageDevRequest(
        @NotBlank String orderId,
        String messageId,
        String senderId,
        String senderName,
        String messageType,
        @NotBlank String content,
        BigDecimal offerPrice,
        String offerStatus,
        List<String> targetUserIds
) {
}
