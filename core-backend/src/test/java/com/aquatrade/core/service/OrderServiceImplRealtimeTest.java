package com.aquatrade.core.service;

import com.aquatrade.core.domain.DigitalProof;
import com.aquatrade.core.domain.Listing;
import com.aquatrade.core.domain.Order;
import com.aquatrade.core.domain.SystemTreasury;
import com.aquatrade.core.domain.User;
import com.aquatrade.core.domain.enums.OrderStatus;
import com.aquatrade.core.domain.enums.ProofRole;
import com.aquatrade.core.domain.enums.Role;
import com.aquatrade.core.dto.AIDetectionDto;
import com.aquatrade.core.realtime.RealtimeEvent;
import com.aquatrade.core.realtime.RealtimeEventFactory;
import com.aquatrade.core.realtime.RealtimeEventPublisher;
import com.aquatrade.core.realtime.RealtimeEventType;
import com.aquatrade.core.repository.DigitalProofRepository;
import com.aquatrade.core.repository.ListingRepository;
import com.aquatrade.core.repository.OrderRepository;
import com.aquatrade.core.repository.SystemTreasuryRepository;
import com.aquatrade.core.repository.TransactionRepository;
import com.aquatrade.core.repository.UserRepository;
import com.aquatrade.core.service.impl.OrderServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class OrderServiceImplRealtimeTest {

    @Mock private OrderRepository orderRepository;
    @Mock private ListingRepository listingRepository;
    @Mock private UserRepository userRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private SystemTreasuryRepository systemTreasuryRepository;
    @Mock private DigitalProofRepository digitalProofRepository;
    @Mock private SimpMessagingTemplate messagingTemplate;
    @Mock private ApplicationEventPublisher eventPublisher;
    @Mock private RestTemplate restTemplate;
    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private RealtimeEventPublisher realtimeEventPublisher;
    @Spy private RealtimeEventFactory realtimeEventFactory = new RealtimeEventFactory();

    @Mock
    private java.util.concurrent.Executor aiTaskExecutor;

    @Captor
    private ArgumentCaptor<RealtimeEvent> eventCaptor;

    @InjectMocks
    private OrderServiceImpl orderService;

    private UUID orderId;
    private UUID proofId;
    private UUID buyerId;
    private UUID sellerId;
    private UUID adminId;
    private Order order;
    private DigitalProof proof;

    @BeforeEach
    void setUp() {
        orderId = UUID.randomUUID();
        proofId = UUID.randomUUID();
        buyerId = UUID.randomUUID();
        sellerId = UUID.randomUUID();
        adminId = UUID.randomUUID();

        // Stub the aiTaskExecutor to run synchronously
        org.mockito.BDDMockito.lenient().doAnswer(invocation -> {
            Runnable runnable = invocation.getArgument(0);
            runnable.run();
            return null;
        }).when(aiTaskExecutor).execute(any(Runnable.class));

        ReflectionTestUtils.setField(orderService, "aiServiceUrl", "http://localhost:8000/ai/v1/jobs");
        ReflectionTestUtils.setField(orderService, "aiTaskExecutor", aiTaskExecutor);

        User buyer = User.builder().fullName("Buyer").role(Role.BUYER).walletBalance(BigDecimal.ZERO).build();
        buyer.setId(buyerId);
        User seller = User.builder().fullName("Seller").role(Role.SELLER).walletBalance(BigDecimal.ZERO).build();
        seller.setId(sellerId);
        Listing listing = Listing.builder().seller(seller).title("Fish batch").build();

        order = Order.builder()
                .buyer(buyer)
                .listing(listing)
                .status(OrderStatus.ESCROW_LOCKED)
                .finalQuantity(100)
                .build();
        order.setId(orderId);

        proof = DigitalProof.builder()
                .order(order)
                .proofRole(ProofRole.SELLER)
                .proofHash("PENDING")
                .batchName("Batch A")
                .batchIndex(1)
                .batchExpectedQuantity(100)
                .videoUrl("https://video.example/a.mp4")
                .videoPublicId("video-public-id")
                .build();
        proof.setId(proofId);

        ReflectionTestUtils.setField(orderService, "aiServiceUrl", "http://localhost:9999/ai/v1/jobs");
        ReflectionTestUtils.setField(orderService, "appBaseUrl", "http://localhost:8080");
    }

    @Test
    void updateDigitalProofPublishesAiCountDoneEvent() {
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(digitalProofRepository.findById(proofId)).willReturn(Optional.of(proof));
        given(digitalProofRepository.findByOrderIdOrderByCreatedAtAsc(orderId)).willReturn(List.of(proof));

        AIDetectionDto.DonePayload aiResult = AIDetectionDto.DonePayload.builder()
                .status("DONE")
                .orderId(orderId.toString())
                .aiFishCount(5050)
                .healthScore(92)
                .qualityStatus("NORMAL")
                .aiImageUrl("https://image.example/result.jpg")
                .proofHash("hash-001")
                .build();

        orderService.updateDigitalProof(orderId, proofId, aiResult);

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.AI_COUNT_DONE);
        assertThat(event.getOrderId()).isEqualTo(orderId.toString());
        assertThat(event.getPayload()).containsEntry("proofId", proofId);
        assertThat(event.getPayload()).containsEntry("proofRole", "SELLER");
        assertThat(event.getPayload()).containsEntry("aiFishCount", 5050);
        assertThat(event.getPayload()).containsEntry("healthScore", 92);
        assertThat(event.getPayload()).containsEntry("qualityStatus", "NORMAL");
        assertThat(event.getPayload()).containsEntry("batchIndex", 1);
        assertThat(event.getPayload()).containsEntry("batchExpectedQuantity", 100);
        assertThat(event.getPayload()).containsEntry("sellerAiTotalCount", 5050);
    }

    @Test
    void updateDigitalProofAggregatesSellerBatchesInRealtimePayload() {
        DigitalProof batch1 = sellerProof(1, 15, "SUCCESS");
        DigitalProof batch2 = sellerProof(2, null, "PENDING");
        batch2.setId(proofId);

        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(digitalProofRepository.findById(proofId)).willReturn(Optional.of(batch2));
        given(digitalProofRepository.findByOrderIdOrderByCreatedAtAsc(orderId)).willReturn(List.of(batch1, batch2));

        AIDetectionDto.DonePayload aiResult = AIDetectionDto.DonePayload.builder()
                .status("DONE")
                .orderId(orderId.toString())
                .aiFishCount(15)
                .aiImageUrl("https://image.example/batch-2.jpg")
                .proofHash("hash-batch-2")
                .build();

        orderService.updateDigitalProof(orderId, proofId, aiResult);

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.AI_COUNT_DONE);
        assertThat(event.getPayload()).containsEntry("aiFishCount", 15);
        assertThat(event.getPayload()).containsEntry("batchIndex", 2);
        assertThat(event.getPayload()).containsEntry("sellerAiTotalCount", 30);
        assertThat(event.getPayload()).containsEntry("sellerAiSuccessfulBatchCount", 2);
        assertThat(event.getPayload()).containsEntry("expectedQuantity", 100);
        assertThat(event.getPayload()).containsEntry("aiProgressPercent", 30);
        assertThat(event.getPayload()).containsEntry("aiDiscrepancyPercent", 70);
        assertThat(event.getPayload()).containsEntry("aiVerificationStatus", "NEEDS_MORE");
    }

    @Test
    void updateDigitalProofPublishesAiCountFailedEvent() {
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(digitalProofRepository.findById(proofId)).willReturn(Optional.of(proof));

        AIDetectionDto.DonePayload aiResult = AIDetectionDto.DonePayload.builder()
                .status("FAILED")
                .orderId(orderId.toString())
                .errorMessage("AI model failed")
                .build();

        orderService.updateDigitalProof(orderId, proofId, aiResult);

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.AI_COUNT_FAILED);
        assertThat(event.getOrderId()).isEqualTo(orderId.toString());
        assertThat(event.getPayload()).containsEntry("proofId", proofId);
        assertThat(event.getPayload()).containsEntry("reason", "AI model failed");
    }

    @Test
    void startAiAnalysisPublishesAiCountStartedEventWhenJobIsAccepted() {
        setCurrentUser(buyerId);
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(digitalProofRepository.findByOrderIdAndProofRoleOrderByCreatedAtAsc(orderId, ProofRole.BUYER))
                .willReturn(List.of());
        given(digitalProofRepository.save(any(DigitalProof.class))).willAnswer(invocation -> {
            DigitalProof savedProof = invocation.getArgument(0);
            savedProof.setId(proofId);
            return savedProof;
        });
        given(restTemplate.postForObject(anyString(), any(Map.class), eq(Map.class)))
                .willReturn(Map.of("status", "accepted", "ticketId", "ticket-001"));

        orderService.startAiAnalysis(orderId, "https://video.example/a.mp4", "video-public-id", "Batch A", 100);

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.AI_COUNT_STARTED);
        assertThat(event.getActorUserId()).isEqualTo(buyerId.toString());
        assertThat(event.getPayload()).containsEntry("proofId", proofId);
        assertThat(event.getPayload()).containsEntry("proofRole", "BUYER");
        assertThat(event.getPayload()).containsEntry("batchIndex", 1);
        assertThat(event.getPayload()).containsEntry("batchExpectedQuantity", 100);
        assertThat(event.getPayload()).containsEntry("status", "PENDING");
    }

    @Test
    void startAiAnalysisPublishesFailedEventWhenAiServiceReturnsFailed() {
        setCurrentUser(buyerId);
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(digitalProofRepository.findByOrderIdAndProofRoleOrderByCreatedAtAsc(orderId, ProofRole.BUYER))
                .willReturn(List.of());
        given(digitalProofRepository.save(any(DigitalProof.class))).willAnswer(invocation -> {
            DigitalProof savedProof = invocation.getArgument(0);
            savedProof.setId(proofId);
            return savedProof;
        });
        given(restTemplate.postForObject(anyString(), any(Map.class), eq(Map.class)))
                .willReturn(Map.of("status", "failed", "message", "AI unavailable"));

        orderService.startAiAnalysis(orderId, "https://video.example/a.mp4", "video-public-id", "Batch A", 100);

        verify(realtimeEventPublisher, times(2)).publish(eventCaptor.capture());
        List<RealtimeEvent> events = eventCaptor.getAllValues();
        assertThat(events).extracting(RealtimeEvent::getEventType)
                .containsExactly(RealtimeEventType.AI_COUNT_STARTED, RealtimeEventType.AI_COUNT_FAILED);
        assertThat(events.get(1).getPayload()).containsEntry("reason", "AI unavailable");
    }

    @Test
    void startAiAnalysisCreatesNextBatchAndKeepsExistingProofs() {
        setCurrentUser(sellerId);
        DigitalProof batch1 = sellerProof(1, 15, "SUCCESS");
        DigitalProof batch2 = sellerProof(2, 15, "SUCCESS");

        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(digitalProofRepository.findByOrderIdAndProofRoleOrderByCreatedAtAsc(orderId, ProofRole.SELLER))
                .willReturn(List.of(batch1, batch2));
        given(digitalProofRepository.save(any(DigitalProof.class))).willAnswer(invocation -> {
            DigitalProof savedProof = invocation.getArgument(0);
            savedProof.setId(proofId);
            return savedProof;
        });
        given(restTemplate.postForObject(anyString(), any(Map.class), eq(Map.class)))
                .willReturn(Map.of("status", "accepted", "ticketId", "ticket-003"));

        orderService.startAiAnalysis(orderId, "https://video.example/c.mp4", "video-public-id-3", "", null);

        ArgumentCaptor<DigitalProof> proofCaptor = ArgumentCaptor.forClass(DigitalProof.class);
        verify(digitalProofRepository).save(proofCaptor.capture());
        DigitalProof savedProof = proofCaptor.getValue();
        assertThat(savedProof.getProofRole()).isEqualTo(ProofRole.SELLER);
        assertThat(savedProof.getBatchIndex()).isEqualTo(3);
        assertThat(savedProof.getBatchExpectedQuantity()).isEqualTo(70);
        assertThat(savedProof.getBatchName()).isEqualTo("Seller batch 3");

        verify(digitalProofRepository, never()).deleteAll(any());
        verify(digitalProofRepository, never()).flush();

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.AI_COUNT_STARTED);
        assertThat(event.getPayload()).containsEntry("batchIndex", 3);
        assertThat(event.getPayload()).containsEntry("batchExpectedQuantity", 70);
    }

    @Test
    void cleanupPendingProofsPublishesFailedEvent() {
        given(digitalProofRepository.findByStatusAndCreatedAtBefore(eq("PENDING"), any()))
                .willReturn(List.of(proof));

        orderService.cleanupPendingProofs();

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.AI_COUNT_FAILED);
        assertThat(event.getOrderId()).isEqualTo(orderId.toString());
        assertThat(event.getPayload()).containsEntry("proofId", proofId);
        assertThat(event.getPayload()).containsEntry("reason", "AI Service timeout (10 minutes). Please try again.");
    }

    @Test
    void updateOrderStatusPublishesOrderStatusChangedEvent() {
        setCurrentUser(sellerId);
        User currentSeller = User.builder().role(Role.SELLER).username("seller").build();
        currentSeller.setId(sellerId);
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(userRepository.findById(sellerId)).willReturn(Optional.of(currentSeller));

        orderService.updateOrderStatus(orderId, OrderStatus.SHIPPING);

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.ORDER_STATUS_CHANGED);
        assertThat(event.getPayload()).containsEntry("previousStatus", "ESCROW_LOCKED");
        assertThat(event.getPayload()).containsEntry("newStatus", "SHIPPING");
    }

    @Test
    void disputeOrderPublishesDisputeCreatedEvent() {
        setCurrentUser(buyerId);
        order.setStatus(OrderStatus.DELIVERED);
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));

        orderService.disputeOrder(orderId, "Count mismatch");

        verify(realtimeEventPublisher).publish(eventCaptor.capture());
        RealtimeEvent event = eventCaptor.getValue();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.DISPUTE_CREATED);
        assertThat(event.getOrderId()).isEqualTo(orderId.toString());
        assertThat(event.getPayload()).containsEntry("reason", "Count mismatch");
        assertThat(event.getPayload()).containsEntry("previousStatus", "DELIVERED");
        assertThat(event.getPayload()).containsEntry("newStatus", "DISPUTED");
    }

    @Test
    void approvePayoutPublishesStatusAndPayoutEvents() {
        setCurrentUser(adminId);
        User admin = User.builder().role(Role.ADMIN).walletBalance(BigDecimal.ZERO).build();
        admin.setId(adminId);
        order.setStatus(OrderStatus.READY_TO_PAYOUT);
        order.setUnitPriceAtPurchase(new BigDecimal("1000"));
        order.setFinalQuantity(10);
        order.setTotalPrice(new BigDecimal("75000"));
        given(orderRepository.findById(orderId)).willReturn(Optional.of(order));
        given(userRepository.findById(adminId)).willReturn(Optional.of(admin));
        given(userRepository.findByRole(Role.ADMIN)).willReturn(List.of(admin));
        given(systemTreasuryRepository.findById(1))
                .willReturn(Optional.of(SystemTreasury.builder().id(1).totalRevenue(BigDecimal.ZERO).build()));

        orderService.approvePayout(orderId);

        verify(realtimeEventPublisher, times(2)).publish(eventCaptor.capture());
        List<RealtimeEvent> events = eventCaptor.getAllValues();
        assertThat(events).extracting(RealtimeEvent::getEventType)
                .containsExactly(RealtimeEventType.ORDER_STATUS_CHANGED, RealtimeEventType.PAYOUT_APPROVED);
        assertThat(events.get(1).getPayload()).containsEntry("sellerAmount", new BigDecimal("10000"));
        assertThat(events.get(1).getPayload()).containsEntry("platformFee", new BigDecimal("25000"));
    }

    private void setCurrentUser(UUID userId) {
        Authentication auth = mock(Authentication.class);
        SecurityContext securityContext = mock(SecurityContext.class);
        given(securityContext.getAuthentication()).willReturn(auth);
        given(auth.getPrincipal()).willReturn(userId);
        SecurityContextHolder.setContext(securityContext);
    }

    private DigitalProof sellerProof(int batchIndex, Integer count, String status) {
        DigitalProof digitalProof = DigitalProof.builder()
                .order(order)
                .proofRole(ProofRole.SELLER)
                .proofHash("hash-" + batchIndex)
                .batchName("Batch " + batchIndex)
                .batchIndex(batchIndex)
                .batchExpectedQuantity(100)
                .aiFishCount(count)
                .status(status)
                .videoUrl("https://video.example/batch-" + batchIndex + ".mp4")
                .videoPublicId("video-public-id-" + batchIndex)
                .build();
        digitalProof.setId(UUID.randomUUID());
        return digitalProof;
    }
}
