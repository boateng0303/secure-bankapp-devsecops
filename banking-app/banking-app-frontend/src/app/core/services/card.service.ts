import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { Card, CreateCardRequest, UpdateCardLimitRequest } from '../../shared/models/card.model';

@Injectable({
  providedIn: 'root'
})
export class CardService {
  constructor(private apiService: ApiService) {}

  getAllCards(): Observable<ApiResponse<Card[]>> {
    return this.apiService.get<ApiResponse<Card[]>>('/cards');
  }

  getActiveCards(): Observable<ApiResponse<Card[]>> {
    return this.apiService.get<ApiResponse<Card[]>>('/cards/active');
  }

  getCardDetails(id: number): Observable<ApiResponse<Card>> {
    return this.apiService.get<ApiResponse<Card>>(`/cards/${id}`);
  }

  createCard(request: CreateCardRequest): Observable<ApiResponse<Card>> {
    return this.apiService.post<ApiResponse<Card>>('/cards', request);
  }

  blockCard(id: number): Observable<ApiResponse<Card>> {
    return this.apiService.post<ApiResponse<Card>>(`/cards/${id}/block`, {});
  }

  unblockCard(id: number): Observable<ApiResponse<Card>> {
    return this.apiService.post<ApiResponse<Card>>(`/cards/${id}/unblock`, {});
  }

  cancelCard(id: number): Observable<ApiResponse<Card>> {
    return this.apiService.post<ApiResponse<Card>>(`/cards/${id}/cancel`, {});
  }

  updateSpendingLimit(request: UpdateCardLimitRequest): Observable<ApiResponse<Card>> {
    return this.apiService.put<ApiResponse<Card>>('/cards/limit', request);
  }
}

