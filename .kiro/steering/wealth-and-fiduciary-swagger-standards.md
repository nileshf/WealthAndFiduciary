# BUSINESS UNIT SWAGGER/OPENAPI STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific Swagger standards override these when conflicts exist

## 🎯 SWAGGER PHILOSOPHY (MANDATORY)

All microservices MUST provide comprehensive Swagger/OpenAPI documentation to enable:
- Interactive API exploration and testing
- Automatic client SDK generation
- API contract validation
- Developer onboarding
- Integration with external systems

## 🏗️ SWAGGER CONFIGURATION (MANDATORY)

### Swashbuckle Setup

**Install NuGet Packages:**
```xml
<PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
<PackageReference Include="Swashbuckle.AspNetCore.Annotations" Version="6.5.0" />
<PackageReference Include="Swashbuckle.AspNetCore.Filters" Version="8.0.0" />
```

### Program.cs Configuration

```csharp
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.Filters;
using System.Reflection;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();

// Configure Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    // API Information
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Version = "v1",
        Title = "[ServiceName] API",
        Description = "API for [ServiceName] - [Brief Description]",
        Contact = new OpenApiContact
        {
            Name = "WealthAndFiduciary Team",
            Email = "team@example.com",
            Url = new Uri("https://example.com/contact")
        },
        License = new OpenApiLicense
        {
            Name = "Proprietary",
            Url = new Uri("https://example.com/license")
        }
    });

    // JWT Bearer Authentication
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token in the text input below. Example: 'Bearer 12345abcdef'",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });

    // XML Comments
    var xmlFilename = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFilename);
    options.IncludeXmlComments(xmlPath);

    // Enable Annotations
    options.EnableAnnotations();

    // Example Filters
    options.ExampleFilters();

    // Custom Schema IDs
    options.CustomSchemaIds(type => type.FullName);

    // Operation Filters
    options.OperationFilter<AppendAuthorizeToSummaryOperationFilter>();
    options.OperationFilter<SecurityRequirementsOperationFilter>();

    // Document Filters
    options.DocumentFilter<CustomDocumentFilter>();
});

// Register example providers
builder.Services.AddSwaggerExamplesFromAssemblyOf<Program>();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment() || app.Environment.IsStaging())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "[ServiceName] API v1");
        options.RoutePrefix = string.Empty; // Serve Swagger UI at root
        options.DocumentTitle = "[ServiceName] API Documentation";
        options.DefaultModelsExpandDepth(2);
        options.DefaultModelExpandDepth(2);
        options.DisplayRequestDuration();
        options.EnableDeepLinking();
        options.EnableFilter();
        options.ShowExtensions();
        options.EnableValidator();
    });
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### Enable XML Documentation

**[ServiceName].Api.csproj:**
```xml
<PropertyGroup>
  <GenerateDocumentationFile>true</GenerateDocumentationFile>
  <NoWarn>$(NoWarn);1591</NoWarn>
</PropertyGroup>
```

## 📋 CONTROLLER DOCUMENTATION (MANDATORY)

### Controller-Level Documentation

```csharp
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace [ServiceName].Api.Controllers;

