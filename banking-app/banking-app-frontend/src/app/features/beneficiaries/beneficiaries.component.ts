import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { BeneficiaryService } from '../../core/services/beneficiary.service';
import { Beneficiary, BeneficiaryRequest } from '../../shared/models/beneficiary.model';

@Component({
  selector: 'app-beneficiaries',
  templateUrl: './beneficiaries.component.html',
  styleUrls: ['./beneficiaries.component.scss']
})
export class BeneficiariesComponent implements OnInit {
  beneficiaries: Beneficiary[] = [];
  loading = false;
  actionLoading = false;
  success = '';
  error = '';
  
  // Modal state
  showModal = false;
  isEditMode = false;
  editingBeneficiary: Beneficiary | null = null;
  
  // Form
  beneficiaryForm!: FormGroup;

  constructor(
    private fb: FormBuilder,
    private beneficiaryService: BeneficiaryService
  ) {}

  ngOnInit(): void {
    this.initializeForm();
    this.loadBeneficiaries();
  }

  initializeForm(): void {
    this.beneficiaryForm = this.fb.group({
      beneficiaryName: ['', [Validators.required, Validators.minLength(2)]],
      accountNumber: ['', [Validators.required, Validators.pattern(/^\d{10}$/)]],
      bankName: ['', Validators.required],
      bankCode: [''],
      nickname: ['']
    });
  }

  loadBeneficiaries(): void {
    this.loading = true;
    this.beneficiaryService.getAllBeneficiaries().subscribe({
      next: (response) => {
        this.beneficiaries = response.data;
        this.loading = false;
      },
      error: (error) => {
        this.error = error.message || 'Failed to load beneficiaries';
        this.loading = false;
      }
    });
  }

  openAddModal(): void {
    this.isEditMode = false;
    this.editingBeneficiary = null;
    this.beneficiaryForm.reset();
    this.beneficiaryForm.patchValue({ bankName: 'Reuel Banking' });
    this.showModal = true;
    this.error = '';
    this.success = '';
  }

  openEditModal(beneficiary: Beneficiary): void {
    this.isEditMode = true;
    this.editingBeneficiary = beneficiary;
    this.beneficiaryForm.patchValue({
      beneficiaryName: beneficiary.beneficiaryName,
      accountNumber: beneficiary.accountNumber,
      bankName: beneficiary.bankName,
      bankCode: beneficiary.bankCode || '',
      nickname: beneficiary.nickname || ''
    });
    this.showModal = true;
    this.error = '';
    this.success = '';
  }

  closeModal(): void {
    this.showModal = false;
    this.isEditMode = false;
    this.editingBeneficiary = null;
    this.beneficiaryForm.reset();
  }

  saveBeneficiary(): void {
    if (this.beneficiaryForm.invalid) {
      this.beneficiaryForm.markAllAsTouched();
      return;
    }

    this.actionLoading = true;
    this.error = '';
    this.success = '';

    const request: BeneficiaryRequest = this.beneficiaryForm.value;

    if (this.isEditMode && this.editingBeneficiary) {
      this.beneficiaryService.updateBeneficiary(this.editingBeneficiary.id, request).subscribe({
        next: (response) => {
          this.success = 'Beneficiary updated successfully!';
          this.actionLoading = false;
          this.closeModal();
          this.loadBeneficiaries();
        },
        error: (error) => {
          this.error = error.message || 'Failed to update beneficiary';
          this.actionLoading = false;
        }
      });
    } else {
      this.beneficiaryService.addBeneficiary(request).subscribe({
        next: (response) => {
          this.success = 'Beneficiary added successfully!';
          this.actionLoading = false;
          this.closeModal();
          this.loadBeneficiaries();
        },
        error: (error) => {
          this.error = error.message || 'Failed to add beneficiary';
          this.actionLoading = false;
        }
      });
    }
  }

  deleteBeneficiary(beneficiary: Beneficiary): void {
    if (!confirm(`Are you sure you want to delete "${beneficiary.nickname || beneficiary.beneficiaryName}"?`)) {
      return;
    }

    this.actionLoading = true;
    this.error = '';
    this.success = '';

    this.beneficiaryService.deleteBeneficiary(beneficiary.id).subscribe({
      next: () => {
        this.success = 'Beneficiary deleted successfully!';
        this.actionLoading = false;
        this.loadBeneficiaries();
      },
      error: (error) => {
        this.error = error.message || 'Failed to delete beneficiary';
        this.actionLoading = false;
      }
    });
  }

  getDisplayName(beneficiary: Beneficiary): string {
    return beneficiary.nickname || beneficiary.beneficiaryName;
  }

  getInitials(name: string): string {
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  }

  getAvatarColor(index: number): string {
    const colors = [
      'bg-primary-500',
      'bg-accent-500',
      'bg-success-500',
      'bg-warning-500',
      'bg-danger-500',
      'bg-indigo-500',
      'bg-pink-500',
      'bg-teal-500'
    ];
    return colors[index % colors.length];
  }
}

