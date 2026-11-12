package com.aquatrade.core.service.impl;

import com.aquatrade.core.domain.Listing;
import org.springframework.jdbc.core.JdbcTemplate;
import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.OrderStatus;
import com.aquatrade.core.domain.enums.ProofRole;
import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.dto.OrderDto;
import com.aquatrade.core.repository.ListingRepository;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.repository.DigitalProofRepository;
import com.aquatrade.core.realtime.RealtimeEvent;
import com.aquatrade.core.realtime.RealtimeEventFactory;
import com.aquatrade.core.realtime.RealtimeEventPublisher;
import com.aquatrade.core.realtime.RealtimeEventType;
import com.aquatrade.core.service.OrderService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import com.aquatrade.core.domain.Transaction;
import com.aquatrade.core.domain.enums.TransactionType;
import com.aquatrade.core.domain.enums.TransactionStatus;
import com.aquatrade.core.repository.TransactionRepository;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import com.aquatrade.core.domain.SystemTreasury;
import com.aquatrade.core.repository.SystemTreasuryRepository;
import com.aquatrade.core.domain.DigitalProof;
import com.aquatrade.core.dto.AIDetectionDto;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.client.RestTemplate;
import java.util.Map;
import java.util.HashMap;
import org.springframework.scheduling.annotation.Scheduled;
import java.time.LocalDateTime;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;

@Slf4j
@Service
@RequiredArgsConstructor
public class OrderServiceImpl implements OrderService {

        private static final int AI_TOLERANCE_PERCENT = 10;
        private static final String PROOF_SUCCESS = "SUCCESS";

        private final OrderRepository orderRepository;
        private final ListingRepository listingRepository;
        private final UserRepository userRepository;
        private final TransactionRepository transactionRepository;
        private final SystemTreasuryRepository systemTreasuryRepository;
        private final DigitalProofRepository digitalProofRepository;
        private final SimpMessagingTemplate messagingTemplate;
        private final org.springframework.context.ApplicationEventPublisher eventPublisher;
        private final RestTemplate restTemplate;
        private final JdbcTemplate jdbcTemplate;
        private final RealtimeEventPublisher realtimeEventPublisher;
        private final RealtimeEventFactory realtimeEventFactory;

        @org.springframework.beans.factory.annotation.Value("${ai.service.url:http://localhost:8000/ai/v1/jobs}")
        private String aiServiceUrl;

        @Autowired
        @Qualifier("aiTaskExecutor")
        private Executor aiTaskExecutor;

        @org.springframework.beans.factory.annotation.Value("${app.baseUrl:${app.baseurl:http://localhost:8080}}")
        private String appBaseUrl;

        @org.springframework.beans.factory.annotation.Value("${app.commission.rate:0.05}")
        private java.math.BigDecimal commissionRate;

        private boolean isSuccessfulProof(DigitalProof proof, ProofRole role) {
                return proof != null
                                && role == proof.getProofRole()
                                && PROOF_SUCCESS.equalsIgnoreCase(proof.getStatus())
                                && proof.getAiFishCount() != null;
        }

        private int sumSuccessfulProofs(List<DigitalProof> proofs, ProofRole role) {
                if (proofs == null) {
                        return 0;
                }
                return proofs.stream()
                                .filter(proof -> isSuccessfulProof(proof, role))
                                .mapToInt(DigitalProof::getAiFishCount)
                                .sum();
        }

        private int countSuccessfulProofs(List<DigitalProof> proofs, ProofRole role) {
                if (proofs == null) {
                        return 0;
                }
                return (int) proofs.stream()
                                .filter(proof -> isSuccessfulProof(proof, role))
                                .count();
        }

        private int progressPercent(int totalCount, int expectedQuantity) {
                if (expectedQuantity <= 0) {
                        return 0;
                }
                return Math.min(100, Math.round(totalCount * 100f / expectedQuantity));
        }

        private int discrepancyPercent(int totalCount, int expectedQuantity) {
                if (expectedQuantity <= 0) {
                        return 0;
                }
                return Math.round(Math.abs(totalCount - expectedQuantity) * 100f / expectedQuantity);
        }

        private String verificationStatus(int totalCount, int expectedQuantity) {
                if (totalCount <= 0) {
                        return "NO_PROOF";
                }
                int discrepancy = discrepancyPercent(totalCount, expectedQuantity);
                if (discrepancy == 0) {
                        return "MATCHED";
                }
                if (discrepancy <= AI_TOLERANCE_PERCENT) {
                        return "ACCEPTABLE";
                }
                return totalCount < expectedQuantity ? "NEEDS_MORE" : "NEEDS_REVIEW";
        }

        private int nextBatchIndex(List<DigitalProof> proofs) {
                if (proofs == null || proofs.isEmpty()) {
                        return 1;
                }
                return proofs.stream()
                                .map(DigitalProof::getBatchIndex)
                                .filter(java.util.Objects::nonNull)
                                .max(Integer::compareTo)
                                .orElse(proofs.size()) + 1;
        }

        private int resolveBatchExpectedQuantity(Order order, List<DigitalProof> roleProofs, ProofRole role,
                        Integer requestedExpectedQuantity) {
                if (requestedExpectedQuantity != null && requestedExpectedQuantity > 0) {
                        return requestedExpectedQuantity;
                }
                int expectedTotal = order.getFinalQuantity() != null ? order.getFinalQuantity() : 0;
                int alreadyCounted = sumSuccessfulProofs(roleProofs, role);
                return Math.max(expectedTotal - alreadyCounted, 0);
        }

        private String resolveBatchName(String batchName, ProofRole role, int batchIndex) {
                if (batchName != null && !batchName.isBlank()) {
                        return batchName.trim();
                }
                return (role == ProofRole.SELLER ? "Seller" : "Buyer") + " batch " + batchIndex;
        }

        private void enrichAiResult(Order order, DigitalProof proof, AIDetectionDto.DonePayload aiResult) {
                List<DigitalProof> proofs = digitalProofRepository.findByOrderIdOrderByCreatedAtAsc(order.getId());
                int expectedQuantity = order.getFinalQuantity() != null ? order.getFinalQuantity() : 0;
                int sellerTotal = sumSuccessfulProofs(proofs, ProofRole.SELLER);
                int sellerBatchCount = countSuccessfulProofs(proofs, ProofRole.SELLER);

                aiResult.setBatchIndex(proof.getBatchIndex());
                aiResult.setBatchName(proof.getBatchName());
                aiResult.setExpectedQuantity(expectedQuantity);
                aiResult.setAiTolerancePercent(AI_TOLERANCE_PERCENT);
                aiResult.setSellerAiTotalCount(sellerTotal);
                aiResult.setSellerAiSuccessfulBatchCount(sellerBatchCount);
                aiResult.setAiProgressPercent(progressPercent(sellerTotal, expectedQuantity));
                aiResult.setAiDiscrepancyPercent(discrepancyPercent(sellerTotal, expectedQuantity));
                aiResult.setAiVerificationStatus(verificationStatus(sellerTotal, expectedQuantity));
        }

        private void fixDatabaseConstraint() {
            try {
                log.info(">>> Đang quét và dọn dẹp mọi ràng buộc CHECK trên bảng orders...");
                // Xóa mọi ràng buộc kiểu CHECK trên bảng orders, bất kể tên là gì
                jdbcTemplate.execute("DO $$ " +
                        "DECLARE r record; " +
                        "BEGIN " +
                        "  FOR r IN (SELECT conname FROM pg_constraint con " +
                        "            JOIN pg_class rel ON rel.oid = con.conrelid " +
                        "            WHERE rel.relname = 'orders' AND con.contype = 'c') LOOP " +
                        "    EXECUTE 'ALTER TABLE orders DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname); " +
                        "  END LOOP; " +
                        "END $$;");
                log.info(">>> Đã dọn dẹp sạch sẽ ràng buộc trên bảng orders!");
            } catch (Exception e) {
                log.warn(">>> Lỗi khi dọn dẹp ràng buộc: {}", e.getMessage());
            }
        }

