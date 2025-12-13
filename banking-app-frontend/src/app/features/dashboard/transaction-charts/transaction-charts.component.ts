import { Component, OnInit, ViewChild } from '@angular/core';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';
import { DashboardService } from '../../../core/services/dashboard.service';

@Component({
  selector: 'app-transaction-charts',
  templateUrl: './transaction-charts.component.html',
  styleUrls: ['./transaction-charts.component.scss']
})
export class TransactionChartsComponent implements OnInit {
  @ViewChild(BaseChartDirective) chart?: BaseChartDirective;

  loading = true;
  error = '';

  // Line Chart: Income vs Withdrawals
  public lineChartData: ChartConfiguration['data'] = {
    datasets: [
      {
        data: [],
        label: 'Deposits',
        backgroundColor: 'rgba(34, 197, 94, 0.2)',
        borderColor: 'rgba(34, 197, 94, 1)',
        pointBackgroundColor: 'rgba(34, 197, 94, 1)',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: 'rgba(34, 197, 94, 1)',
        fill: 'origin',
        tension: 0.4
      },
      {
        data: [],
        label: 'Withdrawals',
        backgroundColor: 'rgba(239, 68, 68, 0.2)',
        borderColor: 'rgba(239, 68, 68, 1)',
        pointBackgroundColor: 'rgba(239, 68, 68, 1)',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: 'rgba(239, 68, 68, 1)',
        fill: 'origin',
        tension: 0.4
      }
    ],
    labels: []
  };

