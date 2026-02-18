# Implementation Guide

## Quick Start

### For SecurityService Implementation

1. **Read the Specification**
   ```
   cat Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/requirements.md
   cat Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/design.md
   cat Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/tasks.md
   ```

2. **Start Phase 2: Core Authentication**
   - Begin with task 2.1: Implement User Entity and Database Configuration
   - Follow the subtasks in order
   - Create entities in Domain layer first
   - Then create DbContext in Infrastructure layer
   - Finally create database migration

3. **Execute Build and Tests**
   ```powershell
   # Run optimized build
   ./build-optimized.ps1
   
   # Or run individual commands
   dotnet restore
   dotnet build -m
   dotnet test --parallel
   ```

4. **Verify Progress**
   - Check that all unit tests pass
   - Verify code coverage meets requirements
   - Review code for compliance with standards

---

### For DataLoaderService Implementation

1. **Read the Specification**
   ```
   cat Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/requirements.md
   cat Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/design.md
   cat Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/tasks.md
   ```

2. **Start Phase 2: Core File Upload**
   - Begin with task 2.1: Implement File Entity and Database Configuration
   - Follow the subtasks in order
   - Create entities in Domain layer first
   - Then create DbContext in Infrastructure layer
   - Finally create database migration

3. **Execute Build and Tests**
   ```powershell
   # Run optimized build
   ./build-optimized.ps1
   
   # Or run individual commands
   dotnet restore
   dotnet build -m
   dotnet test --parallel
   ```

4. **Verify Progress**
   - Check that all unit tests pass
   - Verify code coverage meets requirements
   - Review code for compliance with standards

---

## Implementation Workflow

### Step 1: Understand the Requirements
- Read user stories to understand what users need
- Review acceptance criteria to understand what "done" means
- Identify any ambiguities and clarify with team

### Step 2: Review the Design
- Understand the architecture and layer structure
- Review API endpoints and their contracts
- Understand data models and relationships
- Review security considerations

### Step 3: Execute Tasks in Order
- Start with Phase 2 (Core features)
- Complete all subtasks for each task
- Write tests as you implement
- Verify each subtask works before moving to next

### Step 4: Run Tests and Verify
- Run unit tests: `dotnet test --filter "Category=Unit"`
- Run integration tests: `dotnet test --filter "Category=Integration"`
- Run all tests: `dotnet test`
- Verify code coverage: `dotnet test /p:CollectCoverage=true`

### Step 5: Code Review
- Ensure all code follows business unit coding standards
- Ensure all public members have XML documentation
- Ensure proper error handling and logging
- Ensure security best practices are followed

### Step 6: Move to Next Phase
- Only move to next phase after all tests pass
- Only move to next phase after code review passes
- Update task checkboxes as you complete tasks

---

## Task Execution Checklist

For each task, follow this checklist:

- [ ] Read task description and understand requirements
- [ ] Review subtasks and understand what needs to be done
- [ ] Create necessary files/classes in appropriate layers
- [ ] Implement functionality according to design
- [ ] Write unit tests for the functionality
- [ ] Run tests and verify they pass
- [ ] Review code for compliance with standards
- [ ] Update task checkbox to mark as complete
- [ ] Move to next task

---

## Common Commands

### Build and Test
```powershell
# Optimized build (recommended)
./build-optimized.ps1

# Manual build
dotnet restore
dotnet build -m
dotnet test --parallel

# Run specific test category
dotnet test --filter "Category=Unit"
dotnet test --filter "Category=Integration"
dotnet test --filter "Category=Property"

# Run with code coverage
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

### Database Migrations
```powershell
# Create migration
dotnet ef migrations add MigrationName --context SecurityDbContext

# Update database
dotnet ef database update --context SecurityDbContext

# Remove last migration
dotnet ef migrations remove --context SecurityDbContext
```

### Code Quality
```powershell
# Check for compiler warnings
dotnet build /p:TreatWarningsAsErrors=true

# Run code analysis
dotnet build /p:EnforceCodeStyleInBuild=true

