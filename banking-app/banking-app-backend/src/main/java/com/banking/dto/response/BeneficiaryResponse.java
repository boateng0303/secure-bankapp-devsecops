package com.banking.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BeneficiaryResponse {
    private Long id;
    private String beneficiaryName;
    private String accountNumber;
    private String bankName;
    private String bankCode;
    private String nickname;
    private LocalDateTime createdAt;
}

