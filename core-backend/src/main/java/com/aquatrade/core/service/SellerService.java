package com.aquatrade.core.service;

import com.aquatrade.core.dto.SellerDto;
import java.util.UUID;

public interface SellerService {
    SellerDto.SellerStatsSummary getSellerStats(UUID sellerId);
}
