package com.banking.service;

import com.banking.dto.request.BeneficiaryRequest;
import com.banking.entity.Beneficiary;
import com.banking.entity.User;
import com.banking.exception.BadRequestException;
import com.banking.exception.ResourceNotFoundException;
import com.banking.repository.BeneficiaryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class BeneficiaryService {

    private final BeneficiaryRepository beneficiaryRepository;
    private final UserService userService;

    public Beneficiary getBeneficiaryById(Long id, Long userId) {
        return beneficiaryRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Beneficiary not found"));
    }

    public List<Beneficiary> getBeneficiariesByUserId(Long userId) {
        return beneficiaryRepository.findByUserId(userId);
    }

    public Beneficiary addBeneficiary(BeneficiaryRequest request, Long userId) {
        User user = userService.getUserById(userId);

        // Check if beneficiary already exists
        if (beneficiaryRepository.existsByUserIdAndAccountNumber(userId, request.getAccountNumber())) {
            throw new BadRequestException("Beneficiary with this account number already exists");
        }

        Beneficiary beneficiary = Beneficiary.builder()
                .beneficiaryName(request.getBeneficiaryName())
                .accountNumber(request.getAccountNumber())
                .bankName(request.getBankName())
                .bankCode(request.getBankCode())
                .nickname(request.getNickname())
                .user(user)
                .build();

        return beneficiaryRepository.save(beneficiary);
    }

    public Beneficiary updateBeneficiary(Long id, BeneficiaryRequest request, Long userId) {
        Beneficiary beneficiary = getBeneficiaryById(id, userId);

        beneficiary.setBeneficiaryName(request.getBeneficiaryName());
        beneficiary.setAccountNumber(request.getAccountNumber());
        beneficiary.setBankName(request.getBankName());
        beneficiary.setBankCode(request.getBankCode());
        beneficiary.setNickname(request.getNickname());

        return beneficiaryRepository.save(beneficiary);
    }

    public void deleteBeneficiary(Long id, Long userId) {
        Beneficiary beneficiary = getBeneficiaryById(id, userId);
        beneficiaryRepository.delete(beneficiary);
    }
}

