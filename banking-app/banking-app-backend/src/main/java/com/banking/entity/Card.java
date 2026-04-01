package com.banking.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "cards")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
public class Card {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String cardNumber;

    @Column(nullable = false)
    private String cardHolderName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CardType cardType;

    @Column(nullable = false)
    private LocalDate expiryDate;

    @Column(nullable = false)
    private String cvv;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal spendingLimit;

    @Column(nullable = false, precision = 19, scale = 2)
    private BigDecimal currentSpent = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CardStatus status = CardStatus.ACTIVE;

    @Column(nullable = false)
    private Boolean isVirtual = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public enum CardType {
        DEBIT, CREDIT, VIRTUAL
    }

    public enum CardStatus {
        ACTIVE, BLOCKED, EXPIRED, CANCELLED
    }
}

