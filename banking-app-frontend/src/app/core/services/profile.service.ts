import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { User } from '../../shared/models/user.model';

export interface UpdateProfileRequest {
  firstName?: string;
  lastName?: string;
  phoneNumber?: string;
  address?: string;
}

export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}

@Injectable({
  providedIn: 'root'
})
export class ProfileService {
  constructor(private apiService: ApiService) {}

  getProfile(): Observable<ApiResponse<User>> {
    return this.apiService.get<ApiResponse<User>>('/profile');
  }

  updateProfile(data: UpdateProfileRequest): Observable<ApiResponse<User>> {
    return this.apiService.put<ApiResponse<User>>('/profile', data);
  }

  changePassword(data: ChangePasswordRequest): Observable<ApiResponse<void>> {
    return this.apiService.post<ApiResponse<void>>('/profile/change-password', data);
  }

  toggle2FA(): Observable<ApiResponse<User>> {
    return this.apiService.post<ApiResponse<User>>('/profile/toggle-2fa', {});
  }
}


