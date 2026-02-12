# BUSINESS UNIT CODING STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific coding standards override these when conflicts exist

## 🔧 SOLID PRINCIPLES ENFORCEMENT (MANDATORY)

- **SRP (Single Responsibility)**: One responsibility per class/method
- **OCP (Open/Closed)**: Extend via configuration, not modification  
- **LSP (Liskov Substitution)**: Proper inheritance with BaseEntity
- **ISP (Interface Segregation)**: Specific interfaces (IUserService, IRoleService)
- **DIP (Dependency Inversion)**: Depend on abstractions, inject dependencies

## 📝 CODE GENERATION RULES (MANDATORY)

### **Documentation**
- **XML Documentation**: Required on ALL public members
  - `<summary>`: Describe purpose
  - `<param>`: Describe each parameter
  - `<returns>`: Describe return value
  - `<exception>`: Document thrown exceptions
  - `<example>`: Provide usage examples for complex APIs

### **Validation**
- Use Data Annotations: `[Required]`, `[StringLength]`, `[EmailAddress]`, `[Range]`
- FluentValidation for complex validation logic
- Validate at API boundary (controllers/commands)
- Return meaningful error messages

### **Async/Await**
- All I/O operations MUST be async
- Use `async`/`await` keywords properly
- Avoid `async void` (except event handlers)
- Use `ConfigureAwait(false)` in library code (optional in ASP.NET Core)

### **Logging**
- Use `ILogger<T>` for all logging
- Log at appropriate levels (Trace, Debug, Info, Warning, Error, Critical)
- Include correlation IDs for request tracking
- Never log sensitive data (passwords, tokens, PII, encryption keys)
- Use structured logging with named parameters

### **Error Handling**
- Use try-catch blocks for expected exceptions
- Create custom exception types for domain errors
- Log exceptions with full context
- Return user-friendly error messages
- Include correlation IDs in error responses

### **Null Safety**
- Enable nullable reference types (`<Nullable>enable</Nullable>`)
- Use `?` for nullable types
- Check for null before dereferencing
- Use null-coalescing operators (`??`, `??=`)
- Avoid returning null when possible (use Option/Result types)

### **Constants & Magic Values**
- No magic numbers or strings in code
- Define constants as `const` or `readonly` fields
- Group related constants in static classes
- Use enums for fixed sets of values

## 🏗️ ENTITY PATTERNS (MANDATORY)

### **Base Entity Pattern**
```csharp
[Table("EntityName", Schema = "[ServiceSchema]")]
public class Entity : BaseEntity
{
    private static ILogger<Entity>? _logger;
    
    /// <summary>
    /// Sets the logger for this entity type
    /// </summary>
    public static void SetLogger(ILogger<Entity> logger) => _logger = logger;
    
    // Properties with XML documentation
    /// <summary>Property description</summary>
    public string PropertyName { get; set; } = string.Empty;
    
    // Navigation properties
    /// <summary>Navigation property description</summary>
    public RelatedEntity? RelatedEntity { get; set; }
    
    // Business methods with logging
    /// <summary>Business method description</summary>
    public void BusinessMethod()
    {
        _logger?.LogInformation("Business method called");
        // Implementation
    }
}
```

## 📋 COMMAND/QUERY PATTERNS (MANDATORY)

### **Command Pattern**
```csharp
/// <summary>
/// Command to create a new entity
/// </summary>
/// <param name="Request">Entity creation request</param>
public record CreateEntityCommand([Required] CreateEntityRequest Request) : IRequest<EntityDto>;
```

### **Query Pattern**
```csharp
/// <summary>
/// Query to retrieve entity by ID
/// </summary>
/// <param name="Id">Entity identifier</param>
public record GetEntityByIdQuery([Required] Guid Id) : IRequest<EntityDto?>;
```

### **Handler Pattern**
```csharp
/// <summary>
/// Handler for CreateEntityCommand
/// </summary>
public class CreateEntityCommandHandler : IRequestHandler<CreateEntityCommand, EntityDto>
{
    private readonly IEntityRepository _repository;
    private readonly ILogger<CreateEntityCommandHandler> _logger;

    public CreateEntityCommandHandler(
        IEntityRepository repository,
        ILogger<CreateEntityCommandHandler> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<EntityDto> Handle(CreateEntityCommand command, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling CreateEntityCommand");
        // Implementation
    }
}
```

