import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../core/services/api.service';

interface FAQ {
  question: string;
  answer: string;
}

@Component({
  selector: 'app-help',
  templateUrl: './help.component.html',
  styleUrls: ['./help.component.scss']
})
export class HelpComponent implements OnInit {
  helpData: any = null;
  loading = true;
  expandedIndex = -1;

  constructor(private apiService: ApiService) {}

  ngOnInit(): void {
    this.loadHelpData();
  }

  loadHelpData(): void {
    this.apiService.get('/help').subscribe({
      next: (response: any) => {
        this.helpData = response.data;
        this.loading = false;
      },
      error: (error) => {
        console.error('Failed to load help data', error);
        this.loading = false;
        // Use fallback data
        this.helpData = this.getFallbackData();
      }
    });
  }

  getFallbackData(): any {
    return {
      contactEmail: 'support@securebanking.com',
      contactPhone: '+1-800-123-4567',
      supportHours: 'Monday - Friday: 9:00 AM - 6:00 PM EST',
      faqs: {
        'How do I transfer money?': 'Go to Money/Transfer page, select your account, enter recipient details and amount.',
        'How do I add a beneficiary?': 'Navigate to Beneficiaries page and click "Add Beneficiary" button.',
        'How do I change my password?': 'Go to Profile > Security Settings and click "Change Password".',
        'What should I do if I forget my password?': 'Click "Forgot Password" on the login page and follow the instructions.',
        'How do I enable two-factor authentication?': 'Go to Profile > Security Settings and toggle the 2FA option.'
      }
    };
  }

  toggleAccordion(index: number): void {
    this.expandedIndex = this.expandedIndex === index ? -1 : index;
  }

  getFAQArray(): Array<{ question: string; answer: string }> {
    if (!this.helpData?.faqs) return [];
    return Object.entries(this.helpData.faqs).map(([question, answer]) => ({
      question,
      answer: answer as string
    }));
  }
}


