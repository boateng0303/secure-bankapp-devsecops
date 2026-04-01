import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { CardService } from '../../core/services/card.service';
import { AccountService } from '../../core/services/account.service';
import { Card, CreateCardRequest } from '../../shared/models/card.model';
import { Account } from '../../shared/models/account.model';

@Component({
  selector: 'app-cards',
  templateUrl: './cards.component.html',
  styleUrls: ['./cards.component.scss']
})
export class CardsComponent implements OnInit {
  cards: Card[] = [];
  accounts: Account[] = [];
  loading = false;
  error = '';
  success = '';

  showCreateModal = false;
  showDetailsModal = false;
  showLimitModal = false;
  showConfirmModal = false;

  createCardForm: FormGroup;
  updateLimitForm: FormGroup;

  selectedCard: Card | null = null;
  confirmAction: 'block' | 'unblock' | 'cancel' | null = null;

  cardTypes = [
    { value: 'DEBIT', label: 'Debit Card', icon: '💳' },
    { value: 'CREDIT', label: 'Credit Card', icon: '💎' },
    { value: 'VIRTUAL', label: 'Virtual Card', icon: '📱' }
  ];

  disabledCardTypes: string[] = []; // Card types that are unavailable for selected account

  constructor(
    private cardService: CardService,
    private accountService: AccountService,
    private fb: FormBuilder
  ) {
    this.createCardForm = this.fb.group({
      accountId: ['', Validators.required],
      cardType: ['DEBIT', Validators.required],
      spendingLimit: [5000, [Validators.required, Validators.min(100)]],
      isVirtual: [false]
    });

    this.updateLimitForm = this.fb.group({
      newLimit: ['', [Validators.required, Validators.min(100)]]
    });
  }

  ngOnInit(): void {
    this.loadCards();
    this.loadAccounts();
    this.setupFormListeners();
  }

  setupFormListeners(): void {
    // When account changes, update available card types
    this.createCardForm.get('accountId')?.valueChanges.subscribe((accountId) => {
      this.updateDisabledCardTypes(+accountId);
    });
  }

  updateDisabledCardTypes(accountId: number): void {
    if (!accountId) {
      this.disabledCardTypes = [];
      return;
    }

    const now = new Date();
    const disabledTypes: string[] = [];

    // Find existing active/blocked non-expired cards for this account
    const accountCards = this.cards.filter(card => 
      card.accountId === accountId && 
      (card.status === 'ACTIVE' || card.status === 'BLOCKED') &&
      new Date(card.expiryDate) >= now
    );

    // Check if DEBIT or CREDIT already exists (only one allowed)
    const hasActiveDebit = accountCards.some(card => card.cardType === 'DEBIT');
    const hasActiveCredit = accountCards.some(card => card.cardType === 'CREDIT');

    if (hasActiveDebit) {
      disabledTypes.push('DEBIT');
      // VIRTUAL cards cannot be requested when DEBIT exists
      disabledTypes.push('VIRTUAL');
    }

    if (hasActiveCredit) {
      disabledTypes.push('CREDIT');
    }

    this.disabledCardTypes = disabledTypes;

    // If currently selected card type is disabled, reset to first available
    const currentType = this.createCardForm.get('cardType')?.value;
    if (this.disabledCardTypes.includes(currentType)) {
      const availableType = this.cardTypes.find(t => !this.disabledCardTypes.includes(t.value));
      if (availableType) {
        this.createCardForm.patchValue({ cardType: availableType.value });
      }
    }
  }

  isCardTypeDisabled(cardType: string): boolean {
    return this.disabledCardTypes.includes(cardType);
  }

  getCardTypeTooltip(cardType: string): string {
    if (!this.isCardTypeDisabled(cardType)) {
      return '';
    }
    
    if (cardType === 'VIRTUAL') {
      return 'Virtual cards are only available when you don\'t have a Debit card';
    }
    return `You already have an active ${cardType} card for this account`;
  }

  loadCards(): void {
    this.loading = true;
    this.cardService.getAllCards().subscribe({
      next: (response) => {
        this.cards = response.data || [];
        this.loading = false;
      },
      error: (err) => {
        this.error = err.error?.message || 'Failed to load cards';
        this.loading = false;
      }
    });
  }

  loadAccounts(): void {
    this.accountService.getActiveAccounts().subscribe({
      next: (response) => {
        this.accounts = response.data || [];
      },
      error: (err) => {
        console.error('Failed to load accounts', err);
      }
    });
  }

