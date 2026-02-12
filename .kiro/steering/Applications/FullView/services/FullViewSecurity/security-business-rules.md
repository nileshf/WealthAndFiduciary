# FullViewSecurity Business Rules

> **Scope**: FullViewSecurity service only
> **Level**: Service-level (Level 3)
> **Precedence**: HIGHEST - overrides application and business unit when conflicts exist

## 🎯 Overview

FullViewSecurity is the authentication and authorization service for the FullView application. This document defines service-specific business rules that apply only to FullViewSecurity.

## 🔐 Authentication Rules

### JWT Token Management
- **Access Token Lifetime**: 15 minutes
- **Refresh Token Lifetime**: 7 days
- **Token Storage**: HttpOnly cookies for web clients
- **Token Claims**: UserId, TenantId, Roles, Permissions, Email
- **Token Signing**: RS256 algorithm with rotating keys
- **Token Refresh**: Sliding expiration with automatic rotation

### Password Policy
- **Hashing Algorithm**: PBKDF2 with SHA-256
- **Iterations**: 100,000 minimum
- **Salt**: Unique per user, cryptographically random
- **Minimum Length**: 12 characters
- **Complexity**: Must include uppercase, lowercase, number, special character
- **History**: Cannot reuse last 5 passwords
- **Expiration**: 90 days (configurable per tenant)

### Multi-Factor Authentication (MFA)
- **Support**: TOTP (Time-based One-Time Password)
- **Enrollment**: Optional but recommended
- **Backup Codes**: 10 single-use backup codes generated
- **Recovery**: Email-based recovery with time-limited tokens

### Session Management
- **Concurrent Sessions**: Maximum 3 per user
- **Session Timeout**: 30 minutes of inactivity
- **Session Tracking**: All active sessions tracked in database
- **Force Logout**: Admin can force logout all sessions for a user

## 👥 Authorization Rules

### Role Types (16 Total)
1. **SystemAdmin** - Full system access, can manage all tenants
2. **TenantAdmin** - Full access within tenant
3. **UserManager** - Can manage users and roles within tenant
4. **FinancialAdvisor** - Access to client financial data
5. **ComplianceOfficer** - Access to audit logs and compliance reports
6. **DataAnalyst** - Read-only access to analytics
7. **ClientServiceRep** - Limited client interaction access
8. **PortfolioManager** - Manage investment portfolios
9. **RiskManager** - Access to risk assessment tools
10. **AuditViewer** - Read-only access to audit logs
11. **ReportViewer** - Access to reports only
12. **ClientUser** - End-user client access
13. **APIUser** - Service account for API access
14. **ReadOnlyUser** - Read-only access to all data
15. **DeveloperUser** - Development and testing access
16. **GuestUser** - Limited guest access

### Permission Model
- **Granular Permissions**: Each role has specific permissions
- **Permission Format**: `Resource.Action` (e.g., `User.Create`, `Report.View`)
- **Permission Inheritance**: Roles can inherit permissions from other roles
- **Dynamic Permissions**: Permissions can be added/removed at runtime
- **Tenant-Scoped**: All permissions are tenant-scoped

### Role Assignment Rules
- **Single Tenant**: Users can only have roles within their tenant
- **Multiple Roles**: Users can have multiple roles
- **Role Hierarchy**: SystemAdmin > TenantAdmin > UserManager > Other Roles
- **Role Conflicts**: Higher role takes precedence
- **Temporary Roles**: Support for time-limited role assignments

## 🏢 Multi-Tenant Isolation

### Tenant Identification
- **TenantId**: Guid type, required on all entities
- **Tenant Context**: Injected via middleware, available throughout request
- **Tenant Validation**: Every request validates tenant context
- **Cross-Tenant Access**: Strictly prohibited, enforced at multiple layers

### Tenant Data Isolation
- **Database Level**: Row-level security enforced
- **Application Level**: All queries filtered by TenantId
- **API Level**: Tenant context validated in middleware
- **Cache Level**: Tenant-specific cache keys

### Tenant Administration
- **Tenant Creation**: Only SystemAdmin can create tenants
- **Tenant Configuration**: Each tenant has independent configuration
- **Tenant Suspension**: SystemAdmin can suspend/activate tenants
- **Tenant Deletion**: Soft delete with 30-day recovery period

## 📊 Audit Logging

### What Gets Logged
- **Authentication Events**: Login, logout, failed attempts, MFA events
- **Authorization Events**: Permission checks, role assignments
- **User Management**: User creation, updates, deletion, password changes
- **Role Management**: Role assignments, permission changes
- **Tenant Management**: Tenant creation, configuration changes
- **Security Events**: Suspicious activity, brute force attempts

### Audit Log Format
- **Timestamp**: UTC timestamp with millisecond precision
- **UserId**: User who performed the action
- **TenantId**: Tenant context
- **Action**: What action was performed
- **Resource**: What resource was affected
- **Result**: Success or failure
- **IP Address**: Client IP address
- **User Agent**: Client user agent
- **Correlation ID**: Request correlation ID

### Audit Log Retention
- **Retention Period**: 7 years minimum (financial compliance)
- **Storage**: Immutable storage (append-only)
- **Access**: Read-only access for ComplianceOfficer and AuditViewer roles
- **Export**: Support for exporting audit logs for compliance

## 🔒 Security Constraints

### Brute Force Protection
- **Failed Login Threshold**: 5 failed attempts
- **Lockout Duration**: 15 minutes
- **Lockout Escalation**: Doubles with each subsequent lockout (max 24 hours)
- **IP-Based Throttling**: Rate limiting per IP address

### Password Reset
- **Reset Token**: Time-limited (1 hour), single-use
- **Reset Method**: Email-based with secure token
- **Reset Notification**: User notified of password reset
- **Reset Audit**: All password resets logged

### Account Security
- **Email Verification**: Required for new accounts
- **Email Change**: Requires verification of both old and new email
- **Account Deletion**: Soft delete with 30-day recovery
- **Account Suspension**: Admin can suspend accounts

## 🧪 Testing Requirements

### Security Testing
- **Penetration Testing**: Annual third-party penetration testing
- **Vulnerability Scanning**: Weekly automated scans
- **Security Audits**: Quarterly security audits
- **Compliance Testing**: Regular compliance validation

### Property-Based Testing
- **Token Generation**: Verify tokens are always valid and unique
- **Permission Checks**: Verify permissions are always enforced
- **Tenant Isolation**: Verify cross-tenant access is impossible
- **Password Hashing**: Verify hashes are always unique and secure

## 📚 References

- **Application Architecture**: `../../app-architecture.md`
- **Business Unit Architecture**: `../../../../org-architecture.md`
- **Business Unit Security**: `../../../../org-architecture.md` (Security Baseline section)
- **Entity Specifications**: `./entity-specifications.md`
- **Implementation Patterns**: `./implementation-patterns.md`

---

**Note**: These rules are specific to FullViewSecurity and override application and business unit standards when conflicts exist.

**Last Updated**: January 2025
**Maintained By**: FullViewSecurity Team
