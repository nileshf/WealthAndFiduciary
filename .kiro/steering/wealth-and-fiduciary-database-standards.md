# BUSINESS UNIT DATABASE STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific database standards override these when conflicts exist

## 🎯 DATABASE AGNOSTIC PHILOSOPHY (MANDATORY)

All microservices MUST be database-agnostic to enable:
- Easy switching between SQL Server, PostgreSQL, MySQL, etc.
- Environment-specific database choices (dev vs production)
- Cost optimization (use cheaper databases in non-production)
- Vendor independence and flexibility

## 🏗️ DATABASE ABSTRACTION (MANDATORY)

### Entity Framework Core

**Use EF Core for ALL data access:**
- Provides database-agnostic abstraction
- Supports SQL Server, PostgreSQL, MySQL, SQLite, Oracle, etc.
- Handles migrations across different databases
- Enables easy database switching via configuration

### Supported Databases

**Primary Databases:**
- **SQL Server** - Enterprise applications, financial services
- **PostgreSQL** - Open-source, JSON support, vector extensions
- **MySQL** - Web applications, high read workloads
- **SQLite** - Development, testing, embedded scenarios

**Configuration-Driven Selection:**
- Database provider selected via `appsettings.json`
- No code changes required to switch databases
- Connection strings environment-specific

## 📋 PROJECT STRUCTURE (MANDATORY)

```
[ServiceName].Infrastructure/
├── Data/
│   ├── [ServiceName]DbContext.cs
│   ├── Configurations/
│   │   ├── EntityConfiguration.cs
│   │   └── ...
│   └── Migrations/
│       ├── SqlServer/
│       │   └── [Timestamp]_InitialCreate.cs
│       ├── PostgreSql/
│       │   └── [Timestamp]_InitialCreate.cs
│       └── MySql/
│           └── [Timestamp]_InitialCreate.cs
├── DependencyInjection.cs
└── README.md
```

## ⚙️ CONFIGURATION STANDARDS (MANDATORY)

### appsettings.json Structure

```json
{
  "DatabaseProvider": "SqlServer",
  "ConnectionStrings": {
    "SqlServer": "Server=localhost;Database=[ServiceName];Trusted_Connection=True;TrustServerCertificate=True;",
    "PostgreSql": "Host=localhost;Database=[ServiceName];Username=postgres;Password=postgres;",
    "MySql": "Server=localhost;Database=[ServiceName];User=root;Password=root;",
    "SQLite": "Data Source=[ServiceName].db"
  },
  "DatabaseOptions": {
    "EnableSensitiveDataLogging": false,
    "EnableDetailedErrors": false,
    "CommandTimeout": 30,
    "MaxRetryCount": 3,
    "MaxRetryDelay": 30
  }
}
```

### Environment-Specific Configuration

**appsettings.Development.json:**
```json
{
  "DatabaseProvider": "SQLite",
  "ConnectionStrings": {
    "SQLite": "Data Source=[ServiceName]_dev.db"
  },
  "DatabaseOptions": {
    "EnableSensitiveDataLogging": true,
    "EnableDetailedErrors": true
  }
}
```

**appsettings.Staging.json:**
```json
{
  "DatabaseProvider": "PostgreSql",
  "ConnectionStrings": {
    "PostgreSql": "Host=staging-db.example.com;Database=[ServiceName];Username=app_user;Password=${DB_PASSWORD};"
  }
}
```

**appsettings.Production.json:**
```json
{
  "DatabaseProvider": "SqlServer",
  "ConnectionStrings": {
    "SqlServer": "Server=prod-db.example.com;Database=[ServiceName];User Id=app_user;Password=${DB_PASSWORD};Encrypt=True;"
  }
}
```

## 🔧 DEPENDENCY INJECTION SETUP (MANDATORY)

