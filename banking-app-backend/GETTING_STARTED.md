clear# 🚀 Getting Started

Welcome to the Secure Banking Application Backend! This guide will help you get up and running in minutes.

---

## 📋 Prerequisites

Before you begin, ensure you have:

- ✅ **Java 17** or higher installed
- ✅ **Maven 3.6+** installed
- ✅ A code editor (VS Code, IntelliJ IDEA, Eclipse)
- ✅ Postman or cURL for API testing (optional)

### Check Your Installation

```bash
java -version
# Should output: java version "17" or higher

mvn -version
# Should output: Apache Maven 3.6.x or higher
```

---

## ⚡ Quick Start (3 Steps)

### Step 1: Navigate to Project Directory
```bash
cd secure-banking-app
```

### Step 2: Build the Project
```bash
mvn clean install
```

### Step 3: Run the Application
```bash
mvn spring-boot:run
```

**🎉 That's it!** Your banking application is now running at:
```
http://localhost:8080
```

---

## 🧪 Test Your First API Call

### 1. Register a New User

**Using cURL:**
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

**Using Postman:**
- Method: `POST`
- URL: `http://localhost:8080/api/auth/register`
- Headers: `Content-Type: application/json`
- Body: (same JSON as above)

**Expected Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "type": "Bearer",
    "userId": 1,
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

**📝 Copy the token!** You'll need it for authenticated requests.

### 2. View Your Dashboard

```bash
curl -X GET http://localhost:8080/api/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 3. Deposit Money

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

---

## 🗄️ Access the Database Console

The application uses H2 in-memory database for development.

**Access H2 Console:**
```
http://localhost:8080/h2-console
```

**Login Credentials:**
- JDBC URL: `jdbc:h2:mem:bankingdb`
- Username: `sa`
- Password: (leave empty)

**View Your Data:**
```sql
SELECT * FROM users;
SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM beneficiaries;
```

---

## 📚 What's Available?

### ✅ Implemented Features

| Feature | Endpoint | Method |
|---------|----------|--------|
| Register | `/api/auth/register` | POST |
| Login | `/api/auth/login` | POST |
| Dashboard | `/api/dashboard` | GET |
| View Accounts | `/api/accounts` | GET |
| View Transactions | `/api/transactions` | GET |
| Deposit Money | `/api/money/deposit` | POST |
| Transfer Money | `/api/money/transfer` | POST |
| Internal Transfer | `/api/money/internal-transfer` | POST |
| Manage Beneficiaries | `/api/beneficiaries` | GET/POST/PUT/DELETE |
| View Profile | `/api/profile` | GET |
| Update Profile | `/api/profile` | PUT |
| Change Password | `/api/profile/change-password` | POST |
| Toggle 2FA | `/api/profile/toggle-2fa` | POST |
| Get Help | `/api/help` | GET |

---

## 🎯 Common Scenarios

### Scenario 1: Create Two Users and Transfer Money

**Step 1:** Register User A
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice",
    "lastName": "Smith",
    "email": "alice@example.com",
    "password": "SecurePass123!",
    "phoneNumber": "+1234567890",
    "address": "123 Main St"
  }'
```
Save Alice's token and account number.

**Step 2:** Register User B
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Bob",
    "lastName": "Jones",
    "email": "bob@example.com",
    "password": "SecurePass123!",
    "phoneNumber": "+9876543210",
    "address": "456 Oak Ave"
  }'
```
Save Bob's account number.

**Step 3:** Alice deposits money
```bash
curl -X POST http://localhost:8080/api/money/deposit \
  -H "Authorization: Bearer ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": 1,
    "amount": 5000.00,
    "depositMethod": "BANK_TRANSFER"
  }'
```

**Step 4:** Alice transfers to Bob
```bash
curl -X POST http://localhost:8080/api/money/transfer \
  -H "Authorization: Bearer ALICE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fromAccountId": 1,
    "recipientAccountNumber": "BOB_ACCOUNT_NUMBER",
    "amount": 500.00,
    "description": "Payment for services"
  }'