## 🎯 CONTROLLER PATTERNS (MANDATORY)

### **Base Controller**
```csharp
/// <summary>
/// Base controller with common functionality
/// </summary>
[ApiController]
[Authorize]
public abstract class BaseController : ControllerBase
{
    protected readonly IMediator _mediator;
    protected readonly ILogger _logger;

    protected BaseController(IMediator mediator, ILogger logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Gets correlation ID from request context
    /// </summary>
    protected string CorrelationId =>
        HttpContext.Items["CorrelationId"]?.ToString() ?? Guid.NewGuid().ToString();
}
```

### **Entity Controller**
```csharp
/// <summary>
/// Controller for entity management
/// </summary>
[Route("api/[controller]")]
[ApiVersion("1.0")]
public class EntitiesController : BaseController
{
    /// <summary>
    /// Retrieves entity by ID
    /// </summary>
    /// <param name="id">Entity identifier</param>
    /// <returns>Entity details</returns>
    /// <response code="200">Returns entity details</response>
    /// <response code="404">Entity not found</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(EntityDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<EntityDto>> GetById(Guid id)
    {
        // Implementation with proper error handling
    }
}
```

## 📊 VALIDATION PATTERNS (MANDATORY)

### **Data Annotations**
```csharp
public class EntityRequest
{
    /// <summary>Entity name (1-100 characters)</summary>
    [Required(ErrorMessage = "Name is required")]
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Name must be 1-100 characters")]
    public string Name { get; set; } = string.Empty;
    
    /// <summary>Valid email address</summary>
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    [StringLength(255, ErrorMessage = "Email cannot exceed 255 characters")]
    public string Email { get; set; } = string.Empty;
    
    /// <summary>Age between 18-120</summary>
    [Range(18, 120, ErrorMessage = "Age must be between 18 and 120")]
    public int Age { get; set; }
    
    /// <summary>Valid GUID identifier</summary>
    [Required(ErrorMessage = "Id is required")]
    public Guid Id { get; set; }
}
```

### **FluentValidation**
```csharp
/// <summary>
/// Validator for CreateEntityRequest
/// </summary>
public class CreateEntityRequestValidator : AbstractValidator<CreateEntityRequest>
{
    public CreateEntityRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .Length(1, 100).WithMessage("Name must be 1-100 characters");
            
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");
            
        RuleFor(x => x.Id)
            .NotEmpty().WithMessage("Id is required")
            .Must(id => id != Guid.Empty).WithMessage("Id cannot be empty GUID");
    }
}
```

## 🚨 ERROR HANDLING PATTERNS (MANDATORY)

### **Custom Exceptions**
```csharp
/// <summary>
/// Exception thrown when validation fails
/// </summary>
public class ValidationException : Exception
{
    public ValidationException(string message) : base(message) { }
}

/// <summary>
/// Exception thrown when entity is not found
/// </summary>
public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message) { }
}

/// <summary>
/// Exception thrown when duplicate entity exists
/// </summary>
public class DuplicateEntityException : Exception
{
    public DuplicateEntityException(string message) : base(message) { }
}
```

### **Error Handling in Methods**
```csharp
/// <summary>
/// Handles entity operations with comprehensive error handling
/// </summary>
public async Task<EntityDto> ProcessAsync(EntityRequest request)
{
    try
    {
        _logger.LogInformation("Processing entity request for {Name}", request.Name);
        
        // Validation
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new ValidationException("Name cannot be empty");
            
        // Business logic
        var result = await _repository.CreateAsync(request);
        
        _logger.LogInformation("Successfully processed entity {Id}", result.Id);
        return result;
    }
    catch (ValidationException ex)
    {
        _logger.LogWarning("Validation failed: {Message}", ex.Message);
        throw;
    }
    catch (DuplicateEntityException ex)
    {
        _logger.LogWarning("Duplicate entity: {Message}", ex.Message);
        throw;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Unexpected error processing entity");
        throw;
    }
}
```

## 📋 NAMING CONVENTIONS (MANDATORY)

