import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { Account } from '../../shared/models/account.model';

export interface CreateAccountRequest {
  accountType: string;
  currency?: string;
}

@Injectable({
  providedIn: 'root'
})
export class AccountService {
  constructor(private apiService: ApiService) {}

  getAllAccounts(): Observable<ApiResponse<Account[]>> {
    return this.apiService.get<ApiResponse<Account[]>>('/accounts');
  }

  getActiveAccounts(): Observable<ApiResponse<Account[]>> {
    return this.apiService.get<ApiResponse<Account[]>>('/accounts/active');
  }

  getAccountById(id: number): Observable<ApiResponse<Account>> {
    return this.apiService.get<ApiResponse<Account>>(`/accounts/${id}`);
  }

  createAccount(request: CreateAccountRequest): Observable<ApiResponse<Account>> {
    return this.apiService.post<ApiResponse<Account>>('/accounts', request);
  }

  closeAccount(id: number): Observable<ApiResponse<Account>> {
    return this.apiService.post<ApiResponse<Account>>(`/accounts/${id}/close`, {});
  }
}


