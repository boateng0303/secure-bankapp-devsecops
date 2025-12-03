# Quick Start Guide

Get your Reuel Banking Application up and running in 5 minutes!

## ⚡ Quick Setup

### 1. Prerequisites Check
```bash
java -version    # Should be 17+
mvn -version     # Should be 3.6+
```

### 2. Run the Application
```bash
# Clone and navigate to project
cd secure-banking-app

# Build and run
mvn spring-boot:run
```

The application will start at: **http://localhost:8080**

### 3. Access H2 Console (Optional)
Visit: **http://localhost:8080/h2-console**
- JDBC URL: `jdbc:h2:mem:bankingdb`
- Username: `sa`
- Password: (leave empty)

## 🧪 Test the API

### Step 1: Register a User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "phoneNumber": "+1234567890",
    "address": "123 Main St"
  }'
```

**Save the token from the response!**

### Step 2: Login (Alternative)
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!"
  }'
```

### Step 3: View Dashboard
```bash
curl -X GET http://localhost:8080/api/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Step 4: Deposit Money
```bash
curl -X POST http://localhost:8080/api/money/deposit \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": 1,
    "amount": 1000.00,
    "depositMethod": "BANK_TRANSFER",
    "description": "Initial deposit"
  }'
```

### Step 5: Check Transactions
```bash
curl -X GET http://localhost:8080/api/transactions \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 📱 Using Postman

1. Import the API endpoints from `API_ENDPOINTS.md`
2. Create an environment variable: `jwt_token`
3. After login, save the token to the variable
4. Use `{{jwt_token}}` in Authorization headers

## 🎯 Common Use Cases

### Create a Second Account (Manual via H2)
```sql
INSERT INTO accounts (account_number, account_type, balance, currency, status, user_id, created_at, updated_at)
VALUES ('1234567891', 'SAVINGS', 0.00, 'USD', 'ACTIVE', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
```

### Transfer Between Your Accounts
```bash
curl -X POST http://localhost:8080/api/money/internal-transfer \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "fromAccountId": 1,
    "toAccountId": 2,
    "amount": 250.00,
    "description": "Transfer to savings"
  }'
```

### Add a Beneficiary
```bash
curl -X POST http://localhost:8080/api/beneficiaries \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "beneficiaryName": "Jane Smith",
    "accountNumber": "9876543210",
    "bankName": "ABC Bank",
    "nickname": "Jane"
  }'
```

### Update Profile
```bash
curl -X PUT http://localhost:8080/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe Updated",
    "phoneNumber": "+1234567890",
    "address": "456 New Address"
  }'
```

### Change Password
```bash
curl -X POST http://localhost:8080/api/profile/change-password \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "SecurePass123!",
    "newPassword": "NewSecurePass123!"
  }'
```

## 🔧 Troubleshooting

### Port Already in Use
```bash
# Change port in application.properties
server.port=8081
```

### Database Connection Error
- Check if H2 is properly configured
- Verify `application.properties` settings

### JWT Token Expired
- Token expires after 24 hours (default)
- Login again to get a new token

### Build Errors
```bash
# Clean and rebuild
mvn clean install -U
```

## 📊 Project Structure Quick Reference

```
src/main/java/com/banking/
├── controller/          # API endpoints
├── service/            # Business logic
├── repository/         # Database access
├── entity/            # Database models
├── dto/               # Request/Response objects
├── security/          # JWT & Security config
└── exception/         # Error handling
```

## 🎓 Next Steps

1. Read the full [README.md](README.md) for detailed documentation
2. Check [API_ENDPOINTS.md](API_ENDPOINTS.md) for all available endpoints
3. Explore the H2 console to see the database structure
4. Try creating multiple users and transferring money between them
5. Implement a frontend (React/Angular/Vue) to consume the API

## 💡 Tips

- **Default JWT expiration**: 24 hours
- **Account numbers**: Auto-generated 10-digit numbers
- **Transaction references**: Auto-generated with "TXN" prefix
- **Password requirements**: Min 8 chars, 1 upper, 1 lower, 1 digit, 1 special char
- **H2 Console**: Great for testing and viewing data during development

## 🚀 Production Deployment

For production, switch to MySQL:

1. Create MySQL database:
```sql
CREATE DATABASE banking_db;
```

2. Update `application-prod.properties` with your credentials

3. Run with production profile:
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

## 📞 Need Help?

- Check the [README.md](README.md) for comprehensive documentation
- Review [API_ENDPOINTS.md](API_ENDPOINTS.md) for endpoint details
- Visit `/api/help` endpoint for FAQs
- Email: support@securebanking.com

---

**Happy Banking! 🏦**

