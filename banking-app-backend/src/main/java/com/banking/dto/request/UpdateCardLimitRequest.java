package com.banking.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateCardLimitRequest {
    
    @NotNull(message = "Card ID is required")
    private Long cardId;
    
    @Positive(message = "New limit must be positive")
    private BigDecimal newLimit;
}

