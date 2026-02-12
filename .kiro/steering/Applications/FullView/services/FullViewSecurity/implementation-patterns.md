# FullViewSecurity Implementation Patterns

> **Scope**: FullViewSecurity service only
> **Level**: Service-level (Level 3)
> **Precedence**: HIGHEST - defines exact implementation patterns for this service

## 🎯 Overview

This document defines implementation patterns specific to FullViewSecurity. These patterns must be followed when implementing features in this service.

## 🏗️ Project Structure

```
FullViewSecurity/
├── FullViewSecurity.Domain/
│   ├── Entities/
│   │   ├── User.cs
│   │   ├── Role.cs
│   │   ├── Permission.cs
│   │   ├── UserRole.cs
│   │   ├── RolePermission.cs
│   │   ├── Tenant.cs
│   │   ├── RefreshToken.cs
│   │   └── AuditLog.cs
│   ├── Enums/
│   │   └── RoleType.cs
│   └── ValueObjects/
│       └── PasswordHash.cs
│
├── FullViewSecurity.Application/
│   ├── Commands/
│   │   ├── Users/
│   │   │   ├── CreateUserCommand.cs
│   │   │   ├── UpdateUserCommand.cs
│   │   │   └── DeleteUserCommand.cs
│   │   ├── Auth/
│   │   │   ├── LoginCommand.cs
│   │   │   ├── RefreshTokenCommand.cs
│   │   │   └── LogoutCommand.cs
│   │   └── Roles/
│   │       ├── CreateRoleCommand.cs
│   │       └── AssignRoleCommand.cs
│   ├── Queries/
│   │   ├── Users/
│   │   │   ├── GetUserByIdQuery.cs
│   │   │   └── GetUsersByTenantQuery.cs
│   │   └── Roles/
│   │       └── GetRolesByTenantQuery.cs
│   ├── DTOs/
│   │   ├── UserDto.cs
│   │   ├── RoleDto.cs
│   │   └── AuthResponseDto.cs
│   ├── Interfaces/
│   │   ├── IUserRepository.cs
│   │   ├── IRoleRepository.cs
│   │   ├── ITokenService.cs
│   │   └── IPasswordHasher.cs
│   └── Validators/
│       ├── CreateUserCommandValidator.cs
│       └── LoginCommandValidator.cs
│
├── FullViewSecurity.Infrastructure/
│   ├── Data/
│   │   ├── AuthDbContext.cs
│   │   └── Configurations/
│   │       ├── UserConfiguration.cs
│   │       ├── RoleConfiguration.cs
│   │       └── TenantConfiguration.cs
│   ├── Repositories/
│   │   ├── UserRepository.cs
│   │   └── RoleRepository.cs
│   ├── Services/
│   │   ├── TokenService.cs
│   │   ├── PasswordHasher.cs
│   │   └── AuditLogService.cs
│   └── Migrations/
│
└── FullViewSecurity.Api/
    ├── Controllers/
    │   ├── AuthController.cs
    │   ├── UsersController.cs
    │   └── RolesController.cs
    ├── Middleware/
    │   ├── TenantMiddleware.cs
    │   └── AuditLoggingMiddleware.cs
    └── Configuration/
        └── DependencyInjection.cs
```

## 🔐 Authentication Patterns

### Login Flow

```csharp
// LoginCommand
public record LoginCommand(
    [Required] string Email,
    [Required] string Password,
    string? TenantSubdomain
) : IRequest<AuthResponseDto>;

// LoginCommandHandler
public class LoginCommandHandler : IRequestHandler<LoginCommand, AuthResponseDto>
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly IAuditLogService _auditLogService;
    private readonly ILogger<LoginCommandHandler> _logger;

    public async Task<AuthResponseDto> Handle(LoginCommand command, CancellationToken cancellationToken)
    {
        // 1. Find user by email and tenant
        var user = await _userRepository.GetByEmailAsync(command.Email, command.TenantSubdomain);
        
        if (user == null)
        {
            await _auditLogService.LogFailedLoginAsync(command.Email, "User not found");
            throw new UnauthorizedException("Invalid credentials");
        }
        
        // 2. Check if account is locked
        if (user.LockoutEndDate.HasValue && user.LockoutEndDate > DateTime.UtcNow)
        {
            await _auditLogService.LogFailedLoginAsync(user.Id, "Account locked");
            throw new UnauthorizedException("Account is locked");
        }
        
        // 3. Verify password
        if (!_passwordHasher.VerifyPassword(command.Password, user.PasswordHash, user.PasswordSalt))
        {
            user.FailedLoginAttempts++;
            
            if (user.FailedLoginAttempts >= 5)
            {
                user.LockoutEndDate = DateTime.UtcNow.AddMinutes(15);
            }
            
            await _userRepository.UpdateAsync(user);
            await _auditLogService.LogFailedLoginAsync(user.Id, "Invalid password");
            
            throw new UnauthorizedException("Invalid credentials");
        }
        
        // 4. Reset failed login attempts
        user.FailedLoginAttempts = 0;
        user.LockoutEndDate = null;
        user.LastLoginDate = DateTime.UtcNow;
        await _userRepository.UpdateAsync(user);
        
        // 5. Generate tokens
        var accessToken = _tokenService.GenerateAccessToken(user);
        var refreshToken = await _tokenService.GenerateRefreshTokenAsync(user);
        
        // 6. Log successful login
        await _auditLogService.LogSuccessfulLoginAsync(user.Id);
        
        return new AuthResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = 900, // 15 minutes
            User = user.ToDto()
        };
    }
}
```

