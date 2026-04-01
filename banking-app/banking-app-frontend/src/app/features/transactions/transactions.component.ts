import { Component, OnInit } from '@angular/core';
import { TransactionService } from '../../core/services/transaction.service';
import { AccountService } from '../../core/services/account.service';
import { Transaction } from '../../shared/models/transaction.model';
import { Account } from '../../shared/models/account.model';

@Component({
  selector: 'app-transactions',
  templateUrl: './transactions.component.html',
  styleUrls: ['./transactions.component.scss']
})
export class TransactionsComponent implements OnInit {
  transactions: Transaction[] = [];
  filteredTransactions: Transaction[] = [];
  accounts: Account[] = [];
  loading = true;
  error = '';
  searchTerm = '';
  filterType = 'ALL';
  filterAccount = 'ALL';

  transactionTypes = [
    { value: 'ALL', label: 'All Types' },
    { value: 'DEPOSIT', label: 'Deposits' },
    { value: 'WITHDRAWAL', label: 'Withdrawals' },
    { value: 'TRANSFER_OUT', label: 'Transfers Out' },
    { value: 'TRANSFER_IN', label: 'Transfers In' },
    { value: 'INTERNAL_TRANSFER', label: 'Internal Transfers' }
  ];

  constructor(
    private transactionService: TransactionService,
    private accountService: AccountService
  ) {}

