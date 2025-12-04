export interface Transaction {
  id: number;
  accountId: number;
  accountNumber: string;
  accountType: string;
  transactionReference: string;
  type: string;
  amount: number;
  balanceAfter: number;
  description: string;
  status: string;
  recipientAccountNumber?: string;
  recipientName?: string;
  depositMethod?: string;
  createdAt: string;
}

export interface DepositRequest {
  accountId: number;
  amount: number;
  depositMethod: string;
  description?: string;
}

export interface TransferRequest {
  fromAccountId: number;
  recipientAccountNumber: string;
  amount: number;
  description?: string;
}

export interface InternalTransferRequest {
  fromAccountId: number;
  toAccountId: number;
  amount: number;
  description?: string;
}

export interface WithdrawalRequest {
  accountId: number;
  amount: number;
  withdrawalMethod?: string;
  description?: string;
}