### Token Generation Pattern

```csharp
public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;
    private readonly IRefreshTokenRepository _refreshTokenRepository;

    public string GenerateAccessToken(User user)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim("TenantId", user.TenantId.ToString()),
            new Claim("Username", user.Username)
        };
        
        // Add role claims
        foreach (var userRole in user.UserRoles.Where(ur => ur.IsActive))
        {
            claims.Add(new Claim(ClaimTypes.Role, userRole.Role.Name));
        }
        
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Secret"]));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        
        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: credentials
        );
        
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
    
    public async Task<string> GenerateRefreshTokenAsync(User user)
    {
        var refreshToken = new RefreshToken
        {
            UserId = user.Id,
            TenantId = user.TenantId,
            Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64)),
            ExpirationDate = DateTime.UtcNow.AddDays(7),
            IpAddress = GetClientIpAddress(),
            UserAgent = GetClientUserAgent()
        };
        
        await _refreshTokenRepository.AddAsync(refreshToken);
        
        return refreshToken.Token;
    }
}
```

## 👥 Authorization Patterns

### Permission Check Pattern

```csharp
// Custom authorization attribute
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RequirePermissionAttribute : AuthorizeAttribute, IAuthorizationFilter
{
    private readonly string _resource;
    private readonly string _action;

    public RequirePermissionAttribute(string resource, string action)
    {
        _resource = resource;
        _action = action;
    }

    public void OnAuthorization(AuthorizationFilterContext context)
    {
        var user = context.HttpContext.User;
        
        if (!user.Identity?.IsAuthenticated ?? true)
        {
            context.Result = new UnauthorizedResult();
            return;
        }
        
        var permissionService = context.HttpContext.RequestServices
            .GetRequiredService<IPermissionService>();
        
        var userId = Guid.Parse(user.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var hasPermission = permissionService.HasPermissionAsync(userId, _resource, _action).Result;
        
        if (!hasPermission)
        {
            context.Result = new ForbidResult();
        }
    }
}

// Usage in controller
[HttpPost]
[RequirePermission("User", "Create")]
public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserCommand command)
{
    var result = await _mediator.Send(command);
    return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
}
```

### Tenant Isolation Pattern

```csharp
// Tenant middleware
public class TenantMiddleware
{
    private readonly RequestDelegate _next;

    public async Task InvokeAsync(HttpContext context, ITenantService tenantService)
    {
        // Extract tenant from subdomain or header
        var tenantIdentifier = ExtractTenantIdentifier(context);
        
        if (string.IsNullOrEmpty(tenantIdentifier))
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsync("Tenant identifier is required");
            return;
        }
        
        // Resolve tenant
        var tenant = await tenantService.GetByIdentifierAsync(tenantIdentifier);
        
        if (tenant == null || !tenant.IsActive)
        {
            context.Response.StatusCode = 404;
            await context.Response.WriteAsync("Tenant not found or inactive");
            return;
        }
        
        // Store tenant context
        context.Items["TenantId"] = tenant.Id;
        context.Items["Tenant"] = tenant;
        
        await _next(context);
    }
    
    private string? ExtractTenantIdentifier(HttpContext context)
    {
        // Try subdomain first
        var host = context.Request.Host.Host;
        var parts = host.Split('.');
        
        if (parts.Length > 2)
        {
            return parts[0]; // subdomain
        }
        
        // Try header
        if (context.Request.Headers.TryGetValue("X-Tenant-Id", out var tenantId))
        {
            return tenantId;
        }
        
        return null;
    }
}

// Query filter for tenant isolation
public class AuthDbContext : DbContext
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Apply tenant filter to all tenant-scoped entities
        modelBuilder.Entity<User>().HasQueryFilter(u => 
            u.TenantId == GetCurrentTenantId());
        
        modelBuilder.Entity<Role>().HasQueryFilter(r => 
            r.TenantId == null || r.TenantId == GetCurrentTenantId());
        
        modelBuilder.Entity<UserRole>().HasQueryFilter(ur => 
            ur.TenantId == GetCurrentTenantId());
    }
    
    private Guid GetCurrentTenantId()
    {
        var tenantId = _httpContextAccessor.HttpContext?.Items["TenantId"];
        return tenantId != null ? (Guid)tenantId : Guid.Empty;
    }
}
```

