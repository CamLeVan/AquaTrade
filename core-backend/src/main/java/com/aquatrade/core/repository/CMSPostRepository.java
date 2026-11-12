package com.aquatrade.core.repository;

import com.aquatrade.core.domain.CMSPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface CMSPostRepository extends JpaRepository<CMSPost, UUID> {
}
