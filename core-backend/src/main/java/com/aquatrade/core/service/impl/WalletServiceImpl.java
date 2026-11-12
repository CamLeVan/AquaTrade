package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.Transaction;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.dto.WalletDto;
import com.aquatrade.core.repository.TransactionRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.service.WalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class WalletServiceImpl implements WalletService {

        private final UserRepository userRepository;
        private final TransactionRepository transactionRepository;
        private final com.aquatrade.core.repository.OrderRepository orderRepository;

        @Override
        public WalletDto getMyWallet() {
                // Lấy user từ JWT (DỮ LIỆU THẬT)
                UUID userId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                User user = userRepository.findById(userId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user"));

                // Lấy 10 giao dịch gần nhất
                List<Transaction> transactions;
                if (user.getRole().name().equals("ADMIN")) {
                        // Nếu là Admin, xem 10 giao dịch gần nhất của TOÀN SÀN
                        transactions = transactionRepository.findAllByOrderByCreatedAtDesc(
                                        org.springframework.data.domain.PageRequest.of(0, 10)).getContent();
                } else {
                        // Nếu là User, xem của cá nhân
                        transactions = transactionRepository.findTop10ByUserIdOrderByCreatedAtDesc(userId);
                }

                List<WalletDto.TransactionDto> txDtos = transactions.stream()
                                .map(tx -> WalletDto.TransactionDto.builder()
                                                .id(tx.getId().toString())
                                                .orderId(tx.getOrder() != null ? tx.getOrder().getId().toString()
                                                                : null)
                                                .amount(tx.getAmount())
                                                .postBalance(tx.getPostBalance())
                                                .type(tx.getType())
                                                .paymentMethod(tx.getPaymentMethod())
                                                .status(tx.getStatus())
                                                .note(tx.getNote())
                                                .createdAt(tx.getCreatedAt())
                                                .build())
                                .collect(Collectors.toList());

                java.math.BigDecimal escrowBalance;
                java.math.BigDecimal totalIncome;

                if (user.getRole().name().equals("ADMIN")) {
                        // Nếu là Admin, xem tổng toàn sàn
                        escrowBalance = orderRepository.sumTotalPlatformEscrow();
                        totalIncome = transactionRepository.sumTotalPlatformIncome();
                } else {
                        // Nếu là Buyer/Seller, xem cá nhân
                        escrowBalance = orderRepository.sumEscrowByBuyerId(userId)
                                        .add(orderRepository.sumEscrowBySellerId(userId));
                        totalIncome = transactionRepository.sumTotalIncomeByUserId(userId);
                }

                return WalletDto.builder()
                                .walletBalance(user.getWalletBalance() != null ? user.getWalletBalance()
                                                : java.math.BigDecimal.ZERO)
                                .escrowBalance(escrowBalance)
                                .totalIncome(totalIncome)
                                .userLevel(user.getRole().name())
                                .recentTransactions(txDtos)
                                .build();
        }

        @Override
        @Transactional
        public void deposit(WalletDto.DepositRequest request) {
                UUID userId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                User user = userRepository.findById(userId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user"));

                if (request.getAmount() == null || request.getAmount().compareTo(java.math.BigDecimal.ZERO) <= 0) {
                        throw new IllegalArgumentException("Số tiền nạp phải lớn hơn 0");
                }

                // [PHƯƠNG ÁN 1] Tạo yêu cầu nạp ở trạng thái PENDING — chờ Admin duyệt tiền thực tế
                Transaction tx = Transaction.builder()
                                .user(user)
                                .amount(request.getAmount())
                                .postBalance(user.getWalletBalance())
                                .type(com.aquatrade.core.domain.enums.TransactionType.TOP_UP)
                                .paymentMethod(request.getPaymentMethod())
                                .status(com.aquatrade.core.domain.enums.TransactionStatus.PENDING)
                                .note("Yêu cầu nạp tiền vào ví (Chờ Admin duyệt) — " + (request.getPaymentMethod() != null ? request.getPaymentMethod() : "BANK_TRANSFER"))
                                .build();
                transactionRepository.save(tx);
                log.info("Khởi tạo yêu cầu nạp tiền {} từ user {} số tiền {}", tx.getId(), user.getEmail(), request.getAmount());
        }

        @Override
        public java.util.List<WalletDto.TransactionDto> getAllPendingDeposits() {
                return transactionRepository.findAll().stream()
                                .filter(tx -> tx.getType() == com.aquatrade.core.domain.enums.TransactionType.TOP_UP
                                                && tx.getStatus() == com.aquatrade.core.domain.enums.TransactionStatus.PENDING)
                                .map(tx -> WalletDto.TransactionDto.builder()
                                                .id(tx.getId().toString())
                                                .userName(tx.getUser() != null ? tx.getUser().getFullName() : "")
                                                .userEmail(tx.getUser() != null ? tx.getUser().getEmail() : "")
                                                .amount(tx.getAmount())
                                                .postBalance(tx.getPostBalance())
                                                .type(tx.getType())
                                                .status(tx.getStatus())
                                                .note(tx.getNote())
                                                .createdAt(tx.getCreatedAt())
                                                .paymentMethod(tx.getPaymentMethod())
                                                .build())
                                .collect(Collectors.toList());
        }

        @Override
        @Transactional
        public void approveDeposit(String transactionId) {
                Transaction tx = transactionRepository.findById(UUID.fromString(transactionId))
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy giao dịch"));

                if (tx.getStatus() != com.aquatrade.core.domain.enums.TransactionStatus.PENDING) {
                        throw new IllegalStateException("Giao dịch này đã được xử lý");
                }

                User user = tx.getUser();
                java.math.BigDecimal newBalance = user.getWalletBalance().add(tx.getAmount());
                user.setWalletBalance(newBalance);
                userRepository.save(user);

                tx.setStatus(com.aquatrade.core.domain.enums.TransactionStatus.SUCCESS);
                tx.setPostBalance(newBalance);
                tx.setNote("Nạp tiền vào ví thành công - Phương thức: " + tx.getPaymentMethod());
                transactionRepository.save(tx);
                log.info("Admin đã duyệt nạp tiền {} cho user {}, số dư mới: {}", tx.getId(), user.getEmail(), newBalance);
        }

        @Override
        @Transactional
        public void rejectDeposit(String transactionId) {
                Transaction tx = transactionRepository.findById(UUID.fromString(transactionId))
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy giao dịch"));

                if (tx.getStatus() != com.aquatrade.core.domain.enums.TransactionStatus.PENDING) {
                        throw new IllegalStateException("Giao dịch này đã được xử lý");
                }

                tx.setStatus(com.aquatrade.core.domain.enums.TransactionStatus.FAILED);
                tx.setNote("Yêu cầu nạp tiền bị Admin từ chối");
                transactionRepository.save(tx);
                log.info("Admin đã từ chối lệnh nạp tiền {} của user {}", tx.getId(), tx.getUser().getEmail());
        }
}
