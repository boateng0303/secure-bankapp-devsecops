import { Component, OnInit } from '@angular/core';
import { TransactionService } from '../../core/services/transaction.service';
import { Transaction } from '../../shared/models/transaction.model';

@Component({
  selector: 'app-transactions',
  templateUrl: './transactions.component.html',
  styleUrls: ['./transactions.component.scss']
})
export class TransactionsComponent implements OnInit {
  transactions: Transaction[] = [];
  filteredTransactions: Transaction[] = [];
  loading = true;
  error = '';
  searchTerm = '';
  filterType = 'ALL';

  transactionTypes = [
    { value: 'ALL', label: 'All Types' },
    { value: 'DEPOSIT', label: 'Deposits' },
    { value: 'WITHDRAWAL', label: 'Withdrawals' },
    { value: 'TRANSFER_OUT', label: 'Transfers Out' },
    { value: 'TRANSFER_IN', label: 'Transfers In' },
    { value: 'INTERNAL_TRANSFER', label: 'Internal Transfers' }
  ];

  constructor(private transactionService: TransactionService) {}

  ngOnInit(): void {
    this.loadTransactions();
  }

  loadTransactions(): void {
    this.loading = true;
    this.transactionService.getAllTransactions().subscribe({
      next: (response) => {
        this.transactions = response.data;
        this.filteredTransactions = this.transactions;
        this.loading = false;
      },
      error: (error) => {
        this.error = error.message || 'Failed to load transactions';
        this.loading = false;
      }
    });
  }

  applyFilters(): void {
    this.filteredTransactions = this.transactions.filter(transaction => {
      const matchesSearch = transaction.description.toLowerCase().includes(this.searchTerm.toLowerCase()) ||
                           transaction.transactionReference.toLowerCase().includes(this.searchTerm.toLowerCase());
      const matchesType = this.filterType === 'ALL' || transaction.type === this.filterType;
      return matchesSearch && matchesType;
    });
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  onFilterChange(): void {
    this.applyFilters();
  }

  getTransactionIcon(type: string): string {
    switch (type) {
      case 'DEPOSIT': return 'arrow_downward';
      case 'WITHDRAWAL': return 'arrow_upward';
      case 'TRANSFER_OUT': return 'send';
      case 'TRANSFER_IN': return 'call_received';
      case 'INTERNAL_TRANSFER': return 'swap_horiz';
      default: return 'receipt';
    }
  }

  getTransactionColor(type: string): string {
    switch (type) {
      case 'DEPOSIT':
      case 'TRANSFER_IN':
        return 'success';
      case 'WITHDRAWAL':
      case 'TRANSFER_OUT':
        return 'warn';
      default:
        return 'primary';
    }
  }

  getAmountSign(type: string): string {
    return (type === 'DEPOSIT' || type === 'TRANSFER_IN') ? '+' : '-';
  }
}


