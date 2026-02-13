# SecurityService Design

## Architecture

### Layers
- **API Layer**: REST endpoints for authentication and user management
- **Application Layer**: Commands and queries for business logic
- **Domain Layer**: User, Role, Permission entities
- **Infrastructure Layer**: Database access, token generation

### Database Schema
- **Database**: SQL Server
- **Schema**: `Security`
- **Tables**: Users, Roles, Permissions, UserRoles, RefreshTokens, AuditLogs

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - Login with email and password
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout and invalidate session

### Users
- `POST /api/v1/users` - Create user (admin only)
- `GET /api/v1/users` - List all users (admin only)
- `GET /api/v1/users/{id}` - Get user by ID
- `PUT /api/v1/users/{id}` - Update user (admin only)
- `DELETE /api/v1/users/{id}` - Delete user (admin only)

### Roles
- `POST /api/v1/roles` - Create role (admin only)
- `GET /api/v1/roles` - List all roles
- `PUT /api/v1/roles/{id}` - Update role (admin only)
- `DELETE /api/v1/roles/{id}` - Delete role (admin only)

### Permissions
- `POST /api/v1/permissions` - Create permission (admin only)
- `GET /api/v1/permissions` - List all permissions
- `PUT /api/v1/permissions/{id}` - Update permission (admin only)
- `DELETE /api/v1/permissions/{id}` - Delete permission (admin only)

## Data Models

### User
```
- Id: Guid
- Email: string (unique)
- Username: string
- PasswordHash: string
- PasswordSalt: string
- FirstName: string
- LastName: string
- IsActive: bool
- CreatedDate: DateTime
- LastLoginDate: DateTime
- FailedLoginAttempts: int
- LockoutEndDate: DateTime?
```

### Role
```
- Id: Guid
- Name: string (unique)
- Description: string
- IsActive: bool
- CreatedDate: DateTime
```

### Permission
```
- Id: Guid
- Name: string (unique)
- Resource: string
- Action: string
- Description: string
```

### RefreshToken
```
- Id: Guid
- UserId: Guid
- Token: string (unique)
- ExpirationDate: DateTime
- IsRevoked: bool
- CreatedDate: DateTime
```

## Authentication Flow

1. User submits email and password
2. System validates credentials
3. System checks if account is locked
4. System generates JWT access token (15 min)
5. System generates refresh token (7 days)
6. System returns tokens to client
7. Client stores tokens securely
8. Client includes access token in Authorization header

## Authorization Flow

1. Client sends request with access token
2. System validates token signature
3. System extracts user ID and roles from token
4. System checks if user has required permission
5. System allows or denies request

## Security Considerations

- Passwords hashed with PBKDF2 (100,000 iterations)
- Tokens signed with HS256 algorithm
- Tokens include expiration time
- Refresh tokens stored in database
- Account lockout after 5 failed attempts
- All authentication events logged
- Sensitive data never logged

## Testing Strategy

### Unit Tests
- Password hashing and verification
- Token generation and validation
- Permission checking logic
- User validation

### Integration Tests
- Login endpoint with valid/invalid credentials
- Token refresh endpoint
- User creation and retrieval
- Role assignment and permission checking

### Property-Based Tests
- Token generation always produces valid tokens
- Password hashing always produces unique hashes
- Permission checks are consistent

## Deployment

- Docker container with .NET 9.0
- SQL Server database
- Environment-specific configuration
- Health check endpoints
- Monitoring and alerting

## Performance Targets

- Login: < 500ms
- Token validation: < 100ms
- User lookup: < 200ms
- 1,000+ requests per second
- 99.9% uptime
