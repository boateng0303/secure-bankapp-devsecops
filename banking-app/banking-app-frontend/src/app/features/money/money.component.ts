import { Component, OnInit } from '@angular/core';
import { AbstractControl, FormBuilder, FormGroup, ValidationErrors, Validators } from '@angular/forms';
import { TransactionService } from '../../core/services/transaction.service';
import { AccountService } from '../../core/services/account.service';
import { BeneficiaryService } from '../../core/services/beneficiary.service';
import { CardService } from '../../core/services/card.service';
import { Account } from '../../shared/models/account.model';
import { Beneficiary } from '../../shared/models/beneficiary.model';
import { Card } from '../../shared/models/card.model';

@Component({
  selector: 'app-money',
  templateUrl: './money.component.html',
  styleUrls: ['./money.component.scss']
})
export class MoneyComponent implements OnInit {
  selectedTab = 0;
  accounts: Account[] = [];
  beneficiaries: Beneficiary[] = [];
  cards: Card[] = [];
  accountCards: Card[] = []; // Cards filtered by selected account
  
  depositForm!: FormGroup;
  withdrawalForm!: FormGroup;
  transferForm!: FormGroup;
  internalTransferForm!: FormGroup;
  
  loading = false;
  success = '';
  error = '';

  depositMethods = ['CARD', 'BANK_TRANSFER', 'CASH', 'CHECK'];
  withdrawalMethods = ['ATM', 'BRANCH', 'ONLINE'];

  constructor(
    private fb: FormBuilder,
    private transactionService: TransactionService,
    private accountService: AccountService,
    private beneficiaryService: BeneficiaryService,
    private cardService: CardService
  ) {}

  ngOnInit(): void {
    this.initializeForms();
    this.loadAccounts();
    this.loadBeneficiaries();
    this.loadCards();
    this.setupWithdrawalFormListeners();
  }

  initializeForms(): void {
    this.depositForm = this.fb.group({
      accountId: ['', Validators.required],
      amount: ['', [Validators.required, Validators.min(0.01)]],
      depositMethod: ['', Validators.required],
      description: ['']
    });

    this.withdrawalForm = this.fb.group({
      accountId: ['', Validators.required],
      amount: ['', [Validators.required, Validators.min(0.01)]],
      withdrawalMethod: ['', Validators.required],
      description: [''],
      cardId: ['']
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
    }, { validators: this.sameAccountValidator });
  }

  loadAccounts(): void {
    this.accountService.getActiveAccounts().subscribe({
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

  loadCards(): void {
    this.cardService.getActiveCards().subscribe({
      next: (response) => {
        this.cards = response.data || [];
      },
      error: (error) => {
        console.error('Failed to load cards', error);
      }
    });
  }

  setupWithdrawalFormListeners(): void {
    // When account or withdrawal method changes, filter available cards
    this.withdrawalForm.get('accountId')?.valueChanges.subscribe(() => {
      this.filterCardsForAccount();
    });
    
    this.withdrawalForm.get('withdrawalMethod')?.valueChanges.subscribe((method) => {
      if (method === 'ATM') {
        this.filterCardsForAccount();
      } else {
        this.withdrawalForm.patchValue({ cardId: '' });
        this.accountCards = [];
      }
    });
  }

  filterCardsForAccount(): void {
    const accountId = +this.withdrawalForm.get('accountId')?.value;
    const method = this.withdrawalForm.get('withdrawalMethod')?.value;
    
    if (accountId && method === 'ATM') {
      this.accountCards = this.cards.filter(
        card => card.accountId === accountId && card.status === 'ACTIVE'
      );
      // Reset card selection
      this.withdrawalForm.patchValue({ cardId: '' });
    } else {
      this.accountCards = [];
    }
  }

  isAtmSelected(): boolean {
    return this.withdrawalForm.get('withdrawalMethod')?.value === 'ATM';
  }

  getCardAvailableLimit(card: Card): number {
    return card.spendingLimit - card.currentSpent;
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

  onWithdraw(): void {
    if (this.withdrawalForm.invalid) return;

    this.loading = true;
    this.error = '';
    this.success = '';

    const formValue = this.withdrawalForm.value;
    const request: any = {
      accountId: +formValue.accountId,
      amount: +formValue.amount,
      withdrawalMethod: formValue.withdrawalMethod,
      description: formValue.description || undefined
    };
    
    // Include cardId only if ATM and card is selected
    if (formValue.withdrawalMethod === 'ATM' && formValue.cardId) {
      request.cardId = +formValue.cardId;
    }

    this.transactionService.withdraw(request).subscribe({
      next: (response) => {
        this.success = 'Withdrawal successful!';
        this.withdrawalForm.reset();
        this.accountCards = [];
        this.loading = false;
        this.loadAccounts(); // Refresh accounts
        this.loadCards(); // Refresh cards to update spending
      },
      error: (error) => {
        this.error = error.error?.message || error.message || 'Withdrawal failed';
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

  sameAccountValidator(control: AbstractControl): ValidationErrors | null {
    const fromAccountId = control.get('fromAccountId')?.value;
    const toAccountId = control.get('toAccountId')?.value;
    
    if (fromAccountId && toAccountId && fromAccountId === toAccountId) {
      return { sameAccount: true };
    }
    return null;
  }
}