  ngOnInit(): void {
    this.loadAccounts();
    this.loadTransactions();
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
      const matchesAccount = this.filterAccount === 'ALL' || transaction.accountId.toString() === this.filterAccount;
      return matchesSearch && matchesType && matchesAccount;
    });
  }

  onSearchChange(): void {
    this.applyFilters();
  }

  onFilterChange(): void {
    this.applyFilters();
  }

  onAccountFilterChange(): void {
    this.applyFilters();
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.filterType = 'ALL';
    this.filterAccount = 'ALL';
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

  downloadCSV(): void {
    const transactions = this.filteredTransactions;
    if (transactions.length === 0) {
      alert('No transactions to download');
      return;
    }

    // CSV Header
    const headers = ['Date', 'Reference', 'Account', 'Type', 'Description', 'Amount', 'Balance After', 'Status'];
    
    // CSV Rows
    const rows = transactions.map(t => [
      new Date(t.createdAt).toLocaleString(),
      t.transactionReference,
      `${t.accountType} - ****${t.accountNumber.slice(-4)}`,
      t.type.replace('_', ' '),
      `"${t.description}"`,
      `${this.getAmountSign(t.type)}$${t.amount.toFixed(2)}`,
      `$${t.balanceAfter.toFixed(2)}`,
      t.status
    ]);

    // Combine headers and rows
    const csvContent = [headers, ...rows]
      .map(row => row.join(','))
      .join('\n');

    // Create and download file
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    
    link.setAttribute('href', url);
    link.setAttribute('download', `transaction_statement_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  downloadPDF(): void {
    const transactions = this.filteredTransactions;
    if (transactions.length === 0) {
      alert('No transactions to download');
      return;
    }

    // Create printable HTML content
    const totalDeposits = transactions
      .filter(t => t.type === 'DEPOSIT' || t.type === 'TRANSFER_IN')
      .reduce((sum, t) => sum + t.amount, 0);
    
    const totalWithdrawals = transactions
      .filter(t => t.type === 'WITHDRAWAL' || t.type === 'TRANSFER_OUT')
      .reduce((sum, t) => sum + t.amount, 0);

    const selectedAccount = this.filterAccount === 'ALL' 
      ? 'All Accounts' 
      : this.accounts.find(a => a.id.toString() === this.filterAccount);
    
    const accountLabel = this.filterAccount === 'ALL' 
      ? 'All Accounts'
      : `${(selectedAccount as any)?.accountType} - ****${(selectedAccount as any)?.accountNumber.slice(-4)}`;

    const printContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Transaction Statement - Reuel Banking</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: 'Segoe UI', Arial, sans-serif; padding: 40px; color: #333; }
          .header { text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 2px solid #4f46e5; }
          .header h1 { color: #4f46e5; font-size: 28px; margin-bottom: 5px; }
          .header p { color: #666; font-size: 14px; }
          .meta { display: flex; justify-content: space-between; margin-bottom: 20px; padding: 15px; background: #f8f9fa; border-radius: 8px; }
          .meta-item { text-align: center; }
          .meta-item label { display: block; font-size: 12px; color: #666; margin-bottom: 4px; }
          .meta-item span { font-size: 16px; font-weight: 600; color: #333; }
          .summary { display: flex; gap: 20px; margin-bottom: 30px; }
          .summary-card { flex: 1; padding: 15px; border-radius: 8px; text-align: center; }
          .summary-card.deposits { background: #dcfce7; }
          .summary-card.withdrawals { background: #fef3c7; }
          .summary-card.net { background: #e0e7ff; }
          .summary-card label { display: block; font-size: 12px; color: #666; margin-bottom: 4px; }
          .summary-card span { font-size: 20px; font-weight: 700; }
          .summary-card.deposits span { color: #16a34a; }
          .summary-card.withdrawals span { color: #d97706; }
          .summary-card.net span { color: #4f46e5; }
          table { width: 100%; border-collapse: collapse; margin-top: 20px; }
          th { background: #4f46e5; color: white; padding: 12px 8px; text-align: left; font-size: 12px; }
          td { padding: 10px 8px; border-bottom: 1px solid #eee; font-size: 12px; }
          tr:nth-child(even) { background: #f8f9fa; }
          .amount-positive { color: #16a34a; font-weight: 600; }
          .amount-negative { color: #d97706; font-weight: 600; }
          .footer { margin-top: 40px; text-align: center; color: #999; font-size: 11px; }
          @media print { body { padding: 20px; } }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Reuel Banking</h1>
          <p>Transaction Statement</p>
        </div>
        
        <div class="meta">
          <div class="meta-item">
            <label>Account</label>
            <span>${accountLabel}</span>
          </div>
          <div class="meta-item">
            <label>Statement Date</label>
            <span>${new Date().toLocaleDateString()}</span>
          </div>
          <div class="meta-item">
            <label>Total Transactions</label>
            <span>${transactions.length}</span>
          </div>
        </div>

        <div class="summary">
          <div class="summary-card deposits">
            <label>Total Income</label>
            <span>+$${totalDeposits.toFixed(2)}</span>
          </div>
          <div class="summary-card withdrawals">
            <label>Total Expenses</label>
            <span>-$${totalWithdrawals.toFixed(2)}</span>
          </div>
          <div class="summary-card net">
            <label>Net Change</label>
            <span>${(totalDeposits - totalWithdrawals) >= 0 ? '+' : ''}$${(totalDeposits - totalWithdrawals).toFixed(2)}</span>
          </div>
        </div>
        
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Reference</th>
              <th>Account</th>
              <th>Type</th>
              <th>Description</th>
              <th>Amount</th>
              <th>Balance</th>
            </tr>
          </thead>
          <tbody>
            ${transactions.map(t => `
              <tr>
                <td>${new Date(t.createdAt).toLocaleDateString()}</td>
                <td>${t.transactionReference}</td>
                <td>${t.accountType} ****${t.accountNumber.slice(-4)}</td>
                <td>${t.type.replace('_', ' ')}</td>
                <td>${t.description}</td>
                <td class="${(t.type === 'DEPOSIT' || t.type === 'TRANSFER_IN') ? 'amount-positive' : 'amount-negative'}">
                  ${this.getAmountSign(t.type)}$${t.amount.toFixed(2)}
                </td>
                <td>$${t.balanceAfter.toFixed(2)}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
        
        <div class="footer">
          <p>This is a computer-generated statement from Reuel Banking.</p>
          <p>Generated on ${new Date().toLocaleString()}</p>
        </div>
      </body>
      </html>
    `;

    // Open print dialog
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(printContent);
      printWindow.document.close();
      printWindow.focus();
      setTimeout(() => {
        printWindow.print();
      }, 250);
    }
  }
}