### **General Rules**
- Use PascalCase for classes, methods, properties, constants
- Use camelCase for local variables, parameters, private fields
- Use UPPER_CASE for const values (optional, PascalCase also acceptable)
- Prefix interfaces with `I` (e.g., `IUserService`)
- Prefix private fields with `_` (e.g., `_repository`)

### **Specific Conventions**
- **Entities**: Singular noun (e.g., `User`, `Role`, `AccessToken`)
- **DTOs**: Entity name + `Dto` (e.g., `UserDto`, `RoleDto`)
- **Requests**: Action + Entity + `Request` (e.g., `CreateUserRequest`)
- **Commands**: Action + Entity + `Command` (e.g., `CreateUserCommand`)
- **Queries**: `Get` + Entity + `By` + Criteria + `Query` (e.g., `GetUserByIdQuery`)
- **Handlers**: Command/Query name + `Handler` (e.g., `CreateUserCommandHandler`)
- **Validators**: Request name + `Validator` (e.g., `CreateUserRequestValidator`)
- **Repositories**: Entity + `Repository` (e.g., `UserRepository`)
- **Services**: Entity + `Service` (e.g., `UserService`)
- **Controllers**: Entity plural + `Controller` (e.g., `UsersController`)

### **Method Naming**
- Use verbs for methods (e.g., `CreateUser`, `GetById`, `UpdateEntity`)
- Async methods end with `Async` (e.g., `CreateUserAsync`, `GetByIdAsync`)
- Boolean methods start with `Is`, `Has`, `Can` (e.g., `IsValid`, `HasPermission`)

## 🎨 CODE FORMATTING (MANDATORY)

### **Indentation & Spacing**
- Use 4 spaces for indentation (not tabs)
- One statement per line
- One declaration per line
- Add blank lines between logical sections
- No trailing whitespace

### **Braces**
- Opening brace on same line (K&R style) for methods, classes
- Always use braces for if/else/for/while (even single statements)

### **Line Length**
- Prefer lines under 120 characters
- Break long lines at logical points
- Indent continuation lines

### **File Organization**
```csharp
// 1. Using statements (sorted)
using System;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;

// 2. Namespace
namespace WealthAndFiduciary.FullView.ServiceName.Layer
{
    // 3. Class documentation
    /// <summary>
    /// Class description
    /// </summary>
    public class ClassName
    {
        // 4. Private fields
        private readonly ILogger<ClassName> _logger;
        
        // 5. Constructor
        public ClassName(ILogger<ClassName> logger)
        {
            _logger = logger;
        }
        
        // 6. Public properties
        public string PropertyName { get; set; }
        
        // 7. Public methods
        public void PublicMethod() { }
        
        // 8. Private methods
        private void PrivateMethod() { }
    }
}
```

## 🔍 CODE REVIEW CHECKLIST

### **Before Submitting**
- [ ] All public members have XML documentation
- [ ] No magic numbers or strings
- [ ] Proper error handling with try-catch
- [ ] Logging at appropriate levels
- [ ] No sensitive data in logs
- [ ] Async/await used correctly
- [ ] Null checks where needed
- [ ] Tests written and passing
- [ ] Code follows naming conventions
- [ ] No compiler warnings

### **During Review**
- [ ] Follows Clean Architecture principles
- [ ] SOLID principles applied
- [ ] No business logic in controllers
- [ ] Proper dependency injection
- [ ] Security considerations addressed
- [ ] Performance considerations addressed
- [ ] Code is readable and maintainable

## 🎓 BEST PRACTICES

### **Do's**
- ✅ Write self-documenting code
- ✅ Keep methods small and focused
- ✅ Use meaningful variable names
- ✅ Handle errors gracefully
- ✅ Log important operations
- ✅ Write tests for business logic
- ✅ Use dependency injection
- ✅ Follow SOLID principles

### **Don'ts**
- ❌ Don't use magic values
- ❌ Don't catch and swallow exceptions
- ❌ Don't log sensitive data
- ❌ Don't use `async void` (except event handlers)
- ❌ Don't violate layer dependencies
- ❌ Don't put business logic in controllers
- ❌ Don't skip error handling
- ❌ Don't skip documentation

---

**Note**: Service-specific coding standards can extend these standards but should not contradict them. When conflicts arise, service-specific standards take precedence for that service only.

ALWAYS generate code following these exact patterns for ALL microservices.
