# BUSINESS UNIT TESTING STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific testing standards override these when conflicts exist

## 🎯 TESTING PHILOSOPHY (MANDATORY)

All microservices follow a comprehensive testing strategy with multiple layers of validation to ensure correctness, reliability, and maintainability. **Testing is not optional** - it's a core part of the development process.

## 📊 TEST PYRAMID (MANDATORY)

```
        /\
       /  \      E2E/System Tests (Few)
      /____\
     /      \    Integration Tests (Some)
    /________\
   /          \  Unit Tests (Many)
  /____________\
 /              \ Property-Based Tests (Foundation)
/________________\
```

## 🧪 TESTING LAYERS (MANDATORY)

### **Property-Based Testing (PBT)**
- **Purpose**: Validate universal correctness properties across all possible inputs
- **Framework**: FsCheck or CsCheck for .NET
- **Iterations**: Minimum 100 iterations per property test
- **When**: For business logic, algorithms, data transformations
- **Example Properties**:
  - Round-trip properties (serialize → deserialize = identity)
  - Invariants (entity.Id never changes after creation)
  - Idempotence (calling operation twice = calling once)
  - Commutativity (order doesn't matter)

### **Unit Testing**
- **Purpose**: Test individual components in isolation
- **Framework**: xUnit
- **Mocking**: Moq for dependencies
- **Assertions**: FluentAssertions for readable tests
- **Coverage**: 80% minimum for Domain and Application layers
- **Focus**: Business logic, validation, edge cases

### **Integration Testing**
- **Purpose**: Test component interactions with real dependencies
- **Database**: In-memory database (EF Core InMemory) for fast execution
- **API Testing**: WebApplicationFactory for controller tests
- **Focus**: Repository operations, service integrations, API endpoints

### **Acceptance Testing** (Optional)
- **Purpose**: Validate business requirements in human-readable format
- **Framework**: SpecFlow with Gherkin syntax
- **Format**: Given-When-Then scenarios
- **Focus**: User workflows, business rules, end-to-end scenarios

### **System Testing** (Optional)
- **Purpose**: Validate complete system behavior with real infrastructure
- **Database**: Real SQL Server and/or PostgreSQL
- **Focus**: End-to-end workflows, performance, cross-database compatibility

## 📝 TEST NAMING CONVENTIONS (MANDATORY)

### **Unit Tests**
```csharp
// Pattern: MethodName_Scenario_ExpectedBehavior
public void CreateUser_WithValidData_ReturnsCreatedUser()
public void CreateUser_WithDuplicateUsername_ThrowsValidationException()
public void IsValid_WhenTokenExpired_ReturnsFalse()
```

### **Property Tests**
```csharp
// Pattern: Property_Description
[Property]
public Property EntityIdentityInitialization()

[Property]
public Property EncryptionRoundTrip()

[Property]
public Property RepositoryAddRetrieveRoundTrip()
```

### **Integration Tests**
```csharp
// Pattern: Endpoint_Scenario_ExpectedResult
public async Task GetUserById_WithValidId_Returns200AndUser()
public async Task CreateUser_WithInvalidData_Returns400()
public async Task DeleteUser_WhenNotFound_Returns404()
```

## 🏗️ TEST PROJECT STRUCTURE (MANDATORY)

```
[ServiceName].UnitTests/
├── Domain/
│   ├── Entities/
│   │   └── [Entity]Tests.cs
│   └── Enums/
│       └── [Enum]Tests.cs
├── Application/
│   ├── Commands/
│   │   └── [Entity]/
│   │       └── [Command]HandlerTests.cs
│   ├── Queries/
│   │   └── [Entity]/
│   │       └── [Query]HandlerTests.cs
│   └── Validators/
│       └── [Entity]/
│           └── [Validator]Tests.cs
└── Builders/
    ├── [Entity]Builder.cs
    └── CommonTestData.cs

[ServiceName].IntegrationTests/
├── Controllers/
│   └── [Entity]ControllerTests.cs
├── Repositories/
│   └── [Entity]RepositoryTests.cs
├── Fixtures/
│   ├── CustomWebApplicationFactory.cs
│   ├── DatabaseFixture.cs
│   └── TestDataSeeder.cs
└── [ServiceSpecific]/
    └── [Feature]Tests.cs

[ServiceName].AcceptanceTests/ (Optional)
├── Features/
│   └── [Feature].feature
├── StepDefinitions/
│   └── [Feature]Steps.cs
└── Hooks/
    └── TestHooks.cs
```

## 🔧 TEST INFRASTRUCTURE PATTERNS (MANDATORY)

### **Test Builders (Fluent API)**
```csharp
public class EntityBuilder
{
    private Entity _entity = new Entity
    {
        Name = "test-entity",
        Enabled = true
    };

    public EntityBuilder WithName(string name)
    {
        _entity.Name = name;
        return this;
    }

    public EntityBuilder AsDisabled()
    {
        _entity.Enabled = false;
        return this;
    }

    public Entity Build() => _entity;
}

// Usage:
var entity = new EntityBuilder()
    .WithName("custom-name")
    .Build();
```

### **Test Fixtures (Shared Setup)**
```csharp
public class DatabaseFixture : IDisposable
{
    public DbContext Context { get; }

    public DatabaseFixture()
    {
        var options = new DbContextOptionsBuilder<DbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        
        Context = new DbContext(options);
        SeedTestData();
    }

    private void SeedTestData()
    {
        // Add common test data
    }

    public void Dispose()
    {
        Context.Database.EnsureDeleted();
        Context.Dispose();
    }
}

// Usage:
public class RepositoryTests : IClassFixture<DatabaseFixture>
{
    private readonly DatabaseFixture _fixture;

    public RepositoryTests(DatabaseFixture fixture)
    {
        _fixture = fixture;
    }
}
```

### **Property Test Generators**
```csharp
public static class Generators
{
    public static Arbitrary<Entity> Entity() =>
        Arb.From(
            from name in Arb.Generate<NonEmptyString>()
            from enabled in Arb.Generate<bool>()
            select new Entity
            {
                Name = name.Get,
                Enabled = enabled
            });
}
```

## ✅ CHECKPOINT PATTERN (MANDATORY)

Every spec includes checkpoint tasks to ensure incremental validation:

```markdown
- [ ] X. Checkpoint - Ensure [component] tests pass
  - Run all [component] tests and verify 100% pass rate
  - Verify code coverage meets requirements
  - Review test output for warnings or issues
  - Ensure all tests pass, ask the user if questions arise
```

**Rules for Checkpoints**:
1. Always ask user before proceeding if tests fail
2. Never skip checkpoints to "save time"
3. Fix failing tests immediately
4. Document any test failures for user review

## 🎯 COVERAGE REQUIREMENTS (MANDATORY)

### **Minimum Coverage Targets**
- **Domain Layer**: 80% line coverage
- **Application Layer**: 80% line coverage
- **Infrastructure Layer**: 70% line coverage (harder to test)
- **API Layer**: 70% line coverage (integration tests cover most)

### **What to Test**
- ✅ Business logic and domain methods
- ✅ Validation rules
- ✅ Error handling paths
- ✅ Edge cases and boundary conditions
- ✅ State transitions
- ❌ Auto-generated code (DTOs, simple properties)
- ❌ Third-party library code
- ❌ Configuration classes

## 🚫 TESTING ANTI-PATTERNS TO AVOID (MANDATORY)

### **Don't Test Implementation Details**
```csharp
// ❌ BAD: Testing private methods
[Fact]
public void PrivateMethod_DoesX() { }

// ✅ GOOD: Test public behavior
[Fact]
public void PublicMethod_WithInput_ProducesExpectedOutput() { }
```

### **Don't Use Magic Values**
```csharp
// ❌ BAD: Magic values
var entity = new Entity { Name = "abc123", Value = 42 };

// ✅ GOOD: Named constants or builders
var entity = new EntityBuilder()
    .WithName(TestConstants.ValidName)
    .WithValue(TestConstants.ValidValue)
    .Build();
```

### **Don't Write Brittle Tests**
```csharp
// ❌ BAD: Depends on exact error message
Assert.Equal("Name must be between 3 and 50 characters", exception.Message);

// ✅ GOOD: Check error type and key information
Assert.IsType<ValidationException>(exception);
Assert.Contains("Name", exception.Message);
```

### **Don't Mock Everything**
```csharp
// ❌ BAD: Over-mocking
var mockLogger = new Mock<ILogger>();
var mockDateTime = new Mock<IDateTime>();
var mockGuid = new Mock<IGuidGenerator>();

// ✅ GOOD: Mock only external dependencies
var mockRepository = new Mock<IRepository>();
var mockExternalService = new Mock<IExternalService>();
```

## 📊 TEST EXECUTION (MANDATORY)

### **Local Development**
```bash
# Run all tests
dotnet test

# Run specific test project
dotnet test tests/[ServiceName].UnitTests

# Run with coverage
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover

# Run property tests with more iterations
dotnet test -- FsCheck.MaxTest=1000
```

### **CI/CD Pipeline**
- All tests run on every PR
- Code coverage enforced (80% minimum for Domain/Application)
- Performance tests run on main branch (optional)
- Nightly builds run extended test suites (optional)

## 🔍 DEBUGGING FAILED TESTS (MANDATORY)

### **Property Test Failures**
When a property test fails, it provides a counterexample:
```
Property failed after 42 tests with seed 12345
Counterexample:
  name = ""
  value = -1
```

**Triage Steps**:
1. Is the test incorrect? → Fix the test
2. Is it a bug in the code? → Fix the code
3. Is the specification wrong? → Ask the user

### **Integration Test Failures**
- Check database state
- Review logs for exceptions
- Verify test data setup
- Check for timing issues
- Ensure test isolation

## 🎓 TESTING BEST PRACTICES (MANDATORY)

1. **Arrange-Act-Assert**: Structure all tests with clear sections
2. **One Assertion Per Test**: Focus on single behavior
3. **Test Behavior, Not Implementation**: Test what, not how
4. **Fast Tests**: Unit tests should run in milliseconds
5. **Isolated Tests**: No dependencies between tests
6. **Readable Tests**: Tests are documentation
7. **Maintainable Tests**: Refactor tests like production code

## 📚 RECOMMENDED RESOURCES

- **xUnit Documentation**: https://xunit.net/
- **Moq Documentation**: https://github.com/moq/moq4
- **FluentAssertions**: https://fluentassertions.com/
- **FsCheck**: https://fscheck.github.io/FsCheck/
- **SpecFlow**: https://specflow.org/ (for acceptance tests)

---

**Note**: Service-specific testing standards can extend these standards with additional test types or patterns but should not contradict these baseline requirements.

ALWAYS follow these testing standards when implementing ANY microservice.
