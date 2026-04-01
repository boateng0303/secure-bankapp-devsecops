package com.banking.controller;

import com.banking.dto.request.CreateCardRequest;
import com.banking.dto.request.UpdateCardLimitRequest;
import com.banking.dto.response.ApiResponse;
import com.banking.dto.response.CardResponse;
import com.banking.service.CardService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cards")
@RequiredArgsConstructor
public class CardController {

    private final CardService cardService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<CardResponse>>> getAllCards() {
        List<CardResponse> cards = cardService.getUserCards();
        return ResponseEntity.ok(ApiResponse.success("Cards retrieved successfully", cards));
    }

    @GetMapping("/active")
    public ResponseEntity<ApiResponse<List<CardResponse>>> getActiveCards() {
        List<CardResponse> cards = cardService.getActiveCards();
        return ResponseEntity.ok(ApiResponse.success("Active cards retrieved successfully", cards));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CardResponse>> getCardDetails(@PathVariable Long id) {
        CardResponse card = cardService.getCardDetails(id);
        return ResponseEntity.ok(ApiResponse.success("Card details retrieved successfully", card));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CardResponse>> createCard(@Valid @RequestBody CreateCardRequest request) {
        CardResponse card = cardService.createCard(request);
        return ResponseEntity.ok(ApiResponse.success("Card created successfully", card));
    }

    @PostMapping("/{id}/block")
    public ResponseEntity<ApiResponse<CardResponse>> blockCard(@PathVariable Long id) {
        CardResponse card = cardService.blockCard(id);
        return ResponseEntity.ok(ApiResponse.success("Card blocked successfully", card));
    }

    @PostMapping("/{id}/unblock")
    public ResponseEntity<ApiResponse<CardResponse>> unblockCard(@PathVariable Long id) {
        CardResponse card = cardService.unblockCard(id);
        return ResponseEntity.ok(ApiResponse.success("Card unblocked successfully", card));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<CardResponse>> cancelCard(@PathVariable Long id) {
        CardResponse card = cardService.cancelCard(id);
        return ResponseEntity.ok(ApiResponse.success("Card cancelled successfully", card));
    }

    @PutMapping("/limit")
    public ResponseEntity<ApiResponse<CardResponse>> updateSpendingLimit(
            @Valid @RequestBody UpdateCardLimitRequest request) {
        CardResponse card = cardService.updateSpendingLimit(request);
        return ResponseEntity.ok(ApiResponse.success("Spending limit updated successfully", card));
    }
}

