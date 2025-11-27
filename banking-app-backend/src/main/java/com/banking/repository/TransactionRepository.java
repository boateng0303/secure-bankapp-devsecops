package com.banking.repository;

import com.banking.entity.Account;
import com.banking.entity.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    List<Transaction> findByAccountOrderByCreatedAtDesc(Account account);
    
    Page<Transaction> findByAccountOrderByCreatedAtDesc(Account account, Pageable pageable);
    
    List<Transaction> findByAccount_UserIdOrderByCreatedAtDesc(Long userId);
    
    Optional<Transaction> findByTransactionReference(String transactionReference);
    
    @Query("SELECT t FROM Transaction t WHERE t.account.id = :accountId " +
           "AND t.createdAt BETWEEN :startDate AND :endDate " +
           "ORDER BY t.createdAt DESC")
    List<Transaction> findByAccountIdAndDateRange(Long accountId, 
                                                   LocalDateTime startDate, 
                                                   LocalDateTime endDate);
}

