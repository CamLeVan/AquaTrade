package com.aquatrade.core.repository;

import com.aquatrade.core.domain.Dispute;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface DisputeRepository extends JpaRepository<Dispute, UUID> {
    java.util.List<Dispute> findByStatus(com.aquatrade.core.domain.enums.DisputeStatus status);
    long countByStatus(com.aquatrade.core.domain.enums.DisputeStatus status);
}
