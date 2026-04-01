package com.banking.service;

import com.banking.dto.request.CreateCardRequest;
import com.banking.dto.request.UpdateCardLimitRequest;
import com.banking.dto.response.CardResponse;
import com.banking.entity.Account;
import com.banking.entity.Card;
import com.banking.entity.User;
import com.banking.exception.BadRequestException;
import com.banking.exception.ResourceNotFoundException;
import com.banking.repository.AccountRepository;
import com.banking.repository.CardRepository;
import com.banking.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CardService {

    private final CardRepository cardRepository;
    private final UserRepository userRepository;
    private final AccountRepository accountRepository;
    private final SecureRandom secureRandom = new SecureRandom();

    public List<CardResponse> getUserCards() {
        User user = getCurrentUser();
        return cardRepository.findByUserId(user.getId())
                .stream()
                .map(this::mapToCardResponse)
                .collect(Collectors.toList());
    }

    public List<CardResponse> getActiveCards() {
        User user = getCurrentUser();
        return cardRepository.findByUserIdAndStatus(user.getId(), Card.CardStatus.ACTIVE)
                .stream()
                .map(this::mapToCardResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public CardResponse createCard(CreateCardRequest request) {
        User user = getCurrentUser();
        
        Account account = accountRepository.findById(request.getAccountId())
                .orElseThrow(() -> new ResourceNotFoundException("Account not found"));
        
        if (!account.getUser().getId().equals(user.getId())) {
            throw new BadRequestException("Account does not belong to user");
        }
        
        if (account.getStatus() != Account.AccountStatus.ACTIVE) {
            throw new BadRequestException("Cannot create card for inactive account");
        }

        Card.CardType cardType;
        try {
            cardType = Card.CardType.valueOf(request.getCardType().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Invalid card type. Valid types: DEBIT, CREDIT, VIRTUAL");
        }

        List<Card.CardStatus> activeStatuses = Arrays.asList(
            Card.CardStatus.ACTIVE, 
            Card.CardStatus.BLOCKED
        );

        // Check if user already has an active DEBIT card for this account
        List<Card> existingDebitCards = cardRepository.findByAccountIdAndCardTypeAndStatusIn(
            account.getId(), 
            Card.CardType.DEBIT, 
            activeStatuses
        );
        boolean hasActiveDebitCard = existingDebitCards.stream()
            .anyMatch(card -> !card.getExpiryDate().isBefore(LocalDate.now()));

        // VIRTUAL card rules: Can only request if no active DEBIT card exists
        if (cardType == Card.CardType.VIRTUAL) {
            if (hasActiveDebitCard) {
                throw new BadRequestException(
                    "Cannot request a Virtual card when you have an active Debit card. " +
                    "Virtual cards are only available for accounts without a Debit card."
                );
            }
        }

        // DEBIT and CREDIT cards: Limited to one per account
        if (cardType == Card.CardType.DEBIT || cardType == Card.CardType.CREDIT) {
            List<Card> existingCards = cardRepository.findByAccountIdAndCardTypeAndStatusIn(
                account.getId(), 
                cardType, 
                activeStatuses
            );
            
            // Filter out expired cards
            boolean hasValidCard = existingCards.stream()
                .anyMatch(card -> !card.getExpiryDate().isBefore(LocalDate.now()));
            
            if (hasValidCard) {
                throw new BadRequestException(
                    "You already have an active " + cardType.name() + " card for this account. " +
                    "You can only request a new one after the existing card expires."
                );
            }

            // If creating a DEBIT card, invalidate all active VIRTUAL cards for this account
            if (cardType == Card.CardType.DEBIT) {
                List<Card> virtualCards = cardRepository.findByAccountIdAndCardTypeAndStatusIn(
                    account.getId(),
                    Card.CardType.VIRTUAL,
                    activeStatuses
                );
                
                for (Card virtualCard : virtualCards) {
                    virtualCard.setStatus(Card.CardStatus.CANCELLED);
                    cardRepository.save(virtualCard);
                }
            }
        }

        String cardNumber = generateCardNumber();
        String cvv = generateCVV();
        LocalDate expiryDate = LocalDate.now().plusYears(4);

        BigDecimal spendingLimit = request.getSpendingLimit() != null 
                ? request.getSpendingLimit() 
                : new BigDecimal("5000.00");

        Card card = Card.builder()
                .cardNumber(cardNumber)
                .cardHolderName(user.getFirstName() + " " + user.getLastName())
                .cardType(cardType)
                .expiryDate(expiryDate)
                .cvv(cvv)
                .spendingLimit(spendingLimit)
                .currentSpent(BigDecimal.ZERO)
                .status(Card.CardStatus.ACTIVE)
                .isVirtual(request.getIsVirtual() != null ? request.getIsVirtual() : false)
                .user(user)
                .account(account)
                .build();

        Card savedCard = cardRepository.save(card);
        return mapToCardResponse(savedCard);
    }

    @Transactional
    public CardResponse blockCard(Long cardId) {
        Card card = getCardForCurrentUser(cardId);
        
        if (card.getStatus() == Card.CardStatus.CANCELLED) {
            throw new BadRequestException("Cannot block a cancelled card");
        }
        
        card.setStatus(Card.CardStatus.BLOCKED);
        Card savedCard = cardRepository.save(card);
        return mapToCardResponse(savedCard);
    }

    @Transactional
    public CardResponse unblockCard(Long cardId) {
        Card card = getCardForCurrentUser(cardId);
        
        if (card.getStatus() != Card.CardStatus.BLOCKED) {
            throw new BadRequestException("Card is not blocked");
        }
        
        if (card.getExpiryDate().isBefore(LocalDate.now())) {
            throw new BadRequestException("Cannot unblock an expired card");
        }
        
        card.setStatus(Card.CardStatus.ACTIVE);
        Card savedCard = cardRepository.save(card);
        return mapToCardResponse(savedCard);
    }

    @Transactional
    public CardResponse cancelCard(Long cardId) {
        Card card = getCardForCurrentUser(cardId);
        
        card.setStatus(Card.CardStatus.CANCELLED);
        Card savedCard = cardRepository.save(card);
        return mapToCardResponse(savedCard);
    }

    @Transactional
    public CardResponse updateSpendingLimit(UpdateCardLimitRequest request) {
        Card card = getCardForCurrentUser(request.getCardId());
        
        if (card.getStatus() != Card.CardStatus.ACTIVE) {
            throw new BadRequestException("Cannot update limit for inactive card");
        }
        
        card.setSpendingLimit(request.getNewLimit());
        Card savedCard = cardRepository.save(card);
        return mapToCardResponse(savedCard);
    }

    public CardResponse getCardDetails(Long cardId) {
        Card card = getCardForCurrentUser(cardId);
        return mapToCardResponse(card);
    }

    private Card getCardForCurrentUser(Long cardId) {
        User user = getCurrentUser();
        Card card = cardRepository.findById(cardId)
                .orElseThrow(() -> new ResourceNotFoundException("Card not found"));
        
        if (!card.getUser().getId().equals(user.getId())) {
            throw new BadRequestException("Card does not belong to user");
        }
        
        return card;
    }

    private String generateCardNumber() {
        StringBuilder sb = new StringBuilder();
        // Generate 16-digit card number starting with 4 (Visa-like)
        sb.append("4");
        for (int i = 0; i < 15; i++) {
            sb.append(secureRandom.nextInt(10));
        }
        
        String cardNumber = sb.toString();
        // Ensure uniqueness
        while (cardRepository.existsByCardNumber(cardNumber)) {
            sb = new StringBuilder();
            sb.append("4");
            for (int i = 0; i < 15; i++) {
                sb.append(secureRandom.nextInt(10));
            }
            cardNumber = sb.toString();
        }
        
        return cardNumber;
    }

    private String generateCVV() {
        return String.format("%03d", secureRandom.nextInt(1000));
    }

    private String maskCardNumber(String cardNumber) {
        if (cardNumber.length() < 16) return cardNumber;
        return "**** **** **** " + cardNumber.substring(12);
    }

    private CardResponse mapToCardResponse(Card card) {
        BigDecimal availableLimit = card.getSpendingLimit().subtract(card.getCurrentSpent());
        
        return CardResponse.builder()
                .id(card.getId())
                .cardNumber(card.getCardNumber())
                .maskedCardNumber(maskCardNumber(card.getCardNumber()))
                .cardHolderName(card.getCardHolderName())
                .cardType(card.getCardType().name())
                .expiryDate(card.getExpiryDate())
                .spendingLimit(card.getSpendingLimit())
                .currentSpent(card.getCurrentSpent())
                .availableLimit(availableLimit.max(BigDecimal.ZERO))
                .status(card.getStatus().name())
                .isVirtual(card.getIsVirtual())
                .accountId(card.getAccount().getId())
                .accountNumber(card.getAccount().getAccountNumber())
                .createdAt(card.getCreatedAt())
                .build();
    }

    private User getCurrentUser() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
}

