# SecurityService Business Rules

> **Scope**: SecurityService only
> **Level**: Service-level (Level 3)
> **Precedence**: HIGHEST - overrides application and business unit when conflicts exist

## 🎯 Overview

SecurityService is the authentication and authorization service for the AITooling application. This service provides JWT-based authentication, role-based access control, and user management for AI/ML services.

## 🔐 Authentication Rules

### JWT Token Management
- **Access Token Lifetime**: 15 minutes (consistent with application standards)
- **Refresh Token Lifetime**: 7 days
- **Token Storage**: HttpOnly cookies for web clients, secure storage for mobile
- **Token Claims**: UserId, Username, Email, Roles
- **Token Signing**: HS256 algorithm with secret key
- **Token Refresh**: Sliding expiration with automatic rotation

### Password Policy
- **Hashing Algorithm**: PBKDF2 with SHA-256
- **Iterations**: 100,000 minimum
- **Salt**: Unique per user, cryptographically random
- **Minimum Length**: 8 characters
- **Complexity**: Must include uppercase, lowercase, number
- **History**: Cannot reuse last 3 passwords
- **Expiration**: 90 days (configurable)

### Session Management
- **Concurrent Sessions**: Maximum 5 per user
- **Session Timeout**: 30 minutes of inactivity
- **Session Tracking**: All active sessions tracked in database
- **Force Logout**: Admin can force logout all sessions for a user

## 👥 Authorization Rules

### Role Types
1. **Admin** - Full system access, can manage all users and roles
2. **User** - Standard user access to AI services
3. **Guest** - Limited read-only access

### Permission Model
- **User Permissions**: `User.Create`, `User.Read`, `User.Update`, `User.Delete`
- **Role Permissions**: `Role.Assign`, `Role.Revoke`
- **Service Permissions**: `Service.Access`, `Service.Execute`

### Role Assignment Rules
- **Multiple Roles**: Users can have multiple roles
- **Role Hierarchy**: Admin > User > Guest
- **Default Role**: New users assigned "User" role by default

## 📊 Database Schema

- **Schema Name**: `Security`
- **Rationale**: Clear separation from other services, easy to identify security-related tables

## 🔐 Security Constraints

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

## 📊 Audit Logging

### What Gets Logged
- **Authentication Events**: Login, logout, failed attempts
- **User Management**: User creation, updates, deletion, password changes
- **Role Management**: Role assignments, permission changes
- **Security Events**: Suspicious activity, brute force attempts

### Audit Log Format
- **Timestamp**: UTC timestamp with millisecond precision
- **UserId**: User who performed the action
- **Action**: What action was performed
- **Resource**: What resource was affected
- **Result**: Success or failure
- **IP Address**: Client IP address
- **User Agent**: Client user agent

### Audit Log Retention
- **Retention Period**: 2 years minimum
- **Storage**: Immutable storage (append-only)
- **Access**: Read-only access for Admin role
- **Export**: Support for exporting audit logs

## 🧪 Testing Requirements

### Security Testing
- **Penetration Testing**: Annual third-party penetration testing
- **Vulnerability Scanning**: Weekly automated scans
- **Security Audits**: Quarterly security audits

### Property-Based Testing
- **Token Generation**: Verify tokens are always valid and unique
- **Permission Checks**: Verify permissions are always enforced
- **Password Hashing**: Verify hashes are always unique and secure

## 📚 References

- **Application Architecture**: `../../app-architecture.md`
- **Business Unit Architecture**: `../../../../wealth-and-fiduciary-architecture.md`
- **Business Unit Security**: `../../../../wealth-and-fiduciary-architecture.md` (Security Baseline section)

---

**Note**: These rules are specific to SecurityService and override application and business unit standards when conflicts exist.

**Last Updated**: January 2025
**Maintained By**: SecurityService Team
