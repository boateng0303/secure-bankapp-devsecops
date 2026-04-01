package com.banking.controller;

import com.banking.dto.request.BeneficiaryRequest;
import com.banking.dto.response.ApiResponse;
import com.banking.dto.response.BeneficiaryResponse;
import com.banking.entity.Beneficiary;
import com.banking.entity.User;
import com.banking.service.BeneficiaryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/beneficiaries")
@RequiredArgsConstructor
public class BeneficiaryController {

    private final BeneficiaryService beneficiaryService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BeneficiaryResponse>>> getAllBeneficiaries(@AuthenticationPrincipal User user) {
        List<Beneficiary> beneficiaries = beneficiaryService.getBeneficiariesByUserId(user.getId());
        List<BeneficiaryResponse> response = beneficiaries.stream()
                .map(this::mapToBeneficiaryResponse)
                .collect(Collectors.toList());

        return ResponseEntity.ok(ApiResponse.success("Beneficiaries retrieved successfully", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BeneficiaryResponse>> getBeneficiaryById(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        Beneficiary beneficiary = beneficiaryService.getBeneficiaryById(id, user.getId());
        return ResponseEntity.ok(ApiResponse.success("Beneficiary retrieved successfully", mapToBeneficiaryResponse(beneficiary)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<BeneficiaryResponse>> addBeneficiary(
            @Valid @RequestBody BeneficiaryRequest request,
            @AuthenticationPrincipal User user) {
        Beneficiary beneficiary = beneficiaryService.addBeneficiary(request, user.getId());
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Beneficiary added successfully", mapToBeneficiaryResponse(beneficiary)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BeneficiaryResponse>> updateBeneficiary(
            @PathVariable Long id,
            @Valid @RequestBody BeneficiaryRequest request,
            @AuthenticationPrincipal User user) {
        Beneficiary beneficiary = beneficiaryService.updateBeneficiary(id, request, user.getId());
        return ResponseEntity.ok(ApiResponse.success("Beneficiary updated successfully", mapToBeneficiaryResponse(beneficiary)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBeneficiary(
            @PathVariable Long id,
            @AuthenticationPrincipal User user) {
        beneficiaryService.deleteBeneficiary(id, user.getId());
        return ResponseEntity.ok(ApiResponse.success("Beneficiary deleted successfully", null));
    }

    private BeneficiaryResponse mapToBeneficiaryResponse(Beneficiary beneficiary) {
        return BeneficiaryResponse.builder()
                .id(beneficiary.getId())
                .beneficiaryName(beneficiary.getBeneficiaryName())
                .accountNumber(beneficiary.getAccountNumber())
                .bankName(beneficiary.getBankName())
                .bankCode(beneficiary.getBankCode())
                .nickname(beneficiary.getNickname())
                .createdAt(beneficiary.getCreatedAt())
                .build();
    }
}

