import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { CardService } from './card.service';
import { ApiService } from './api.service';

describe('CardService', () => {
  let service: CardService;
  let apiServiceSpy: jasmine.SpyObj<ApiService>;

  beforeEach(() => {
    const spy = jasmine.createSpyObj('ApiService', ['get', 'post', 'put']);

    TestBed.configureTestingModule({
      providers: [
        CardService,
        { provide: ApiService, useValue: spy }
      ]
    });

    service = TestBed.inject(CardService);
    apiServiceSpy = TestBed.inject(ApiService) as jasmine.SpyObj<ApiService>;
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should get all cards', () => {
    const mockResponse = {
      success: true,
      message: 'Cards fetched successfully',
      data: [],
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.get.and.returnValue(of(mockResponse as any));

    service.getAllCards().subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.get).toHaveBeenCalledWith('/cards');
  });

  it('should get active cards', () => {
    const mockResponse = {
      success: true,
      message: 'Active cards fetched successfully',
      data: [],
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.get.and.returnValue(of(mockResponse as any));

    service.getActiveCards().subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.get).toHaveBeenCalledWith('/cards/active');
  });

  it('should get card details by id', () => {
    const mockResponse = {
      success: true,
      message: 'Card fetched successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.get.and.returnValue(of(mockResponse as any));

    service.getCardDetails(1).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.get).toHaveBeenCalledWith('/cards/1');
  });

  it('should create a card', () => {
    const request = {
      accountId: 1,
      cardType: 'DEBIT'
    };

    const mockResponse = {
      success: true,
      message: 'Card created successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };

    apiServiceSpy.post.and.returnValue(of(mockResponse as any));

    service.createCard(request as any).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.post).toHaveBeenCalledWith('/cards', request);
  });

  it('should block a card', () => {
    const mockResponse = {
      success: true,
      message: 'Card blocked successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.post.and.returnValue(of(mockResponse as any));

    service.blockCard(1).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.post).toHaveBeenCalledWith('/cards/1/block', {});
  });

  it('should unblock a card', () => {
    const mockResponse = {
      success: true,
      message: 'Card unblocked successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.post.and.returnValue(of(mockResponse as any));

    service.unblockCard(1).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.post).toHaveBeenCalledWith('/cards/1/unblock', {});
  });

  it('should cancel a card', () => {
    const mockResponse = {
      success: true,
      message: 'Card cancelled successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };
    apiServiceSpy.post.and.returnValue(of(mockResponse as any));

    service.cancelCard(1).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.post).toHaveBeenCalledWith('/cards/1/cancel', {});
  });

  it('should update spending limit', () => {
    const request = {
      cardId: 1,
      dailyLimit: 5000
    };

    const mockResponse = {
      success: true,
      message: 'Card limit updated successfully',
      data: { id: 1 },
      timestamp: new Date().toISOString()
    };

    apiServiceSpy.put.and.returnValue(of(mockResponse as any));

    service.updateSpendingLimit(request as any).subscribe(response => {
      expect(response).toEqual(mockResponse as any);
    });

    expect(apiServiceSpy.put).toHaveBeenCalledWith('/cards/limit', request);
  });
});