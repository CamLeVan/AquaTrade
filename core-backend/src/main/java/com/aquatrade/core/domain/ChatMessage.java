package com.aquatrade.core.domain;

import com.aquatrade.core.domain.base.BaseObject;
import com.aquatrade.core.domain.enums.MessageType;
import com.aquatrade.core.domain.enums.OfferStatus;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "chat_messages")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage extends BaseObject {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MessageType messageType;

    @Column(precision = 15, scale = 2)
    private BigDecimal offerPrice;

    @Enumerated(EnumType.STRING)
    private OfferStatus offerStatus;

    @Column(precision = 15, scale = 2)
    private BigDecimal aiRecommendedPrice;
}
