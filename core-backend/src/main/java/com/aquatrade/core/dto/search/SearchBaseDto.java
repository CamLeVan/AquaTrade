package com.aquatrade.core.dto.search;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class SearchBaseDto {
    private String keyword;
    private Integer pageIndex;
    private Integer pageSize; 
    
}
