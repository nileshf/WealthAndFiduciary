# FullView Application Architecture Standards

> **Scope**: All FullView microservices
> **Level**: Application-level (Level 2)
> **Precedence**: Service-specific standards override these when conflicts exist

## 🎯 Overview

FullView is a financial services application within the WealthAndFiduciary business unit. This document defines application-wide architecture standards that apply to all FullView microservices.

## 🏗️ Application-Specific Architecture

### Database Strategy
- **Primary Database**: SQL Server
- **Rationale**: Enterprise-grade reliability, strong ACID compliance for financial data
- **Version**: SQL Server 2022 or later
- **Connection**: Encrypted connections required (TLS 1.2+)

### Multi-Tenant Architecture
- **Isolation Level**: Database-level tenant isolation
- **Tenant Identification**: TenantId in all entities (Guid type)
- **Data Access**: Row-level security enforced at database and application layers
- **Cross-Tenant Access**: Strictly prohibited, enforced by architecture tests
- **Tenant Context**: Injected via middleware, available throughout request pipeline

### Financial Compliance
- **Audit Logging**: All financial transactions logged immutably
- **Data Retention**: 7 years minimum for financial records
- **Encryption**: All PII and financial data encrypted at rest (AES-256)
- **Compliance Standards**: SOX, GDPR, PCI-DSS where applicable
- **Audit Trail**: Who, What, When, Where for all data modifications

## 🔐 Security Standards

### Authentication
- **Method**: JWT Bearer tokens
- **Token Lifetime**: 15 minutes (access), 7 days (refresh)
- **Token Storage**: HttpOnly cookies for web, secure storage for mobile
- **Token Claims**: UserId, TenantId, Roles, Permissions
- **Refresh Strategy**: Sliding expiration with rotation

### Authorization
- **Model**: Role-Based Access Control (RBAC)
- **Roles**: Defined per service (e.g., FullViewSecurity has 16 role types)
- **Permissions**: Fine-grained, checked at API and domain layers
- **Tenant Isolation**: Authorization checks include tenant context
- **Policy-Based**: Use ASP.NET Core policies for complex authorization

### Data Protection
- **PII Encryption**: AES-256 encryption for all PII at rest
- **Password Hashing**: PBKDF2 with 100,000 iterations minimum
- **Sensitive Data**: Never logged, never cached unencrypted
- **Data Masking**: PII masked in logs and non-production environments
- **Key Management**: Azure Key Vault or equivalent

## 📊 Data Management

### Schema Naming
- **Pattern**: Service-specific schemas (e.g., `Auth`, `DataSource`)
- **Rationale**: Clear ownership, easier maintenance
- **Convention**: PascalCase, descriptive names

### Database Migrations
- **Tool**: Entity Framework Core Migrations
- **Strategy**: Forward-only migrations in production
- **Rollback**: Separate rollback scripts for production emergencies
- **Testing**: All migrations tested in staging before production
- **Naming**: `YYYYMMDDHHMMSS_DescriptiveName`

### Data Consistency
- **Transactions**: Use distributed transactions where needed (Saga pattern)
- **Eventual Consistency**: Acceptable for non-critical cross-service data
- **Saga Pattern**: For complex multi-service workflows
- **Idempotency**: All operations must be idempotent

## 🔄 Integration Patterns

### Service Communication
- **Synchronous**: REST APIs for request-response patterns
- **Asynchronous**: Azure Service Bus for events and commands
- **API Gateway**: Centralized entry point for external clients
- **Service Mesh**: Consider for complex service-to-service communication

### API Contracts
- **Versioning**: URL-based versioning (e.g., `/api/v1/users`)
- **Documentation**: OpenAPI/Swagger for all endpoints
- **Breaking Changes**: New version required, deprecation period for old version (6 months minimum)
- **Backward Compatibility**: Maintain for at least 2 versions

### Error Handling
- **Standard Format**: RFC 7807 Problem Details
- **Correlation IDs**: Propagated across all services (Guid format)
- **Logging**: Structured logging with correlation IDs
- **Error Codes**: Application-specific error codes for client handling

## 🧪 Testing Strategy

### Application-Level Testing
- **Contract Tests**: Verify API contracts between services (Pact or similar)
- **Integration Tests**: Test service interactions with real dependencies
- **End-to-End Tests**: Critical user workflows across services
- **Performance Tests**: Load testing for critical paths

### Test Data
- **Isolation**: Each test uses isolated test data with unique TenantId
- **Cleanup**: Automatic cleanup after tests
- **Realistic**: Test data mirrors production patterns
- **Multi-Tenant**: Tests verify tenant isolation

## 📦 Deployment

### Containerization
- **Platform**: Docker containers
- **Orchestration**: Kubernetes or Azure Container Apps
- **Configuration**: Environment-specific config files (appsettings.{env}.json)
- **Secrets**: Never in containers, always from Key Vault

### Environments
- **Development**: Local development environment
- **Staging**: Pre-production testing with production-like data
- **Production**: Live environment with blue-green deployment
- **DR**: Disaster recovery environment

### Monitoring
- **APM**: Application Insights for all services
- **Logging**: Centralized logging (Azure Log Analytics or equivalent)
- **Alerts**: Proactive alerting for critical issues
- **Dashboards**: Real-time dashboards for operations team

## 🎓 FullView Services

### Current Services
1. **FullViewSecurity** - Authentication, authorization, user management
2. **INN8DataSource** - Data integration and synchronization with INN8 systems

### Planned Services
- **FullViewReporting** - Financial reporting and analytics
- **FullViewNotifications** - Email, SMS, push notifications
- **FullViewAudit** - Centralized audit logging and compliance

### Shared Libraries
- **FullView.Common** - Shared utilities, extensions, constants
- **FullView.Contracts** - Shared DTOs, interfaces, events
- **FullView.Testing** - Shared test infrastructure, builders, fixtures

## 📚 References

- Business Unit Architecture: `../../org-architecture.md`
- Business Unit Coding Standards: `../../org-coding-standards.md`
- Business Unit Testing Standards: `../../org-testing-standards.md`
- Business Unit Code Review Standards: `../../org-code-review-standards.md`

---

**Note**: Service-specific architecture rules can extend these standards but should not contradict them. When conflicts arise, service-specific rules take precedence for that service only.

**Last Updated**: January 2025
**Maintained By**: FullView Architecture Team

