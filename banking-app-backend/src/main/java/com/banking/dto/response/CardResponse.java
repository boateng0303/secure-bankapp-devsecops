package com.banking.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CardResponse {
    private Long id;
    private String cardNumber;
    private String maskedCardNumber;
    private String cardHolderName;
    private String cardType;
    private LocalDate expiryDate;
    private BigDecimal spendingLimit;
    private BigDecimal currentSpent;
    private BigDecimal availableLimit;
    private String status;
    private Boolean isVirtual;
    private Long accountId;
    private String accountNumber;
    private LocalDateTime createdAt;
}

