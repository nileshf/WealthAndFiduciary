# Design Document

## 1. System Architecture

### 1.1 Overview

SecurityService is a JWT-based authentication microservice built using Clean Architecture principles. The service provides user registration and login capabilities with BCrypt password hashing and JWT token generation.

### 1.2 Architecture Layers

```
SecurityService/
├── Domain/              # Core business entities and interfaces
│   ├── User.cs         # User entity
│   └── IUserRepository.cs
├── Application/         # Business logic and services
│   └── AuthService.cs  # Authentication service
├── Infrastructure/      # Data access and external concerns
│   ├── SecurityDbContext.cs
│   └── UserRepository.cs
└── API/                # HTTP endpoints and controllers
    └── AuthController.cs
```

### 1.3 Technology Stack

- **Framework**: ASP.NET Core 8.0
- **Database**: SQL Server
- **ORM**: Entity Framework Core
- **Password Hashing**: BCrypt.Net
- **JWT**: System.IdentityModel.Tokens.Jwt
- **API Documentation**: Swashbuckle (Swagger)

## 2. Component Design

### 2.1 Domain Layer

#### 2.1.1 User Entity

```csharp
public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "User";
}
```

**Properties**:
- `Id`: Auto-incrementing primary key
- `Username`: Unique identifier for the user
- `PasswordHash`: BCrypt hash of the user's password
- `Role`: Simple role string (default: "User")

#### 2.1.2 IUserRepository Interface

```csharp
public interface IUserRepository
{
    Task<User?> GetByUsernameAsync(string username);
    Task<User> CreateAsync(User user);
}
```

### 2.2 Application Layer

#### 2.2.1 AuthService

**Responsibilities**:
- User registration with password hashing
- User login with credential verification
- JWT token generation

**Methods**:

```csharp
public async Task<User> RegisterAsync(string username, string password, string role = "User")
```
- Hashes password using BCrypt
- Creates new user entity
- Persists to database via repository
- Returns created user

```csharp
public async Task<string?> LoginAsync(string username, string password)
```
- Retrieves user by username
- Verifies password using BCrypt.Verify
- Generates JWT token on success
- Returns null on failure

```csharp
private string GenerateToken(User user)
```
- Creates JWT with username and role claims
- Signs with HMAC SHA-256
- Sets 2-hour expiration
- Returns token string

### 2.3 Infrastructure Layer

#### 2.3.1 SecurityDbContext

```csharp
public class SecurityDbContext : DbContext
{
    public DbSet<User> Users { get; set; }
}
```

**Configuration**:
- SQL Server connection via connection string
- Entity Framework Core migrations enabled

#### 2.3.2 UserRepository

```csharp
public class UserRepository : IUserRepository
{
    public async Task<User?> GetByUsernameAsync(string username)
    public async Task<User> CreateAsync(User user)
}
```

**Implementation**:
- Uses SecurityDbContext for database operations
- Async/await for all database calls
- Returns null when user not found

### 2.4 API Layer

#### 2.4.1 AuthController

**Endpoints**:

```csharp
POST /api/auth/register
Request: { "username": "string", "password": "string", "role": "string?" }
Response: { "id": int, "username": "string", "role": "string" }
```

```csharp
POST /api/auth/login
Request: { "username": "string", "password": "string" }
Response: { "token": "string" }
Error: 401 Unauthorized { "message": "Invalid credentials" }
```

## 3. Security Design

### 3.1 Password Security

**Hashing Algorithm**: BCrypt
- Industry-standard password hashing
- Built-in salt generation
- Configurable work factor
- Resistant to rainbow table attacks

**Implementation**:
```csharp
// Registration
user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(password);

// Login verification
BCrypt.Net.BCrypt.Verify(password, user.PasswordHash)
```

### 3.2 JWT Token Design

**Token Structure**:
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name": "username",
    "http://schemas.microsoft.com/ws/2008/06/identity/claims/role": "User",
    "exp": 1234567890,
    "iss": "configured-issuer",
    "aud": "configured-audience"
  }
}
```

**Token Configuration**:
- **Algorithm**: HMAC SHA-256 (HS256)
- **Expiration**: 2 hours from creation
- **Issuer**: Configured in appsettings.json
- **Audience**: Configured in appsettings.json
- **Signing Key**: Configured in appsettings.json

### 3.3 Authentication Middleware

**Configuration**:
```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.TokenValidationParameters = new TokenValidationParameters {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = configuration["Jwt:Issuer"],
            ValidAudience = configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(...)
        };
    });
