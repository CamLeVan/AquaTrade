package com.aquatrade.realtime.dto;

import java.util.List;

public record RouteResult(
        RealtimeEvent event,
        List<String> destinations
) {
}
