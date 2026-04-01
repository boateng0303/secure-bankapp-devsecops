import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';

// Components
import { LandingComponent } from './features/landing/landing.component';
import { LoginComponent } from './features/auth/login/login.component';
import { RegisterComponent } from './features/auth/register/register.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';
import { TransactionsComponent } from './features/transactions/transactions.component';
import { MoneyComponent } from './features/money/money.component';
import { ProfileComponent } from './features/profile/profile.component';
import { HelpComponent } from './features/help/help.component';
import { AccountsComponent } from './features/accounts/accounts.component';
import { BeneficiariesComponent } from './features/beneficiaries/beneficiaries.component';
import { CardsComponent } from './features/cards/cards.component';

const routes: Routes = [
  // Public routes
  { path: '', component: LandingComponent },
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  
  // Protected routes
  { 
    path: 'dashboard', 
    component: DashboardComponent,
    canActivate: [AuthGuard]
  },
  { 
    path: 'accounts', 
    component: AccountsComponent,
    canActivate: [AuthGuard]
  },
  { 
    path: 'transactions', 
    component: TransactionsComponent,
    canActivate: [AuthGuard]
  },
  { 
    path: 'money', 
    component: MoneyComponent,
    canActivate: [AuthGuard]
  },
  { 
    path: 'profile', 
    component: ProfileComponent,
    canActivate: [AuthGuard]
  },
  { 
    path: 'beneficiaries', 
    component: BeneficiariesComponent,
    canActivate: [AuthGuard]
  },
  { 
    path: 'cards', 
    component: CardsComponent,
    canActivate: [AuthGuard]
  },
  { 
    path: 'help', 
    component: HelpComponent,
    canActivate: [AuthGuard]
  },
  
  // Redirect unknown routes to landing
  { path: '**', redirectTo: '' }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }


