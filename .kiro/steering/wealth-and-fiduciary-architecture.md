# BUSINESS UNIT ARCHITECTURE STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific architecture rules override these when conflicts exist

## 🏛️ CLEAN ARCHITECTURE PRINCIPLES (MANDATORY)

### **Layer Dependencies (Dependency Rule)**
ALL microservices MUST follow this dependency structure:
- **Domain Layer**: No dependencies on other layers
- **Application Layer**: Depends only on Domain
- **Infrastructure Layer**: Depends on Domain and Application
- **API Layer**: Depends on Application and Infrastructure
- **Rule**: Dependencies point inward only - outer layers depend on inner layers

### **Domain Layer Rules**
- Contains entities, enums, and domain logic only
- No dependencies on frameworks, databases, or external concerns
- Business rules and domain models are framework-agnostic
- Entities define their own schema via Table attributes

### **Application Layer Rules**
- Contains Commands, Queries, DTOs, and Application Services
- Uses MediatR for CQRS pattern implementation
- Defines interfaces for external dependencies (repositories, services)
- No direct database or infrastructure dependencies

### **Infrastructure Layer Rules**
- Implements Application layer interfaces
- Contains Entity Framework DbContext and configurations
- Handles external system integrations
- Database-specific implementations

### **API Layer Rules**
- Controllers are thin - delegate to MediatR
- No business logic in controllers
- Handles HTTP concerns only (routing, serialization, authentication)
- Depends on Application layer abstractions

## 🔧 SOLID PRINCIPLES IMPLEMENTATION (MANDATORY)

### **Single Responsibility Principle (SRP)**
- Each entity has one reason to change
- Each command handles one operation
- Each service has one responsibility
- Each controller handles one resource type

### **Open/Closed Principle (OCP)**
- New features added via configuration, not modification
- Extensible via enum extension
- New relationships added via configuration
- New validation rules added via FluentValidation extensions

### **Liskov Substitution Principle (LSP)**
- All entities inherit from BaseEntity and can be substituted
- All commands/queries implement IRequest<T> and are interchangeable
- All repositories implement common interface
- Service implementations are fully substitutable

### **Interface Segregation Principle (ISP)**
- Specific interfaces per service (IUserService, IRoleService, etc.)
- Each command implements only IRequest<T>
- Separate interfaces for different entity operations
- Clients depend only on methods they use

### **Dependency Inversion Principle (DIP)**
- High-level modules depend on abstractions, not concretions
- Interfaces defined in Application, implemented in Infrastructure
- All dependencies injected via DI container
- External dependencies accessed via interfaces

## 🏢 PROJECT STRUCTURE RULES (MANDATORY)

### **Naming Conventions**
- **Projects**: `[ServiceName].[Layer]` (e.g., `FullViewSecurity.Domain`)
- **Namespaces**: `WealthAndFiduciary.FullView.[ServiceName].[Layer]`
- **Database Schemas**: `[ServiceName]` or service-specific (e.g., `Auth`, `DataSource`)

### **Clean Architecture Layers**
```
[ServiceName].Domain/
├── Entities/           # Domain entities
├── Enums/             # Domain enums
└── ValueObjects/      # Domain value objects

[ServiceName].Application/
├── Commands/          # Write operations (CQRS)
├── Queries/           # Read operations (CQRS)
├── DTOs/              # Data transfer objects
├── Interfaces/        # Service abstractions
└── Validators/        # FluentValidation rules

[ServiceName].Infrastructure/
├── Data/              # EF DbContext, configurations
├── Repositories/      # Data access implementations
├── Services/          # External service implementations
└── Migrations/        # Database migrations

[ServiceName].Api/
├── Controllers/       # HTTP endpoints
├── Middleware/        # Cross-cutting concerns
└── Configuration/     # DI setup, startup
```

### **Dependency Flow**
```
API → Application → Domain
 ↓       ↓
Infrastructure → Domain
```

## 🛠️ TECHNOLOGY STACK (MANDATORY)

### **Framework & Runtime**
- **.NET Version**: .NET 9.0 for all services
- **Language**: C# 13.0
- **Runtime**: ASP.NET Core for APIs

### **Data Access**
- **ORM**: Entity Framework Core 9.0
- **Databases**: SQL Server and/or PostgreSQL support
- **Migrations**: EF Core Migrations

### **CQRS & Messaging**
- **CQRS**: MediatR for command/query separation
- **Validation**: FluentValidation for request validation

### **Testing**
- **Unit Tests**: xUnit
- **Mocking**: Moq
- **Assertions**: FluentAssertions
- **Property-Based**: FsCheck or CsCheck

### **Logging & Monitoring**
- **Logging**: Microsoft.Extensions.Logging
- **Structured Logging**: Serilog (optional)
- **Correlation**: Correlation IDs for request tracking

### **API Documentation**
- **OpenAPI**: Swashbuckle.AspNetCore for Swagger
- **Versioning**: Microsoft.AspNetCore.Mvc.Versioning

