package com.aquatrade.core.domain.event;

import com.aquatrade.core.domain.Order;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class OrderCompletedEvent {
    private final Order order;
}
