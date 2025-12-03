# Reuel Banking Application - Backend

A simple, secure banking application backend built with Spring Boot, featuring JWT authentication, RESTful APIs, and comprehensive banking operations.

## 🚀 Features

- **User Authentication & Authorization**
  - User registration and login
  - JWT-based authentication
  - Password encryption with BCrypt
  - Two-factor authentication support

- **Account Management**
  - Multiple account types (Checking, Savings, Investment)
  - View account details and balances
  - Account status management

- **Transaction Operations**
  - Deposit money
  - Transfer money to other accounts
  - Internal transfers between own accounts
  - Transaction history with detailed records

- **Beneficiary Management**
  - Add, update, and delete beneficiaries
  - Quick transfer to saved beneficiaries

- **Profile Management**
  - View and update user profile
  - Change password
  - Security settings

- **Dashboard**
  - Overview of all accounts
  - Total balance calculation
  - Recent transactions
  - Quick statistics

## 🛠️ Technology Stack

- **Java 17**
- **Spring Boot 3.2.0**
- **Spring Security** with JWT
- **Spring Data JPA**
- **H2 Database** (Development)
- **MySQL** (Production)
- **Lombok**
- **Maven**

## 📋 Prerequisites

- Java 17 or higher
- Maven 3.6+
- MySQL 8.0+ (for production)

## 🔧 Installation & Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd secure-banking-app
```

### 2. Configure the database

For **development** (H2 Database):
- No configuration needed, H2 is configured by default
- Access H2 Console at: `http://localhost:8080/h2-console`
- JDBC URL: `jdbc:h2:mem:bankingdb`
- Username: `sa`
- Password: (leave empty)

For **production** (MySQL):
- Create a MySQL database:
```sql
CREATE DATABASE banking_db;
```
- Update `src/main/resources/application-prod.properties` with your MySQL credentials

### 3. Build the project

```bash
mvn clean install
```

### 4. Run the application

**Development mode:**
```bash
mvn spring-boot:run
```

**Production mode:**
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

The application will start on `http://localhost:8080`

## 📚 API Documentation

### Base URL
```
http://localhost:8080/api
```

### Authentication Endpoints

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com",
  "password": "SecurePass123!",
  "phoneNumber": "+1234567890",
  "address": "123 Main St, City, Country"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john.doe@example.com",
  "password": "SecurePass123!"
}
```

**Response:**
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
  }
}
```

### Protected Endpoints (Require Authentication)

Add the JWT token to the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

#### Dashboard
```http
GET /api/dashboard
```

#### Accounts
```http
GET /api/accounts              # Get all accounts
GET /api/accounts/{id}         # Get specific account
```

#### Transactions
```http
GET /api/transactions                    # Get all transactions
GET /api/transactions/{id}               # Get specific transaction
GET /api/transactions/account/{accountId} # Get transactions by account
```

#### Money Operations

**Deposit Money:**
```http
POST /api/money/deposit
Content-Type: application/json

{
  "accountId": 1,
  "amount": 1000.00,
  "depositMethod": "BANK_TRANSFER",
  "description": "Initial deposit"
}
```

**Transfer Money:**
```http
POST /api/money/transfer
Content-Type: application/json

{
  "fromAccountId": 1,
  "recipientAccountNumber": "1234567890",
  "amount": 500.00,
  "description": "Payment for services"
}
```

**Internal Transfer:**
```http
POST /api/money/internal-transfer
Content-Type: application/json

{
  "fromAccountId": 1,
  "toAccountId": 2,
  "amount": 250.00,
  "description": "Transfer to savings"
}
```

#### Beneficiaries
```http
GET /api/beneficiaries           # Get all beneficiaries
GET /api/beneficiaries/{id}      # Get specific beneficiary
POST /api/beneficiaries          # Add beneficiary
PUT /api/beneficiaries/{id}      # Update beneficiary
DELETE /api/beneficiaries/{id}   # Delete beneficiary
```

**Add Beneficiary:**
```json
{
  "beneficiaryName": "Jane Smith",
  "accountNumber": "9876543210",
  "bankName": "ABC Bank",
  "bankCode": "ABC123",
  "nickname": "Jane"
}
```

#### Profile
```http
GET /api/profile                      # Get profile
PUT /api/profile                      # Update profile
POST /api/profile/change-password     # Change password
POST /api/profile/toggle-2fa          # Toggle 2FA
```

**Update Profile:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890",
  "address": "456 New St, City, Country"
}
```

**Change Password:**
```json
{
  "currentPassword": "OldPass123!",
  "newPassword": "NewSecurePass123!"
}
```

#### Help
```http
GET /api/help                    # Get help information and FAQs
```

## 🔒 Security Features

1. **JWT Authentication**: Secure token-based authentication
2. **Password Encryption**: BCrypt hashing for passwords
3. **CORS Configuration**: Configured for frontend integration
4. **Input Validation**: Comprehensive validation on all endpoints
5. **Exception Handling**: Global exception handler for consistent error responses
6. **Authorization**: Role-based access control
7. **Account Verification**: Ensures users can only access their own data

## 📁 Project Structure

```
src/main/java/com/banking/
├── controller/          # REST API Controllers
├── dto/                # Data Transfer Objects
│   ├── request/       # Request DTOs
│   └── response/      # Response DTOs
├── entity/            # JPA Entities
├── exception/         # Custom Exceptions
├── repository/        # Data Access Layer
├── security/          # Security Configuration & JWT
└── service/           # Business Logic Layer

src/main/resources/
├── application.properties       # Development configuration
└── application-prod.properties  # Production configuration
```

## 🧪 Testing

Run tests with:
```bash
mvn test
```

## 📊 Database Schema

### Main Tables:
- **users**: User account information
- **accounts**: Bank accounts
- **transactions**: Transaction records
- **beneficiaries**: Saved beneficiaries

## 🚦 API Response Format

All API responses follow this structure:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... },
  "timestamp": "2024-11-26T10:30:00"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error message",
  "data": null,
  "timestamp": "2024-11-26T10:30:00"
}
```

## 🔑 Environment Variables

You can override properties using environment variables:

```bash
export JWT_SECRET=your-secret-key
export JWT_EXPIRATION=86400000
export DB_URL=jdbc:mysql://localhost:3306/banking_db
export DB_USERNAME=your-username
export DB_PASSWORD=your-password
```

## 📝 Password Requirements

- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit
- At least one special character (@#$%^&+=)

## 🌐 CORS Configuration

By default, the application allows requests from:
- `http://localhost:3000` (React)
- `http://localhost:4200` (Angular)

Update `SecurityConfig.java` to add more origins.

## 📞 Support

For help and support:
- Email: support@securebanking.com
- Phone: +1-800-123-4567
- Hours: Monday - Friday, 9:00 AM - 6:00 PM EST

## 📄 License

This project is licensed under the MIT License.

## 👥 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 🎯 Future Enhancements

- [ ] Email notifications for transactions
- [ ] SMS OTP for 2FA
- [ ] Account statements (PDF generation)
- [ ] Scheduled/recurring transfers
- [ ] Bill payment integration
- [ ] Card management
- [ ] Loan applications
- [ ] Investment portfolio tracking
- [ ] Budget tracking and analytics
- [ ] Mobile app support

## 📸 Postman Collection

Import the API endpoints into Postman for easy testing. A collection file will be provided in the `postman/` directory.

---

**Built with ❤️ using Spring Boot**

