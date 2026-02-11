# Design Document

## Introduction

This document describes the design of DataLoaderService, a CSV file processing microservice for the AITooling application. The service follows Clean Architecture principles with clear layer separation and SOLID design principles.

## Architecture Overview

### Clean Architecture Layers

```
DataLoaderService/
├── Domain/                    # No external dependencies
│   ├── DataRecord.cs         # Data entity
│   └── IDataRepository.cs    # Repository interface
├── Application/               # Depends only on Domain
│   └── FileLoaderService.cs  # Business logic
├── Infrastructure/            # Implements Application interfaces
│   ├── DataDbContext.cs      # EF Core DbContext
│   └── DataRepository.cs     # Repository implementation
└── API/                       # Delegates to Application
    └── DataController.cs     # HTTP endpoints
```

### Dependency Flow

```
API → Application → Domain
 ↓       ↓
Infrastructure → Domain
```

**Rules**:
- Domain has no dependencies on other layers
- Application depends only on Domain
- Infrastructure implements Domain interfaces
- API delegates to Application layer

## Technology Stack

### Framework & Runtime
- **.NET 8.0** - Framework
- **ASP.NET Core** - Web API
- **C# 12.0** - Language

### Data Access
- **Entity Framework Core 8.0** - ORM
- **SQL Server** - Database
- **EF Core Migrations** - Schema management

### Libraries
- **CsvHelper 30.0.1** - CSV parsing
- **JWT Bearer Authentication** - Security
- **Swashbuckle** - Swagger/OpenAPI documentation

### Testing (To Be Added)
- **xUnit** - Unit testing framework
- **Moq** - Mocking framework
- **FluentAssertions** - Assertion library
- **FsCheck** - Property-based testing
- **WebApplicationFactory** - Integration testing

## Domain Layer Design

### DataRecord Entity

```csharp
public class DataRecord
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
```

**Properties**:
- `Id`: Auto-generated primary key
- `Name`: Name field from CSV (required)
- `Value`: Value field from CSV (required)
- `CreatedAt`: UTC timestamp when record was created

**Design Decisions**:
- Simple entity with no business logic (data transfer object pattern)
- All properties are required (non-nullable)
- CreatedAt set by application layer, not database default
- No audit fields (CreatedBy, UpdatedAt) in initial version

### IDataRepository Interface

```csharp
public interface IDataRepository
{
    Task<IEnumerable<DataRecord>> GetAllAsync();
    Task AddRangeAsync(IEnumerable<DataRecord> records);
}
```

**Methods**:
- `GetAllAsync`: Retrieve all data records
- `AddRangeAsync`: Batch insert multiple records

**Design Decisions**:
- Minimal interface focused on current requirements
- Batch operations for performance
- Async methods for scalability
- No pagination in initial version (can be added later)

## Application Layer Design

### FileLoaderService

```csharp
public class FileLoaderService
{
    private readonly IDataRepository _dataRepository;

    public async Task<int> LoadFromCsvAsync(Stream fileStream)
    {
        // Parse CSV and create DataRecord entities
        // Save to database via repository
        // Return count of records loaded
    }

    public async Task<IEnumerable<DataRecord>> GetAllDataAsync()
    {
        // Retrieve all records from repository
    }
}
```

**Responsibilities**:
- CSV parsing using CsvHelper
- Data transformation (CSV → DataRecord)
- Batch saving via repository
- Error handling for parsing failures

**Design Decisions**:
- Service accepts Stream (not IFormFile) for testability
- Uses CsvHelper with InvariantCulture for consistent parsing
- Sets CreatedAt timestamp in application layer
- Returns count for user feedback

### CsvRecord DTO

```csharp
public class CsvRecord
{
    public string Name { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}
```

**Purpose**: Maps CSV columns to strongly-typed properties for CsvHelper

## Infrastructure Layer Design

### DataDbContext

```csharp
public class DataDbContext : DbContext
{
    public DbSet<DataRecord> DataRecords { get; set; }
}
```

**Configuration**:
- SQL Server provider
- Connection string from appsettings.json
- No custom entity configurations (using conventions)

**Design Decisions**:
- Simple DbContext with single DbSet
- No schema specified (uses default "dbo")
- No custom table names (uses entity name)

### DataRepository

