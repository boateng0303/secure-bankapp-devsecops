import { Account } from './account.model';
import { Transaction } from './transaction.model';

export interface DashboardData {
  totalBalance: number;
  accounts: Account[];
  recentTransactions: Transaction[];
  totalAccounts: number;
  totalTransactions: number;
}