```

## 4. Data Design

### 4.1 Database Schema

**Table**: Users

| Column | Type | Constraints |
|--------|------|-------------|
| Id | int | PRIMARY KEY, IDENTITY |
| Username | nvarchar(max) | NOT NULL |
| PasswordHash | nvarchar(max) | NOT NULL |
| Role | nvarchar(max) | NOT NULL, DEFAULT 'User' |

**Indexes**:
- Primary key on Id (auto-created)
- Consider unique index on Username (future enhancement)

### 4.2 Connection String

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=...;Database=SecurityDb;..."
  }
}
```

## 5. API Design

### 5.1 Request/Response Models

**RegisterRequest**:
```csharp
public record RegisterRequest(
    string Username,
    string Password,
    string? Role
);
```

**LoginRequest**:
```csharp
public record LoginRequest(
    string Username,
    string Password
);
```

**LoginResponse**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**RegisterResponse**:
```json
{
  "id": 1,
  "username": "testuser",
  "role": "User"
}
```

### 5.2 Error Responses

**401 Unauthorized** (Invalid credentials):
```json
{
  "message": "Invalid credentials"
}
```

**400 Bad Request** (Validation error):
```json
{
  "errors": {
    "Username": ["The Username field is required."]
  }
}
```

## 6. Configuration Design

### 6.1 appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=SecurityDb;Trusted_Connection=True;TrustServerCertificate=True"
  },
  "Jwt": {
    "Key": "your-secret-key-min-32-characters",
    "Issuer": "SecurityService",
    "Audience": "AIToolingClients"
  }
}
```

### 6.2 Dependency Injection

```csharp
// Database
builder.Services.AddDbContext<SecurityDbContext>(options =>
    options.UseSqlServer(connectionString));

// Repositories
builder.Services.AddScoped<IUserRepository, UserRepository>();

// Services
builder.Services.AddScoped<AuthService>();

// Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(...);
```

## 7. Deployment Design

### 7.1 Environment Configuration

**Development**:
- Swagger UI enabled
- Detailed error messages
- Local SQL Server

**Production**:
- Swagger UI disabled
- Generic error messages
- Azure SQL or production SQL Server
- HTTPS enforced

### 7.2 Database Migrations

```bash
# Create migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update
```

## 8. Testing Strategy

### 8.1 Unit Tests

**AuthService Tests**:
- Test successful registration
- Test successful login
- Test failed login with invalid credentials
- Test password hashing
- Test token generation

**UserRepository Tests**:
- Test user creation
- Test user retrieval by username
- Test null return when user not found

### 8.2 Integration Tests

**API Tests**:
- Test POST /api/auth/register endpoint
- Test POST /api/auth/login endpoint
- Test authentication middleware
- Test token validation

### 8.3 Property-Based Tests

**Properties to Test**:
- Password hashing is always unique for same password
- Token generation is always valid JWT format
- Token expiration is always 2 hours from creation
- Username uniqueness is enforced

## 9. Correctness Properties

### 9.1 Authentication Properties

**Property 1.1: Password Hash Uniqueness**
```
∀ password, salt1, salt2: salt1 ≠ salt2 ⟹ Hash(password, salt1) ≠ Hash(password, salt2)
```
**Validates**: Requirement 3.1

**Property 1.2: Password Verification Correctness**
```
∀ password, hash: Verify(password, Hash(password)) = true
∀ password1, password2, hash: password1 ≠ password2 ⟹ Verify(password2, Hash(password1)) = false
```
**Validates**: Requirement 3.2

### 9.2 Token Properties

**Property 2.1: Token Expiration**
```
∀ user, token: token = GenerateToken(user) ⟹ token.exp = now + 2 hours
```
**Validates**: Requirement 2.3

**Property 2.2: Token Claims Completeness**
```
∀ user, token: token = GenerateToken(user) ⟹ 
  token.claims.contains(user.username) ∧ token.claims.contains(user.role)
```
**Validates**: Requirement 2.2

### 9.3 Registration Properties

**Property 3.1: Password Never Stored Plain**
```
∀ user, password: RegisterAsync(username, password, role) ⟹ 
  user.PasswordHash ≠ password
```
**Validates**: Requirement 3.3

## 10. Future Enhancements

### 10.1 Planned Features
- Refresh token support
- Email-based authentication
- Password complexity validation
- Account lockout after failed attempts
- Password reset functionality
- Multi-factor authentication
- API key authentication
- OAuth 2.0 integration

### 10.2 Performance Optimizations
- Username uniqueness index
- Connection pooling
- Token caching
- Rate limiting

### 10.3 Security Enhancements
- HTTPS enforcement
- CORS configuration
- Input validation
- SQL injection prevention (already using EF Core)
- XSS prevention