        @Override
        @Transactional
        public java.util.List<OrderDto.OrderResponse> checkoutCart(OrderDto.CartCheckoutRequest request) {
                UUID buyerId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                User buyer = userRepository.findById(buyerId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user buyer"));

                if (buyer.getRole() == com.aquatrade.core.domain.enums.Role.ADMIN) {
                        throw new IllegalArgumentException("Tài khoản Quản trị viên không có quyền thực hiện giao dịch mua bán.");
                }

                BigDecimal totalToPay = BigDecimal.ZERO;
                java.util.List<Order> ordersToSave = new java.util.ArrayList<>();
                java.util.List<Listing> listingsToUpdate = new java.util.ArrayList<>();

                // Validate and calculate totals
                for (OrderDto.CartItemRequest item : request.getItems()) {
                        Listing listing = listingRepository.findById(UUID.fromString(item.getListingId()))
                                        .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tin đăng " + item.getListingId()));

                        if (listing.getStatus() == com.aquatrade.core.domain.enums.ListingStatus.SOLD) {
                                throw new IllegalArgumentException("Rất tiếc, lô hàng '" + listing.getTitle() + "' đã bán hết!");
                        }

                        // Nếu availableQuantity chưa được set (listing cũ), fallback về estimatedQuantity
                        int availableQty = listing.getAvailableQuantity() != null
                                ? listing.getAvailableQuantity()
                                : listing.getEstimatedQuantity();

                        if (item.getQuantity() > availableQty) {
                                throw new IllegalArgumentException("Số lượng mua vượt quá số lượng cá còn lại trong kho cho lô '" + listing.getTitle() + "'");
                        }

                        if (listing.getSeller().getId().equals(buyerId)) {
                                throw new IllegalArgumentException("Hệ thống không cho phép tự mua hàng của chính mình: '" + listing.getTitle() + "'");
                        }

                        BigDecimal subtotal = listing.getPricePerFish().multiply(BigDecimal.valueOf(item.getQuantity()));
                        BigDecimal shippingFee = new BigDecimal("50000");
                        BigDecimal aiFee = new BigDecimal("25000");
                        BigDecimal itemTotal = subtotal.add(shippingFee).add(aiFee);

                        if (!Boolean.TRUE.equals(item.getIsPrecheckOnly())) {
                                totalToPay = totalToPay.add(itemTotal);
                        }

                        Order order = Order.builder()
                                        .buyer(buyer)
                                        .listing(listing)
                                        .status(Boolean.TRUE.equals(item.getIsPrecheckOnly()) ? OrderStatus.PENDING : OrderStatus.ESCROW_LOCKED)
                                        .unitPriceAtPurchase(listing.getPricePerFish())
                                        .finalQuantity(item.getQuantity())
                                        .totalPrice(itemTotal)
                                        .shippingAddress(item.getShippingAddress())
                                        .build();

                        ordersToSave.add(order);

                        if (!Boolean.TRUE.equals(item.getIsPrecheckOnly())) {
                                int currentAvailable = listing.getAvailableQuantity() != null
                                        ? listing.getAvailableQuantity()
                                        : listing.getEstimatedQuantity();
                                listing.setAvailableQuantity(currentAvailable - item.getQuantity());
                                if (listing.getAvailableQuantity() <= 0) {
                                        listing.setStatus(com.aquatrade.core.domain.enums.ListingStatus.SOLD);
                                }
                                listingsToUpdate.add(listing);
                        }
                }

                // Check wallet for items that require immediate payment
                if (totalToPay.compareTo(BigDecimal.ZERO) > 0) {
                        if (buyer.getWalletBalance().compareTo(totalToPay) < 0) {
                                throw new IllegalArgumentException("Số dư trong ví không đủ (Cần " + totalToPay.toPlainString() + "đ). Vui lòng nạp thêm.");
                        }

                        buyer.setWalletBalance(buyer.getWalletBalance().subtract(totalToPay));
                        userRepository.save(buyer);
                }

                // Save listings (optimistic locking will apply per listing)
                for (Listing listing : listingsToUpdate) {
                        try {
                                listingRepository.save(listing);
                        } catch (org.springframework.dao.OptimisticLockingFailureException ex) {
                                throw new IllegalStateException("Hệ thống đang xử lý giao dịch khác cho lô hàng '" + listing.getTitle() + "', vui lòng thử lại sau.", ex);
                        }
                }

                // Save orders and create transactions
                java.util.List<OrderDto.OrderResponse> responses = new java.util.ArrayList<>();
                for (Order order : ordersToSave) {
                        order = orderRepository.save(order);
                        responses.add(mapToDto(order));

                        if (order.getStatus() == OrderStatus.ESCROW_LOCKED) {
                                Transaction tx = Transaction.builder()
                                                .order(order)
                                                .user(buyer)
                                                .amount(order.getTotalPrice())
                                                .postBalance(buyer.getWalletBalance()) // Note: for multiple items, postBalance will just show the final balance after batch deduction
                                                .type(TransactionType.ESCROW_LOCK)
                                                .status(TransactionStatus.SUCCESS)
                                                .note("Tạm giữ tiền giao dịch - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                                .build();
                                transactionRepository.save(tx);
                        }
                        log.info("Order (từ Giỏ hàng): {} - Buyer: {} - Listing: {}", order.getId(), buyer.getFullName(), order.getListing().getTitle());
                }

                return responses;
        }

        @Override
        @Transactional
        public OrderDto.OrderResponse createOrder(OrderDto.CreateOrderRequest request) {
                Listing listing = listingRepository.findById(UUID.fromString(request.getListingId()))
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy tin đăng"));

                if (listing.getStatus() == com.aquatrade.core.domain.enums.ListingStatus.SOLD) {
                        throw new IllegalArgumentException("Rất tiếc, lô hàng này đã bán hết!");
                }

                if (request.getQuantity() > listing.getAvailableQuantity()) {
                        throw new IllegalArgumentException("Số lượng mua (" + request.getQuantity()
                                        + ") vượt quá số lượng cá còn lại trong kho (" + listing.getAvailableQuantity()
                                        + " con)");
                }

                // Lấy Buyer từ JWT SecurityContext (DỮ LIỆU THẬT)
                UUID buyerId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

                // [INTEGRITY CHECK] Không cho phép Seller tự mua hàng của chính mình
                if (listing.getSeller().getId().equals(buyerId)) {
                        throw new IllegalArgumentException(
                                        "Hệ thống không cho phép bạn tự mua hàng từ bài đăng của chính mình.");
                }

                User buyer = userRepository.findById(buyerId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy user buyer"));

                // [INTEGRITY CHECK] Admin không được mua bán
                if (buyer.getRole() == com.aquatrade.core.domain.enums.Role.ADMIN) {
                        throw new IllegalArgumentException(
                                        "Tài khoản Quản trị viên không có quyền thực hiện giao dịch mua bán.");
                }

                // BE tự tính giá từ DB theo Số lượng KHÁCH MUỐN MUA
                BigDecimal subtotal = listing.getPricePerFish()
                                .multiply(BigDecimal.valueOf(request.getQuantity()));

                // CỘNG THÊM PHÍ GIAO HÀNG (50k) VÀ PHÍ AI (25k) để khớp với FE
                BigDecimal shippingFee = new BigDecimal("50000");
                BigDecimal aiFee = new BigDecimal("25000");
                BigDecimal totalPrice = subtotal.add(shippingFee).add(aiFee);

                if (Boolean.TRUE.equals(request.getIsPrecheckOnly())) {
                        Order order = Order.builder()
                                        .buyer(buyer)
                                        .listing(listing)
                                        .status(OrderStatus.PENDING) // Trạng thái chờ đếm AI trước khi mua
                                        .unitPriceAtPurchase(listing.getPricePerFish())
                                        .finalQuantity(request.getQuantity())
                                        .totalPrice(totalPrice)
                                        .shippingAddress(request.getShippingAddress())
                                        .build();
                        order = orderRepository.save(order);
                        log.info("Order Yêu cầu đếm AI mới: {} - Buyer: {} - Listing: {}", order.getId(),
                                        buyer.getFullName(), listing.getTitle());
                        return mapToDto(order);
                }

                // Check số dư
                if (buyer.getWalletBalance().compareTo(totalPrice) < 0) {
                        throw new IllegalArgumentException("Số dư trong ví không đủ (Cần " + totalPrice.toPlainString()
                                        + "đ). Vui lòng nạp thêm.");
                }

                // Tự động khóa Escrow bằng cách trừ tiền trong ví người mua
                buyer.setWalletBalance(buyer.getWalletBalance().subtract(totalPrice));
                userRepository.save(buyer);

                // TRỪ KHO BÃI & CHỐT TRẠNG THÁI (Concurrency by @Version inherited in
                // BaseObject)
                listing.setAvailableQuantity(listing.getAvailableQuantity() - request.getQuantity());
                if (listing.getAvailableQuantity() <= 0) {
                        listing.setStatus(com.aquatrade.core.domain.enums.ListingStatus.SOLD);
                }
                try {
                        listingRepository.save(listing);
                } catch (org.springframework.dao.OptimisticLockingFailureException ex) {
                        throw new IllegalStateException(
                                        "Hệ thống đang xử lý giao dịch khác cho lô hàng này, vui lòng thử lại sau.",
                                        ex);
                }

                Order order = Order.builder()
                                .buyer(buyer)
                                .listing(listing)
                                .status(OrderStatus.ESCROW_LOCKED)
                                .unitPriceAtPurchase(listing.getPricePerFish())
                                .finalQuantity(request.getQuantity())
                                .totalPrice(totalPrice)
                                .shippingAddress(request.getShippingAddress())
                                .build();

                order = orderRepository.save(order);

                // Lưu log Transaction cho đối soát dòng tiền
                Transaction tx = Transaction.builder()
                                .order(order)
                                .user(buyer)
                                .amount(totalPrice)
                                .postBalance(buyer.getWalletBalance())
                                .type(TransactionType.ESCROW_LOCK)
                                .status(TransactionStatus.SUCCESS)
                                .note("Tạm giữ tiền giao dịch - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                .build();
                transactionRepository.save(tx);
                log.info("Order mới: {} - Buyer: {} - Listing: {}", order.getId(), buyer.getFullName(),
                                listing.getTitle());

                return mapToDto(order);
        }

        @Override
        @Transactional
        public void lockEscrowAndPurchase(UUID orderId) {
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                if (!order.getBuyer().getId().equals(currentUserId)) {
                        throw new org.springframework.security.access.AccessDeniedException("Chỉ người mua mới được chốt thanh toán");
                }

                if (order.getStatus() != OrderStatus.AI_VERIFIED && order.getStatus() != OrderStatus.PENDING) {
                        throw new IllegalStateException("Đơn hàng không ở trạng thái hợp lệ để khóa ví Escrow");
                }

                User buyer = order.getBuyer();
                Listing listing = order.getListing();
                BigDecimal totalPrice = order.getTotalPrice();

                if (buyer.getWalletBalance().compareTo(totalPrice) < 0) {
                        throw new IllegalArgumentException("Số dư trong ví không đủ (Cần " + totalPrice.toPlainString()
                                        + "đ). Vui lòng nạp thêm.");
                }

                if (listing.getAvailableQuantity() < order.getFinalQuantity()) {
                        throw new IllegalArgumentException("Số lượng cá giống trong kho không còn đủ!");
                }

                buyer.setWalletBalance(buyer.getWalletBalance().subtract(totalPrice));
                userRepository.save(buyer);

                listing.setAvailableQuantity(listing.getAvailableQuantity() - order.getFinalQuantity());
                if (listing.getAvailableQuantity() <= 0) {
                        listing.setStatus(com.aquatrade.core.domain.enums.ListingStatus.SOLD);
                }
                listingRepository.save(listing);

                order.setStatus(OrderStatus.ESCROW_LOCKED);
                orderRepository.save(order);

                Transaction tx = Transaction.builder()
                                .order(order)
                                .user(buyer)
                                .amount(totalPrice)
                                .postBalance(buyer.getWalletBalance())
                                .type(TransactionType.ESCROW_LOCK)
                                .status(TransactionStatus.SUCCESS)
                                .note("Tạm giữ tiền giao dịch - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                .build();
                transactionRepository.save(tx);
                log.info("Đã khóa ví Escrow cho đơn hàng AI_VERIFIED: {}", order.getId());
        }

        @Override
        public OrderDto.OrderResponse getOrderById(UUID id) {
                Order order = orderRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "Không tìm thấy đơn hàng với ID: " + id));

                // IDOR Check: Chỉ người mua, người bán, hoặc admin mới được phép xem đơn hàng
                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                boolean isBuyer = order.getBuyer().getId().equals(currentUserId);
                boolean isSeller = order.getListing().getSeller().getId().equals(currentUserId);

                if (!isBuyer && !isSeller) {
                        throw new org.springframework.security.access.AccessDeniedException(
                                        "Bạn không có quyền xem đơn hàng này");
                }

                return mapToDto(order);
        }

    @Override
    public List<OrderDto.OrderResponse> getMyOrders() {
        UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        List<Order> boughtOrders = orderRepository.findByBuyerIdOrderByCreatedAtDesc(currentUserId);
        List<Order> soldOrders = orderRepository.findByListingSellerIdOrderByCreatedAtDesc(currentUserId);

        java.util.List<Order> allOrders = new java.util.ArrayList<>();
        allOrders.addAll(boughtOrders);
        allOrders.addAll(soldOrders);
        allOrders.sort((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()));

        return allOrders.stream()
                .map(this::mapToDto)
                .toList();
    }

        @Override
        public List<OrderDto.OrderResponse> getSellerOrders(UUID sellerId) {
                return orderRepository.findByListingSellerIdOrderByCreatedAtDesc(sellerId)
                                .stream()
                                .map(this::mapToDto)
                                .toList();
        }

        private OrderDto.OrderResponse mapToDto(Order entity) {
                java.util.List<OrderDto.DigitalProofSummary> proofSummaries = new java.util.ArrayList<>();
                List<DigitalProof> proofs = entity.getProofs() != null
                                ? new java.util.ArrayList<>(entity.getProofs())
                                : java.util.Collections.emptyList();
                proofs.sort((left, right) -> {
                        Integer leftIndex = left.getBatchIndex() != null ? left.getBatchIndex() : Integer.MAX_VALUE;
                        Integer rightIndex = right.getBatchIndex() != null ? right.getBatchIndex() : Integer.MAX_VALUE;
                        int indexCompare = leftIndex.compareTo(rightIndex);
                        if (indexCompare != 0) {
                                return indexCompare;
                        }
                        if (left.getCreatedAt() == null || right.getCreatedAt() == null) {
                                return 0;
                        }
                        return left.getCreatedAt().compareTo(right.getCreatedAt());
                });

                if (!proofs.isEmpty()) {
                        for (DigitalProof p : proofs) {
                                proofSummaries.add(OrderDto.DigitalProofSummary.builder()
                                                .id(p.getId().toString())
                                                .proofRole(p.getProofRole() != null ? p.getProofRole().name() : null)
                                                .batchName(p.getBatchName())
                                                .batchIndex(p.getBatchIndex())
                                                .batchExpectedQuantity(p.getBatchExpectedQuantity())
                                                .aiFishCount(p.getAiFishCount())
                                                .status(p.getStatus())
                                                .errorMessage(p.getErrorMessage())
                                                .videoUrl(p.getVideoUrl())
                                                .videoPublicId(p.getVideoPublicId())
                                                .aiImageUrl(p.getAiImageUrl())
                                                .proofHash(p.getProofHash())
                                                .createdAt(p.getCreatedAt())
                                                .build());
                        }
                }

                String thumbnailUrl = entity.getListing().getThumbnailUrl();
                if ((thumbnailUrl == null || thumbnailUrl.isEmpty()) && !entity.getListing().getImages().isEmpty()) {
                        thumbnailUrl = entity.getListing().getImages().get(0).getImageUrl();
                }

                int expectedQuantity = entity.getFinalQuantity() != null ? entity.getFinalQuantity() : 0;
                int sellerTotal = sumSuccessfulProofs(proofs, ProofRole.SELLER);
                int buyerTotal = sumSuccessfulProofs(proofs, ProofRole.BUYER);

                return OrderDto.OrderResponse.builder()
                                .id(entity.getId().toString())
                                .listingTitle(entity.getListing().getTitle())
                                .listingThumbnailUrl(thumbnailUrl)
                                .buyerName(entity.getBuyer().getFullName())
                                .buyerId(entity.getBuyer().getId().toString())
                                .sellerName(entity.getListing().getSeller().getFullName())
                                .sellerId(entity.getListing().getSeller().getId().toString())
                                .unitPriceAtPurchase(entity.getUnitPriceAtPurchase())
                                .finalQuantity(entity.getFinalQuantity())
                                .totalPrice(entity.getTotalPrice())
                                .shippingAddress(entity.getShippingAddress())
                                .status(entity.getStatus())
                                .createdAt(entity.getCreatedAt())
                                .proofs(proofSummaries)
                                .aiExpectedQuantity(expectedQuantity)
                                .aiTolerancePercent(AI_TOLERANCE_PERCENT)
                                .sellerAiTotalCount(sellerTotal)
                                .sellerAiSuccessfulBatchCount(countSuccessfulProofs(proofs, ProofRole.SELLER))
                                .sellerAiProgressPercent(progressPercent(sellerTotal, expectedQuantity))
                                .sellerAiDiscrepancyPercent(discrepancyPercent(sellerTotal, expectedQuantity))
                                .sellerAiVerificationStatus(verificationStatus(sellerTotal, expectedQuantity))
                                .buyerAiTotalCount(buyerTotal)
                                .buyerAiSuccessfulBatchCount(countSuccessfulProofs(proofs, ProofRole.BUYER))
                                .buyerAiProgressPercent(progressPercent(buyerTotal, expectedQuantity))
                                .buyerAiDiscrepancyPercent(discrepancyPercent(buyerTotal, expectedQuantity))
                                .buyerAiVerificationStatus(verificationStatus(buyerTotal, expectedQuantity))
                                .disputeReason(entity.getDisputeReason())
                                .sellerResponse(entity.getSellerResponse())
                                .build();
        }

        @Override
        @Transactional
        public void completeOrder(UUID id) {
                fixDatabaseConstraint();
                Order order = orderRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "Không tìm thấy đơn hàng với ID: " + id));

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                if (!order.getBuyer().getId().equals(currentUserId)) {
                        throw new IllegalArgumentException("Chỉ người mua mới được phép xác nhận hoàn thành đơn hàng.");
                }

                if (order.getStatus() != OrderStatus.DELIVERED && order.getStatus() != OrderStatus.AI_VERIFIED && order.getStatus() != OrderStatus.SHIPPING) {
                        throw new IllegalArgumentException(
                                        "Bạn chỉ có thể xác nhận hoàn tất sau khi đơn hàng đã đếm AI hoặc đang giao hàng (AI_VERIFIED / DELIVERED / SHIPPING).");
                }

                OrderStatus previousStatus = order.getStatus();
                order.setStatus(com.aquatrade.core.domain.enums.OrderStatus.READY_TO_PAYOUT);
                orderRepository.save(order);
                publishOrderStatusChangedEvent(order, previousStatus, order.getStatus(), currentUserId,
                                "Buyer confirmed delivery. Order is ready for payout.");
                log.info("Order {} đã được Buyer xác nhận nhận hàng. Đang chờ Admin duyệt chi (READY_TO_PAYOUT).", id);
        }

        @Override
        @Transactional
        public void approvePayout(UUID id) {
                Order order = orderRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "Không tìm thấy đơn hàng với ID: " + id));

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                User currentUser = userRepository.findById(currentUserId).get();
                if (currentUser.getRole() != com.aquatrade.core.domain.enums.Role.ADMIN) {
                        throw new SecurityException("Chỉ Quản trị viên mới có quyền duyệt giải ngân tiền.");
                }

