package com.banking.service;

import com.banking.dto.request.DepositRequest;
import com.banking.dto.request.InternalTransferRequest;
import com.banking.dto.request.TransferRequest;
import com.banking.dto.request.WithdrawalRequest;
import com.banking.entity.Account;
import com.banking.entity.Transaction;
import com.banking.exception.BadRequestException;
import com.banking.exception.InsufficientBalanceException;
import com.banking.exception.ResourceNotFoundException;
import com.banking.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final AccountService accountService;

    public Transaction getTransactionById(Long id) {
        return transactionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found with id: " + id));
    }

    public List<Transaction> getTransactionsByAccount(Account account) {
        return transactionRepository.findByAccountOrderByCreatedAtDesc(account);
    }

    public Page<Transaction> getTransactionsByAccount(Account account, Pageable pageable) {
        return transactionRepository.findByAccountOrderByCreatedAtDesc(account, pageable);
    }

    public List<Transaction> getTransactionsByUserId(Long userId) {
        return transactionRepository.findByAccount_UserIdOrderByCreatedAtDesc(userId);
    }

    public List<Transaction> getTransactionsByDateRange(Long accountId, LocalDateTime startDate, LocalDateTime endDate) {
        return transactionRepository.findByAccountIdAndDateRange(accountId, startDate, endDate);
    }

    @Transactional
    public Transaction deposit(DepositRequest request) {
        Account account = accountService.getAccountById(request.getAccountId());

        // Check if account is active
        if (account.getStatus() != Account.AccountStatus.ACTIVE) {
            throw new BadRequestException("Cannot deposit to a closed or inactive account");
        }

        // Update balance
        BigDecimal newBalance = account.getBalance().add(request.getAmount());
        accountService.updateBalance(account, newBalance);

        // Create transaction record
        Transaction transaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .type(Transaction.TransactionType.DEPOSIT)
                .amount(request.getAmount())
                .balanceAfter(newBalance)
                .description(request.getDescription() != null ? request.getDescription() : "Deposit")
                .status(Transaction.TransactionStatus.COMPLETED)
                .account(account)
                .depositMethod(request.getDepositMethod())
                .build();

        return transactionRepository.save(transaction);
    }

    @Transactional
    public Transaction withdraw(WithdrawalRequest request, Long userId) {
        Account account = accountService.getAccountById(request.getAccountId());

        // Verify account belongs to user
        if (!account.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to withdraw from this account");
        }

        // Check if account is active
        if (account.getStatus() != Account.AccountStatus.ACTIVE) {
            throw new BadRequestException("Account is not active");
        }

        // Check sufficient balance
        if (account.getBalance().compareTo(request.getAmount()) < 0) {
            throw new InsufficientBalanceException("Insufficient balance for this withdrawal");
        }

        // Update balance
        BigDecimal newBalance = account.getBalance().subtract(request.getAmount());
        accountService.updateBalance(account, newBalance);

        // Create transaction record
        Transaction transaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .type(Transaction.TransactionType.WITHDRAWAL)
                .amount(request.getAmount())
                .balanceAfter(newBalance)
                .description(request.getDescription() != null ? request.getDescription() : "Withdrawal")
                .status(Transaction.TransactionStatus.COMPLETED)
                .account(account)
                .depositMethod(request.getWithdrawalMethod()) // Reusing depositMethod field for withdrawal method
                .build();

        return transactionRepository.save(transaction);
    }

    @Transactional
    public Transaction transfer(TransferRequest request, Long userId) {
        Account fromAccount = accountService.getAccountById(request.getFromAccountId());

        // Verify account belongs to user
        if (!fromAccount.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to transfer from this account");
        }

        // Check if account is active
        if (fromAccount.getStatus() != Account.AccountStatus.ACTIVE) {
            throw new BadRequestException("Account is not active");
        }

        // Check sufficient balance
        if (fromAccount.getBalance().compareTo(request.getAmount()) < 0) {
            throw new InsufficientBalanceException("Insufficient balance for this transfer");
        }

        // Check if recipient account exists
        Account recipientAccount;
        try {
            recipientAccount = accountService.getAccountByNumber(request.getRecipientAccountNumber());
        } catch (ResourceNotFoundException e) {
            throw new BadRequestException("Recipient account not found");
        }

        // Check if recipient account is active
        if (recipientAccount.getStatus() != Account.AccountStatus.ACTIVE) {
            throw new BadRequestException("Cannot transfer to a closed or inactive account");
        }

        // Deduct from sender
        BigDecimal newBalance = fromAccount.getBalance().subtract(request.getAmount());
        accountService.updateBalance(fromAccount, newBalance);

        // Add to recipient
        BigDecimal recipientNewBalance = recipientAccount.getBalance().add(request.getAmount());
        accountService.updateBalance(recipientAccount, recipientNewBalance);

        // Create transaction record for sender
        Transaction senderTransaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .type(Transaction.TransactionType.TRANSFER_OUT)
                .amount(request.getAmount())
                .balanceAfter(newBalance)
                .description(request.getDescription() != null ? request.getDescription() : "Transfer to " + request.getRecipientAccountNumber())
                .status(Transaction.TransactionStatus.COMPLETED)
                .account(fromAccount)
                .recipientAccountNumber(request.getRecipientAccountNumber())
                .recipientName(recipientAccount.getUser().getFirstName() + " " + recipientAccount.getUser().getLastName())
                .build();

        transactionRepository.save(senderTransaction);

        // Create transaction record for recipient
        Transaction recipientTransaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .type(Transaction.TransactionType.TRANSFER_IN)
                .amount(request.getAmount())
                .balanceAfter(recipientNewBalance)
                .description("Transfer from " + fromAccount.getAccountNumber())
                .status(Transaction.TransactionStatus.COMPLETED)
                .account(recipientAccount)
                .recipientAccountNumber(fromAccount.getAccountNumber())
                .recipientName(fromAccount.getUser().getFirstName() + " " + fromAccount.getUser().getLastName())
                .build();

        transactionRepository.save(recipientTransaction);

        return senderTransaction;
    }

    @Transactional
    public Transaction internalTransfer(InternalTransferRequest request, Long userId) {
        Account fromAccount = accountService.getAccountById(request.getFromAccountId());
        Account toAccount = accountService.getAccountById(request.getToAccountId());

        // Verify both accounts belong to user
        if (!fromAccount.getUser().getId().equals(userId) || !toAccount.getUser().getId().equals(userId)) {
            throw new BadRequestException("You don't have permission to transfer between these accounts");
        }

        // Check if accounts are active
        if (fromAccount.getStatus() != Account.AccountStatus.ACTIVE || toAccount.getStatus() != Account.AccountStatus.ACTIVE) {
            throw new BadRequestException("One or both accounts are not active");
        }

        // Check sufficient balance
        if (fromAccount.getBalance().compareTo(request.getAmount()) < 0) {
            throw new InsufficientBalanceException("Insufficient balance for this transfer");
        }

        // Deduct from source account
        BigDecimal fromNewBalance = fromAccount.getBalance().subtract(request.getAmount());
        accountService.updateBalance(fromAccount, fromNewBalance);

        // Add to destination account
        BigDecimal toNewBalance = toAccount.getBalance().add(request.getAmount());
        accountService.updateBalance(toAccount, toNewBalance);

        // Create transaction record for source account
        Transaction fromTransaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .type(Transaction.TransactionType.INTERNAL_TRANSFER)
                .amount(request.getAmount())
                .balanceAfter(fromNewBalance)
                .description(request.getDescription() != null ? request.getDescription() : "Internal transfer to " + toAccount.getAccountNumber())
                .status(Transaction.TransactionStatus.COMPLETED)
                .account(fromAccount)
                .recipientAccountNumber(toAccount.getAccountNumber())
                .build();

        transactionRepository.save(fromTransaction);

        // Create transaction record for destination account
        Transaction toTransaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .type(Transaction.TransactionType.INTERNAL_TRANSFER)
                .amount(request.getAmount())
                .balanceAfter(toNewBalance)
                .description("Internal transfer from " + fromAccount.getAccountNumber())
                .status(Transaction.TransactionStatus.COMPLETED)
                .account(toAccount)
                .recipientAccountNumber(fromAccount.getAccountNumber())
                .build();

        transactionRepository.save(toTransaction);

        return fromTransaction;
    }

    private String generateTransactionReference() {
        return "TXN" + UUID.randomUUID().toString().replace("-", "").substring(0, 12).toUpperCase();
    }
}