  openCreateModal(): void {
    this.disabledCardTypes = [];
    this.createCardForm.reset({
      cardType: 'DEBIT',
      spendingLimit: 5000,
      isVirtual: false
    });
    this.showCreateModal = true;
  }

  closeCreateModal(): void {
    this.showCreateModal = false;
    this.createCardForm.reset();
  }

  onCreateCard(): void {
    if (this.createCardForm.invalid) return;

    const request: CreateCardRequest = {
      accountId: +this.createCardForm.value.accountId,
      cardType: this.createCardForm.value.cardType,
      spendingLimit: +this.createCardForm.value.spendingLimit,
      isVirtual: this.createCardForm.value.isVirtual
    };

    this.loading = true;
    this.cardService.createCard(request).subscribe({
      next: (response) => {
        this.success = 'Card created successfully!';
        this.loadCards();
        this.closeCreateModal();
        this.loading = false;
        setTimeout(() => this.success = '', 3000);
      },
      error: (err) => {
        this.error = err.error?.message || 'Failed to create card';
        this.loading = false;
        setTimeout(() => this.error = '', 5000);
      }
    });
  }

  openDetailsModal(card: Card): void {
    this.selectedCard = card;
    this.showDetailsModal = true;
  }

  closeDetailsModal(): void {
    this.showDetailsModal = false;
    this.selectedCard = null;
  }

  openLimitModal(card: Card): void {
    this.selectedCard = card;
    this.updateLimitForm.patchValue({ newLimit: card.spendingLimit });
    this.showLimitModal = true;
  }

  closeLimitModal(): void {
    this.showLimitModal = false;
    this.updateLimitForm.reset();
  }

  onUpdateLimit(): void {
    if (this.updateLimitForm.invalid || !this.selectedCard) return;

    this.loading = true;
    this.cardService.updateSpendingLimit({
      cardId: this.selectedCard.id,
      newLimit: +this.updateLimitForm.value.newLimit
    }).subscribe({
      next: () => {
        this.success = 'Spending limit updated!';
        this.loadCards();
        this.closeLimitModal();
        this.loading = false;
        setTimeout(() => this.success = '', 3000);
      },
      error: (err) => {
        this.error = err.error?.message || 'Failed to update limit';
        this.loading = false;
        setTimeout(() => this.error = '', 5000);
      }
    });
  }

  openConfirmModal(card: Card, action: 'block' | 'unblock' | 'cancel'): void {
    this.selectedCard = card;
    this.confirmAction = action;
    this.showConfirmModal = true;
  }

  closeConfirmModal(): void {
    this.showConfirmModal = false;
    this.confirmAction = null;
  }

  onConfirmAction(): void {
    if (!this.selectedCard || !this.confirmAction) return;

    this.loading = true;
    let action$;

    switch (this.confirmAction) {
      case 'block':
        action$ = this.cardService.blockCard(this.selectedCard.id);
        break;
      case 'unblock':
        action$ = this.cardService.unblockCard(this.selectedCard.id);
        break;
      case 'cancel':
        action$ = this.cardService.cancelCard(this.selectedCard.id);
        break;
    }

    action$.subscribe({
      next: () => {
        this.success = `Card ${this.confirmAction}ed successfully!`;
        this.loadCards();
        this.closeConfirmModal();
        this.loading = false;
        setTimeout(() => this.success = '', 3000);
      },
      error: (err) => {
        this.error = err.error?.message || `Failed to ${this.confirmAction} card`;
        this.loading = false;
        setTimeout(() => this.error = '', 5000);
      }
    });
  }

  getCardColor(cardType: string): string {
    switch (cardType) {
      case 'DEBIT': return 'from-blue-600 to-blue-800';
      case 'CREDIT': return 'from-purple-600 to-purple-900';
      case 'VIRTUAL': return 'from-emerald-500 to-teal-700';
      default: return 'from-gray-600 to-gray-800';
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'ACTIVE': return 'bg-green-100 text-green-800';
      case 'BLOCKED': return 'bg-red-100 text-red-800';
      case 'EXPIRED': return 'bg-orange-100 text-orange-800';
      case 'CANCELLED': return 'bg-gray-100 text-gray-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  }

  formatCardNumber(cardNumber: string): string {
    return cardNumber.replace(/(.{4})/g, '$1 ').trim();
  }

  formatExpiryDate(date: string): string {
    const d = new Date(date);
    return `${String(d.getMonth() + 1).padStart(2, '0')}/${String(d.getFullYear()).slice(-2)}`;
  }
}

