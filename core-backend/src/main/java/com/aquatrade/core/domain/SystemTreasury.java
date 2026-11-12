package com.aquatrade.core.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "system_treasury")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SystemTreasury {
    
    @Id
    @Builder.Default
    private Integer id = 1;

    @Builder.Default
    private BigDecimal totalRevenue = BigDecimal.ZERO;

    @Version
    private Integer version;
}