### DependencyInjection.cs

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace [ServiceName].Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Get database provider from configuration
        var databaseProvider = configuration["DatabaseProvider"] 
            ?? throw new InvalidOperationException("DatabaseProvider not configured");

        // Register DbContext with appropriate provider
        services.AddDbContext<[ServiceName]DbContext>((serviceProvider, options) =>
        {
            ConfigureDatabase(options, databaseProvider, configuration);
            
            // Apply common options
            var dbOptions = configuration.GetSection("DatabaseOptions");
            
            if (dbOptions.GetValue<bool>("EnableSensitiveDataLogging"))
                options.EnableSensitiveDataLogging();
            
            if (dbOptions.GetValue<bool>("EnableDetailedErrors"))
                options.EnableDetailedErrors();
            
            options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
        });

        // Register repositories
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
        services.AddScoped<IUserRepository, UserRepository>();
        // ... other repositories

        return services;
    }

    private static void ConfigureDatabase(
        DbContextOptionsBuilder options,
        string provider,
        IConfiguration configuration)
    {
        var dbOptions = configuration.GetSection("DatabaseOptions");
        var commandTimeout = dbOptions.GetValue<int>("CommandTimeout", 30);
        var maxRetryCount = dbOptions.GetValue<int>("MaxRetryCount", 3);
        var maxRetryDelay = dbOptions.GetValue<int>("MaxRetryDelay", 30);

        switch (provider.ToLower())
        {
            case "sqlserver":
                var sqlServerConnection = configuration.GetConnectionString("SqlServer")
                    ?? throw new InvalidOperationException("SqlServer connection string not configured");
                
                options.UseSqlServer(sqlServerConnection, sqlOptions =>
                {
                    sqlOptions.CommandTimeout(commandTimeout);
                    sqlOptions.EnableRetryOnFailure(
                        maxRetryCount: maxRetryCount,
                        maxRetryDelay: TimeSpan.FromSeconds(maxRetryDelay),
                        errorNumbersToAdd: null);
                    sqlOptions.MigrationsHistoryTable("__EFMigrationsHistory", "[ServiceName]");
                });
                break;

            case "postgresql":
            case "postgres":
                var postgresConnection = configuration.GetConnectionString("PostgreSql")
                    ?? throw new InvalidOperationException("PostgreSql connection string not configured");
                
                options.UseNpgsql(postgresConnection, npgsqlOptions =>
                {
                    npgsqlOptions.CommandTimeout(commandTimeout);
                    npgsqlOptions.EnableRetryOnFailure(
                        maxRetryCount: maxRetryCount,
                        maxRetryDelay: TimeSpan.FromSeconds(maxRetryDelay));
                    npgsqlOptions.MigrationsHistoryTable("__EFMigrationsHistory", "[ServiceName]");
                });
                break;

            case "mysql":
                var mysqlConnection = configuration.GetConnectionString("MySql")
                    ?? throw new InvalidOperationException("MySql connection string not configured");
                
                options.UseMySql(mysqlConnection, ServerVersion.AutoDetect(mysqlConnection), mysqlOptions =>
                {
                    mysqlOptions.CommandTimeout(commandTimeout);
                    mysqlOptions.EnableRetryOnFailure(
                        maxRetryCount: maxRetryCount,
                        maxRetryDelay: TimeSpan.FromSeconds(maxRetryDelay));
                    mysqlOptions.MigrationsHistoryTable("__EFMigrationsHistory", "[ServiceName]");
                });
                break;

            case "sqlite":
                var sqliteConnection = configuration.GetConnectionString("SQLite")
                    ?? throw new InvalidOperationException("SQLite connection string not configured");
                
                options.UseSqlite(sqliteConnection, sqliteOptions =>
                {
                    sqliteOptions.CommandTimeout(commandTimeout);
                    sqliteOptions.MigrationsHistoryTable("__EFMigrationsHistory");
                });
                break;

            default:
                throw new InvalidOperationException($"Unsupported database provider: {provider}");
        }
    }
}
```

## 📊 DBCONTEXT IMPLEMENTATION (MANDATORY)

### Database-Agnostic DbContext

```csharp
using Microsoft.EntityFrameworkCore;

namespace [ServiceName].Infrastructure.Data;

public class [ServiceName]DbContext : DbContext
{
    public [ServiceName]DbContext(DbContextOptions<[ServiceName]DbContext> options)
        : base(options)
    {
    }

    // DbSets
    public DbSet<Entity> Entities { get; set; }
    public DbSet<User> Users { get; set; }
    // ... other DbSets

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply configurations
        modelBuilder.ApplyConfigurationsFromAssembly(typeof([ServiceName]DbContext).Assembly);