```csharp
public class DataRepository : IDataRepository
{
    private readonly DataDbContext _context;

    public async Task<IEnumerable<DataRecord>> GetAllAsync()
    {
        return await _context.DataRecords.ToListAsync();
    }

    public async Task AddRangeAsync(IEnumerable<DataRecord> records)
    {
        _context.DataRecords.AddRange(records);
        await _context.SaveChangesAsync();
    }
}
```

**Design Decisions**:
- Direct EF Core usage (no additional abstraction)
- Batch operations for performance
- Single SaveChanges call per batch

## API Layer Design

### DataController

```csharp
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DataController : ControllerBase
{
    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile(IFormFile file)
    {
        // Validate file
        // Delegate to FileLoaderService
        // Return result
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        // Delegate to FileLoaderService
        // Return data
    }
}
```

**Endpoints**:
1. `POST /api/data/upload` - Upload CSV file
2. `GET /api/data` - Retrieve all data

**Design Decisions**:
- [Authorize] attribute on controller (all endpoints require auth)
- Minimal validation in controller (file null/empty check)
- Delegates to application layer for business logic
- Returns simple JSON responses

## Security Design

### JWT Authentication

**Configuration**:
```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(...)
        };
    });
```

**Design Decisions**:
- Same JWT configuration as SecurityService for interoperability
- All validation flags enabled
- Tokens issued by SecurityService, validated by DataLoaderService
- No token generation in this service (authentication only)

### Authorization

**Current Implementation**:
- [Authorize] attribute on all endpoints
- No role-based authorization (all authenticated users can upload)

**Future Enhancements**:
- Role-based authorization (e.g., only "DataUploader" role)
- File size limits
- Rate limiting per user

## Database Design

### Schema

**Table**: `DataRecords` (default schema: dbo)

| Column    | Type         | Nullable | Key     | Description                    |
|-----------|--------------|----------|---------|--------------------------------|
| Id        | int          | No       | Primary | Auto-increment primary key     |
| Name      | nvarchar(max)| No       |         | Name from CSV                  |
| Value     | nvarchar(max)| No       |         | Value from CSV                 |
| CreatedAt | datetime2    | No       |         | UTC timestamp of creation      |

**Indexes**:
- Primary key on Id (clustered)
- No additional indexes in initial version

**Design Decisions**:
- Simple schema matching entity structure
- nvarchar(max) for flexibility (no length constraints)
- datetime2 for precision
- No foreign keys (standalone service)

## Error Handling Design

### Validation Errors

**Scenarios**:
1. No file uploaded → 400 Bad Request
2. Empty file → 400 Bad Request
3. Invalid JWT token → 401 Unauthorized
4. Expired JWT token → 401 Unauthorized

### Parsing Errors

**Scenarios**:
1. Invalid CSV format → 500 Internal Server Error (current)
2. Missing required columns → 500 Internal Server Error (current)

**Future Enhancements**:
- Custom exception types (CsvParsingException)
- Detailed error messages for CSV format issues
- Validation of CSV structure before parsing

### Database Errors

**Scenarios**:
1. Connection failure → 500 Internal Server Error
2. Constraint violation → 500 Internal Server Error

**Current Approach**: Let exceptions bubble up (ASP.NET Core handles)

## Correctness Properties

### Property 1: Data Integrity

**Property 1.1: CSV Round-Trip**
- **Statement**: For any valid CSV file, parsing and storing should preserve all data
- **Test**: Upload CSV → Retrieve data → Verify all records match CSV content
- **Validates**: Requirements 2, 3, 4

**Property 1.2: Timestamp Consistency**
- **Statement**: All records from a single upload should have CreatedAt within 1 second
- **Test**: Upload CSV → Verify all CreatedAt timestamps are close
- **Validates**: Requirement 2.5

### Property 2: Batch Operations

**Property 2.1: Batch Atomicity**
- **Statement**: Either all records are saved or none are saved
- **Test**: Upload CSV → Verify count matches or database is unchanged
- **Validates**: Requirement 3.3

**Property 2.2: Count Accuracy**
- **Statement**: Returned count always matches number of records saved
- **Test**: Upload CSV → Verify returned count equals database count
- **Validates**: Requirement 2.6

### Property 3: Authentication

**Property 3.1: Authentication Required**
- **Statement**: All endpoints require valid JWT token
- **Test**: Call endpoints without token → Verify 401 Unauthorized
- **Validates**: Requirements 1.1, 1.2, 4.1, 7

**Property 3.2: Token Validation**
- **Statement**: Invalid or expired tokens are rejected
- **Test**: Call endpoints with invalid/expired token → Verify 401
- **Validates**: Requirements 7.4, 7.5

