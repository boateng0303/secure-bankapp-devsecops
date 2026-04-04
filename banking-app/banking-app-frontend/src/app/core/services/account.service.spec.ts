import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { AccountService, CreateAccountRequest } from './account.service';
import { ApiService } from './api.service';

describe('AccountService', () => {
  let service: AccountService;
  let apiServiceSpy: jasmine.SpyObj<ApiService>;

  beforeEach(() => {
    const spy = jasmine.createSpyObj('ApiService', ['get', 'post']);

    TestBed.configureTestingModule({
      providers: [
        AccountService,
        { provide: ApiService, useValue: spy }
      ]
    });

    service = TestBed.inject(AccountService);
    apiServiceSpy = TestBed.inject(ApiService) as jasmine.SpyObj<ApiService>;
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should get all accounts', () => {
    const mockResponse = {
      success: true,
      message: 'Accounts fetched successfully',
      data: [],
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.get.and.returnValue(of(mockResponse as any));

    service.getAllAccounts().subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.get).toHaveBeenCalledWith('/accounts');
  });

  it('should get active accounts', () => {
    const mockResponse = {
      success: true,
      message: 'Active accounts fetched successfully',
      data: [],
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.get.and.returnValue(of(mockResponse as any));

    service.getActiveAccounts().subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.get).toHaveBeenCalledWith('/accounts/active');
  });

  it('should get account by id', () => {
    const mockResponse = {
      success: true,
      message: 'Account fetched successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.get.and.returnValue(of(mockResponse as any));

    service.getAccountById(1).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.get).toHaveBeenCalledWith('/accounts/1');
  });

  it('should create account', () => {
    const request: CreateAccountRequest = {
      accountType: 'SAVINGS',
      currency: 'USD'
    };

    const mockResponse = {
      success: true,
      message: 'Account created successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };

    apiServiceSpy.post.and.returnValue(of(mockResponse as any));

    service.createAccount(request).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.post).toHaveBeenCalledWith('/accounts', request);
  });

  it('should close account', () => {
    const mockResponse = {
      success: true,
      message: 'Account closed successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.post.and.returnValue(of(mockResponse as any));

    service.closeAccount(1).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.post).toHaveBeenCalledWith('/accounts/1/close', {});
  });
});