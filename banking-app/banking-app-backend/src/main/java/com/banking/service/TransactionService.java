package com.banking.service;

import com.banking.dto.request.DepositRequest;
import com.banking.dto.request.InternalTransferRequest;
import com.banking.dto.request.TransferRequest;
import com.banking.dto.request.WithdrawalRequest;
import com.banking.entity.Account;
import com.banking.entity.Card;
import com.banking.entity.Transaction;
import com.banking.exception.BadRequestException;
import com.banking.exception.InsufficientBalanceException;
import com.banking.exception.ResourceNotFoundException;
import com.banking.repository.CardRepository;
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
    private final CardRepository cardRepository;

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

        // Handle ATM withdrawal - update card spending
        Card usedCard = null;
        if ("ATM".equalsIgnoreCase(request.getWithdrawalMethod())) {
            usedCard = findCardForAtmWithdrawal(request, account, userId);
            
            if (usedCard != null) {
                // Check if withdrawal exceeds available card limit
                BigDecimal availableLimit = usedCard.getSpendingLimit().subtract(usedCard.getCurrentSpent());
                if (request.getAmount().compareTo(availableLimit) > 0) {
                    throw new BadRequestException("Withdrawal exceeds card spending limit. Available: $" + availableLimit);
                }
                
                // Update card's current spent
                BigDecimal newSpent = usedCard.getCurrentSpent().add(request.getAmount());
                usedCard.setCurrentSpent(newSpent);
                cardRepository.save(usedCard);
            }
        }

        // Update balance
        BigDecimal newBalance = account.getBalance().subtract(request.getAmount());
        accountService.updateBalance(account, newBalance);

        // Create transaction record
        String description = request.getDescription() != null ? request.getDescription() : 
                ("ATM".equalsIgnoreCase(request.getWithdrawalMethod()) ? "ATM Withdrawal" : "Withdrawal");
        
        Transaction transaction = Transaction.builder()
                .transactionReference(generateTransactionReference())
                .type(Transaction.TransactionType.WITHDRAWAL)
                .amount(request.getAmount())
                .balanceAfter(newBalance)
                .description(description)
                .status(Transaction.TransactionStatus.COMPLETED)
                .account(account)
                .depositMethod(request.getWithdrawalMethod())
                .build();

        return transactionRepository.save(transaction);
    }

    private Card findCardForAtmWithdrawal(WithdrawalRequest request, Account account, Long userId) {
        // If specific card ID provided, use that
        if (request.getCardId() != null) {
            Card card = cardRepository.findById(request.getCardId())
                    .orElseThrow(() -> new ResourceNotFoundException("Card not found"));
            
            if (!card.getUser().getId().equals(userId)) {
                throw new BadRequestException("Card does not belong to user");
            }
            if (!card.getAccount().getId().equals(account.getId())) {
                throw new BadRequestException("Card is not linked to this account");
            }
            if (card.getStatus() != Card.CardStatus.ACTIVE) {
                throw new BadRequestException("Card is not active");
            }
            
            return card;
        }
        
        // Auto-find an active DEBIT card for this account
        return cardRepository.findFirstByAccountIdAndCardTypeAndStatus(
                account.getId(), 
                Card.CardType.DEBIT, 
                Card.CardStatus.ACTIVE
        ).orElse(null); // Return null if no card found (withdrawal still proceeds without card tracking)
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
        // Check if source and destination accounts are the same
        if (request.getFromAccountId().equals(request.getToAccountId())) {
            throw new BadRequestException("Cannot transfer to the same account");
        }

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

