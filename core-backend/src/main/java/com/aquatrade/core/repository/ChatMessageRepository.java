package com.aquatrade.core.repository;

import com.aquatrade.core.domain.ChatMessage;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {
    @EntityGraph(attributePaths = {"sender"})
    List<ChatMessage> findByOrderIdOrderByCreatedAtAsc(UUID orderId);
}
