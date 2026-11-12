package com.aquatrade.core.repository;

import com.aquatrade.core.domain.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface ReviewRepository extends JpaRepository<Review, UUID> {
}