        // Apply database-specific configurations
        ApplyDatabaseSpecificConfigurations(modelBuilder);
    }

    private void ApplyDatabaseSpecificConfigurations(ModelBuilder modelBuilder)
    {
        var databaseProvider = Database.ProviderName;

        switch (databaseProvider)
        {
            case "Microsoft.EntityFrameworkCore.SqlServer":
                // SQL Server specific configurations
                modelBuilder.Entity<Entity>()
                    .Property(e => e.CreatedDate)
                    .HasDefaultValueSql("GETUTCDATE()");
                break;

            case "Npgsql.EntityFrameworkCore.PostgreSQL":
                // PostgreSQL specific configurations
                modelBuilder.Entity<Entity>()
                    .Property(e => e.CreatedDate)
                    .HasDefaultValueSql("NOW()");
                break;

            case "Pomelo.EntityFrameworkCore.MySql":
                // MySQL specific configurations
                modelBuilder.Entity<Entity>()
                    .Property(e => e.CreatedDate)
                    .HasDefaultValueSql("UTC_TIMESTAMP()");
                break;

            case "Microsoft.EntityFrameworkCore.Sqlite":
                // SQLite specific configurations
                modelBuilder.Entity<Entity>()
                    .Property(e => e.CreatedDate)
                    .HasDefaultValueSql("datetime('now')");
                break;
        }
    }
}
```

## 🔄 MIGRATION MANAGEMENT (MANDATORY)

### Separate Migrations per Database

**Generate Migrations:**
```bash
# SQL Server
dotnet ef migrations add InitialCreate \
  --context [ServiceName]DbContext \
  --output-dir Data/Migrations/SqlServer \
  -- --DatabaseProvider SqlServer

# PostgreSQL
dotnet ef migrations add InitialCreate \
  --context [ServiceName]DbContext \
  --output-dir Data/Migrations/PostgreSql \
  -- --DatabaseProvider PostgreSql

# MySQL
dotnet ef migrations add InitialCreate \
  --context [ServiceName]DbContext \
  --output-dir Data/Migrations/MySql \
  -- --DatabaseProvider MySql

# SQLite
dotnet ef migrations add InitialCreate \
  --context [ServiceName]DbContext \
  --output-dir Data/Migrations/SQLite \
  -- --DatabaseProvider SQLite
```

**Apply Migrations:**
```bash
# Development (SQLite)
dotnet ef database update --context [ServiceName]DbContext

# Staging (PostgreSQL)
dotnet ef database update --context [ServiceName]DbContext -- --DatabaseProvider PostgreSql

# Production (SQL Server)
dotnet ef database update --context [ServiceName]DbContext -- --DatabaseProvider SqlServer
```

### Migration Helper Script

**migrate-database.ps1:**
```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("SqlServer", "PostgreSql", "MySql", "SQLite")]
    [string]$Provider,
    
    [Parameter(Mandatory=$true)]
    [string]$MigrationName
)

$outputDir = "Data/Migrations/$Provider"

Write-Host "Generating migration for $Provider..." -ForegroundColor Green

dotnet ef migrations add $MigrationName `
    --context [ServiceName]DbContext `
    --output-dir $outputDir `
    -- --DatabaseProvider $Provider

if ($LASTEXITCODE -eq 0) {
    Write-Host "Migration generated successfully!" -ForegroundColor Green
} else {
    Write-Host "Migration generation failed!" -ForegroundColor Red
    exit 1
}
```

## 🚫 DATABASE-SPECIFIC CODE TO AVOID (MANDATORY)

### ❌ Don't Use Database-Specific SQL

```csharp
// ❌ BAD: SQL Server specific
context.Database.ExecuteSqlRaw("SELECT GETDATE()");

// ✅ GOOD: Database agnostic
var now = DateTime.UtcNow;
```

### ❌ Don't Use Database-Specific Functions

```csharp
// ❌ BAD: SQL Server specific
query.Where(e => EF.Functions.DateDiffDay(e.CreatedDate, DateTime.UtcNow) > 30);

// ✅ GOOD: Database agnostic
var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);
query.Where(e => e.CreatedDate < thirtyDaysAgo);
```

