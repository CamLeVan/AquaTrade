package com.aquatrade.core.service.impl.listener;

import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.SystemTreasury;
import com.aquatrade.core.domain.Transaction;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.TransactionStatus;
import com.aquatrade.core.domain.enums.TransactionType;
import com.aquatrade.core.domain.event.OrderCompletedEvent;
import com.aquatrade.core.repository.SystemTreasuryRepository;
import com.aquatrade.core.repository.TransactionRepository;
import com.aquatrade.core.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderEventListener {

    private final UserRepository userRepository;
    private final SystemTreasuryRepository systemTreasuryRepository;
    private final TransactionRepository transactionRepository;

    @Value("${app.commission.rate:0.05}")
    private BigDecimal commissionRate;

    @EventListener
    @Transactional
    public void handleOrderCompleted(OrderCompletedEvent event) {
        Order order = event.getOrder();
        log.info("Order {} completed successfully. Sending notifications...", order.getId());
        
        // TODO: Create notification record for Seller and Buyer
        // messagingTemplate.convertAndSendToUser(sellerId, "/queue/notifications", ...);
    }
}
