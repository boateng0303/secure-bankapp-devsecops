export interface Beneficiary {
  id: number;
  beneficiaryName: string;
  accountNumber: string;
  bankName: string;
  bankCode?: string;
  nickname?: string;
  createdAt: string;
}

export interface BeneficiaryRequest {
  beneficiaryName: string;
  accountNumber: string;
  bankName: string;
  bankCode?: string;
  nickname?: string;
}


