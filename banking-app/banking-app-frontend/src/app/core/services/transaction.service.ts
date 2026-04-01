import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { Transaction, DepositRequest, TransferRequest, InternalTransferRequest, WithdrawalRequest } from '../../shared/models/transaction.model';

@Injectable({
  providedIn: 'root'
})
export class TransactionService {
  constructor(private apiService: ApiService) {}

  getAllTransactions(): Observable<ApiResponse<Transaction[]>> {
    return this.apiService.get<ApiResponse<Transaction[]>>('/transactions');
  }

  getTransactionById(id: number): Observable<ApiResponse<Transaction>> {
    return this.apiService.get<ApiResponse<Transaction>>(`/transactions/${id}`);
  }

  getTransactionsByAccount(accountId: number): Observable<ApiResponse<Transaction[]>> {
    return this.apiService.get<ApiResponse<Transaction[]>>(`/transactions/account/${accountId}`);
  }

  deposit(data: DepositRequest): Observable<ApiResponse<Transaction>> {
    return this.apiService.post<ApiResponse<Transaction>>('/money/deposit', data);
  }

  withdraw(data: WithdrawalRequest): Observable<ApiResponse<Transaction>> {
    return this.apiService.post<ApiResponse<Transaction>>('/money/withdraw', data);
  }

  transfer(data: TransferRequest): Observable<ApiResponse<Transaction>> {
    return this.apiService.post<ApiResponse<Transaction>>('/money/transfer', data);
  }

  internalTransfer(data: InternalTransferRequest): Observable<ApiResponse<Transaction>> {
    return this.apiService.post<ApiResponse<Transaction>>('/money/internal-transfer', data);
  }
}


