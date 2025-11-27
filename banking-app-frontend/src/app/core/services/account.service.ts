import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { Account } from '../../shared/models/account.model';

@Injectable({
  providedIn: 'root'
})
export class AccountService {
  constructor(private apiService: ApiService) {}

  getAllAccounts(): Observable<ApiResponse<Account[]>> {
    return this.apiService.get<ApiResponse<Account[]>>('/accounts');
  }

  getAccountById(id: number): Observable<ApiResponse<Account>> {
    return this.apiService.get<ApiResponse<Account>>(`/accounts/${id}`);
  }
}