/// <summary>
/// Manages entity operations including creation, retrieval, and lifecycle management
/// </summary>
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
[Produces("application/json")]
[Consumes("application/json")]
[SwaggerTag("Entity management endpoints for creating, retrieving, and managing entities")]
public class EntitiesController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<EntitiesController> _logger;

    /// <summary>
    /// Initializes a new instance of the EntitiesController
    /// </summary>
    /// <param name="mediator">MediatR instance for CQRS</param>
    /// <param name="logger">Logger instance</param>
    public EntitiesController(IMediator mediator, ILogger<EntitiesController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }
}
```

## 📝 ENDPOINT DOCUMENTATION (MANDATORY)

### GET Endpoint Example

```csharp
/// <summary>
/// Retrieves an entity by its unique identifier
/// </summary>
/// <param name="id">The unique identifier of the entity</param>
/// <returns>The entity details</returns>
/// <response code="200">Returns the entity details</response>
/// <response code="401">Unauthorized - Missing or invalid authentication token</response>
/// <response code="403">Forbidden - User does not have permission to access this entity</response>
/// <response code="404">Not Found - Entity with the specified ID does not exist</response>
/// <response code="500">Internal Server Error - An unexpected error occurred</response>
[HttpGet("{id}")]
[Authorize]
[SwaggerOperation(
    Summary = "Get entity by ID",
    Description = "Retrieves a single entity by its unique identifier. Requires authentication and appropriate permissions.",
    OperationId = "GetEntityById",
    Tags = new[] { "Entities" }
)]
[SwaggerResponse(200, "Entity retrieved successfully", typeof(EntityDto))]
[SwaggerResponse(401, "Unauthorized - Missing or invalid token")]
[SwaggerResponse(403, "Forbidden - Insufficient permissions")]
[SwaggerResponse(404, "Not Found - Entity does not exist", typeof(ProblemDetails))]
[SwaggerResponse(500, "Internal Server Error", typeof(ProblemDetails))]
[ProducesResponseType(typeof(EntityDto), StatusCodes.Status200OK)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
public async Task<ActionResult<EntityDto>> GetById(
    [FromRoute, SwaggerParameter("The unique identifier of the entity", Required = true)] Guid id)
{
    _logger.LogInformation("Getting entity with ID: {EntityId}", id);
    
    var query = new GetEntityByIdQuery(id);
    var result = await _mediator.Send(query);
    
    if (result == null)
    {
        return NotFound(new ProblemDetails
        {
            Type = "https://api.example.com/errors/not-found",
            Title = "Entity Not Found",
            Status = StatusCodes.Status404NotFound,
            Detail = $"Entity with ID {id} was not found",
            Instance = HttpContext.Request.Path
        });
    }
    
    return Ok(result);
}
```

### POST Endpoint Example

```csharp
/// <summary>
/// Creates a new entity
/// </summary>
/// <param name="request">The entity creation request</param>
/// <returns>The created entity</returns>
/// <response code="201">Entity created successfully</response>
/// <response code="400">Bad Request - Invalid input data</response>
/// <response code="401">Unauthorized - Missing or invalid authentication token</response>
/// <response code="403">Forbidden - User does not have permission to create entities</response>
/// <response code="409">Conflict - Entity with same identifier already exists</response>
/// <response code="500">Internal Server Error - An unexpected error occurred</response>
[HttpPost]
[Authorize(Roles = "Agent")]
[SwaggerOperation(
    Summary = "Create a new entity",
    Description = "Creates a new entity with the provided details. Requires Agent role. The entity will be created in Draft status.",
    OperationId = "CreateEntity",
    Tags = new[] { "Entities" }
)]
[SwaggerResponse(201, "Entity created successfully", typeof(EntityDto))]
[SwaggerResponse(400, "Bad Request - Validation failed", typeof(ValidationProblemDetails))]
[SwaggerResponse(401, "Unauthorized - Missing or invalid token")]
[SwaggerResponse(403, "Forbidden - Requires Agent role")]
[SwaggerResponse(409, "Conflict - Duplicate entity", typeof(ProblemDetails))]
[SwaggerResponse(500, "Internal Server Error", typeof(ProblemDetails))]
[ProducesResponseType(typeof(EntityDto), StatusCodes.Status201Created)]
[ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
public async Task<ActionResult<EntityDto>> Create(
    [FromBody, SwaggerRequestBody("Entity creation request", Required = true)] CreateEntityRequest request)
{
    _logger.LogInformation("Creating new entity: {EntityName}", request.Name);
    
    var command = new CreateEntityCommand(
        request.Name,
        request.IdentificationNumber,
        request.Email,
        request.PhoneNumber,
        request.TransactionValue
    );
    
    var result = await _mediator.Send(command);
    
    return CreatedAtAction(
        nameof(GetById),
        new { id = result.Id },
        result
    );
}
```

### PUT Endpoint Example

```csharp
/// <summary>
/// Updates an existing entity
/// </summary>
/// <param name="id">The unique identifier of the entity to update</param>
/// <param name="request">The entity update request</param>
/// <returns>The updated entity</returns>
/// <response code="200">Entity updated successfully</response>
/// <response code="400">Bad Request - Invalid input data</response>
/// <response code="401">Unauthorized - Missing or invalid authentication token</response>
/// <response code="403">Forbidden - User does not have permission to update this entity</response>
/// <response code="404">Not Found - Entity with the specified ID does not exist</response>
/// <response code="500">Internal Server Error - An unexpected error occurred</response>
[HttpPut("{id}")]
[Authorize(Roles = "Agent")]
[SwaggerOperation(
    Summary = "Update an entity",
    Description = "Updates an existing entity with the provided details. Requires Agent role.",
    OperationId = "UpdateEntity",
    Tags = new[] { "Entities" }
)]
[SwaggerResponse(200, "Entity updated successfully", typeof(EntityDto))]
[SwaggerResponse(400, "Bad Request - Validation failed", typeof(ValidationProblemDetails))]
[SwaggerResponse(401, "Unauthorized - Missing or invalid token")]
[SwaggerResponse(403, "Forbidden - Requires Agent role")]
[SwaggerResponse(404, "Not Found - Entity does not exist", typeof(ProblemDetails))]
[SwaggerResponse(500, "Internal Server Error", typeof(ProblemDetails))]
[ProducesResponseType(typeof(EntityDto), StatusCodes.Status200OK)]
[ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
public async Task<ActionResult<EntityDto>> Update(
    [FromRoute, SwaggerParameter("The unique identifier of the entity", Required = true)] Guid id,
    [FromBody, SwaggerRequestBody("Entity update request", Required = true)] UpdateEntityRequest request)
{
    _logger.LogInformation("Updating entity with ID: {EntityId}", id);
    
    var command = new UpdateEntityCommand(id, request);
    var result = await _mediator.Send(command);
    
    return Ok(result);
}
```

### DELETE Endpoint Example

```csharp
/// <summary>
/// Deletes an entity
/// </summary>
/// <param name="id">The unique identifier of the entity to delete</param>
/// <returns>No content</returns>
/// <response code="204">Entity deleted successfully</response>
/// <response code="401">Unauthorized - Missing or invalid authentication token</response>
/// <response code="403">Forbidden - User does not have permission to delete this entity</response>
/// <response code="404">Not Found - Entity with the specified ID does not exist</response>
/// <response code="409">Conflict - Entity cannot be deleted in its current state</response>
/// <response code="500">Internal Server Error - An unexpected error occurred</response>
[HttpDelete("{id}")]
[Authorize(Roles = "Manager")]
[SwaggerOperation(
    Summary = "Delete an entity",
    Description = "Soft deletes an entity. Requires Manager role. Entity must not be in Active status.",
    OperationId = "DeleteEntity",
    Tags = new[] { "Entities" }
)]
[SwaggerResponse(204, "Entity deleted successfully")]
[SwaggerResponse(401, "Unauthorized - Missing or invalid token")]
[SwaggerResponse(403, "Forbidden - Requires Manager role")]
[SwaggerResponse(404, "Not Found - Entity does not exist", typeof(ProblemDetails))]
[SwaggerResponse(409, "Conflict - Cannot delete active entity", typeof(ProblemDetails))]
[SwaggerResponse(500, "Internal Server Error", typeof(ProblemDetails))]
[ProducesResponseType(StatusCodes.Status204NoContent)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status409Conflict)]
[ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status500InternalServerError)]
public async Task<IActionResult> Delete(
    [FromRoute, SwaggerParameter("The unique identifier of the entity", Required = true)] Guid id)
{
    _logger.LogInformation("Deleting entity with ID: {EntityId}", id);
    
    var command = new DeleteEntityCommand(id);
    await _mediator.Send(command);
    
    return NoContent();
}
```

## 📦 DTO DOCUMENTATION (MANDATORY)

### Request DTO Example

```csharp
using System.ComponentModel.DataAnnotations;
using Swashbuckle.AspNetCore.Annotations;

namespace [ServiceName].Application.DTOs;

/// <summary>
/// Request model for creating a new entity
/// </summary>
[SwaggerSchema(
    Title = "Create Entity Request",
    Description = "Contains all required and optional fields for creating a new entity"
)]
public class CreateEntityRequest
{
    /// <summary>
    /// The full name of the entity
    /// </summary>
    /// <example>John Doe</example>
    [Required(ErrorMessage = "Name is required")]
    [StringLength(200, MinimumLength = 1, ErrorMessage = "Name must be between 1 and 200 characters")]
    [SwaggerSchema("The full name of the entity (1-200 characters)", Nullable = false)]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// The identification number (ID number for RICA/FICA, passport for Travel)
    /// </summary>
    /// <example>8001015009087</example>
    [Required(ErrorMessage = "Identification number is required")]
    [StringLength(100, ErrorMessage = "Identification number cannot exceed 100 characters")]
    [SwaggerSchema("Identification number - SA ID for RICA/FICA, passport for Travel", Nullable = false)]
    public string IdentificationNumber { get; set; } = string.Empty;

    /// <summary>
    /// The email address of the entity
    /// </summary>
    /// <example>john.doe@example.com</example>
    [Required(ErrorMessage = "Email is required")]
    [EmailAddress(ErrorMessage = "Invalid email format")]
    [StringLength(255, ErrorMessage = "Email cannot exceed 255 characters")]
    [SwaggerSchema("Valid email address", Nullable = false)]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// The phone number of the entity (optional)
    /// </summary>
    /// <example>+27821234567</example>
    [Phone(ErrorMessage = "Invalid phone number format")]
    [StringLength(20, ErrorMessage = "Phone number cannot exceed 20 characters")]
    [SwaggerSchema("Phone number in international format (optional)", Nullable = true)]
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// The transaction value (optional, used for approval routing)
    /// </summary>
    /// <example>7500.00</example>
    [Range(0, double.MaxValue, ErrorMessage = "Transaction value must be positive")]
    [SwaggerSchema("Transaction value in local currency (optional)", Nullable = true)]
    public decimal? TransactionValue { get; set; }
}
```

### Response DTO Example

```csharp
using Swashbuckle.AspNetCore.Annotations;

namespace [ServiceName].Application.DTOs;

/// <summary>
/// Response model containing entity details
/// </summary>
[SwaggerSchema(
    Title = "Entity Response",
    Description = "Contains complete entity information including status and verification details"
)]
public class EntityDto
{
    /// <summary>
    /// The unique identifier of the entity
    /// </summary>
    /// <example>3fa85f64-5717-4562-b3fc-2c963f66afa6</example>
    [SwaggerSchema("Unique identifier (GUID)", Nullable = false)]
    public Guid Id { get; set; }

    /// <summary>
    /// The full name of the entity
    /// </summary>
    /// <example>John Doe</example>
    [SwaggerSchema("Full name", Nullable = false)]
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// The identification number
    /// </summary>
    /// <example>8001015009087</example>
    [SwaggerSchema("Identification number", Nullable = false)]
    public string IdentificationNumber { get; set; } = string.Empty;

    /// <summary>
    /// The email address
    /// </summary>
    /// <example>john.doe@example.com</example>
    [SwaggerSchema("Email address", Nullable = false)]
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// The phone number
    /// </summary>
    /// <example>+27821234567</example>
    [SwaggerSchema("Phone number", Nullable = true)]
    public string? PhoneNumber { get; set; }

    /// <summary>
    /// The current status of the entity
    /// </summary>
    /// <example>Verified</example>
    [SwaggerSchema("Current status (Draft, Verified, PendingApproval, Approved, Rejected, Active)", Nullable = false)]
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// The transaction value
    /// </summary>
    /// <example>7500.00</example>
    [SwaggerSchema("Transaction value", Nullable = true)]
    public decimal? TransactionValue { get; set; }

    /// <summary>
    /// The date and time when verification was performed
    /// </summary>
    /// <example>2025-01-15T10:30:00Z</example>
    [SwaggerSchema("Verification timestamp (UTC)", Nullable = true)]
    public DateTime? VerificationDate { get; set; }

    /// <summary>
    /// The result of the verification process
    /// </summary>
    /// <example>Verification successful</example>
    [SwaggerSchema("Verification result message", Nullable = true)]
    public string? VerificationResult { get; set; }

    /// <summary>
    /// The date and time when the entity was created
    /// </summary>
    /// <example>2025-01-15T09:00:00Z</example>
    [SwaggerSchema("Creation timestamp (UTC)", Nullable = false)]
    public DateTime CreatedDate { get; set; }
}
```

## 🎯 EXAMPLE PROVIDERS (MANDATORY)

### Request Example Provider

```csharp
using Swashbuckle.AspNetCore.Filters;

namespace [ServiceName].Api.Examples;

/// <summary>
/// Provides example data for CreateEntityRequest
/// </summary>
public class CreateEntityRequestExample : IExamplesProvider<CreateEntityRequest>
{
    public CreateEntityRequest GetExamples()
    {
        return new CreateEntityRequest
        {
            Name = "John Doe",
            IdentificationNumber = "8001015009087",
            Email = "john.doe@example.com",
            PhoneNumber = "+27821234567",
            TransactionValue = 7500.00m
        };
    }
}
```

### Response Example Provider

```csharp
using Swashbuckle.AspNetCore.Filters;

namespace [ServiceName].Api.Examples;

/// <summary>
/// Provides example data for EntityDto
/// </summary>
public class EntityDtoExample : IExamplesProvider<EntityDto>
{
    public EntityDto GetExamples()
    {
        return new EntityDto
        {
            Id = Guid.Parse("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
            Name = "John Doe",
            IdentificationNumber = "8001015009087",
            Email = "john.doe@example.com",
            PhoneNumber = "+27821234567",
            Status = "Verified",
            TransactionValue = 7500.00m,
            VerificationDate = DateTime.UtcNow.AddMinutes(-30),
            VerificationResult = "Verification successful",
            CreatedDate = DateTime.UtcNow.AddHours(-1)
        };
    }
}
```

## 🔧 CUSTOM FILTERS (MANDATORY)

### Document Filter

```csharp
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace [ServiceName].Api.Filters;

/// <summary>
/// Custom document filter to add additional metadata
/// </summary>
public class CustomDocumentFilter : IDocumentFilter
{
    public void Apply(OpenApiDocument swaggerDoc, DocumentFilterContext context)
    {
        // Add custom metadata
        swaggerDoc.Info.Extensions.Add("x-api-id", new Microsoft.OpenApi.Any.OpenApiString("[ServiceName]"));
        swaggerDoc.Info.Extensions.Add("x-audience", new Microsoft.OpenApi.Any.OpenApiString("internal"));
        
        // Add server URLs
        swaggerDoc.Servers = new List<OpenApiServer>
        {
            new OpenApiServer { Url = "https://localhost:5001", Description = "Development" },
            new OpenApiServer { Url = "https://staging-api.example.com", Description = "Staging" },
            new OpenApiServer { Url = "https://api.example.com", Description = "Production" }
        };
        
        // Sort endpoints alphabetically
        var paths = swaggerDoc.Paths.OrderBy(p => p.Key).ToDictionary(p => p.Key, p => p.Value);
        swaggerDoc.Paths = new OpenApiPaths();
        foreach (var path in paths)
        {
            swaggerDoc.Paths.Add(path.Key, path.Value);
        }
    }
}
```

## 📚 HEALTH CHECK ENDPOINTS (MANDATORY)

```csharp
/// <summary>
/// Health check endpoints for monitoring
/// </summary>
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
[SwaggerTag("Health check endpoints for monitoring and diagnostics")]
public class HealthController : ControllerBase
{
    /// <summary>
    /// Basic health check
    /// </summary>
    /// <returns>Health status</returns>
    /// <response code="200">Service is healthy</response>
    /// <response code="503">Service is unhealthy</response>
    [HttpGet]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Health check",
        Description = "Returns the health status of the service",
        OperationId = "GetHealth",
        Tags = new[] { "Health" }
    )]
    [SwaggerResponse(200, "Service is healthy")]
    [SwaggerResponse(503, "Service is unhealthy")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public IActionResult GetHealth()
    {
        return Ok(new { status = "Healthy", timestamp = DateTime.UtcNow });
    }

    /// <summary>
    /// Readiness check
    /// </summary>
    /// <returns>Readiness status</returns>
    /// <response code="200">Service is ready</response>
    /// <response code="503">Service is not ready</response>
    [HttpGet("ready")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Readiness check",
        Description = "Returns whether the service is ready to accept requests",
        OperationId = "GetReadiness",
        Tags = new[] { "Health" }
    )]
    [SwaggerResponse(200, "Service is ready")]
    [SwaggerResponse(503, "Service is not ready")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public IActionResult GetReadiness()
    {
        // Check database connection, external dependencies, etc.
        return Ok(new { status = "Ready", timestamp = DateTime.UtcNow });
    }

    /// <summary>
    /// Liveness check
    /// </summary>
    /// <returns>Liveness status</returns>
    /// <response code="200">Service is alive</response>
    [HttpGet("live")]
    [AllowAnonymous]
    [SwaggerOperation(
        Summary = "Liveness check",
        Description = "Returns whether the service is alive",
        OperationId = "GetLiveness",
        Tags = new[] { "Health" }
    )]
    [SwaggerResponse(200, "Service is alive")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult GetLiveness()
    {
        return Ok(new { status = "Alive", timestamp = DateTime.UtcNow });
    }
}
```

## 🎓 BEST PRACTICES

### Do's
- ✅ Document ALL endpoints with XML comments
- ✅ Provide example requests and responses
- ✅ Document all response codes
- ✅ Use SwaggerOperation for detailed descriptions
- ✅ Include authentication requirements
- ✅ Document validation rules
- ✅ Provide meaningful error examples
- ✅ Keep Swagger UI enabled in development and staging
- ✅ Version your API properly
- ✅ Include health check endpoints

### Don'ts
- ❌ Don't expose Swagger in production (security risk)
- ❌ Don't skip XML documentation
- ❌ Don't use generic error messages
- ❌ Don't forget to document query parameters
- ❌ Don't skip example providers
- ❌ Don't use unclear parameter names
- ❌ Don't forget to document headers

## 📊 SWAGGER UI CUSTOMIZATION (OPTIONAL)

### Custom CSS

```csharp
app.UseSwaggerUI(options =>
{
    options.InjectStylesheet("/swagger-ui/custom.css");
    options.InjectJavascript("/swagger-ui/custom.js");
});
```

**wwwroot/swagger-ui/custom.css:**
```css
.swagger-ui .topbar {
    background-color: #0066CC;
}

.swagger-ui .info .title {
    color: #0066CC;
}
```

---

**Note**: Service-specific Swagger standards can extend these standards but should not contradict them.

ALWAYS provide comprehensive Swagger documentation for ALL microservices.
