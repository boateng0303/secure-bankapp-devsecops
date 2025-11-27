package com.banking.controller;

import com.banking.dto.response.AccountResponse;
import com.banking.dto.response.ApiResponse;
import com.banking.dto.response.DashboardResponse;
import com.banking.dto.response.TransactionResponse;
import com.banking.entity.Account;
import com.banking.entity.Transaction;
import com.banking.entity.User;
import com.banking.service.AccountService;
import com.banking.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final AccountService accountService;
    private final TransactionService transactionService;

    @GetMapping
    public ResponseEntity<ApiResponse<DashboardResponse>> getDashboard(@AuthenticationPrincipal User user) {
        List<Account> accounts = accountService.getAccountsByUserId(user.getId());
        List<Transaction> allTransactions = transactionService.getTransactionsByUserId(user.getId());

        // Get total balance
        BigDecimal totalBalance = accountService.getTotalBalance(user.getId());

        // Convert to response DTOs
        List<AccountResponse> accountResponses = accounts.stream()
                .map(this::mapToAccountResponse)
                .collect(Collectors.toList());

        // Get recent 5 transactions
        List<TransactionResponse> recentTransactions = allTransactions.stream()
                .limit(5)
                .map(this::mapToTransactionResponse)
                .collect(Collectors.toList());

        DashboardResponse dashboard = DashboardResponse.builder()
                .totalBalance(totalBalance)
                .accounts(accountResponses)
                .recentTransactions(recentTransactions)
                .totalAccounts(accounts.size())
                .totalTransactions(allTransactions.size())
                .build();

        return ResponseEntity.ok(ApiResponse.success("Dashboard data retrieved successfully", dashboard));
    }

    private AccountResponse mapToAccountResponse(Account account) {
        return AccountResponse.builder()
                .id(account.getId())
                .accountNumber(account.getAccountNumber())
                .accountType(account.getAccountType().name())
                .balance(account.getBalance())
                .currency(account.getCurrency())
                .status(account.getStatus().name())
                .createdAt(account.getCreatedAt())
                .build();
    }

    private TransactionResponse mapToTransactionResponse(Transaction transaction) {
        return TransactionResponse.builder()
                .id(transaction.getId())
                .transactionReference(transaction.getTransactionReference())
                .type(transaction.getType().name())
                .amount(transaction.getAmount())
                .balanceAfter(transaction.getBalanceAfter())
                .description(transaction.getDescription())
                .status(transaction.getStatus().name())
                .recipientAccountNumber(transaction.getRecipientAccountNumber())
                .recipientName(transaction.getRecipientName())
                .depositMethod(transaction.getDepositMethod())
                .createdAt(transaction.getCreatedAt())
                .build();
    }
}

