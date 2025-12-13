package com.banking.controller;

import com.banking.dto.response.AccountResponse;
import com.banking.dto.response.ApiResponse;
import com.banking.dto.response.DashboardResponse;
import com.banking.dto.response.TransactionAnalytics;
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
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
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

    @GetMapping("/analytics")
    public ResponseEntity<ApiResponse<TransactionAnalytics>> getTransactionAnalytics(@AuthenticationPrincipal User user) {
        List<Transaction> allTransactions = transactionService.getTransactionsByUserId(user.getId());
        List<Account> accounts = accountService.getAccountsByUserId(user.getId());
        
        TransactionAnalytics analytics = TransactionAnalytics.builder()
                .monthlyData(calculateMonthlyData(allTransactions))
                .typeDistribution(calculateTypeDistribution(allTransactions))
                .dailyCashFlow(calculateDailyCashFlow(allTransactions))
                .accountDistribution(calculateAccountDistribution(accounts))
                .balanceHistory(calculateBalanceHistory(allTransactions, accounts))
                .build();
        
        return ResponseEntity.ok(ApiResponse.success("Analytics retrieved successfully", analytics));
    }

    private TransactionAnalytics.MonthlyData calculateMonthlyData(List<Transaction> transactions) {
        LocalDateTime now = LocalDateTime.now();
        List<String> labels = new ArrayList<>();
        List<BigDecimal> deposits = new ArrayList<>();
        List<BigDecimal> withdrawals = new ArrayList<>();
        
        // Get last 6 months
        for (int i = 5; i >= 0; i--) {
            LocalDateTime monthStart = now.minusMonths(i).withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
            LocalDateTime monthEnd = monthStart.plusMonths(1).minusSeconds(1);
            
            String monthLabel = monthStart.format(DateTimeFormatter.ofPattern("MMM yyyy"));
            labels.add(monthLabel);
            
            // Calculate deposits for this month
            BigDecimal monthDeposits = transactions.stream()
                    .filter(t -> t.getCreatedAt().isAfter(monthStart) && t.getCreatedAt().isBefore(monthEnd))
                    .filter(t -> t.getType() == Transaction.TransactionType.DEPOSIT || 
                                t.getType() == Transaction.TransactionType.TRANSFER_IN)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            deposits.add(monthDeposits);
            
            // Calculate withdrawals for this month
            BigDecimal monthWithdrawals = transactions.stream()
                    .filter(t -> t.getCreatedAt().isAfter(monthStart) && t.getCreatedAt().isBefore(monthEnd))
                    .filter(t -> t.getType() == Transaction.TransactionType.WITHDRAWAL || 
                                t.getType() == Transaction.TransactionType.TRANSFER_OUT)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            withdrawals.add(monthWithdrawals);
        }
        
        return TransactionAnalytics.MonthlyData.builder()
                .labels(labels)
                .deposits(deposits)
                .withdrawals(withdrawals)
                .build();
    }

    private TransactionAnalytics.TypeDistribution calculateTypeDistribution(List<Transaction> transactions) {
        Map<Transaction.TransactionType, Long> typeCounts = transactions.stream()
                .collect(Collectors.groupingBy(Transaction::getType, Collectors.counting()));
        
        return TransactionAnalytics.TypeDistribution.builder()
                .deposits(typeCounts.getOrDefault(Transaction.TransactionType.DEPOSIT, 0L).intValue())
                .withdrawals(typeCounts.getOrDefault(Transaction.TransactionType.WITHDRAWAL, 0L).intValue())
                .transfersOut(typeCounts.getOrDefault(Transaction.TransactionType.TRANSFER_OUT, 0L).intValue())
                .transfersIn(typeCounts.getOrDefault(Transaction.TransactionType.TRANSFER_IN, 0L).intValue())
                .build();
    }

    private TransactionAnalytics.DailyCashFlow calculateDailyCashFlow(List<Transaction> transactions) {
        LocalDateTime now = LocalDateTime.now();
        List<String> labels = new ArrayList<>();
        List<BigDecimal> netFlow = new ArrayList<>();
        
        // Get last 30 days
        for (int i = 29; i >= 0; i--) {
            LocalDateTime dayStart = now.minusDays(i).withHour(0).withMinute(0).withSecond(0);
            LocalDateTime dayEnd = dayStart.plusDays(1).minusSeconds(1);
            
            String dayLabel = dayStart.format(DateTimeFormatter.ofPattern("MMM d"));
            labels.add(dayLabel);
            
            // Calculate income (deposits + transfers in)
            BigDecimal dayIncome = transactions.stream()
                    .filter(t -> t.getCreatedAt().isAfter(dayStart) && t.getCreatedAt().isBefore(dayEnd))
                    .filter(t -> t.getType() == Transaction.TransactionType.DEPOSIT || 
                                t.getType() == Transaction.TransactionType.TRANSFER_IN)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            
            // Calculate expenses (withdrawals + transfers out)
            BigDecimal dayExpenses = transactions.stream()
                    .filter(t -> t.getCreatedAt().isAfter(dayStart) && t.getCreatedAt().isBefore(dayEnd))
                    .filter(t -> t.getType() == Transaction.TransactionType.WITHDRAWAL || 
                                t.getType() == Transaction.TransactionType.TRANSFER_OUT)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            
            // Net flow = income - expenses
            BigDecimal dayNet = dayIncome.subtract(dayExpenses);
            netFlow.add(dayNet);
        }
        
        return TransactionAnalytics.DailyCashFlow.builder()
                .labels(labels)
                .netFlow(netFlow)
                .build();
    }

    private TransactionAnalytics.AccountDistribution calculateAccountDistribution(List<Account> accounts) {
        List<String> labels = new ArrayList<>();
        List<BigDecimal> balances = new ArrayList<>();
        List<String> accountNumbers = new ArrayList<>();
        
        for (Account account : accounts) {
            // Create label with account type
            String label = account.getAccountType().name().charAt(0) + 
                          account.getAccountType().name().substring(1).toLowerCase();
            labels.add(label);
            balances.add(account.getBalance());
            // Store last 4 digits of account number
            String accNum = account.getAccountNumber();
            accountNumbers.add("****" + accNum.substring(accNum.length() - 4));
        }
        
        return TransactionAnalytics.AccountDistribution.builder()
                .labels(labels)
                .balances(balances)
                .accountNumbers(accountNumbers)
                .build();
    }

    private TransactionAnalytics.BalanceHistory calculateBalanceHistory(List<Transaction> transactions, List<Account> accounts) {
        LocalDateTime now = LocalDateTime.now();
        List<String> labels = new ArrayList<>();
        List<BigDecimal> totalBalances = new ArrayList<>();
        
        // Calculate current total balance
        BigDecimal currentTotalBalance = accounts.stream()
                .map(Account::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        // We'll work backwards from current balance
        // For each month, calculate what the balance was at end of that month
        List<BigDecimal> monthlyChanges = new ArrayList<>();
        
        // Get last 6 months
        for (int i = 5; i >= 0; i--) {
            LocalDateTime monthStart = now.minusMonths(i).withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0);
            LocalDateTime monthEnd = monthStart.plusMonths(1).minusSeconds(1);
            
            String monthLabel = monthStart.format(DateTimeFormatter.ofPattern("MMM yyyy"));
            labels.add(monthLabel);
            
            // Calculate net change for this month (income - expenses)
            BigDecimal monthIncome = transactions.stream()
                    .filter(t -> t.getCreatedAt().isAfter(monthStart) && t.getCreatedAt().isBefore(monthEnd))
                    .filter(t -> t.getType() == Transaction.TransactionType.DEPOSIT || 
                                t.getType() == Transaction.TransactionType.TRANSFER_IN)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            
            BigDecimal monthExpenses = transactions.stream()
                    .filter(t -> t.getCreatedAt().isAfter(monthStart) && t.getCreatedAt().isBefore(monthEnd))
                    .filter(t -> t.getType() == Transaction.TransactionType.WITHDRAWAL || 
                                t.getType() == Transaction.TransactionType.TRANSFER_OUT)
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            
            BigDecimal netChange = monthIncome.subtract(monthExpenses);
            monthlyChanges.add(netChange);
        }
        
        // Calculate balance at end of each month by working backwards from current
        // Current month (index 5) ends with currentTotalBalance
        // Previous months can be calculated by subtracting subsequent month changes
        BigDecimal runningBalance = currentTotalBalance;
        BigDecimal[] balanceArray = new BigDecimal[6];
        balanceArray[5] = currentTotalBalance;
        
        for (int i = 4; i >= 0; i--) {
            // Balance at end of month i = balance at end of month (i+1) - change in month (i+1)
            runningBalance = runningBalance.subtract(monthlyChanges.get(i + 1));
            balanceArray[i] = runningBalance.max(BigDecimal.ZERO); // Ensure non-negative
        }
        
        for (BigDecimal balance : balanceArray) {
            totalBalances.add(balance);
        }
        
        return TransactionAnalytics.BalanceHistory.builder()
                .labels(labels)
                .totalBalance(totalBalances)
                .build();
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

