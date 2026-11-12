package com.aquatrade.core.realtime;

import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class RealtimeEventFactoryTest {

    private final RealtimeEventFactory factory = new RealtimeEventFactory();

    @Test
    void orderEventBuildsRequiredEnvelopeFields() {
        UUID orderId = UUID.randomUUID();
        UUID actorUserId = UUID.randomUUID();
        UUID targetUserId = UUID.randomUUID();

        RealtimeEvent event = factory.orderEvent(
                RealtimeEventType.AI_COUNT_DONE,
                orderId,
                actorUserId,
                List.of(targetUserId),
                Map.of("proofId", "proof-001", "aiFishCount", 5050)
        );

        assertThat(event.getEventId()).isNotBlank();
        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.AI_COUNT_DONE);
        assertThat(event.getVersion()).isEqualTo(1);
        assertThat(event.getOccurredAt()).isNotNull();
        assertThat(event.getCorrelationId()).isNotBlank();
        assertThat(event.getAggregateType()).isEqualTo("ORDER");
        assertThat(event.getAggregateId()).isEqualTo(orderId.toString());
        assertThat(event.getOrderId()).isEqualTo(orderId.toString());
        assertThat(event.getActorUserId()).isEqualTo(actorUserId.toString());
        assertThat(event.getTargetUserIds()).containsExactly(targetUserId.toString());
        assertThat(event.getPayload()).containsEntry("proofId", "proof-001");
        assertThat(event.getPayload()).containsEntry("aiFishCount", 5050);
    }

    @Test
    void userNotificationUsesUserAggregateAndTarget() {
        UUID userId = UUID.randomUUID();

        RealtimeEvent event = factory.userNotification(userId, null, Map.of("title", "New update"));

        assertThat(event.getEventType()).isEqualTo(RealtimeEventType.USER_NOTIFICATION);
        assertThat(event.getAggregateType()).isEqualTo("USER");
        assertThat(event.getAggregateId()).isEqualTo(userId.toString());
        assertThat(event.getTargetUserIds()).containsExactly(userId.toString());
        assertThat(event.getPayload()).containsEntry("title", "New update");
    }
}
