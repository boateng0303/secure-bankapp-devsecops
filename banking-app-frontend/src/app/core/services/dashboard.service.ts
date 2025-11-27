import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { DashboardData } from '../../shared/models/dashboard.model';

@Injectable({
  providedIn: 'root'
})
export class DashboardService {
  constructor(private apiService: ApiService) {}

  getDashboardData(): Observable<ApiResponse<DashboardData>> {
    return this.apiService.get<ApiResponse<DashboardData>>('/dashboard');
  }
}