# Format code
dotnet format
```

---

## Phase Completion Criteria

Each phase is complete when:

1. ✅ All tasks in the phase are marked as complete
2. ✅ All unit tests pass (100% pass rate)
3. ✅ All integration tests pass (100% pass rate)
4. ✅ Code coverage meets minimum requirements:
   - Domain layer: ≥ 80%
   - Application layer: ≥ 80%
   - Infrastructure layer: ≥ 70%
5. ✅ Code review passes (all standards met)
6. ✅ No compiler warnings
7. ✅ No security issues

---

## Troubleshooting

### Build Fails
- Check that all NuGet packages are restored: `dotnet restore`
- Check that all project files are valid
- Check for compiler errors: `dotnet build`

### Tests Fail
- Run tests with verbose output: `dotnet test --verbosity detailed`
- Check test output for specific error messages
- Verify test data is set up correctly
- Check that all dependencies are mocked/injected correctly

### Code Coverage Low
- Identify untested code paths
- Add unit tests for missing coverage
- Add integration tests for API endpoints
- Use code coverage reports to identify gaps

### Performance Issues
- Check that in-memory database is being used for tests
- Check that property-based test iterations are set to 50 (not 100)
- Check that tests are running in parallel: `dotnet test --parallel`
- Use build optimization script: `./build-optimized.ps1`

---

## Standards and Best Practices

### Code Standards
- Follow business unit coding standards (see `.kiro/steering/wealth-and-fiduciary-coding-standards.md`)
- Use Clean Architecture principles
- Follow SOLID principles
- Use meaningful variable and method names
- Add XML documentation to all public members

### Testing Standards
- Write unit tests for all business logic
- Write integration tests for API endpoints
- Write property-based tests for universal properties
- Use descriptive test names: `MethodName_Scenario_ExpectedBehavior`
- Aim for 80%+ code coverage

### Security Standards
- Never log sensitive data (passwords, tokens, PII)
- Use PBKDF2 for password hashing (100,000 iterations)
- Use JWT for token generation
- Encrypt sensitive data at rest (AES-256)
- Validate all user input
- Check permissions before allowing access

### Documentation Standards
- Add XML documentation to all public members
- Include parameter descriptions
- Include return value descriptions
- Include exception descriptions
- Add examples for complex APIs

---

## Getting Help

### Documentation
- Business Unit Standards: `.kiro/steering/wealth-and-fiduciary-*.md`
- Application Architecture: `.kiro/steering/Applications/AITooling/app-architecture.md`
- Service-Specific Rules: `.kiro/steering/Applications/AITooling/services/[Service]/`

### Code Examples
- Review existing code in the service
- Review test examples for patterns
- Review other services for similar implementations

### Questions
- Ask team members for clarification
- Review design document for architectural decisions
- Check requirements for acceptance criteria

---

## Success Metrics

### Code Quality
- ✅ 100% test pass rate
- ✅ 80%+ code coverage
- ✅ 0 compiler warnings
- ✅ 0 security issues
- ✅ All standards met

### Performance
- ✅ Build time: < 8 minutes
- ✅ Test execution: < 5 minutes
- ✅ API response time: < 500ms
- ✅ Database query time: < 1 second

### Functionality
- ✅ All user stories implemented
- ✅ All acceptance criteria met
- ✅ All API endpoints working
- ✅ All data models correct

---

## Timeline

### SecurityService
- Phase 2 (Core Auth): 1-2 weeks
- Phase 3 (User Mgmt): 1 week
- Phase 4 (Authorization): 1 week
- Phase 5 (Security): 1 week
- Phase 6 (Testing): 1 week
- **Total**: 5-7 weeks

### DataLoaderService
- Phase 2 (File Upload): 1-2 weeks
- Phase 3 (CSV Processing): 1-2 weeks
- Phase 4 (Data Access): 1 week
- Phase 5 (File Mgmt): 1 week
- Phase 6 (Security): 1 week
- Phase 7 (Testing): 1 week
- **Total**: 6-8 weeks

---

## Next Steps

1. **Choose a service to start with**
   - SecurityService (recommended first - other services depend on it)
   - DataLoaderService (can be done in parallel)

2. **Read the specification**
   - Requirements: Understand user stories and acceptance criteria
   - Design: Understand architecture and implementation approach
   - Tasks: Understand detailed implementation tasks

3. **Start Phase 2 implementation**
   - Follow tasks in order
   - Write tests as you implement
   - Verify each task works before moving to next

4. **Execute checkpoint tasks**
   - Run tests after each phase
   - Verify code coverage
   - Review code for standards compliance

5. **Move to next phase**
   - Only after all tests pass
   - Only after code review passes
   - Update task checkboxes

---

**Ready to start? Pick a service and begin Phase 2!**

For SecurityService: `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/tasks.md`

For DataLoaderService: `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/tasks.md`