                if (order.getStatus() != OrderStatus.READY_TO_PAYOUT && order.getStatus() != OrderStatus.AI_VERIFIED && order.getStatus() != OrderStatus.DELIVERED) {
                        throw new IllegalArgumentException(
                                        "Đơn hàng chưa ở trạng thái sẵn sàng giải ngân (Cần READY_TO_PAYOUT hoặc AI_VERIFIED hoặc DELIVERED).");
                }

                // --- LOGIC TÍNH TIỀN THEO MÔ HÌNH MỚI ---
                // Buyer Trả = (Giá cá * Số lượng) + 50k Ship + 25k Phí AI
                BigDecimal unitPrice = order.getUnitPriceAtPurchase();
                BigDecimal finalQuantity = BigDecimal.valueOf(order.getFinalQuantity());
                
                BigDecimal sellerPayout = unitPrice.multiply(finalQuantity); // Người bán nhận đúng tiền hàng
                BigDecimal adminIncome = new BigDecimal("25000"); // Admin nhận đúng phí AI
                BigDecimal shippingFee = new BigDecimal("50000"); // Phí ship "mất đi" cho shipper

                // 1. Cộng tiền cho Người bán (Chỉ tiền hàng)
                User seller = order.getListing().getSeller();
                BigDecimal currentSellerBalance = seller.getWalletBalance() != null ? seller.getWalletBalance()
                                : BigDecimal.ZERO;
                seller.setWalletBalance(currentSellerBalance.add(sellerPayout));
                userRepository.save(seller);

