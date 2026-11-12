package com.aquatrade.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.aquatrade.core.domain.SystemTreasury;

@Repository
public interface SystemTreasuryRepository extends JpaRepository<SystemTreasury, Integer> {
}
