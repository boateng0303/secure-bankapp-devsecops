import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { Beneficiary, BeneficiaryRequest } from '../../shared/models/beneficiary.model';

@Injectable({
  providedIn: 'root'
})
export class BeneficiaryService {
  constructor(private apiService: ApiService) {}

  getAllBeneficiaries(): Observable<ApiResponse<Beneficiary[]>> {
    return this.apiService.get<ApiResponse<Beneficiary[]>>('/beneficiaries');
  }

  getBeneficiaryById(id: number): Observable<ApiResponse<Beneficiary>> {
    return this.apiService.get<ApiResponse<Beneficiary>>(`/beneficiaries/${id}`);
  }

  addBeneficiary(data: BeneficiaryRequest): Observable<ApiResponse<Beneficiary>> {
    return this.apiService.post<ApiResponse<Beneficiary>>('/beneficiaries', data);
  }

  updateBeneficiary(id: number, data: BeneficiaryRequest): Observable<ApiResponse<Beneficiary>> {
    return this.apiService.put<ApiResponse<Beneficiary>>(`/beneficiaries/${id}`, data);
  }

  deleteBeneficiary(id: number): Observable<ApiResponse<void>> {
    return this.apiService.delete<ApiResponse<void>>(`/beneficiaries/${id}`);
  }
}