  public lineChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'top',
      },
      tooltip: {
        mode: 'index',
        intersect: false,
        callbacks: {
          label: function(context) {
            let label = context.dataset.label || '';
            if (label) {
              label += ': ';
            }
            const value = context.parsed?.y ?? 0;
            label += '$' + value.toFixed(2);
            return label;
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          callback: function(value) {
            return '$' + value;
          }
        }
      }
    },
    interaction: {
      mode: 'nearest',
      axis: 'x',
      intersect: false
    }
  };

  public lineChartType: ChartType = 'line';

  // Doughnut Chart: Transaction Types
  public doughnutChartData: ChartData<'doughnut'> = {
    labels: ['Deposits', 'Withdrawals', 'Transfers Out', 'Transfers In'],
    datasets: [{
      data: [],
      backgroundColor: [
        'rgba(34, 197, 94, 0.8)',   // Green for deposits
        'rgba(239, 68, 68, 0.8)',    // Red for withdrawals
        'rgba(249, 115, 22, 0.8)',   // Orange for transfers out
        'rgba(59, 130, 246, 0.8)'    // Blue for transfers in
      ],
      borderWidth: 2,
      borderColor: '#fff',
      hoverOffset: 15
    }]
  };

  public doughnutChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'bottom',
      },
      tooltip: {
        callbacks: {
          label: function(context) {
            const label = context.label || '';
            const value = context.parsed || 0;
            const dataset = context.dataset.data as number[];
            const total = dataset.reduce((a: number, b: number) => a + b, 0);
            const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : '0.0';
            return `${label}: ${value} (${percentage}%)`;
          }
        }
      }
    }
  };

  public doughnutChartType: ChartType = 'doughnut';

  // Bar Chart: Daily Net Cash Flow
  public barChartData: ChartData<'bar'> = {
    labels: [],
    datasets: [
      {
        data: [],
        label: 'Net Cash Flow',
        backgroundColor: [],
        borderColor: [],
        borderWidth: 2,
        borderRadius: 8
      }
    ]
  };

  public barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        callbacks: {
          label: function(context) {
            const value = context.parsed?.y ?? 0;
            return value >= 0 
              ? `Income: $${value.toFixed(2)}`
              : `Expense: $${Math.abs(value).toFixed(2)}`;
          }
        }
      }
    },
    scales: {
      y: {
        ticks: {
          callback: function(value) {
            return '$' + value;
          }
        }
      }
    }
  };

  public barChartType: ChartType = 'bar';

  // Polar Area Chart: Account Balance Distribution
  public polarChartData: ChartData<'polarArea'> = {
    labels: [],
    datasets: [{
      data: [],
      backgroundColor: [
        'rgba(59, 130, 246, 0.8)',   // Blue
        'rgba(34, 197, 94, 0.8)',    // Green
        'rgba(168, 85, 247, 0.8)',   // Purple
        'rgba(249, 115, 22, 0.8)',   // Orange
        'rgba(236, 72, 153, 0.8)',   // Pink
        'rgba(20, 184, 166, 0.8)'    // Teal
      ],
      borderWidth: 2,
      borderColor: '#fff'
    }]
  };

  public polarChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: true,
        position: 'bottom'
      },
      tooltip: {
        callbacks: {
          label: function(context) {
            const label = context.label || '';
            const value = context.parsed?.r ?? 0;
            const dataset = context.dataset.data as number[];
            const total = dataset.reduce((a: number, b: number) => a + b, 0);
            const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : '0.0';
            return `${label}: $${value.toLocaleString('en-US', { minimumFractionDigits: 2 })} (${percentage}%)`;
          }
        }
      }
    },
    scales: {
      r: {
        ticks: {
          display: false
        }
      }
    }
  };

  public polarChartType: ChartType = 'polarArea';

  // Area Chart: Balance Over Time
  public areaChartData: ChartConfiguration['data'] = {
    labels: [],
    datasets: [{
      data: [],
      label: 'Total Balance',
      backgroundColor: 'rgba(99, 102, 241, 0.3)',
      borderColor: 'rgba(99, 102, 241, 1)',
      pointBackgroundColor: 'rgba(99, 102, 241, 1)',
      pointBorderColor: '#fff',
      pointHoverBackgroundColor: '#fff',
      pointHoverBorderColor: 'rgba(99, 102, 241, 1)',
      pointRadius: 6,
      pointHoverRadius: 8,
      fill: true,
      tension: 0.4
    }]
  };

  public areaChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        callbacks: {
          label: function(context) {
            const value = context.parsed?.y ?? 0;
            return `Balance: $${value.toLocaleString('en-US', { minimumFractionDigits: 2 })}`;
          }
        }
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          callback: function(value) {
            return '$' + Number(value).toLocaleString();
          }
        }
      }
    },
    interaction: {
      mode: 'nearest',
      axis: 'x',
      intersect: false
    }
  };

  public areaChartType: ChartType = 'line';

  constructor(private dashboardService: DashboardService) {}

  ngOnInit(): void {
    this.loadChartData();
  }

  loadChartData(): void {
    this.loading = true;
    this.dashboardService.getTransactionAnalytics().subscribe({
      next: (response) => {
        const data = response.data;
        this.updateLineChart(data.monthlyData);
        this.updateDoughnutChart(data.typeDistribution);
        this.updateBarChart(data.dailyCashFlow);
        this.updatePolarChart(data.accountDistribution);
        this.updateAreaChart(data.balanceHistory);
        this.loading = false;
      },
      error: (error) => {
        this.error = error.message || 'Failed to load chart data';
        this.loading = false;
      }
    });
  }

  private updateLineChart(monthlyData: any): void {
    this.lineChartData.labels = monthlyData.labels;
    this.lineChartData.datasets[0].data = monthlyData.deposits;
    this.lineChartData.datasets[1].data = monthlyData.withdrawals;
    this.chart?.update();
  }

  private updateDoughnutChart(typeDistribution: any): void {
    this.doughnutChartData.datasets[0].data = [
      typeDistribution.deposits,
      typeDistribution.withdrawals,
      typeDistribution.transfersOut,
      typeDistribution.transfersIn
    ];
  }

  private updateBarChart(dailyCashFlow: any): void {
    this.barChartData.labels = dailyCashFlow.labels;
    this.barChartData.datasets[0].data = dailyCashFlow.netFlow;
    
    // Set colors based on positive/negative values
    const colors = dailyCashFlow.netFlow.map((value: number) => {
      return value >= 0 ? 'rgba(34, 197, 94, 0.8)' : 'rgba(239, 68, 68, 0.8)';
    });
    const borderColors = dailyCashFlow.netFlow.map((value: number) => {
      return value >= 0 ? 'rgba(34, 197, 94, 1)' : 'rgba(239, 68, 68, 1)';
    });
    
    this.barChartData.datasets[0].backgroundColor = colors;
    this.barChartData.datasets[0].borderColor = borderColors;
  }

  private updatePolarChart(accountDistribution: any): void {
    if (accountDistribution) {
      // Create labels with account type and last 4 digits
      const labels = accountDistribution.labels.map((label: string, index: number) => {
        return `${label} ${accountDistribution.accountNumbers[index]}`;
      });
      this.polarChartData.labels = labels;
      this.polarChartData.datasets[0].data = accountDistribution.balances;
    }
  }

  private updateAreaChart(balanceHistory: any): void {
    if (balanceHistory) {
      this.areaChartData.labels = balanceHistory.labels;
      this.areaChartData.datasets[0].data = balanceHistory.totalBalance;
    }
  }
}