                // 2. Chuyển tiền cho Platform (Cộng vào ví Admin và Treasury)
                SystemTreasury treasury = systemTreasuryRepository.findById(1)
                                .orElse(SystemTreasury.builder().id(1).totalRevenue(BigDecimal.ZERO).build());
                treasury.setTotalRevenue(treasury.getTotalRevenue().add(adminIncome));
                systemTreasuryRepository.save(treasury);

                // Cộng trực tiếp vào ví của user Admin để hiển thị trên UI
                User adminUser = userRepository.findByRole(Role.ADMIN).stream().findFirst().orElse(null);
                if (adminUser != null) {
                        BigDecimal currentAdminBalance = adminUser.getWalletBalance() != null ? adminUser.getWalletBalance() : BigDecimal.ZERO;
                        adminUser.setWalletBalance(currentAdminBalance.add(adminIncome));
                        userRepository.save(adminUser);
                }

                // 3. Log Transaction cho Seller (Người bán)
                Transaction sellerTx = Transaction.builder()
                                .order(order)
                                .user(seller)
                                .amount(sellerPayout)
                                .postBalance(seller.getWalletBalance())
                                .type(TransactionType.ORDER_PAYOUT)
                                .status(TransactionStatus.SUCCESS)
                                .note("Nhận tiền bán hàng - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                .build();
                transactionRepository.save(sellerTx);
                
                // 3.5 Log phí sàn cho Platform (Chỉ Admin thấy phí AI)
                User admin = userRepository.findByRole(Role.ADMIN).stream().findFirst().orElse(currentUser);
                Transaction commissionTx = Transaction.builder()
                                .order(order)
                                .user(admin) 
                                .amount(adminIncome)
                                .postBalance(BigDecimal.ZERO) 
                                .type(TransactionType.PLATFORM_COMMISSION)
                                .status(TransactionStatus.SUCCESS)
                                .note("Thu phí dịch vụ AI - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                .build();
                transactionRepository.save(commissionTx);

                // 3.6 Log xác nhận giải phóng tiền cho Buyer (Người mua)
                Transaction buyerTx = Transaction.builder()
                                .order(order)
                                .user(order.getBuyer())
                                .amount(order.getTotalPrice())
                                .postBalance(order.getBuyer().getWalletBalance())
                                .type(TransactionType.ESCROW_RELEASE)
                                .status(TransactionStatus.SUCCESS)
                                .note("Giao dịch hoàn tất - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                .build();
                transactionRepository.save(buyerTx);

                // 4. Chốt trạng thái Order
                OrderStatus previousStatus = order.getStatus();
                order.setStatus(com.aquatrade.core.domain.enums.OrderStatus.COMPLETED);
                orderRepository.save(order);
                publishOrderStatusChangedEvent(order, previousStatus, order.getStatus(), currentUserId,
                                "Payout approved. Order completed.");
                publishPayoutApprovedEvent(order, sellerPayout, adminIncome, currentUserId);

                log.info("Admin đã duyệt giải ngân cho Order {}. Seller {} nhận: {}đ. Platform nhận: {}đ",
                                id, seller.getFullName(), sellerPayout, adminIncome);

                eventPublisher.publishEvent(new com.aquatrade.core.domain.event.OrderCompletedEvent(order));
        }

        @Override
        @Transactional
        public void cancelOrder(UUID id) {
                Order order = orderRepository.findById(id)
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "Không tìm thấy đơn hàng với ID: " + id));

                if (order.getStatus() == OrderStatus.COMPLETED || order.getStatus() == OrderStatus.CANCELLED) {
                        throw new IllegalArgumentException("Đơn hàng không thể hủy trong trạng thái hiện tại.");
                }

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                if (!order.getBuyer().getId().equals(currentUserId)) {
                        throw new IllegalArgumentException("Chỉ người mua (hoặc Admin) mới được quyền hủy đơn.");
                }

                BigDecimal refundAmount = order.getTotalPrice();
                User buyer = order.getBuyer();
                buyer.setWalletBalance(buyer.getWalletBalance().add(refundAmount));
                userRepository.save(buyer);

                Transaction refundTx = Transaction.builder()
                                .order(order)
                                .user(buyer)
                                .amount(refundAmount)
                                .postBalance(buyer.getWalletBalance())
                                .type(TransactionType.REFUND)
                                .status(TransactionStatus.SUCCESS)
                                .build();
                transactionRepository.save(refundTx);

                OrderStatus previousStatus = order.getStatus();
                order.setStatus(OrderStatus.CANCELLED);
                orderRepository.save(order);
                publishOrderStatusChangedEvent(order, previousStatus, order.getStatus(), currentUserId,
                                "Order cancelled and buyer refunded.");

                log.info("Order {} cancelled. Refunded {} to Buyer {}.", order.getId(), refundAmount, buyer.getId());
        }

