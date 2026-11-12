package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.Dispute;
import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.DisputeStatus;
import com.aquatrade.core.dto.DisputeDto;
import com.aquatrade.core.repository.DisputeRepository;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.service.DisputeService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class DisputeServiceImpl implements DisputeService {

    private final DisputeRepository disputeRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final com.aquatrade.core.repository.TransactionRepository transactionRepository;
    private final com.aquatrade.core.repository.SystemTreasuryRepository systemTreasuryRepository;

    @org.springframework.beans.factory.annotation.Value("${app.commission.rate:0.05}")
    private java.math.BigDecimal commissionRate;

    @Override
    public DisputeDto.DisputeResponse createDispute(String orderId, DisputeDto.CreateDisputeRequest request) {
        Order order = orderRepository.findById(UUID.fromString(orderId))
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

        UUID userId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User complainer = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user"));

        // IDOR Fix: Prevent arbitrary users from creating disputes on other people's orders
        if (!order.getBuyer().getId().equals(userId) && !order.getListing().getSeller().getId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền tạo khiếu nại cho đơn hàng này.");
        }

        // Lưu Dispute vào DB thật
        Dispute dispute = Dispute.builder()
                .order(order)
                .complainer(complainer)
                .reasonText(request.getReason())
                .status(DisputeStatus.OPEN)
                .build();

        dispute = disputeRepository.save(dispute);
        log.info("Dispute mới: {} - Order: {} - By: {}", dispute.getId(), orderId, complainer.getFullName());

        return DisputeDto.DisputeResponse.builder()
                .id(dispute.getId().toString())
                .orderId(orderId)
                .status(dispute.getStatus().name())
                .reasonText(dispute.getReasonText())
                .createdAt(dispute.getCreatedAt())
                .build();
    }

    @Override
    @org.springframework.transaction.annotation.Transactional
    public void refundOrder(String disputeId) {
        Dispute dispute = disputeRepository.findById(UUID.fromString(disputeId))
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy Dispute"));
        
        if (dispute.getStatus() != DisputeStatus.OPEN) {
            throw new IllegalArgumentException("Đơn khiếu nại này đã được xử lý");
        }

        Order order = dispute.getOrder();
        if (order.getStatus() != com.aquatrade.core.domain.enums.OrderStatus.ESCROW_LOCKED 
            && order.getStatus() != com.aquatrade.core.domain.enums.OrderStatus.DISPUTED) {
            throw new IllegalArgumentException("Đơn hàng không ở trạng thái tạm giữ hoặc tranh chấp, không thể hoàn tiền");
        }

        // 1. Hoàn tiền lại cho Buyer
        User buyer = order.getBuyer();
        java.math.BigDecimal amount = order.getTotalPrice();
        buyer.setWalletBalance(buyer.getWalletBalance().add(amount));
        userRepository.save(buyer);

        // 2. Log Transaction
        com.aquatrade.core.domain.Transaction tx = com.aquatrade.core.domain.Transaction.builder()
                .order(order)
                .user(buyer)
                .amount(amount)
                .postBalance(buyer.getWalletBalance())
                .type(com.aquatrade.core.domain.enums.TransactionType.REFUND)
                .status(com.aquatrade.core.domain.enums.TransactionStatus.SUCCESS)
                .build();
        transactionRepository.save(tx);

        // 3. Mark Refunded
        order.setStatus(com.aquatrade.core.domain.enums.OrderStatus.CANCELLED);
        orderRepository.save(order);

        dispute.setStatus(DisputeStatus.RESOLVED);
        disputeRepository.save(dispute);
        log.info("Dispute REFUNDED: Admin hoàn tiền cho Buyer {}", buyer.getFullName());
    }

    @Override
    @org.springframework.transaction.annotation.Transactional
    public void forceComplete(String disputeId) {
        Dispute dispute = disputeRepository.findById(UUID.fromString(disputeId))
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy Dispute"));
        
        if (dispute.getStatus() != DisputeStatus.OPEN) {
            throw new IllegalArgumentException("Đơn khiếu nại này đã được xử lý");
        }

        Order order = dispute.getOrder();
        if (order.getStatus() != com.aquatrade.core.domain.enums.OrderStatus.ESCROW_LOCKED
            && order.getStatus() != com.aquatrade.core.domain.enums.OrderStatus.DISPUTED) {
            throw new IllegalArgumentException("Đơn hàng không ở trạng thái tạm giữ hoặc tranh chấp");
        }

        order.setStatus(com.aquatrade.core.domain.enums.OrderStatus.COMPLETED);
        orderRepository.save(order);

        // Split tiền
        java.math.BigDecimal total = order.getTotalPrice();
        java.math.BigDecimal commission = total.multiply(commissionRate)
                .setScale(0, java.math.RoundingMode.HALF_UP);
        java.math.BigDecimal sellerPayout = total.subtract(commission);

        // Nạp cho Seller
        User seller = order.getListing().getSeller();
        seller.setWalletBalance(seller.getWalletBalance().add(sellerPayout));
        userRepository.save(seller);

        com.aquatrade.core.domain.Transaction txSeller = com.aquatrade.core.domain.Transaction.builder()
                .order(order)
                .user(seller)
                .amount(sellerPayout)
                .postBalance(seller.getWalletBalance())
                .type(com.aquatrade.core.domain.enums.TransactionType.ORDER_PAYOUT)
                .status(com.aquatrade.core.domain.enums.TransactionStatus.SUCCESS)
                .build();
        transactionRepository.save(txSeller);

        // Nạp cho Treasury
        com.aquatrade.core.domain.SystemTreasury treasury = systemTreasuryRepository.findById(1)
                .orElse(com.aquatrade.core.domain.SystemTreasury.builder().id(1).totalRevenue(java.math.BigDecimal.ZERO).build());
        treasury.setTotalRevenue(treasury.getTotalRevenue().add(commission));
        systemTreasuryRepository.save(treasury);

        com.aquatrade.core.domain.Transaction txPlatform = com.aquatrade.core.domain.Transaction.builder()
                .order(order)
                .user(seller)
                .amount(commission)
                .postBalance(treasury.getTotalRevenue())
                .type(com.aquatrade.core.domain.enums.TransactionType.PLATFORM_COMMISSION)
                .status(com.aquatrade.core.domain.enums.TransactionStatus.SUCCESS)
                .build();
        transactionRepository.save(txPlatform);

        dispute.setStatus(DisputeStatus.REJECTED); // Bác bỏ khiếu nại (bắt Seller giao dịch)
        disputeRepository.save(dispute);
        log.info("Dispute REJECTED -> FORCE COMPLETE: Admin chốt đơn, tiền về Seller.");
    }
}
