package com.banking.repository;

import com.banking.entity.Card;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByUserId(Long userId);
    List<Card> findByUserIdAndStatus(Long userId, Card.CardStatus status);
    Optional<Card> findByCardNumber(String cardNumber);
    boolean existsByCardNumber(String cardNumber);
    
    // Methods for linking ATM withdrawals to cards
    List<Card> findByAccountIdAndStatus(Long accountId, Card.CardStatus status);
    Optional<Card> findFirstByAccountIdAndCardTypeAndStatus(Long accountId, Card.CardType cardType, Card.CardStatus status);
    
    // Check for existing active/blocked cards of a type for an account (not expired or cancelled)
    List<Card> findByAccountIdAndCardTypeAndStatusIn(Long accountId, Card.CardType cardType, List<Card.CardStatus> statuses);
}

