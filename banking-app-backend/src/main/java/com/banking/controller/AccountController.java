package com.banking.controller;

import com.banking.dto.response.AccountResponse;
import com.banking.dto.response.ApiResponse;
import com.banking.entity.Account;
import com.banking.entity.User;
import com.banking.service.AccountService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final AccountService accountService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<AccountResponse>>> getAllAccounts(@AuthenticationPrincipal User user) {
        List<Account> accounts = accountService.getAccountsByUserId(user.getId());
        List<AccountResponse> response = accounts.stream()
                .map(this::mapToAccountResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success("Accounts retrieved successfully", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AccountResponse>> getAccountById(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        Account account = accountService.getAccountById(id);

        // Verify account belongs to user
        if (!account.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403)
                    .body(ApiResponse.error("You don't have permission to access this account"));
        }

        return ResponseEntity.ok(ApiResponse.success("Account retrieved successfully", mapToAccountResponse(account)));
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
}