        @Override
        @Transactional
        public void confirmOrderQuantity(UUID orderId) {
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException(
                                                "Không tìm thấy đơn hàng với ID: " + orderId));

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                if (!order.getBuyer().getId().equals(currentUserId)) {
                        throw new IllegalArgumentException(
                                        "Chỉ người mua mới có quyền đối soát số lượng cho đơn hàng này.");
                }

                if (order.getStatus() != OrderStatus.AI_VERIFIED) {
                        throw new IllegalStateException("Đơn hàng chưa ở trạng thái chờ xác nhận (AI_VERIFIED).");
                }

                List<DigitalProof> proofs = order.getProofs();
                if (proofs == null || proofs.isEmpty()) {
                        throw new IllegalStateException("Đơn hàng thiếu Bằng chứng số học (DigitalProof).");
                }

                int sellerTotal = proofs.stream()
                                .filter(p -> ProofRole.SELLER == p.getProofRole() && p.getAiFishCount() != null)
                                .mapToInt(DigitalProof::getAiFishCount).sum();

                int buyerTotal = proofs.stream()
                                .filter(p -> ProofRole.BUYER == p.getProofRole() && p.getAiFishCount() != null)
                                .mapToInt(DigitalProof::getAiFishCount).sum();

                if (sellerTotal == 0) {
                        throw new IllegalStateException("Bên bán chưa có dữ liệu đếm AI hợp lệ.");
                }
                if (buyerTotal == 0) {
                        throw new IllegalStateException("Bên mua chưa thực hiện đếm AI để đối soát.");
                }

                double discrepancy = Math.abs(sellerTotal - buyerTotal) / (double) sellerTotal;

                if (discrepancy > 0.10) {
                        order.setStatus(OrderStatus.DISPUTED);
                        log.warn("[DISCREPANCY ALERT] Order {}: Seller Total = {}, Buyer Total = {}. Discrepancy = {}%. Status -> DISPUTED.",
                                        orderId, sellerTotal, buyerTotal, String.format("%.2f", discrepancy * 100));
                } else {
                        order.setStatus(OrderStatus.READY_TO_PAYOUT);
                        order.setFinalQuantity(buyerTotal);
                        log.info("[CONFIRMATION SUCCESS] Order {}: Seller Total = {}, Buyer Total = {}. Status -> READY_TO_PAYOUT.",
                                        orderId, sellerTotal, buyerTotal);
                }

