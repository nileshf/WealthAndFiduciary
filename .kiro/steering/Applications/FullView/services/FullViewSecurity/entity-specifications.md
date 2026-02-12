# FullViewSecurity Entity Specifications

> **Scope**: FullViewSecurity service only
> **Level**: Service-level (Level 3)
> **Precedence**: HIGHEST - defines exact entity structure for this service

## 🎯 Overview

This document defines the exact entity structure for FullViewSecurity. All entities must follow these specifications exactly.

## 📊 Database Schema

- **Schema Name**: `Auth`
- **Rationale**: Clear separation from other services, easy to identify security-related tables

## 🏗️ Entity Specifications

### User Entity

**Table**: `Auth.Users`

```csharp
[Table("Users", Schema = "Auth")]
public class User : BaseEntity
{
    // Identity
    [Required]
    [StringLength(255)]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100)]
    public string Username { get; set; } = string.Empty;
    
    // Authentication
    [Required]
    [StringLength(500)]
    public string PasswordHash { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100)]
    public string PasswordSalt { get; set; } = string.Empty;
    
    public DateTime? LastPasswordChangeDate { get; set; }
    
    public int FailedLoginAttempts { get; set; }
    
    public DateTime? LockoutEndDate { get; set; }
    
    // MFA
    public bool MfaEnabled { get; set; }
    
    [StringLength(500)]
    public string? MfaSecret { get; set; }
    
    [StringLength(1000)]
    public string? MfaBackupCodes { get; set; }
    
    // Profile
    [StringLength(100)]
    public string? FirstName { get; set; }
    
    [StringLength(100)]
    public string? LastName { get; set; }
    
    [StringLength(20)]
    public string? PhoneNumber { get; set; }
    
    // Status
    public bool IsActive { get; set; } = true;
    
    public bool EmailVerified { get; set; }
    
    public DateTime? EmailVerifiedDate { get; set; }
    
    public DateTime? LastLoginDate { get; set; }
    
    // Multi-Tenant
    [Required]
    public Guid TenantId { get; set; }
    
    // Navigation Properties
    public Tenant? Tenant { get; set; }
    
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    
    public ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
}
```

### Role Entity

**Table**: `Auth.Roles`

```csharp
[Table("Roles", Schema = "Auth")]
public class Role : BaseEntity
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    [Required]
    public RoleType RoleType { get; set; }
    
    public bool IsSystemRole { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Multi-Tenant (null for system roles)
    public Guid? TenantId { get; set; }
    
    // Navigation Properties
    public Tenant? Tenant { get; set; }
    
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    
    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
}
```

### Permission Entity

**Table**: `Auth.Permissions`

```csharp
[Table("Permissions", Schema = "Auth")]
public class Permission : BaseEntity
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100)]
    public string Resource { get; set; } = string.Empty;
    
    [Required]
    [StringLength(50)]
    public string Action { get; set; } = string.Empty;
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Navigation Properties
    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
}
```

### UserRole Entity (Join Table)

**Table**: `Auth.UserRoles`

```csharp
[Table("UserRoles", Schema = "Auth")]
public class UserRole : BaseEntity
{
    [Required]
    public Guid UserId { get; set; }
    
    [Required]
    public Guid RoleId { get; set; }
    
    public DateTime AssignedDate { get; set; } = DateTime.UtcNow;
    
    public DateTime? ExpirationDate { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Multi-Tenant
    [Required]
    public Guid TenantId { get; set; }
    
    // Navigation Properties
    public User? User { get; set; }
    
    public Role? Role { get; set; }
    
    public Tenant? Tenant { get; set; }
}
```

### RolePermission Entity (Join Table)

**Table**: `Auth.RolePermissions`

```csharp
[Table("RolePermissions", Schema = "Auth")]
public class RolePermission : BaseEntity
{
    [Required]
    public Guid RoleId { get; set; }
    
    [Required]
    public Guid PermissionId { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Navigation Properties
    public Role? Role { get; set; }
    
    public Permission? Permission { get; set; }
}
```

### Tenant Entity

**Table**: `Auth.Tenants`

```csharp
[Table("Tenants", Schema = "Auth")]
public class Tenant : BaseEntity
{
    [Required]
    [StringLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [StringLength(100)]
    public string? Subdomain { get; set; }
    
    [StringLength(500)]
    public string? Description { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public DateTime? SuspendedDate { get; set; }
    
    [StringLength(500)]
    public string? SuspensionReason { get; set; }
    
    // Configuration
    [StringLength(2000)]
    public string? Configuration { get; set; } // JSON configuration
    
    // Subscription
    public DateTime? SubscriptionStartDate { get; set; }
    
    public DateTime? SubscriptionEndDate { get; set; }
    
    [StringLength(50)]
    public string? SubscriptionTier { get; set; }
    
    // Navigation Properties
    public ICollection<User> Users { get; set; } = new List<User>();
    
    public ICollection<Role> Roles { get; set; } = new List<Role>();
    
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}
```

### RefreshToken Entity

**Table**: `Auth.RefreshTokens`

