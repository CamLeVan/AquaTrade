package com.aquatrade.core.service.impl;

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
import java.math.RoundingMode;

@Slf4j
@Component
@RequiredArgsConstructor
public class OrderCompletedEventListener {

    private final UserRepository userRepository;
    private final TransactionRepository transactionRepository;
    private final SystemTreasuryRepository systemTreasuryRepository;

    @Value("${app.commission.rate:0.05}")
    private BigDecimal commissionRate;

    @EventListener
    @Transactional
    public void handleOrderCompletedEvent(OrderCompletedEvent event) {
        Order order = event.getOrder();

        // Chuyển hóa dòng tiền (End-Game): 5% Platform, 95% Seller (dựa trên cấu hình)
        // Lỗi logic cũ: Dùng order.getTotalPrice() nhưng lại không cập nhật totalPrice khi finalQuantity thay đổi.
        // Fix: Thanh toán dựa trên finalQuantity.
        BigDecimal total = order.getUnitPriceAtPurchase().multiply(BigDecimal.valueOf(order.getFinalQuantity()));
        BigDecimal commission = total.multiply(commissionRate)
                .setScale(0, RoundingMode.HALF_UP);
        BigDecimal sellerPayout = total.subtract(commission);

        // 1. Chuyển tiền cho Seller
        User seller = order.getListing().getSeller();
        seller.setWalletBalance(seller.getWalletBalance().add(sellerPayout));
        userRepository.save(seller);

        // Sinh hoá đơn thu nhập cho Seller
        Transaction txSeller = Transaction.builder()
                .order(order)
                .user(seller)
                .amount(sellerPayout)
                .postBalance(seller.getWalletBalance())
                .type(TransactionType.ORDER_PAYOUT)
                .status(TransactionStatus.SUCCESS)
                .build();
        transactionRepository.save(txSeller);

        // 2. Chuyển tiền cho Platform (Treasury)
        SystemTreasury treasury = systemTreasuryRepository.findById(1)
                .orElse(SystemTreasury.builder().id(1).totalRevenue(BigDecimal.ZERO).build());
        treasury.setTotalRevenue(treasury.getTotalRevenue().add(commission));
        systemTreasuryRepository.save(treasury);

        // Sinh hoá đơn hoa hồng cho Platform
        Transaction txPlatform = Transaction.builder()
                .order(order)
                .user(seller) // Đánh dấu nguồn gốc giao dịch
                .amount(commission)
                .postBalance(treasury.getTotalRevenue())
                .type(TransactionType.PLATFORM_COMMISSION)
                .status(TransactionStatus.SUCCESS)
                .build();
        transactionRepository.save(txPlatform);

        log.info("Order COMPLETED: {} - Payout to Seller: {} - Commission: {}", order.getId(), sellerPayout, commission);
    }
}
