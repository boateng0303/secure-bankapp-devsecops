export interface Card {
  id: number;
  cardNumber: string;
  maskedCardNumber: string;
  cardHolderName: string;
  cardType: string;
  expiryDate: string;
  spendingLimit: number;
  currentSpent: number;
  availableLimit: number;
  status: string;
  isVirtual: boolean;
  accountId: number;
  accountNumber: string;
  createdAt: string;
}

export interface CreateCardRequest {
  accountId: number;
  cardType: string;
  spendingLimit?: number;
  isVirtual?: boolean;
}

export interface UpdateCardLimitRequest {
  cardId: number;
  newLimit: number;
}