### Property 4: CSV Parsing

**Property 4.1: Column Mapping**
- **Statement**: CSV columns Name and Value map correctly to DataRecord
- **Test**: Upload CSV with known values → Verify exact match
- **Validates**: Requirements 2.3, 2.4, 12

**Property 4.2: Empty File Handling**
- **Statement**: Empty files are rejected before parsing
- **Test**: Upload empty file → Verify 400 Bad Request
- **Validates**: Requirement 1.5

## Testing Strategy

### Unit Tests

**Domain Layer**:
- DataRecord entity instantiation
- Property setters and getters

**Application Layer**:
- FileLoaderService.LoadFromCsvAsync with valid CSV
- FileLoaderService.LoadFromCsvAsync with empty stream
- FileLoaderService.GetAllDataAsync returns all records
- CSV parsing with CsvHelper

**Infrastructure Layer**:
- DataRepository.AddRangeAsync saves records
- DataRepository.GetAllAsync retrieves records
- Database operations with in-memory database

### Integration Tests

**API Layer**:
- POST /api/data/upload with valid file and token
- POST /api/data/upload without token (401)
- POST /api/data/upload with empty file (400)
- GET /api/data with valid token
- GET /api/data without token (401)
- End-to-end: Upload → Retrieve → Verify

### Property-Based Tests

**Property Tests**:
- CSV round-trip (upload → retrieve → verify)
- Timestamp consistency across batch
- Count accuracy (returned count = database count)
- Authentication enforcement (all endpoints)

## Performance Considerations

### Current Implementation

**Strengths**:
- Batch insert for multiple records
- Async/await throughout
- Streaming CSV parsing (memory efficient)

**Limitations**:
- No pagination for GET /api/data
- No file size limits
- No connection pooling configuration
- No caching

### Future Optimizations

1. **Pagination**: Add skip/take parameters to GET endpoint
2. **File Size Limits**: Enforce maximum file size (e.g., 10 MB)
3. **Streaming Upload**: Process CSV as it uploads (for large files)
4. **Caching**: Cache frequently accessed data
5. **Indexing**: Add indexes on Name or CreatedAt for queries

## Deployment Considerations

### Configuration

**Required Settings**:
- `ConnectionStrings:DefaultConnection` - SQL Server connection
- `Jwt:Key` - JWT signing key (must match SecurityService)
- `Jwt:Issuer` - JWT issuer (must match SecurityService)
- `Jwt:Audience` - JWT audience (must match SecurityService)

**Environment-Specific**:
- Development: Swagger enabled, local SQL Server
- Production: Swagger disabled, Azure SQL Database, HTTPS enforced

### Database Migrations

**Initial Migration**:
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

**Production Deployment**:
1. Generate migration script
2. Review script
3. Apply to production database
4. Verify schema

### Dependencies

**External Services**:
- SecurityService (for JWT token generation)
- SQL Server (for data storage)

**Shared Configuration**:
- JWT settings must match SecurityService exactly

## Future Enhancements

### Phase 2 Features

1. **File Validation**:
   - File size limits (e.g., 10 MB max)
   - File type validation (ensure it's CSV)
   - Virus scanning integration

2. **Enhanced CSV Support**:
   - Support for additional file formats (Excel, JSON)
   - Custom column mapping
   - Data validation rules
   - Duplicate detection

3. **Data Management**:
   - Pagination for GET endpoint
   - Filtering and sorting
   - Delete endpoint
   - Update endpoint
   - Export functionality

4. **Audit Logging**:
   - Track who uploaded what file
   - Track when data was accessed
   - Immutable audit trail

5. **Performance**:
   - Background processing for large files
   - Progress tracking for uploads
   - Caching for frequently accessed data

6. **Security**:
   - Role-based authorization
   - Rate limiting per user
   - File encryption at rest

## References

- **Requirements**: `./requirements.md`
- **Business Unit Architecture**: `../../../../.kiro/steering/org-architecture.md`
- **Business Unit Coding Standards**: `../../../../.kiro/steering/org-coding-standards.md`
- **Business Unit Testing Standards**: `../../../../.kiro/steering/org-testing-standards.md`
- **SecurityService Design**: `../../SecurityService/.kiro/specs/security-service/design.md`

---

**Last Updated**: January 28, 2026  
**Status**: Initial Design  
**Author**: Kiro AI Assistant
