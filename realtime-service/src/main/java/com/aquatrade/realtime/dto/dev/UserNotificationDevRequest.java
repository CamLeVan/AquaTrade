package com.aquatrade.realtime.dto.dev;

import java.util.List;

public record UserNotificationDevRequest(
        String userId,
        List<String> targetUserIds,
        String title,
        String message,
        String level,
        String actionUrl
) {
}
