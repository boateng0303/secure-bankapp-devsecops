import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { TransactionService } from '../../core/services/transaction.service';
import { AccountService } from '../../core/services/account.service';
import { BeneficiaryService } from '../../core/services/beneficiary.service';
import { Account } from '../../shared/models/account.model';
import { Beneficiary } from '../../shared/models/beneficiary.model';

@Component({
  selector: 'app-money',
  templateUrl: './money.component.html',
  styleUrls: ['./money.component.scss']
})
export class MoneyComponent implements OnInit {
  selectedTab = 0;
  accounts: Account[] = [];
  beneficiaries: Beneficiary[] = [];
  
  depositForm!: FormGroup;
  transferForm!: FormGroup;
  internalTransferForm!: FormGroup;
  
  loading = false;
  success = '';
  error = '';

  depositMethods = ['CARD', 'BANK_TRANSFER', 'CASH', 'CHECK'];

  constructor(
    private fb: FormBuilder,
    private transactionService: TransactionService,
    private accountService: AccountService,
    private beneficiaryService: BeneficiaryService
  ) {}

  ngOnInit(): void {
    this.initializeForms();
    this.loadAccounts();
    this.loadBeneficiaries();
  }

  initializeForms(): void {
    this.depositForm = this.fb.group({
      accountId: ['', Validators.required],
      amount: ['', [Validators.required, Validators.min(0.01)]],
      depositMethod: ['', Validators.required],
      description: ['']
    });

    this.transferForm = this.fb.group({
      fromAccountId: ['', Validators.required],
      recipientAccountNumber: ['', [Validators.required, Validators.pattern(/^\d{10}$/)]],
      amount: ['', [Validators.required, Validators.min(0.01)]],
      description: ['']
    });

    this.internalTransferForm = this.fb.group({
      fromAccountId: ['', Validators.required],
      toAccountId: ['', Validators.required],
      amount: ['', [Validators.required, Validators.min(0.01)]],
      description: ['']
    });
  }

  loadAccounts(): void {
    this.accountService.getAllAccounts().subscribe({
      next: (response) => {
        this.accounts = response.data;
      },
      error: (error) => {
        console.error('Failed to load accounts', error);
      }
    });
  }

  loadBeneficiaries(): void {
    this.beneficiaryService.getAllBeneficiaries().subscribe({
      next: (response) => {
        this.beneficiaries = response.data;
      },
      error: (error) => {
        console.error('Failed to load beneficiaries', error);
      }
    });
  }

  onDeposit(): void {
    if (this.depositForm.invalid) return;

    this.loading = true;
    this.error = '';
    this.success = '';

    this.transactionService.deposit(this.depositForm.value).subscribe({
      next: (response) => {
        this.success = 'Deposit successful!';
        this.depositForm.reset();
        this.loading = false;
        this.loadAccounts(); // Refresh accounts
      },
      error: (error) => {
        this.error = error.message || 'Deposit failed';
        this.loading = false;
      }
    });
  }

  onTransfer(): void {
    if (this.transferForm.invalid) return;

    this.loading = true;
    this.error = '';
    this.success = '';

    this.transactionService.transfer(this.transferForm.value).subscribe({
      next: (response) => {
        this.success = 'Transfer successful!';
        this.transferForm.reset();
        this.loading = false;
        this.loadAccounts(); // Refresh accounts
      },
      error: (error) => {
        this.error = error.message || 'Transfer failed';
        this.loading = false;
      }
    });
  }

  onInternalTransfer(): void {
    if (this.internalTransferForm.invalid) return;

    this.loading = true;
    this.error = '';
    this.success = '';

    this.transactionService.internalTransfer(this.internalTransferForm.value).subscribe({
      next: (response) => {
        this.success = 'Internal transfer successful!';
        this.internalTransferForm.reset();
        this.loading = false;
        this.loadAccounts(); // Refresh accounts
      },
      error: (error) => {
        this.error = error.message || 'Internal transfer failed';
        this.loading = false;
      }
    });
  }

  selectBeneficiary(accountNumber: string): void {
    this.transferForm.patchValue({ recipientAccountNumber: accountNumber });
  }

  getAccountBalance(accountId: number): string {
    const account = this.accounts.find(a => a.id === accountId);
    return account ? `$${account.balance.toFixed(2)}` : 'N/A';
  }
}