### ❌ Don't Use Database-Specific Data Types

```csharp
// ❌ BAD: SQL Server specific
[Column(TypeName = "datetime2")]
public DateTime CreatedDate { get; set; }

// ✅ GOOD: Database agnostic
public DateTime CreatedDate { get; set; }
```

## ✅ DATABASE-AGNOSTIC PATTERNS (MANDATORY)

### Use EF Core Abstractions

```csharp
// ✅ GOOD: Use EF.Functions for database functions
query.Where(e => EF.Functions.Like(e.Name, "%search%"));

// ✅ GOOD: Use DateTime methods
query.Where(e => e.CreatedDate.Date == DateTime.UtcNow.Date);

// ✅ GOOD: Use standard LINQ
query.OrderBy(e => e.Name).ThenBy(e => e.CreatedDate);
```

### Use Database-Agnostic Configurations

```csharp
public class EntityConfiguration : IEntityTypeConfiguration<Entity>
{
    public void Configure(EntityTypeBuilder<Entity> builder)
    {
        builder.ToTable("Entities", "[ServiceName]");
        
        builder.HasKey(e => e.Id);
        
        builder.Property(e => e.Name)
            .IsRequired()
            .HasMaxLength(200);
        
        builder.Property(e => e.CreatedDate)
            .IsRequired();
        
        // Use HasDefaultValueSql in DbContext.OnModelCreating for database-specific defaults
    }
}
```

## 🧪 TESTING WITH MULTIPLE DATABASES (MANDATORY)

### Integration Tests

```csharp
public class DatabaseIntegrationTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public DatabaseIntegrationTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }

    [Theory]
    [InlineData("SqlServer")]
    [InlineData("PostgreSql")]
    [InlineData("MySql")]
    [InlineData("SQLite")]
    public async Task Repository_CRUD_WorksOnAllDatabases(string provider)
    {
        // Arrange
        var context = _fixture.CreateContext(provider);
        var repository = new EntityRepository(context);
        var entity = new Entity { Name = "Test" };

        // Act
        await repository.AddAsync(entity);
        var retrieved = await repository.GetByIdAsync(entity.Id);

        // Assert
        retrieved.Should().NotBeNull();
        retrieved.Name.Should().Be("Test");
    }
}
```

## 📚 DOCUMENTATION (MANDATORY)

### README.md

```markdown
# [ServiceName] Database Configuration

## Supported Databases

- SQL Server 2022+
- PostgreSQL 15+
- MySQL 8.0+
- SQLite 3.0+

## Configuration

Set the database provider in `appsettings.json`:

```json
{
  "DatabaseProvider": "SqlServer"
}
```

## Connection Strings

Configure connection strings for each provider:

```json
{
  "ConnectionStrings": {
    "SqlServer": "Server=localhost;Database=[ServiceName];...",
    "PostgreSql": "Host=localhost;Database=[ServiceName];...",
    "MySql": "Server=localhost;Database=[ServiceName];...",
    "SQLite": "Data Source=[ServiceName].db"
  }
}
```

## Migrations

Generate migrations for each database:

```bash
# SQL Server
.\migrate-database.ps1 -Provider SqlServer -MigrationName InitialCreate

# PostgreSQL
.\migrate-database.ps1 -Provider PostgreSql -MigrationName InitialCreate
```

Apply migrations:

```bash
dotnet ef database update
```

## Switching Databases

1. Update `DatabaseProvider` in `appsettings.json`
2. Update connection string
3. Apply migrations: `dotnet ef database update`
4. Restart application
```

## 🎓 BEST PRACTICES

### Do's
- ✅ Use EF Core for all data access
- ✅ Test on multiple databases
- ✅ Use database-agnostic LINQ queries
- ✅ Generate separate migrations per database
- ✅ Use configuration for database selection
- ✅ Document supported databases

### Don'ts
- ❌ Don't use raw SQL queries
- ❌ Don't use database-specific functions
- ❌ Don't hardcode database provider
- ❌ Don't use database-specific data types
- ❌ Don't skip testing on target databases

---

**Note**: Service-specific database standards can extend these standards but should not contradict them.

ALWAYS ensure database agnosticism for ALL microservices.
