import { Injectable } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { ApiService } from './api.service';
import { TokenService } from './token.service';
import { ApiResponse } from '../../shared/models/api-response.model';
import { AuthResponse, LoginRequest, RegisterRequest, User } from '../../shared/models/user.model';
import { Router } from '@angular/router';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUser: AuthResponse | null = null;

  constructor(
    private apiService: ApiService,
    private tokenService: TokenService,
    private router: Router
  ) {}

  register(data: RegisterRequest): Observable<ApiResponse<AuthResponse>> {
    return this.apiService.post<ApiResponse<AuthResponse>>('/auth/register', data).pipe(
      tap(response => {
        if (response.success && response.data) {
          this.handleAuthSuccess(response.data);
        }
      })
    );
  }

  login(credentials: LoginRequest): Observable<ApiResponse<AuthResponse>> {
    return this.apiService.post<ApiResponse<AuthResponse>>('/auth/login', credentials).pipe(
      tap(response => {
        if (response.success && response.data) {
          this.handleAuthSuccess(response.data);
        }
      })
    );
  }

  logout(): void {
    this.tokenService.removeToken();
    this.currentUser = null;
    this.router.navigate(['/login']);
  }

  isLoggedIn(): boolean {
    return this.tokenService.isLoggedIn();
  }

  getCurrentUser(): AuthResponse | null {
    return this.currentUser;
  }

  private handleAuthSuccess(authData: AuthResponse): void {
    this.tokenService.saveToken(authData.token);
    this.currentUser = authData;
  }
}


