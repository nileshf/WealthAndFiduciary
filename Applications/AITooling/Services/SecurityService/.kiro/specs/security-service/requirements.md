# Requirements Document

## Introduction

SecurityService is the authentication microservice for the AITooling application within the WealthAndFiduciary business unit. This service provides basic JWT-based authentication with user registration and login capabilities. The service uses BCrypt for password hashing and generates JWT tokens for authenticated sessions.

**Note**: This spec reflects the current implementation. The service is a foundational authentication service that can be extended with additional features like API keys, OAuth, and model access control in future iterations.

## Glossary

- **System**: The SecurityService microservice
- **User**: A person accessing the system with username and password
- **Token**: A JWT (JSON Web Token) used for authentication
- **Role**: A simple role string assigned to users (e.g., "User", "Admin")
- **Password_Hash**: A BCrypt hash of the user's password

## Requirements

### Requirement 1: User Registration

**User Story:** As a new user, I want to register with a username and password, so that I can create an account in the system.

#### Acceptance Criteria

1. WHEN a user provides a username and password, THE System SHALL create a new user account
2. WHEN a password is provided, THE System SHALL hash it using BCrypt before storage
3. WHEN a user is created, THE System SHALL assign a default role of "User" if no role is specified
4. WHEN a user provides a custom role during registration, THE System SHALL assign that role
5. WHEN a user is successfully registered, THE System SHALL return the user ID, username, and role
6. WHEN a username already exists, THE System SHALL reject the registration

### Requirement 2: User Login with JWT

**User Story:** As a registered user, I want to log in with my username and password, so that I can access protected resources.

#### Acceptance Criteria

1. WHEN a user provides valid credentials, THE System SHALL generate a JWT token
2. WHEN a JWT token is generated, THE System SHALL include username and role as claims
3. WHEN a JWT token is generated, THE System SHALL set expiration to 2 hours from creation
4. WHEN a JWT token is generated, THE System SHALL sign it using HMAC SHA-256 algorithm
5. WHEN a user provides invalid credentials, THE System SHALL return 401 Unauthorized
6. WHEN a user provides invalid credentials, THE System SHALL return an error message "Invalid credentials"
7. WHEN a user successfully logs in, THE System SHALL return the JWT token

### Requirement 3: Password Security

**User Story:** As a security officer, I want passwords securely hashed, so that user credentials are protected even if the database is compromised.

#### Acceptance Criteria

1. WHEN a user creates a password, THE System SHALL hash it using BCrypt
2. WHEN a user logs in, THE System SHALL verify the password using BCrypt.Verify
3. WHEN passwords are stored, THE System SHALL never store plain text passwords
4. WHEN password verification fails, THE System SHALL reject the login attempt

### Requirement 4: JWT Token Configuration

**User Story:** As a system administrator, I want JWT tokens configured with proper issuer and audience, so that tokens are validated correctly.

#### Acceptance Criteria

1. WHEN a JWT token is generated, THE System SHALL use the configured JWT key from appsettings
2. WHEN a JWT token is generated, THE System SHALL include the configured issuer
3. WHEN a JWT token is generated, THE System SHALL include the configured audience
4. WHEN a JWT token is validated, THE System SHALL verify the issuer matches configuration
5. WHEN a JWT token is validated, THE System SHALL verify the audience matches configuration
6. WHEN a JWT token is validated, THE System SHALL verify the signature using the configured key
7. WHEN a JWT token is expired, THE System SHALL reject the token

### Requirement 5: User Data Model

**User Story:** As a developer, I want a simple user data model, so that user information is stored consistently.

#### Acceptance Criteria

1. THE System SHALL store user ID as an integer
2. THE System SHALL store username as a string
3. THE System SHALL store password hash as a string
4. THE System SHALL store role as a string with default value "User"
5. THE System SHALL persist users to SQL Server database

### Requirement 6: API Endpoints

**User Story:** As a client application, I want RESTful API endpoints, so that I can integrate authentication into my application.

#### Acceptance Criteria

1. THE System SHALL expose POST /api/auth/register endpoint for user registration
2. THE System SHALL expose POST /api/auth/login endpoint for user login
3. WHEN /api/auth/register is called, THE System SHALL accept RegisterRequest with Username, Password, and optional Role
4. WHEN /api/auth/login is called, THE System SHALL accept LoginRequest with Username and Password
5. WHEN registration succeeds, THE System SHALL return 200 OK with user details
6. WHEN login succeeds, THE System SHALL return 200 OK with JWT token
7. WHEN login fails, THE System SHALL return 401 Unauthorized

### Requirement 7: Authentication Middleware

**User Story:** As a developer, I want JWT authentication middleware configured, so that protected endpoints can validate tokens.

#### Acceptance Criteria

1. THE System SHALL configure JWT Bearer authentication
2. THE System SHALL validate token issuer, audience, lifetime, and signing key
3. WHEN a request includes a valid JWT token, THE System SHALL authenticate the request
4. WHEN a request includes an invalid JWT token, THE System SHALL reject the request
5. WHEN a request includes an expired JWT token, THE System SHALL reject the request

### Requirement 8: Database Integration

**User Story:** As a system administrator, I want user data persisted to SQL Server, so that user accounts are durable.

#### Acceptance Criteria

1. THE System SHALL use Entity Framework Core for database access
2. THE System SHALL connect to SQL Server using configured connection string
3. THE System SHALL use SecurityDbContext for database operations
4. THE System SHALL use UserRepository for user data access
5. THE System SHALL support database migrations for schema management

### Requirement 9: Swagger Documentation

**User Story:** As a developer, I want API documentation, so that I can understand how to use the authentication endpoints.

#### Acceptance Criteria

1. THE System SHALL expose Swagger UI in development environment
2. THE System SHALL document all API endpoints with Swagger
3. THE System SHALL include request/response schemas in Swagger documentation
4. WHEN Swagger UI is accessed, THE System SHALL display all available endpoints

### Requirement 10: Dependency Injection

**User Story:** As a developer, I want proper dependency injection, so that services are loosely coupled and testable.

#### Acceptance Criteria

1. THE System SHALL register AuthService as scoped service
2. THE System SHALL register IUserRepository as scoped service
3. THE System SHALL register UserRepository as implementation of IUserRepository
4. THE System SHALL inject dependencies via constructor injection
5. THE System SHALL use built-in ASP.NET Core DI container
