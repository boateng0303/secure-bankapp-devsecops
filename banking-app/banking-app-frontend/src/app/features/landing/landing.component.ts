import { Component } from '@angular/core';

@Component({
  selector: 'app-landing',
  templateUrl: './landing.component.html',
  styleUrls: ['./landing.component.scss']
})
export class LandingComponent {
  features = [
    { icon: 'security', title: 'Secure', description: 'Bank-level security with JWT authentication' },
    { icon: 'speed', title: 'Fast', description: 'Lightning-fast transactions' },
    { icon: 'account_balance_wallet', title: 'Easy', description: 'Simple and intuitive interface' }
  ];
}


