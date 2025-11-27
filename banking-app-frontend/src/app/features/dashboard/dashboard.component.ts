import { Component, OnInit } from '@angular/core';
import { DashboardService } from '../../core/services/dashboard.service';
import { DashboardData } from '../../shared/models/dashboard.model';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit {
  dashboardData: DashboardData | null = null;
  loading = true;
  error = '';

  constructor(private dashboardService: DashboardService) {}

  ngOnInit(): void {
    this.loadDashboard();
  }

  loadDashboard(): void {
    this.loading = true;
    this.dashboardService.getDashboardData().subscribe({
      next: (response) => {
        this.dashboardData = response.data;
        this.loading = false;
      },
      error: (error) => {
        this.error = error.message || 'Failed to load dashboard';
        this.loading = false;
      }
    });
  }

  getAccountTypeIcon(type: string): string {
    switch (type) {
      case 'CHECKING': return 'account_balance';
      case 'SAVINGS': return 'savings';
      case 'INVESTMENT': return 'trending_up';
      default: return 'account_balance_wallet';
    }
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
}


