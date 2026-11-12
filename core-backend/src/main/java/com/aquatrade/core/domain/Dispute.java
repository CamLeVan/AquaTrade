package com.aquatrade.core.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

import com.aquatrade.core.domain.base.BaseObject;
import com.aquatrade.core.domain.enums.DisputeStatus;

@Entity
@Table(name = "disputes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Dispute extends BaseObject {

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false, unique = true)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "complainer_id", nullable = false)
    private User complainer;

    @Column(name = "reason_text", columnDefinition = "TEXT")
    private String reasonText;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private DisputeStatus status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by")
    private User resolvedBy;

    @Column(name = "resolution_note", columnDefinition = "TEXT")
    private String resolutionNote;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    // [SECURITY] Optimistic Locking — chặn 2 Admin đồng thời Refund + ForceComplete cùng 1 Dispute
    @Version
    @Column(name = "version")
    private Integer version;
}
