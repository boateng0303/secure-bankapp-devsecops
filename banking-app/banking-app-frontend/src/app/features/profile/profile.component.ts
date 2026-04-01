import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ProfileService } from '../../core/services/profile.service';
import { User } from '../../shared/models/user.model';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.scss']
})
export class ProfileComponent implements OnInit {
  user: User | null = null;
  profileForm!: FormGroup;
  passwordForm!: FormGroup;
  
  loading = true;
  updating = false;
  changingPassword = false;
  toggling2FA = false;
  
  profileSuccess = '';
  profileError = '';
  passwordSuccess = '';
  passwordError = '';
  
  hideCurrentPassword = true;
  hideNewPassword = true;

  constructor(
    private fb: FormBuilder,
    private profileService: ProfileService
  ) {}

  ngOnInit(): void {
    this.initializeForms();
    this.loadProfile();
  }

  initializeForms(): void {
    this.profileForm = this.fb.group({
      firstName: ['', [Validators.required, Validators.minLength(2)]],
      lastName: ['', [Validators.required, Validators.minLength(2)]],
      phoneNumber: ['', [Validators.required, Validators.pattern(/^[+]?[0-9]{10,15}$/)]],
      address: ['', Validators.required]
    });

    this.passwordForm = this.fb.group({
      currentPassword: ['', Validators.required],
      newPassword: ['', [
        Validators.required,
        Validators.minLength(8),
        Validators.pattern(/^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=]).*$/)
      ]]
    });
  }

  loadProfile(): void {
    this.loading = true;
    this.profileService.getProfile().subscribe({
      next: (response) => {
        this.user = response.data;
        this.profileForm.patchValue({
          firstName: this.user.firstName,
          lastName: this.user.lastName,
          phoneNumber: this.user.phoneNumber,
          address: this.user.address
        });
        this.loading = false;
      },
      error: (error) => {
        this.profileError = error.message || 'Failed to load profile';
        this.loading = false;
      }
    });
  }

  updateProfile(): void {
    if (this.profileForm.invalid) return;

    this.updating = true;
    this.profileSuccess = '';
    this.profileError = '';

    this.profileService.updateProfile(this.profileForm.value).subscribe({
      next: (response) => {
        this.user = response.data;
        this.profileSuccess = 'Profile updated successfully!';
        this.updating = false;
      },
      error: (error) => {
        this.profileError = error.message || 'Failed to update profile';
        this.updating = false;
      }
    });
  }

  changePassword(): void {
    if (this.passwordForm.invalid) return;

    this.changingPassword = true;
    this.passwordSuccess = '';
    this.passwordError = '';

    this.profileService.changePassword(this.passwordForm.value).subscribe({
      next: (response) => {
        this.passwordSuccess = 'Password changed successfully!';
        this.passwordForm.reset();
        this.changingPassword = false;
      },
      error: (error) => {
        this.passwordError = error.message || 'Failed to change password';
        this.changingPassword = false;
      }
    });
  }

  toggle2FA(): void {
    this.toggling2FA = true;
    this.profileService.toggle2FA().subscribe({
      next: (response) => {
        this.user = response.data;
        this.profileSuccess = `Two-factor authentication ${this.user.twoFactorEnabled ? 'enabled' : 'disabled'}!`;
        this.toggling2FA = false;
      },
      error: (error) => {
        this.profileError = error.message || 'Failed to toggle 2FA';
        this.toggling2FA = false;
      }
    });
  }
}