                orderRepository.save(order);
        }

        @Override
        @Transactional
        public void updateDigitalProof(UUID orderId, UUID proofId, AIDetectionDto.DonePayload aiResult) {
                log.info(">>> [DEBUG 5/5] Received AI results callback from FastAPI for Order: {}, Proof: {}, Count: {}, Status: {}", 
                                orderId, proofId, aiResult.getAiFishCount(), aiResult.getStatus());
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Order not found"));

                DigitalProof proof = digitalProofRepository.findById(proofId)
                                .orElseThrow(() -> new IllegalArgumentException("Proof not found"));

                if (!proof.getOrder().getId().equals(order.getId())) {
                        throw new IllegalArgumentException("Proof does not belong to this order");
                }

                if ("FAILED".equals(aiResult.getStatus())) {
                        proof.setStatus("FAILED");
                        proof.setErrorMessage(aiResult.getErrorMessage());
                        digitalProofRepository.save(proof);
                        aiResult.setBatchIndex(proof.getBatchIndex());
                        aiResult.setBatchName(proof.getBatchName());
                        aiResult.setExpectedQuantity(order.getFinalQuantity());
                        aiResult.setAiTolerancePercent(AI_TOLERANCE_PERCENT);
                        publishAiFailedEvent(orderId, proof, aiResult.getErrorMessage());
                        messagingTemplate.convertAndSend("/topic/orders/" + orderId, aiResult);
                        return;
                }

                proof.setAiFishCount(aiResult.getAiFishCount());
                proof.setProofHash(aiResult.getProofHash());
                proof.setAiImageUrl(aiResult.getAiImageUrl());
                proof.setStatus("SUCCESS");

                digitalProofRepository.save(proof);
                enrichAiResult(order, proof, aiResult);

                // KHÔNG TỰ ĐỘNG CHUYỂN TRẠNG THÁI ĐƠN HÀNG SANG AI_VERIFIED!
                // Để Người bán chủ động xem kết quả, nếu đồng ý mới bấm "Gửi kết quả cho Người mua" từ Web Dashboard.
                /*
                if (order.getStatus() == OrderStatus.COUNTING_AI) {
                        order.setStatus(OrderStatus.AI_VERIFIED);
                        orderRepository.save(order);
                }
                */

                messagingTemplate.convertAndSend("/topic/orders/" + orderId, aiResult);
                publishAiDoneEvent(orderId, proof, aiResult);
        }

        @Override
        @Transactional
        public void startAiAnalysis(UUID orderId, String videoUrl, String videoPublicId, String batchName,
                        Integer batchExpectedQuantity) {
                log.info(">>> [DEBUG 1/5] Received start-ai request from Frontend for Order: {}, Video: {}", orderId, videoUrl);
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Order not found"));

                if (order.getStatus() != OrderStatus.ESCROW_LOCKED && order.getStatus() != OrderStatus.COUNTING_AI
                                && order.getStatus() != OrderStatus.AI_VERIFIED && order.getStatus() != OrderStatus.PENDING
                                && order.getStatus() != OrderStatus.PREPARING) {
                        throw new IllegalStateException("Đơn hàng không ở trạng thái hợp lệ để gọi AI.");
                }

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                boolean isBuyer = order.getBuyer().getId().equals(currentUserId);
                boolean isSeller = order.getListing().getSeller().getId().equals(currentUserId);

                if (!isBuyer && !isSeller) {
                        throw new IllegalArgumentException("Chỉ người mua hoặc người bán mới được gọi AI.");
                }

                ProofRole role = isBuyer ? ProofRole.BUYER : ProofRole.SELLER;

                List<DigitalProof> existingProofs = digitalProofRepository
                                .findByOrderIdAndProofRoleOrderByCreatedAtAsc(orderId, role);
                int batchIndex = nextBatchIndex(existingProofs);

                DigitalProof proof = new DigitalProof();
                proof.setOrder(order);
                proof.setVideoUrl(videoUrl);
                proof.setVideoPublicId(videoPublicId);
                proof.setProofHash("PENDING");
                proof.setProofRole(role);
                proof.setBatchIndex(batchIndex);
                proof.setBatchExpectedQuantity(resolveBatchExpectedQuantity(order, existingProofs, role,
                                batchExpectedQuantity));
                proof.setBatchName(resolveBatchName(batchName, role, batchIndex));
                proof = digitalProofRepository.save(proof);
                log.info(">>> [DEBUG 2/5] Saved DigitalProof ID: {} in PENDING state. Publishing AI_COUNT_STARTED event.", proof.getId());
                publishAiStartedEvent(orderId, proof, currentUserId);

                /*
                if (order.getStatus() == OrderStatus.ESCROW_LOCKED 
                    || order.getStatus() == OrderStatus.PENDING
                    || order.getStatus() == OrderStatus.PREPARING
                    || order.getStatus() == OrderStatus.AI_VERIFIED) {
                        order.setStatus(OrderStatus.COUNTING_AI);
                        orderRepository.save(order);
                }
                */

                String callbackUrl = appBaseUrl + "/api/v1/internal/orders/" + orderId + "/proofs/" + proof.getId()
                                + "/ai-result";

                UUID proofId = proof.getId();
                String proofBatchName = proof.getBatchName();
                Integer proofBatchIndex = proof.getBatchIndex();
                Integer proofBatchExpectedQuantity = proof.getBatchExpectedQuantity();

                Runnable triggerAiJob = () -> triggerAiJob(
                                orderId,
                                proofId,
                                videoUrl,
                                videoPublicId,
                                callbackUrl,
                                proofBatchName,
                                proofBatchIndex,
                                proofBatchExpectedQuantity);

                if (TransactionSynchronizationManager.isSynchronizationActive()) {
                        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                                @Override
                                public void afterCommit() {
                                        CompletableFuture.runAsync(triggerAiJob, aiTaskExecutor);
                                }
                        });
                } else {
                        CompletableFuture.runAsync(triggerAiJob, aiTaskExecutor);
                }
        }

        private void triggerAiJob(UUID orderId, UUID proofId, String videoUrl, String videoPublicId,
                        String callbackUrl, String batchName, Integer batchIndex, Integer batchExpectedQuantity) {

                Map<String, String> aiRequest = new HashMap<>();
                aiRequest.put("orderId", orderId.toString());
                aiRequest.put("proofId", proofId.toString());
                aiRequest.put("videoUrl", videoUrl);
                aiRequest.put("videoPublicId", videoPublicId);
                aiRequest.put("callbackUrl", callbackUrl);
                aiRequest.put("batchName", batchName);
                aiRequest.put("batchIndex", String.valueOf(batchIndex));
                aiRequest.put("batchExpectedQuantity", String.valueOf(batchExpectedQuantity));

                log.info(">>> [DEBUG 3/5] Forwarding Job Request to FastAPI AI service at: {} | CallbackUrl: {}", aiServiceUrl, callbackUrl);
                try {
                        Map<String, Object> response = restTemplate.postForObject(aiServiceUrl, aiRequest, Map.class);
                        if (response != null) {
                                log.info(">>> [DEBUG 4/5] FastAPI AI Service responded with: {}", response);
                                String aiStatus = String.valueOf(response.getOrDefault("status", ""));
                                if ("failed".equalsIgnoreCase(aiStatus)) {
                                        String errorMessage = String.valueOf(response.getOrDefault("message",
                                                        "AI Service failed before counting."));
                                        markAiProofFailed(orderId, proofId, errorMessage);
                                        log.warn("AI Job failed before counting for proof {}: {}", proofId,
                                                        errorMessage);
                                        return;
                                }

                                if (response.containsKey("ticketId")) {
                                        log.info("AI Job started successfully for proof {}. Ticket ID: {}",
                                                        proofId, response.get("ticketId"));
                                }
                        }
                } catch (Exception e) {
                        String errorMessage = "He thong kiem dinh AI dang ban hoac gap su co.";
                        log.error("Failed to trigger AI Service for proof {}: {}", proofId, e.getMessage());
                        markAiProofFailed(orderId, proofId, errorMessage);
                }
        }

        private void markAiProofFailed(UUID orderId, UUID proofId, String errorMessage) {
                DigitalProof proof = digitalProofRepository.findById(proofId).orElse(null);
                if (proof == null) {
                        log.warn("Cannot mark AI proof {} as FAILED because it was not found. Publishing failure event only.",
                                        proofId);
                        proof = new DigitalProof();
                        proof.setId(proofId);
                        proof.setStatus("FAILED");
                        proof.setErrorMessage(errorMessage);
                } else {
                        proof.setStatus("FAILED");
                        proof.setErrorMessage(errorMessage);
                        digitalProofRepository.save(proof);
                }

                AIDetectionDto.DonePayload failPayload = AIDetectionDto.DonePayload.builder()
                                .status("FAILED")
                                .orderId(orderId.toString())
                                .errorMessage(errorMessage)
                                .build();
                publishAiFailedEvent(orderId, proof, errorMessage);
                messagingTemplate.convertAndSend("/topic/orders/" + orderId, failPayload);
        }

        @Scheduled(fixedDelay = 300000)
        @Transactional
        public void cleanupPendingProofs() {
                LocalDateTime tenMinutesAgo = LocalDateTime.now().minusMinutes(10);
                List<DigitalProof> stuckProofs = digitalProofRepository.findByStatusAndCreatedAtBefore("PENDING",
                                tenMinutesAgo);

                if (!stuckProofs.isEmpty()) {
                        log.info("Found {} stuck AI proofs. Marking as FAILED.", stuckProofs.size());
                        for (DigitalProof proof : stuckProofs) {
                                proof.setStatus("FAILED");
                                proof.setErrorMessage("AI Service timeout (10 minutes). Please try again.");
                                digitalProofRepository.save(proof);

                                AIDetectionDto.DonePayload failPayload = AIDetectionDto.DonePayload.builder()
                                                .status("FAILED")
                                                .orderId(proof.getOrder().getId().toString())
                                                .errorMessage(proof.getErrorMessage())
                                                .build();
                                publishAiFailedEvent(proof.getOrder().getId(), proof, proof.getErrorMessage());
                                messagingTemplate.convertAndSend("/topic/orders/" + proof.getOrder().getId(),
                                                failPayload);
                        }
                }
        }

        private void publishAiStartedEvent(UUID orderId, DigitalProof proof, UUID actorUserId) {
                Map<String, Object> payload = new HashMap<>();
                putIfNotNull(payload, "proofId", proof.getId());
                putIfNotNull(payload, "proofRole", proof.getProofRole() != null ? proof.getProofRole().name() : null);
                putIfNotNull(payload, "videoUrl", proof.getVideoUrl());
                putIfNotNull(payload, "videoPublicId", proof.getVideoPublicId());
                putIfNotNull(payload, "batchName", proof.getBatchName());
                putIfNotNull(payload, "batchIndex", proof.getBatchIndex());
                putIfNotNull(payload, "batchExpectedQuantity", proof.getBatchExpectedQuantity());
                payload.put("status", "PENDING");
                payload.put("message", "AI analysis started");

                RealtimeEvent event = realtimeEventFactory.orderEvent(
                                RealtimeEventType.AI_COUNT_STARTED,
                                orderId,
                                actorUserId,
                                payload);
                realtimeEventPublisher.publish(event);
        }

        private void publishAiDoneEvent(UUID orderId, DigitalProof proof, AIDetectionDto.DonePayload aiResult) {
                Map<String, Object> payload = new HashMap<>();
                putIfNotNull(payload, "proofId", proof.getId());
                putIfNotNull(payload, "proofRole", proof.getProofRole() != null ? proof.getProofRole().name() : null);
                putIfNotNull(payload, "batchName", proof.getBatchName());
                putIfNotNull(payload, "batchIndex", proof.getBatchIndex());
                putIfNotNull(payload, "batchExpectedQuantity", proof.getBatchExpectedQuantity());
                putIfNotNull(payload, "aiFishCount", aiResult.getAiFishCount());
                putIfNotNull(payload, "healthScore", aiResult.getHealthScore());
                putIfNotNull(payload, "qualityStatus", aiResult.getQualityStatus());
                putIfNotNull(payload, "aiImageUrl", aiResult.getAiImageUrl());
                putIfNotNull(payload, "proofHash", aiResult.getProofHash());
                putIfNotNull(payload, "expectedQuantity", aiResult.getExpectedQuantity());
                putIfNotNull(payload, "aiTolerancePercent", aiResult.getAiTolerancePercent());
                putIfNotNull(payload, "sellerAiTotalCount", aiResult.getSellerAiTotalCount());
                putIfNotNull(payload, "sellerAiSuccessfulBatchCount", aiResult.getSellerAiSuccessfulBatchCount());
                putIfNotNull(payload, "aiProgressPercent", aiResult.getAiProgressPercent());
                putIfNotNull(payload, "aiDiscrepancyPercent", aiResult.getAiDiscrepancyPercent());
                putIfNotNull(payload, "aiVerificationStatus", aiResult.getAiVerificationStatus());
                putIfNotNull(payload, "averageSize", aiResult.getAverageSize());
                putIfNotNull(payload, "impuritiesCount", aiResult.getImpuritiesCount());
                putIfNotNull(payload, "colorUniformity", aiResult.getColorUniformity());
                putIfNotNull(payload, "aiNotes", aiResult.getAiNotes());
                payload.put("status", aiResult.getStatus() != null ? aiResult.getStatus() : "DONE");
                payload.put("message", "AI count completed");

                RealtimeEvent event = realtimeEventFactory.orderEvent(
                                RealtimeEventType.AI_COUNT_DONE,
                                orderId,
                                null,
                                payload);
                realtimeEventPublisher.publish(event);
        }

        private void publishAiFailedEvent(UUID orderId, DigitalProof proof, String reason) {
                Map<String, Object> payload = new HashMap<>();
                putIfNotNull(payload, "proofId", proof.getId());
                putIfNotNull(payload, "proofRole", proof.getProofRole() != null ? proof.getProofRole().name() : null);
                putIfNotNull(payload, "batchName", proof.getBatchName());
                putIfNotNull(payload, "batchIndex", proof.getBatchIndex());
                putIfNotNull(payload, "batchExpectedQuantity", proof.getBatchExpectedQuantity());
                payload.put("reason", reason != null ? reason : "AI_COUNT_FAILED");
                payload.put("message", reason != null ? reason : "AI count failed");

                RealtimeEvent event = realtimeEventFactory.orderEvent(
                                RealtimeEventType.AI_COUNT_FAILED,
                                orderId,
                                null,
                                payload);
                realtimeEventPublisher.publish(event);
        }

        private void publishOrderStatusChangedEvent(
                        Order order,
                        OrderStatus previousStatus,
                        OrderStatus newStatus,
                        UUID actorUserId,
                        String message) {
                Map<String, Object> payload = new HashMap<>();
                putIfNotNull(payload, "previousStatus", previousStatus != null ? previousStatus.name() : null);
                putIfNotNull(payload, "newStatus", newStatus != null ? newStatus.name() : null);
                putIfNotNull(payload, "message", message);

                RealtimeEvent event = realtimeEventFactory.orderEvent(
                                RealtimeEventType.ORDER_STATUS_CHANGED,
                                order.getId(),
                                actorUserId,
                                payload);
                realtimeEventPublisher.publish(event);
        }

        private void publishDisputeCreatedEvent(Order order, OrderStatus previousStatus, String reason, UUID actorUserId) {
                Map<String, Object> payload = new HashMap<>();
                putIfNotNull(payload, "reason", reason);
                putIfNotNull(payload, "previousStatus", previousStatus != null ? previousStatus.name() : null);
                payload.put("newStatus", OrderStatus.DISPUTED.name());
                payload.put("severity", "NORMAL");
                payload.put("message", "Dispute created for order.");

                RealtimeEvent event = realtimeEventFactory.orderEvent(
                                RealtimeEventType.DISPUTE_CREATED,
                                order.getId(),
                                actorUserId,
                                payload);
                realtimeEventPublisher.publish(event);
        }

        private void publishPayoutApprovedEvent(Order order, BigDecimal sellerPayout, BigDecimal platformFee, UUID actorUserId) {
                Map<String, Object> payload = new HashMap<>();
                putIfNotNull(payload, "sellerId", order.getListing() != null && order.getListing().getSeller() != null
                                ? order.getListing().getSeller().getId()
                                : null);
                putIfNotNull(payload, "sellerAmount", sellerPayout);
                putIfNotNull(payload, "platformFee", platformFee);
                payload.put("message", "Payout approved");

                RealtimeEvent event = realtimeEventFactory.orderEvent(
                                RealtimeEventType.PAYOUT_APPROVED,
                                order.getId(),
                                actorUserId,
                                payload);
                realtimeEventPublisher.publish(event);
        }

        private void putIfNotNull(Map<String, Object> payload, String key, Object value) {
                if (value != null) {
                        payload.put(key, value);
                }
        }

        @Override
        @Transactional
        public void adminReviewOrder(UUID orderId, Integer finalQuantity) {
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

                BigDecimal unitPrice = order.getUnitPriceAtPurchase();
                BigDecimal shippingFee = new BigDecimal("50000");
                BigDecimal aiFee = new BigDecimal("25000");

                BigDecimal newSubtotal = unitPrice.multiply(BigDecimal.valueOf(finalQuantity));
                BigDecimal newTotal = newSubtotal.add(shippingFee).add(aiFee);

                if (newTotal.compareTo(order.getTotalPrice()) < 0) {
                        BigDecimal refundAmount = order.getTotalPrice().subtract(newTotal);
                        User buyer = order.getBuyer();
                        buyer.setWalletBalance(buyer.getWalletBalance().add(refundAmount));
                        userRepository.save(buyer);

                        Transaction refundTx = Transaction.builder()
                                        .order(order)
                                        .user(buyer)
                                        .amount(refundAmount)
                                        .postBalance(buyer.getWalletBalance())
                                        .type(TransactionType.REFUND)
                                        .status(TransactionStatus.SUCCESS)
                                        .note("Hoàn tiền chênh lệch số lượng - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                        .build();
                        transactionRepository.save(refundTx);
                        log.info("Admin điều chỉnh giảm số lượng: Hoàn trả {}đ cho Buyer {}", refundAmount,
                                        buyer.getFullName());
                }

                order.setFinalQuantity(finalQuantity);
                order.setTotalPrice(newTotal);
                OrderStatus previousStatus = order.getStatus();
                order.setStatus(OrderStatus.PREPARING);
                orderRepository.save(order);
                publishOrderStatusChangedEvent(order, previousStatus, order.getStatus(), null,
                                "Admin reviewed final quantity. Order is preparing.");
        }

        @Override
        @Transactional
        public void updateOrderStatus(UUID orderId, OrderStatus newStatus) {
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

                if (order.getStatus() == OrderStatus.COMPLETED) {
                        throw new IllegalArgumentException(
                                        "Đơn hàng đã hoàn tất vĩnh viễn, không thể thay đổi trạng thái!");
                }

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                User currentUser = userRepository.findById(currentUserId)
                                .orElseThrow(() -> new IllegalArgumentException("Người dùng không tồn tại"));

                boolean isAdmin = currentUser.getRole().name().equals("ADMIN");
                boolean isOwnerSeller = order.getListing().getSeller().getId().equals(currentUserId);

                if (!isAdmin && !isOwnerSeller) {
                        throw new SecurityException("Bạn không có quyền cập nhật trạng thái cho đơn hàng này!");
                }

                OrderStatus previousStatus = order.getStatus();
                order.setStatus(newStatus);
                orderRepository.save(order);
                publishOrderStatusChangedEvent(order, previousStatus, newStatus, currentUserId,
                                "Order status updated.");
                log.info("Order {} status updated to {} by {}", orderId, newStatus, currentUser.getUsername());
        }

        @Override
        @Transactional
        public void disputeOrder(UUID orderId, String reason) {
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                if (!order.getBuyer().getId().equals(currentUserId)) {
                        throw new IllegalArgumentException("Chỉ người mua mới được quyền khiếu nại.");
                }

                if (order.getStatus() != OrderStatus.DELIVERED && order.getStatus() != OrderStatus.COMPLETED) {
                        throw new IllegalArgumentException(
                                        "Đơn hàng chưa ở trạng thái có thể khiếu nại (Cần DELIVERED hoặc COMPLETED).");
                }

                OrderStatus previousStatus = order.getStatus();
                order.setStatus(OrderStatus.DISPUTED);
                order.setDisputeReason(reason);
                orderRepository.save(order);
                publishDisputeCreatedEvent(order, previousStatus, reason, currentUserId);
                log.info("Order {} bị khiếu nại bởi Buyer {}. Lý do: {}", orderId, order.getBuyer().getFullName(),
                                reason);
        }

        @Override
        @Transactional
        public void respondToDispute(UUID orderId, String response) {
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                if (!order.getListing().getSeller().getId().equals(currentUserId)) {
                        throw new IllegalArgumentException("Chỉ người bán mới được quyền phản hồi khiếu nại.");
                }

                if (order.getStatus() != OrderStatus.DISPUTED) {
                        throw new IllegalArgumentException("Đơn hàng này không ở trạng thái khiếu nại.");
                }

                order.setSellerResponse(response);
                orderRepository.save(order);
                log.info("Seller {} đã phản hồi khiếu nại cho Order {}: {}",
                                order.getListing().getSeller().getFullName(), orderId, response);
        }

        @Override
        @Transactional
        public void refundOrder(UUID orderId) {
                Order order = orderRepository.findById(orderId)
                                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn hàng"));

                UUID currentUserId = (UUID) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
                User currentUser = userRepository.findById(currentUserId).get();

                boolean isAdmin = currentUser.getRole().name().equals("ADMIN");
                if (!isAdmin) {
                        throw new IllegalArgumentException("Chỉ Admin mới có quyền phê duyệt phán quyết khiếu nại.");
                }

                if (order.getStatus() != OrderStatus.DISPUTED) {
                        throw new IllegalArgumentException("Đơn hàng phải ở trạng thái khiếu nại mới có thể duyệt hoàn tiền.");
                }

                // --- LOGIC HOÀN TIỀN (TRẢ LẠI BUYER) ---
                BigDecimal totalPrice = order.getTotalPrice();
                // Hoàn lại 90% cho người mua, 10% sàn giữ lại làm phí xử lý tranh chấp
                BigDecimal refundAmount = totalPrice.multiply(new BigDecimal("0.90"))
                                .setScale(0, java.math.RoundingMode.DOWN);

                // 1. Cộng tiền cho Người mua
                User buyer = order.getBuyer();
                BigDecimal currentBuyerBalance = buyer.getWalletBalance() != null ? buyer.getWalletBalance() : BigDecimal.ZERO;
                buyer.setWalletBalance(currentBuyerBalance.add(refundAmount));
                userRepository.save(buyer);

                // 2. Chuyển 10% phí cho Platform (Treasury)
                BigDecimal platformFee = totalPrice.subtract(refundAmount);
                SystemTreasury treasury = systemTreasuryRepository.findById(1)
                                .orElse(SystemTreasury.builder().id(1).totalRevenue(BigDecimal.ZERO).build());
                treasury.setTotalRevenue(treasury.getTotalRevenue().add(platformFee));
                systemTreasuryRepository.save(treasury);

                // 3. Log Transaction cho Buyer
                Transaction refundTx = Transaction.builder()
                                .order(order)
                                .user(buyer)
                                .amount(refundAmount)
                                .postBalance(buyer.getWalletBalance())
                                .type(TransactionType.REFUND)
                                .status(TransactionStatus.SUCCESS)
                                .note("Hoàn tiền khiếu nại (90%) - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                .build();
                transactionRepository.save(refundTx);

                // 3.5 Log Transaction cho Seller (Để họ biết đơn bị hoàn tiền)
                Transaction sellerRefundLog = Transaction.builder()
                                .order(order)
                                .user(order.getListing().getSeller())
                                .amount(BigDecimal.ZERO)
                                .postBalance(order.getListing().getSeller().getWalletBalance())
                                .type(TransactionType.CANCELLED)
                                .status(TransactionStatus.FAILED)
                                .note("Đơn hàng bị khiếu nại & Hoàn tiền - Đơn hàng #" + order.getId().toString().substring(0, 8).toUpperCase())
                                .build();
                transactionRepository.save(sellerRefundLog);

                OrderStatus previousStatus = order.getStatus();
                publishOrderStatusChangedEvent(order, previousStatus, OrderStatus.CANCELLED, currentUserId,
                                "Dispute refunded. Order cancelled.");

                // 4. Chốt trạng thái Order
                order.setStatus(OrderStatus.CANCELLED);
                orderRepository.save(order);

                log.info("Admin đã duyệt hoàn tiền cho Order {}. Buyer nhận lại {}đ. Platform thu phí tranh chấp: {}đ",
                                orderId, refundAmount, platformFee);
        }
}
