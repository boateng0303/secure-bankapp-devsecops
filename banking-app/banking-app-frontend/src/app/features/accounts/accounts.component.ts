import { Component, OnInit } from '@angular/core';
import { AccountService, CreateAccountRequest } from '../../core/services/account.service';
import { Account } from '../../shared/models/account.model';

@Component({
  selector: 'app-accounts',
  templateUrl: './accounts.component.html',
  styleUrls: ['./accounts.component.scss']
})
export class AccountsComponent implements OnInit {
  accounts: Account[] = [];
  loading = false;
  actionLoading = false;
  success = '';
  error = '';
  
  // Create account form
  showCreateModal = false;
  selectedAccountType = '';
  accountTypes = ['SAVINGS', 'CHECKING', 'INVESTMENT'];

  constructor(private accountService: AccountService) {}

  ngOnInit(): void {
    this.loadAccounts();
  }

  loadAccounts(): void {
    this.loading = true;
    this.accountService.getAllAccounts().subscribe({
      next: (response) => {
        this.accounts = response.data;
        this.loading = false;
      },
      error: (error) => {
        this.error = error.message || 'Failed to load accounts';
        this.loading = false;
      }
    });
  }

  openCreateModal(): void {
    this.showCreateModal = true;
    this.selectedAccountType = '';
    this.error = '';
    this.success = '';
  }

  closeCreateModal(): void {
    this.showCreateModal = false;
    this.selectedAccountType = '';
  }

  createAccount(): void {
    if (!this.selectedAccountType) {
      this.error = 'Please select an account type';
      return;
    }

    this.actionLoading = true;
    this.error = '';
    this.success = '';

    const request: CreateAccountRequest = {
      accountType: this.selectedAccountType,
      currency: 'USD'
    };

    this.accountService.createAccount(request).subscribe({
      next: (response) => {
        this.success = `${this.selectedAccountType} account created successfully!`;
        this.actionLoading = false;
        this.closeCreateModal();
        this.loadAccounts();
      },
      error: (error) => {
        this.error = error.message || 'Failed to create account';
        this.actionLoading = false;
      }
    });
  }

  closeAccount(account: Account): void {
    if (!confirm(`Are you sure you want to close your ${account.accountType} account? This action cannot be undone.`)) {
      return;
    }

    this.actionLoading = true;
    this.error = '';
    this.success = '';

    this.accountService.closeAccount(account.id).subscribe({
      next: (response) => {
        this.success = `${account.accountType} account closed successfully!`;
        this.actionLoading = false;
        this.loadAccounts();
      },
      error: (error) => {
        this.error = error.message || 'Failed to close account';
        this.actionLoading = false;
      }
    });
  }

  getAccountIcon(type: string): string {
    switch (type) {
      case 'CHECKING': return 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z';
      case 'SAVINGS': return 'M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z';
      case 'INVESTMENT': return 'M13 7h8m0 0v8m0-8l-8 8-4-4-6 6';
      default: return 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z';
    }
  }

  getAccountColor(type: string): string {
    switch (type) {
      case 'CHECKING': return 'primary';
      case 'SAVINGS': return 'success';
      case 'INVESTMENT': return 'accent';
      default: return 'primary';
    }
  }

  getAvailableAccountTypes(): string[] {
    const existingTypes = this.accounts
      .filter(a => a.status === 'ACTIVE')
      .map(a => a.accountType);
    return this.accountTypes.filter(type => !existingTypes.includes(type));
  }

  get totalBalance(): number {
    return this.accounts
      .filter(a => a.status === 'ACTIVE')
      .reduce((sum, account) => sum + account.balance, 0);
  }

  get activeAccounts(): Account[] {
    return this.accounts.filter(a => a.status === 'ACTIVE');
  }

  get closedAccounts(): Account[] {
    return this.accounts.filter(a => a.status === 'CLOSED');
  }
}