## 📊 Audit Logging Pattern

```csharp
// Audit logging middleware
public class AuditLoggingMiddleware
{
    private readonly RequestDelegate _next;

    public async Task InvokeAsync(HttpContext context, IAuditLogService auditLogService)
    {
        var correlationId = Guid.NewGuid().ToString();
        context.Items["CorrelationId"] = correlationId;
        
        // Log request
        await auditLogService.LogRequestAsync(new AuditLogEntry
        {
            CorrelationId = correlationId,
            UserId = GetUserId(context),
            TenantId = GetTenantId(context),
            Action = context.Request.Method,
            Resource = context.Request.Path,
            IpAddress = context.Connection.RemoteIpAddress?.ToString(),
            UserAgent = context.Request.Headers["User-Agent"].ToString()
        });
        
        await _next(context);
        
        // Log response
        await auditLogService.LogResponseAsync(new AuditLogEntry
        {
            CorrelationId = correlationId,
            Result = context.Response.StatusCode < 400 ? "Success" : "Failure"
        });
    }
}

// Audit log service
public class AuditLogService : IAuditLogService
{
    private readonly IAuditLogRepository _repository;

    public async Task LogAsync(string action, string resource, string? resourceId, string result, string? details)
    {
        var auditLog = new AuditLog
        {
            UserId = GetCurrentUserId(),
            TenantId = GetCurrentTenantId(),
            Action = action,
            Resource = resource,
            ResourceId = resourceId,
            Result = result,
            Details = details,
            IpAddress = GetClientIpAddress(),
            UserAgent = GetClientUserAgent(),
            CorrelationId = GetCorrelationId()
        };
        
        await _repository.AddAsync(auditLog);
    }
}
```

## 🧪 Testing Patterns

### Unit Test Pattern

```csharp
public class LoginCommandHandlerTests
{
    private readonly Mock<IUserRepository> _userRepositoryMock;
    private readonly Mock<IPasswordHasher> _passwordHasherMock;
    private readonly Mock<ITokenService> _tokenServiceMock;
    private readonly LoginCommandHandler _handler;

    public LoginCommandHandlerTests()
    {
        _userRepositoryMock = new Mock<IUserRepository>();
        _passwordHasherMock = new Mock<IPasswordHasher>();
        _tokenServiceMock = new Mock<ITokenService>();
        _handler = new LoginCommandHandler(
            _userRepositoryMock.Object,
            _passwordHasherMock.Object,
            _tokenServiceMock.Object);
    }

    [Fact]
    public async Task Handle_WithValidCredentials_ReturnsAuthResponse()
    {
        // Arrange
        var user = new UserBuilder()
            .WithEmail("test@example.com")
            .WithPasswordHash("hash")
            .Build();
        
        _userRepositoryMock
            .Setup(x => x.GetByEmailAsync(It.IsAny<string>(), It.IsAny<string>()))
            .ReturnsAsync(user);
        
        _passwordHasherMock
            .Setup(x => x.VerifyPassword(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>()))
            .Returns(true);
        
        _tokenServiceMock
            .Setup(x => x.GenerateAccessToken(It.IsAny<User>()))
            .Returns("access-token");
        
        var command = new LoginCommand("test@example.com", "password", null);
        
        // Act
        var result = await _handler.Handle(command, CancellationToken.None);
        
        // Assert
        result.Should().NotBeNull();
        result.AccessToken.Should().Be("access-token");
    }
}
```

### Property-Based Test Pattern

```csharp
public class UserPropertyTests
{
    [Property]
    public Property PasswordHash_IsAlwaysUnique()
    {
        return Prop.ForAll<string, string>((password1, password2) =>
        {
            if (password1 == password2) return true;
            
            var hasher = new PasswordHasher();
            var hash1 = hasher.HashPassword(password1);
            var hash2 = hasher.HashPassword(password2);
            
            return hash1 != hash2;
        });
    }
    
    [Property]
    public Property TenantIsolation_PreventsCrossTenantAccess()
    {
        return Prop.ForAll<Guid, Guid>((tenantId1, tenantId2) =>
        {
            if (tenantId1 == tenantId2) return true;
            
            var user1 = new UserBuilder().WithTenantId(tenantId1).Build();
            var user2 = new UserBuilder().WithTenantId(tenantId2).Build();
            
            // Verify users cannot access each other's data
            return user1.TenantId != user2.TenantId;
        });
    }
}
```

## 📚 References

- **Business Rules**: `./security-business-rules.md`
- **Entity Specifications**: `./entity-specifications.md`
- **Application Architecture**: `../../app-architecture.md`
- **Business Unit Coding Standards**: `../../../../org-coding-standards.md`
- **Business Unit Testing Standards**: `../../../../org-testing-standards.md`

---

**Note**: These implementation patterns are specific to FullViewSecurity and must be followed exactly.

**Last Updated**: January 2025
**Maintained By**: FullViewSecurity Team
