package com.aquatrade.core.repository;

import com.aquatrade.core.domain.DigitalProof;
import com.aquatrade.core.domain.enums.ProofRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

import java.util.List;
import java.time.LocalDateTime;

@Repository
public interface DigitalProofRepository extends JpaRepository<DigitalProof, UUID> {
    List<DigitalProof> findByStatusAndCreatedAtBefore(String status, LocalDateTime dateTime);
    List<DigitalProof> findByOrderId(UUID orderId);
    List<DigitalProof> findByOrderIdOrderByCreatedAtAsc(UUID orderId);
    List<DigitalProof> findByOrderIdAndProofRoleOrderByCreatedAtAsc(UUID orderId, ProofRole proofRole);
    void deleteByOrderId(UUID orderId);
}