## 📋 ARCHITECTURAL PATTERNS (MANDATORY)

### **Command/Query Patterns**
- All operations use MediatR commands/queries
- Commands for writes, Queries for reads
- Validation attributes required on all command parameters
- Handlers implement IRequestHandler<TRequest, TResponse>

### **Repository Pattern**
- All data access through repositories
- Generic BaseRepository<T> for common operations
- Entity-specific repositories for specialized queries
- Repositories return entities, not DTOs

### **Unit of Work Pattern**
- Transaction management via Unit of Work
- DbContext acts as Unit of Work in EF Core
- Explicit transaction boundaries for complex operations

### **Dependency Injection**
- All dependencies injected via constructor
- Service lifetimes: Scoped for repositories, Singleton for stateless services
- Configuration via DependencyInjection.cs extension methods

### **Error Handling**
- Custom exception types (ValidationException, NotFoundException, etc.)
- Global exception middleware for API layer
- Correlation IDs link errors to requests
- Structured error responses

## 🔒 SECURITY BASELINE (MANDATORY)

### **Authentication**
- JWT Bearer tokens for API authentication
- Token expiration and refresh mechanisms
- Secure token storage and transmission

### **Authorization**
- Role-based access control (RBAC)
- Policy-based authorization where appropriate
- Principle of least privilege

### **Data Protection**
- Sensitive data encrypted at rest
- HTTPS/TLS for data in transit
- Password hashing with PBKDF2 or bcrypt
- Never log sensitive data (passwords, tokens, PII)

### **Audit Logging**
- All operations logged with correlation IDs
- Track authentication attempts (success and failure)
- Immutable audit trails for compliance
- Retention policies per regulatory requirements

## 🧪 TESTING STANDARDS (MANDATORY)

### **Test Pyramid**
- Many unit tests (80% coverage minimum for Domain/Application)
- Some integration tests (70% coverage for Infrastructure/API)
- Few end-to-end tests (critical paths only)
- Property-based tests for universal properties

### **Test Organization**
- Separate test projects per layer
- Test naming: `MethodName_Scenario_ExpectedBehavior`
- Test builders for complex object creation
- Fixtures for shared test setup

### **Test Execution**
- All tests run on every PR
- Code coverage enforced in CI/CD
- Fast unit tests (milliseconds)
- Isolated tests (no dependencies between tests)

## 📦 DEPLOYMENT STANDARDS (MANDATORY)

### **Containerization**
- All services containerized with Docker
- Multi-stage builds for optimized images
- Health checks in Dockerfile

### **Configuration**
- Environment-specific configuration
- Secrets management (Azure Key Vault, AWS Secrets Manager, etc.)
- Configuration validation on startup

### **Observability**
- Health check endpoints (/health, /ready, /live)
- Metrics collection (Prometheus format)
- Distributed tracing (OpenTelemetry)

## 🎯 CODE QUALITY STANDARDS (MANDATORY)

### **Code Style**
- Follow Microsoft C# coding conventions
- Use EditorConfig for consistent formatting
- XML documentation on all public members
- Meaningful variable and method names

### **Code Reviews**
- All code changes require peer review
- Automated checks (linting, tests, coverage)
- Review checklist (architecture, security, tests)

### **Technical Debt**
- Document technical debt with TODO comments
- Regular refactoring sprints
- Track debt in issue tracker

## 📚 DOCUMENTATION STANDARDS (MANDATORY)

### **Code Documentation**
- XML documentation on all public APIs
- README.md in each project root
- Architecture Decision Records (ADRs) for major decisions

### **API Documentation**
- OpenAPI/Swagger for all REST APIs
- Example requests and responses
- Error code documentation

### **Runbooks**
- Deployment procedures
- Troubleshooting guides
- Incident response procedures

## 🔄 CONTINUOUS INTEGRATION/DEPLOYMENT (MANDATORY)

### **CI Pipeline**
- Build on every commit
- Run all tests
- Code coverage reporting
- Security scanning

### **CD Pipeline**
- Automated deployment to dev/staging
- Manual approval for production
- Blue-green or canary deployments
- Automated rollback on failure

## 🎓 BEST PRACTICES

### **Do's**
- ✅ Follow Clean Architecture principles
- ✅ Write tests for all business logic
- ✅ Use dependency injection
- ✅ Log with correlation IDs
- ✅ Handle errors gracefully
- ✅ Document public APIs
- ✅ Review code before merging

### **Don'ts**
- ❌ Don't violate layer dependencies
- ❌ Don't put business logic in controllers
- ❌ Don't use magic strings/numbers
- ❌ Don't log sensitive data
- ❌ Don't skip tests
- ❌ Don't commit secrets to source control
- ❌ Don't deploy without testing

---

**Note**: Service-specific architecture rules can extend or specialize these standards but should not contradict them. When conflicts arise, service-specific rules take precedence for that service only.

ALWAYS follow these business unit-wide architecture standards when generating code for ANY microservice.
