package com.banking.controller;

import com.banking.dto.request.DepositRequest;
import com.banking.dto.request.InternalTransferRequest;
import com.banking.dto.request.TransferRequest;
import com.banking.dto.response.ApiResponse;
import com.banking.dto.response.TransactionResponse;
import com.banking.entity.Transaction;
import com.banking.entity.User;
import com.banking.service.TransactionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/money")
@RequiredArgsConstructor
public class MoneyController {

    private final TransactionService transactionService;

    @PostMapping("/deposit")
    public ResponseEntity<ApiResponse<TransactionResponse>> deposit(
            @Valid @RequestBody DepositRequest request,
            @AuthenticationPrincipal User user) {
        Transaction transaction = transactionService.deposit(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Deposit successful", mapToTransactionResponse(transaction)));
    }

    @PostMapping("/transfer")
    public ResponseEntity<ApiResponse<TransactionResponse>> transfer(
            @Valid @RequestBody TransferRequest request,
            @AuthenticationPrincipal User user) {
        Transaction transaction = transactionService.transfer(request, user.getId());
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Transfer successful", mapToTransactionResponse(transaction)));
    }

    @PostMapping("/internal-transfer")
    public ResponseEntity<ApiResponse<TransactionResponse>> internalTransfer(
            @Valid @RequestBody InternalTransferRequest request,
            @AuthenticationPrincipal User user) {
        Transaction transaction = transactionService.internalTransfer(request, user.getId());
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Internal transfer successful", mapToTransactionResponse(transaction)));
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

