package com.banking.controller;

import com.banking.dto.request.DepositRequest;
import com.banking.dto.request.InternalTransferRequest;
import com.banking.dto.request.TransferRequest;
import com.banking.dto.response.ApiResponse;
import com.banking.dto.response.TransactionResponse;
import com.banking.entity.Account;
import com.banking.entity.Transaction;
import com.banking.entity.User;
import com.banking.service.AccountService;
import com.banking.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/transactions")
@RequiredArgsConstructor
public class TransactionController {

    private final TransactionService transactionService;
    private final AccountService accountService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<TransactionResponse>>> getAllTransactions(@AuthenticationPrincipal User user) {
        List<Transaction> transactions = transactionService.getTransactionsByUserId(user.getId());
        List<TransactionResponse> response = transactions.stream()
                .map(this::mapToTransactionResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success("Transactions retrieved successfully", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TransactionResponse>> getTransactionById(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        Transaction transaction = transactionService.getTransactionById(id);

        // Verify transaction belongs to user
        if (!transaction.getAccount().getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403)
                    .body(ApiResponse.error("You don't have permission to access this transaction"));
        }

        return ResponseEntity.ok(ApiResponse.success("Transaction retrieved successfully", mapToTransactionResponse(transaction)));
    }

    @GetMapping("/account/{accountId}")
    public ResponseEntity<ApiResponse<List<TransactionResponse>>> getTransactionsByAccount(
            @PathVariable Long accountId,
            @AuthenticationPrincipal User user) {
        Account account = accountService.getAccountById(accountId);

        // Verify account belongs to user
        if (!account.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403)
                    .body(ApiResponse.error("You don't have permission to access this account"));
        }

        List<Transaction> transactions = transactionService.getTransactionsByAccount(account);
        List<TransactionResponse> response = transactions.stream()
                .map(this::mapToTransactionResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success("Transactions retrieved successfully", response));
    }

    private TransactionResponse mapToTransactionResponse(Transaction transaction) {
        return TransactionResponse.builder()
                .id(transaction.getId())
                .accountId(transaction.getAccount().getId())
                .accountNumber(transaction.getAccount().getAccountNumber())
                .accountType(transaction.getAccount().getAccountType().name())
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

