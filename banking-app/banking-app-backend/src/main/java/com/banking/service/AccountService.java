package com.banking.service;

import com.banking.dto.request.CreateAccountRequest;
import com.banking.entity.Account;
import com.banking.entity.User;
import com.banking.exception.BadRequestException;
import com.banking.exception.ResourceNotFoundException;
import com.banking.repository.AccountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class AccountService {

    private final AccountRepository accountRepository;

    public Account getAccountById(Long id) {
        return accountRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Account not found with id: " + id));
    }

    public Account getAccountByNumber(String accountNumber) {
        return accountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new ResourceNotFoundException("Account not found with number: " + accountNumber));
    }

    public List<Account> getAccountsByUser(User user) {
        return accountRepository.findByUser(user);
    }

    public List<Account> getAccountsByUserId(Long userId) {
        return accountRepository.findByUserId(userId);
    }

    public Account saveAccount(Account account) {
        return accountRepository.save(account);
    }

    public boolean existsByAccountNumber(String accountNumber) {
        return accountRepository.existsByAccountNumber(accountNumber);
    }

    public BigDecimal getTotalBalance(Long userId) {
        List<Account> accounts = accountRepository.findByUserId(userId);
        return accounts.stream()
                .map(Account::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public void updateBalance(Account account, BigDecimal newBalance) {
        account.setBalance(newBalance);
        accountRepository.save(account);
    }

    @Transactional
    public Account createAccount(CreateAccountRequest request, User user) {
        // Parse account type
        Account.AccountType accountType;
        try {
            accountType = Account.AccountType.valueOf(request.getAccountType().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Invalid account type. Must be SAVINGS, CHECKING, or INVESTMENT");
        }

        // Check if user already has this type of account
        List<Account> existingAccounts = accountRepository.findByUserId(user.getId());
        boolean hasAccountType = existingAccounts.stream()
                .anyMatch(acc -> acc.getAccountType() == accountType && acc.getStatus() == Account.AccountStatus.ACTIVE);
        
        if (hasAccountType) {
            throw new BadRequestException("You already have an active " + accountType + " account");
        }

        // Create new account
        Account account = Account.builder()
                .accountNumber(generateAccountNumber())
                .accountType(accountType)
                .balance(BigDecimal.ZERO)
                .currency(request.getCurrency() != null ? request.getCurrency() : "USD")
                .status(Account.AccountStatus.ACTIVE)
                .user(user)
                .build();

        return accountRepository.save(account);
    }

    @Transactional
    public Account closeAccount(Long accountId, User user) {
        Account account = getAccountById(accountId);

        // Verify account belongs to user
        if (!account.getUser().getId().equals(user.getId())) {
            throw new BadRequestException("You don't have permission to close this account");
        }

        // Check if account is already closed
        if (account.getStatus() == Account.AccountStatus.CLOSED) {
            throw new BadRequestException("Account is already closed");
        }

        // Check if account has balance
        if (account.getBalance().compareTo(BigDecimal.ZERO) > 0) {
            throw new BadRequestException("Cannot close account with remaining balance. Please withdraw or transfer funds first.");
        }

        // Close the account
        account.setStatus(Account.AccountStatus.CLOSED);
        return accountRepository.save(account);
    }

    public String generateAccountNumber() {
        Random random = new Random();
        StringBuilder accountNumber = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            accountNumber.append(random.nextInt(10));
        }
        
        // Check if account number already exists
        if (existsByAccountNumber(accountNumber.toString())) {
            return generateAccountNumber(); // Recursively generate new number
        }
        
        return accountNumber.toString();
    }

    public List<Account> getActiveAccountsByUserId(Long userId) {
        return accountRepository.findByUserIdAndStatus(userId, Account.AccountStatus.ACTIVE);
    }
}

