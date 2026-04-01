# API Endpoints Reference

## Base URL
```
http://localhost:8080/api
```

## 📋 Table of Contents
1. [Authentication](#authentication)
2. [Dashboard](#dashboard)
3. [Accounts](#accounts)
4. [Transactions](#transactions)
5. [Money Operations](#money-operations)
6. [Beneficiaries](#beneficiaries)
7. [Profile](#profile)
8. [Help](#help)

---

## Authentication

### Register New User
**Endpoint:** `POST /api/auth/register`

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "password": "SecurePass123!",
  "phoneNumber": "+1234567890",
  "address": "123 Main St, City, Country"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "type": "Bearer",
    "userId": 1,
    "email": "john.doe@example.com",
    "firstName": "John",
    "lastName": "Doe"
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

### Login
**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
  "email": "john.doe@example.com",
  "password": "SecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "type": "Bearer",
    "userId": 1,
    "email": "john.doe@example.com",
    "firstName": "John",
    "lastName": "Doe"
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

---

## Dashboard

### Get Dashboard Data
**Endpoint:** `GET /api/dashboard`

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Dashboard data retrieved successfully",
  "data": {
    "totalBalance": 5000.00,
    "accounts": [
      {
        "id": 1,
        "accountNumber": "1234567890",
        "accountType": "CHECKING",
        "balance": 3000.00,
        "currency": "USD",
        "status": "ACTIVE",
        "createdAt": "2024-11-26T10:00:00"
      }
    ],
    "recentTransactions": [
      {
        "id": 1,
        "transactionReference": "TXN123456789ABC",
        "type": "DEPOSIT",
        "amount": 1000.00,
        "balanceAfter": 3000.00,
        "description": "Initial deposit",
        "status": "COMPLETED",
        "createdAt": "2024-11-26T10:15:00"
      }
    ],
    "totalAccounts": 1,
    "totalTransactions": 1
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

---

## Accounts

### Get All Accounts
**Endpoint:** `GET /api/accounts`

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Accounts retrieved successfully",
  "data": [
    {
      "id": 1,
      "accountNumber": "1234567890",
      "accountType": "CHECKING",
      "balance": 3000.00,
      "currency": "USD",
      "status": "ACTIVE",
      "createdAt": "2024-11-26T10:00:00"
    }
  ],
  "timestamp": "2024-11-26T10:30:00"
}
```

### Get Account by ID
**Endpoint:** `GET /api/accounts/{id}`

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Account retrieved successfully",
  "data": {
    "id": 1,
    "accountNumber": "1234567890",
    "accountType": "CHECKING",
    "balance": 3000.00,
    "currency": "USD",
    "status": "ACTIVE",
    "createdAt": "2024-11-26T10:00:00"
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

---

## Transactions

### Get All Transactions
**Endpoint:** `GET /api/transactions`

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Transactions retrieved successfully",
  "data": [
    {
      "id": 1,
      "transactionReference": "TXN123456789ABC",
      "type": "DEPOSIT",
      "amount": 1000.00,
      "balanceAfter": 3000.00,
      "description": "Initial deposit",
      "status": "COMPLETED",
      "depositMethod": "BANK_TRANSFER",
      "createdAt": "2024-11-26T10:15:00"
    }
  ],
  "timestamp": "2024-11-26T10:30:00"
}
```

### Get Transaction by ID
**Endpoint:** `GET /api/transactions/{id}`

### Get Transactions by Account
**Endpoint:** `GET /api/transactions/account/{accountId}`

---

## Money Operations

### Deposit Money
**Endpoint:** `POST /api/money/deposit`

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "accountId": 1,
  "amount": 1000.00,
  "depositMethod": "BANK_TRANSFER",
  "description": "Monthly salary"
}
```

**Deposit Methods:**
- `CARD`
- `BANK_TRANSFER`
- `CASH`
- `CHECK`

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Deposit successful",
  "data": {
    "id": 1,
    "transactionReference": "TXN123456789ABC",
    "type": "DEPOSIT",
    "amount": 1000.00,
    "balanceAfter": 4000.00,
    "description": "Monthly salary",
    "status": "COMPLETED",
    "depositMethod": "BANK_TRANSFER",
    "createdAt": "2024-11-26T10:30:00"
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

### Transfer Money
**Endpoint:** `POST /api/money/transfer`

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "fromAccountId": 1,
  "recipientAccountNumber": "9876543210",
  "amount": 500.00,
  "description": "Payment for services"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Transfer successful",
  "data": {
    "id": 2,
    "transactionReference": "TXN987654321XYZ",
    "type": "TRANSFER_OUT",
    "amount": 500.00,
    "balanceAfter": 3500.00,
    "description": "Payment for services",
    "status": "COMPLETED",
    "recipientAccountNumber": "9876543210",
    "recipientName": "Jane Smith",
    "createdAt": "2024-11-26T10:35:00"
  },
  "timestamp": "2024-11-26T10:35:00"
}
```

### Internal Transfer
**Endpoint:** `POST /api/money/internal-transfer`

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "fromAccountId": 1,
  "toAccountId": 2,
  "amount": 250.00,
  "description": "Transfer to savings"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "Internal transfer successful",
  "data": {
    "id": 3,
    "transactionReference": "TXN456789123DEF",
    "type": "INTERNAL_TRANSFER",
    "amount": 250.00,
    "balanceAfter": 3250.00,
    "description": "Transfer to savings",
    "status": "COMPLETED",
    "recipientAccountNumber": "1234567891",
    "createdAt": "2024-11-26T10:40:00"
  },
  "timestamp": "2024-11-26T10:40:00"
}
```

---

## Beneficiaries

### Get All Beneficiaries
**Endpoint:** `GET /api/beneficiaries`

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Beneficiaries retrieved successfully",
  "data": [
    {
      "id": 1,
      "beneficiaryName": "Jane Smith",
      "accountNumber": "9876543210",
      "bankName": "ABC Bank",
      "bankCode": "ABC123",
      "nickname": "Jane",
      "createdAt": "2024-11-26T10:00:00"
    }
  ],
  "timestamp": "2024-11-26T10:30:00"
}
```

### Get Beneficiary by ID
**Endpoint:** `GET /api/beneficiaries/{id}`

### Add Beneficiary
**Endpoint:** `POST /api/beneficiaries`

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "beneficiaryName": "Jane Smith",
  "accountNumber": "9876543210",
  "bankName": "ABC Bank",
  "bankCode": "ABC123",
  "nickname": "Jane"
}
```

**Response:** `201 Created`

### Update Beneficiary
**Endpoint:** `PUT /api/beneficiaries/{id}`

**Request Body:** Same as Add Beneficiary

### Delete Beneficiary
**Endpoint:** `DELETE /api/beneficiaries/{id}`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Beneficiary deleted successfully",
  "data": null,
  "timestamp": "2024-11-26T10:30:00"
}
```

---

## Profile

### Get Profile
**Endpoint:** `GET /api/profile`

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phoneNumber": "+1234567890",
    "address": "123 Main St, City, Country",
    "twoFactorEnabled": false,
    "createdAt": "2024-11-26T10:00:00"
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

### Update Profile
**Endpoint:** `PUT /api/profile`

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890",
  "address": "456 New St, City, Country"
}
```

**Response:** `200 OK`

### Change Password
**Endpoint:** `POST /api/profile/change-password`

**Headers:**
```
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "currentPassword": "OldPass123!",
  "newPassword": "NewSecurePass123!"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Password changed successfully",
  "data": null,
  "timestamp": "2024-11-26T10:30:00"
}
```

### Toggle Two-Factor Authentication
**Endpoint:** `POST /api/profile/toggle-2fa`

**Headers:**
```
Authorization: Bearer <jwt-token>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Two-factor authentication enabled",
  "data": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phoneNumber": "+1234567890",
    "address": "123 Main St, City, Country",
    "twoFactorEnabled": true,
    "createdAt": "2024-11-26T10:00:00"
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

---

## Help

### Get Help Information
**Endpoint:** `GET /api/help`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Help information retrieved successfully",
  "data": {
    "contactEmail": "support@securebanking.com",
    "contactPhone": "+1-800-123-4567",
    "supportHours": "Monday - Friday: 9:00 AM - 6:00 PM EST",
    "faqs": {
      "How do I transfer money?": "Go to Money/Transfer page, select your account, enter recipient details and amount.",
      "How do I add a beneficiary?": "Navigate to Beneficiaries page and click 'Add Beneficiary' button.",
      "How do I change my password?": "Go to Profile > Security Settings and click 'Change Password'."
    }
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

---

## Error Responses

### Validation Error
**Status:** `400 Bad Request`
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "email": "Email must be valid",
    "password": "Password must be at least 8 characters"
  },
  "timestamp": "2024-11-26T10:30:00"
}
```

### Authentication Error
**Status:** `401 Unauthorized`
```json
{
  "success": false,
  "message": "Invalid email or password",
  "data": null,
  "timestamp": "2024-11-26T10:30:00"
}
```

### Resource Not Found
**Status:** `404 Not Found`
```json
{
  "success": false,
  "message": "Account not found with id: 999",
  "data": null,
  "timestamp": "2024-11-26T10:30:00"
}
```

### Insufficient Balance
**Status:** `400 Bad Request`
```json
{
  "success": false,
  "message": "Insufficient balance for this transfer",
  "data": null,
  "timestamp": "2024-11-26T10:30:00"
}
```

---

## Notes

1. All protected endpoints require a valid JWT token in the Authorization header
2. All timestamps are in ISO 8601 format
3. All monetary amounts are in decimal format with 2 decimal places
4. Transaction references are unique and auto-generated
5. Account numbers are 10-digit unique identifiers

