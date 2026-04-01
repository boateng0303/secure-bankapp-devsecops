package com.banking.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateAccountRequest {
    
    @NotNull(message = "Account type is required")
    private String accountType; // SAVINGS, CHECKING, INVESTMENT
    
    private String currency; // Optional, defaults to USD
}