```csharp
[Table("RefreshTokens", Schema = "Auth")]
public class RefreshToken : BaseEntity
{
    [Required]
    public Guid UserId { get; set; }
    
    [Required]
    [StringLength(500)]
    public string Token { get; set; } = string.Empty;
    
    [Required]
    public DateTime ExpirationDate { get; set; }
    
    public bool IsRevoked { get; set; }
    
    public DateTime? RevokedDate { get; set; }
    
    [StringLength(500)]
    public string? ReplacedByToken { get; set; }
    
    [StringLength(100)]
    public string? IpAddress { get; set; }
    
    [StringLength(500)]
    public string? UserAgent { get; set; }
    
    // Multi-Tenant
    [Required]
    public Guid TenantId { get; set; }
    
    // Navigation Properties
    public User? User { get; set; }
    
    public Tenant? Tenant { get; set; }
}
```

### AuditLog Entity

**Table**: `Auth.AuditLogs`

```csharp
[Table("AuditLogs", Schema = "Auth")]
public class AuditLog : BaseEntity
{
    [Required]
    public Guid UserId { get; set; }
    
    [Required]
    [StringLength(100)]
    public string Action { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100)]
    public string Resource { get; set; } = string.Empty;
    
    [StringLength(100)]
    public string? ResourceId { get; set; }
    
    [StringLength(50)]
    public string Result { get; set; } = string.Empty; // Success, Failure
    
    [StringLength(2000)]
    public string? Details { get; set; } // JSON details
    
    [StringLength(100)]
    public string? IpAddress { get; set; }
    
    [StringLength(500)]
    public string? UserAgent { get; set; }
    
    [Required]
    [StringLength(100)]
    public string CorrelationId { get; set; } = string.Empty;
    
    // Multi-Tenant
    [Required]
    public Guid TenantId { get; set; }
    
    // Navigation Properties
    public User? User { get; set; }
    
    public Tenant? Tenant { get; set; }
}
```

## 🔢 Enums

### RoleType Enum

```csharp
public enum RoleType
{
    SystemAdmin = 1,
    TenantAdmin = 2,
    UserManager = 3,
    FinancialAdvisor = 4,
    ComplianceOfficer = 5,
    DataAnalyst = 6,
    ClientServiceRep = 7,
    PortfolioManager = 8,
    RiskManager = 9,
    AuditViewer = 10,
    ReportViewer = 11,
    ClientUser = 12,
    APIUser = 13,
    ReadOnlyUser = 14,
    DeveloperUser = 15,
    GuestUser = 16
}
```

## 🔗 Relationships

### User Relationships
- **User → Tenant**: Many-to-One (required)
- **User → UserRole**: One-to-Many
- **User → RefreshToken**: One-to-Many
- **User → AuditLog**: One-to-Many

### Role Relationships
- **Role → Tenant**: Many-to-One (optional, null for system roles)
- **Role → UserRole**: One-to-Many
- **Role → RolePermission**: One-to-Many

### Tenant Relationships
- **Tenant → User**: One-to-Many
- **Tenant → Role**: One-to-Many
- **Tenant → UserRole**: One-to-Many
- **Tenant → RefreshToken**: One-to-Many
- **Tenant → AuditLog**: One-to-Many

## 📏 Validation Rules

### User Validation
- Email must be unique per tenant
- Username must be unique per tenant
- Email must be valid email format
- Password must meet complexity requirements
- TenantId is required

### Role Validation
- Role name must be unique per tenant (or globally for system roles)
- RoleType must be valid enum value
- System roles cannot be deleted

### Permission Validation
- Permission name must be unique
- Resource and Action combination must be unique
- Format: `Resource.Action` (e.g., `User.Create`)

### Tenant Validation
- Tenant name must be unique
- Subdomain must be unique (if provided)
- Subdomain must be valid DNS subdomain format

## 🔒 Security Constraints

### Encryption
- **PasswordHash**: PBKDF2 with SHA-256, 100,000 iterations
- **MfaSecret**: Encrypted at rest (AES-256)
- **MfaBackupCodes**: Encrypted at rest (AES-256)

### Indexes
- **User.Email**: Unique index per tenant
- **User.Username**: Unique index per tenant
- **User.TenantId**: Index for tenant filtering
- **Role.Name**: Unique index per tenant
- **Permission.Name**: Unique index
- **Tenant.Subdomain**: Unique index
- **RefreshToken.Token**: Unique index
- **AuditLog.CorrelationId**: Index for correlation

### Soft Delete
- All entities support soft delete (IsDeleted flag in BaseEntity)
- Soft deleted entities excluded from queries by default
- Audit logs are never deleted (immutable)

## 📚 References

- **Business Rules**: `./security-business-rules.md`
- **Implementation Patterns**: `./implementation-patterns.md`
- **Application Architecture**: `../../app-architecture.md`
- **Business Unit Architecture**: `../../../../org-architecture.md`

---

**Note**: These entity specifications are exact and must be followed precisely when implementing FullViewSecurity.

**Last Updated**: January 2025
**Maintained By**: FullViewSecurity Team
