# Project Structure

## 📁 Complete Directory Structure

```
secure-banking-app/
│
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── banking/
│   │   │           ├── SecureBankingApplication.java
│   │   │           │
│   │   │           ├── controller/
│   │   │           │   ├── AuthController.java
│   │   │           │   ├── DashboardController.java
│   │   │           │   ├── AccountController.java
│   │   │           │   ├── TransactionController.java
│   │   │           │   ├── MoneyController.java
│   │   │           │   ├── BeneficiaryController.java
│   │   │           │   ├── ProfileController.java
│   │   │           │   └── HelpController.java
│   │   │           │
│   │   │           ├── service/
│   │   │           │   ├── UserService.java
│   │   │           │   ├── AuthService.java
│   │   │           │   ├── AccountService.java
│   │   │           │   ├── TransactionService.java
│   │   │           │   └── BeneficiaryService.java
│   │   │           │
│   │   │           ├── repository/
│   │   │           │   ├── UserRepository.java
│   │   │           │   ├── AccountRepository.java
│   │   │           │   ├── TransactionRepository.java
│   │   │           │   └── BeneficiaryRepository.java
│   │   │           │
│   │   │           ├── entity/
│   │   │           │   ├── User.java
│   │   │           │   ├── Account.java
│   │   │           │   ├── Transaction.java
│   │   │           │   └── Beneficiary.java
│   │   │           │
│   │   │           ├── dto/
│   │   │           │   ├── request/
│   │   │           │   │   ├── RegisterRequest.java
│   │   │           │   │   ├── LoginRequest.java
│   │   │           │   │   ├── TransferRequest.java
│   │   │           │   │   ├── DepositRequest.java
│   │   │           │   │   ├── InternalTransferRequest.java
│   │   │           │   │   ├── BeneficiaryRequest.java
│   │   │           │   │   ├── UpdateProfileRequest.java
│   │   │           │   │   └── ChangePasswordRequest.java
│   │   │           │   │
│   │   │           │   └── response/
│   │   │           │       ├── AuthResponse.java
│   │   │           │       ├── UserResponse.java
│   │   │           │       ├── AccountResponse.java
│   │   │           │       ├── TransactionResponse.java
│   │   │           │       ├── BeneficiaryResponse.java
│   │   │           │       ├── ApiResponse.java
│   │   │           │       └── DashboardResponse.java
│   │   │           │
│   │   │           ├── security/
│   │   │           │   ├── JwtService.java
│   │   │           │   ├── JwtAuthenticationFilter.java
│   │   │           │   └── SecurityConfig.java
│   │   │           │
│   │   │           └── exception/
│   │   │               ├── ResourceNotFoundException.java
│   │   │               ├── BadRequestException.java
│   │   │               ├── InsufficientBalanceException.java
│   │   │               └── GlobalExceptionHandler.java
│   │   │
│   │   └── resources/
│   │       ├── application.properties
│   │       └── application-prod.properties
│   │
│   └── test/
│       └── java/
│           └── com/
│               └── banking/
│                   └── (test files)
│
├── pom.xml
├── .gitignore
├── README.md
├── API_ENDPOINTS.md
├── QUICK_START.md
└── PROJECT_STRUCTURE.md
```

## 📦 Components Overview

### 🎯 Controllers (8 files)
REST API endpoints that handle HTTP requests and responses.

| Controller | Purpose | Endpoints |
|------------|---------|-----------|
| `AuthController` | Authentication | `/api/auth/*` |
| `DashboardController` | Dashboard data | `/api/dashboard` |
| `AccountController` | Account management | `/api/accounts/*` |
| `TransactionController` | Transaction history | `/api/transactions/*` |
| `MoneyController` | Money operations | `/api/money/*` |
| `BeneficiaryController` | Beneficiary management | `/api/beneficiaries/*` |
| `ProfileController` | User profile | `/api/profile/*` |
| `HelpController` | Help & FAQs | `/api/help` |

### 🔧 Services (5 files)
Business logic layer that processes data and enforces rules.

| Service | Responsibility |
|---------|---------------|
| `UserService` | User management & authentication |
| `AuthService` | Registration & login logic |
| `AccountService` | Account operations |
| `TransactionService` | Transaction processing |
| `BeneficiaryService` | Beneficiary CRUD operations |

### 💾 Repositories (4 files)
Data access layer using Spring Data JPA.

| Repository | Entity |
|------------|--------|
| `UserRepository` | User |
| `AccountRepository` | Account |
| `TransactionRepository` | Transaction |
| `BeneficiaryRepository` | Beneficiary |

### 🗃️ Entities (4 files)
Database models representing tables.

| Entity | Description |
|--------|-------------|
| `User` | User account information |
| `Account` | Bank accounts |
| `Transaction` | Transaction records |
| `Beneficiary` | Saved beneficiaries |

### 📝 DTOs (15 files)
Data Transfer Objects for API requests and responses.

**Request DTOs (8):**
- `RegisterRequest`
- `LoginRequest`
- `TransferRequest`
- `DepositRequest`
- `InternalTransferRequest`
- `BeneficiaryRequest`
- `UpdateProfileRequest`
- `ChangePasswordRequest`

**Response DTOs (7):**
- `AuthResponse`
- `UserResponse`
- `AccountResponse`
- `TransactionResponse`
- `BeneficiaryResponse`
- `ApiResponse<T>` (Generic wrapper)
- `DashboardResponse`

