package com.banking.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreateCardRequest {
    
    @NotNull(message = "Account ID is required")
    private Long accountId;
    
    @NotBlank(message = "Card type is required")
    private String cardType;
    
    @Positive(message = "Spending limit must be positive")
    private BigDecimal spendingLimit;
    
    private Boolean isVirtual = false;
}