```

### Scenario 2: Manage Beneficiaries

**Add a Beneficiary:**
```bash
curl -X POST http://localhost:8080/api/beneficiaries \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "beneficiaryName": "Jane Doe",
    "accountNumber": "9876543210",
    "bankName": "ABC Bank",
    "nickname": "Jane"
  }'
```

**View All Beneficiaries:**
```bash
curl -X GET http://localhost:8080/api/beneficiaries \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Scenario 3: Update Profile and Change Password

**Update Profile:**
```bash
curl -X PUT http://localhost:8080/api/profile \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe Updated",
    "phoneNumber": "+1234567890",
    "address": "789 New Street"
  }'
```

**Change Password:**
```bash
curl -X POST http://localhost:8080/api/profile/change-password \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "SecurePass123!",
    "newPassword": "NewSecurePass456!"
  }'
```

---

## 🔧 Configuration

### Development Mode (Default)
- Uses H2 in-memory database
- Database resets on restart
- H2 Console enabled
- Debug logging enabled

### Production Mode
1. Create MySQL database:
```sql
CREATE DATABASE banking_db;
```

2. Update `src/main/resources/application-prod.properties`:
```properties
spring.datasource.url=jdbc:mysql://localhost:3306/banking_db
spring.datasource.username=your_username
spring.datasource.password=your_password
```

3. Run with production profile:
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Complete project documentation |
| [API_ENDPOINTS.md](API_ENDPOINTS.md) | Detailed API reference |
| [QUICK_START.md](QUICK_START.md) | Quick testing guide |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Architecture details |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | What's been built |

---

## 🐛 Troubleshooting

### Problem: Port 8080 already in use
**Solution:** Change port in `application.properties`
```properties
server.port=8081
```

### Problem: Maven build fails
**Solution:** Clean and rebuild
```bash
mvn clean install -U
```

### Problem: JWT token expired
**Solution:** Login again to get a new token (tokens expire after 24 hours)

### Problem: Can't access H2 console
**Solution:** Ensure you're using the correct JDBC URL: `jdbc:h2:mem:bankingdb`

### Problem: Validation errors on registration
**Solution:** Ensure password meets requirements:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit
- At least one special character (@#$%^&+=)

---

## 🎓 Learning Path

### Beginner
1. ✅ Register and login
2. ✅ View dashboard
3. ✅ Deposit money
4. ✅ View transactions

### Intermediate
1. ✅ Create multiple users
2. ✅ Transfer money between users
3. ✅ Add beneficiaries
4. ✅ Update profile

### Advanced
1. ✅ Explore the H2 database
2. ✅ Review the code structure
3. ✅ Understand JWT authentication
4. ✅ Customize the application

---

## 🚀 Next Steps

### For Backend Developers
- [ ] Review the code in `src/main/java/com/banking/`
- [ ] Understand the architecture
- [ ] Add custom features
- [ ] Write unit tests
- [ ] Deploy to production

### For Frontend Developers
- [ ] Read the API documentation
- [ ] Test all endpoints with Postman
- [ ] Create the frontend pages
- [ ] Integrate with the API
- [ ] Build beautiful UI

### For Full Stack Developers
- [ ] Set up the complete stack
- [ ] Implement all features end-to-end
- [ ] Add additional features
- [ ] Deploy the full application

---

## 💡 Tips

1. **Save your JWT tokens** - You'll need them for authenticated requests
2. **Use Postman Collections** - Create a collection for easy testing
3. **Check H2 Console** - Great for debugging and seeing data
4. **Read the logs** - Application logs show detailed information
5. **Start simple** - Test basic features before complex ones

---

## 📞 Need Help?

- 📖 Check the [README.md](README.md) for detailed documentation
- 🔍 Review [API_ENDPOINTS.md](API_ENDPOINTS.md) for API details
- 🐛 Look at the error messages - they're descriptive
- 💬 Check the application logs for debugging

---

## ✨ You're All Set!

Your secure banking application backend is ready to use. Start testing the APIs and building your frontend!

**Happy Coding! 🎉**

---

**Quick Command Reference:**

```bash
# Build
mvn clean install

# Run (Development)
mvn spring-boot:run

# Run (Production)
mvn spring-boot:run -Dspring-boot.run.profiles=prod

# Run Tests
mvn test

# Package
mvn package
```

