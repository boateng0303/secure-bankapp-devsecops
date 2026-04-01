package com.banking.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardResponse {
    private BigDecimal totalBalance;
    private List<AccountResponse> accounts;
    private List<TransactionResponse> recentTransactions;
    private int totalAccounts;
    private int totalTransactions;
}