### 🔒 Security (3 files)
JWT authentication and security configuration.

| File | Purpose |
|------|---------|
| `JwtService` | JWT token generation & validation |
| `JwtAuthenticationFilter` | Request authentication filter |
| `SecurityConfig` | Spring Security configuration |

### ⚠️ Exceptions (4 files)
Custom exceptions and global error handling.

| Exception | Usage |
|-----------|-------|
| `ResourceNotFoundException` | Entity not found |
| `BadRequestException` | Invalid request data |
| `InsufficientBalanceException` | Insufficient funds |
| `GlobalExceptionHandler` | Centralized error handling |

## 🔗 Component Relationships

```
┌─────────────┐
│  Controller │ ← HTTP Requests
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Service   │ ← Business Logic
└──────┬──────┘
       │
       ↓
┌─────────────┐
│ Repository  │ ← Data Access
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Entity    │ ← Database Tables
└─────────────┘
```

## 🗄️ Database Schema

### Users Table
```sql
- id (PK)
- first_name
- last_name
- email (unique)
- password
- phone_number (unique)
- address
- role
- two_factor_enabled
- two_factor_secret
- account_locked
- enabled
- created_at
- updated_at
```

### Accounts Table
```sql
- id (PK)
- account_number (unique)
- account_type
- balance
- currency
- status
- user_id (FK → users)
- created_at
- updated_at
```

### Transactions Table
```sql
- id (PK)
- transaction_reference (unique)
- type
- amount
- balance_after
- description
- status
- account_id (FK → accounts)
- recipient_account_number
- recipient_name
- deposit_method
- created_at
```

### Beneficiaries Table
```sql
- id (PK)
- beneficiary_name
- account_number
- bank_name
- bank_code
- nickname
- user_id (FK → users)
- created_at
```

## 📊 API Endpoint Mapping

### Public Endpoints (No Authentication)
```
POST   /api/auth/register
POST   /api/auth/login
GET    /h2-console/**
```

### Protected Endpoints (JWT Required)
```
GET    /api/dashboard
GET    /api/accounts
GET    /api/accounts/{id}
GET    /api/transactions
GET    /api/transactions/{id}
GET    /api/transactions/account/{accountId}
POST   /api/money/deposit
POST   /api/money/transfer
POST   /api/money/internal-transfer
GET    /api/beneficiaries
GET    /api/beneficiaries/{id}
POST   /api/beneficiaries
PUT    /api/beneficiaries/{id}
DELETE /api/beneficiaries/{id}
GET    /api/profile
PUT    /api/profile
POST   /api/profile/change-password
POST   /api/profile/toggle-2fa
GET    /api/help
```

## 🔄 Request Flow Example

**Example: Transfer Money**

1. **Client** sends POST request to `/api/money/transfer`
   ```
   Headers: Authorization: Bearer <jwt-token>
   Body: { fromAccountId, recipientAccountNumber, amount }
   ```

2. **JwtAuthenticationFilter** validates JWT token
   - Extracts user from token
   - Sets authentication in SecurityContext

3. **MoneyController** receives request
   - Validates request body
   - Calls TransactionService

4. **TransactionService** processes transfer
   - Validates user permissions
   - Checks account status
   - Verifies sufficient balance
   - Calls AccountService to update balances
   - Creates transaction records

5. **AccountService** updates accounts
   - Uses AccountRepository to save changes

6. **TransactionService** creates transactions
   - Uses TransactionRepository to save records

7. **MoneyController** returns response
   - Maps Transaction entity to TransactionResponse DTO
   - Wraps in ApiResponse
   - Returns to client

## 🛠️ Technology Stack Details

### Core Dependencies
```xml
Spring Boot 3.2.0
├── spring-boot-starter-web
├── spring-boot-starter-data-jpa
├── spring-boot-starter-security
├── spring-boot-starter-validation
└── spring-boot-starter-test

Database
├── H2 (development)
└── MySQL (production)

Security
├── jjwt-api 0.12.3
├── jjwt-impl 0.12.3
└── jjwt-jackson 0.12.3

Utilities
└── Lombok
```

## 📈 Scalability Considerations

### Current Architecture
- Monolithic application
- Single database
- Stateless authentication (JWT)

### Future Enhancements
- Microservices architecture
- Redis for caching
- Message queue for async operations
- Separate authentication service
- API Gateway
- Load balancing

## 🔐 Security Features

1. **JWT Authentication**
   - Stateless tokens
   - 24-hour expiration
   - Secure secret key

2. **Password Security**
   - BCrypt hashing
   - Strong password requirements
   - Password change functionality

3. **Authorization**
   - Role-based access control
   - User-specific data access
   - Request validation

4. **Data Protection**
   - Input validation
   - SQL injection prevention (JPA)
   - XSS protection
   - CORS configuration

## 📝 Code Quality

- **Lombok**: Reduces boilerplate code
- **Validation**: Bean validation on all inputs
- **Exception Handling**: Centralized error handling
- **Separation of Concerns**: Clear layer separation
- **RESTful Design**: Standard HTTP methods and status codes

---

**Total Files Created: 50+**
**Lines of Code: ~4000+**
**Endpoints: 20+**
**Database Tables: 4**

