# Spec Analysis: WEALTHFID-396

## Jira Issue Summary
- **Key**: WEALTHFID-396
- **Title**: Add data validation logic
- **Description**: 
- **Status**: To Do
- **Assignee**: Unassigned
- **Priority**: Medium
- **Reporter**: Nilesh Arvind Fakira
- **Created**: 2026-02-19T10:18:46.231+0200
- **Updated**: 2026-02-19T10:18:47.975+0200

## Kiro's Suggestion

Based on the task **"Add data validation logic"** and the **DataLoaderService** service standards, here's what you should consider:

**Focus Areas:**
1. **Review service-specific rules** - Check \Applications/AITooling/Services/DataLoaderService/.kiro/steering/\ for patterns
2. **Database selection** - AITooling uses PostgreSQL (per \pp-architecture.md\)
3. **Validation requirements** - Follow 80%+ coverage for validation logic
4. **PII handling** - Encrypt PII at rest (AES-256) per security standards
5. **Testing strategy** - Property-based tests for universal properties (FsCheck/CsCheck)

**Recommended Approach:**
- Start with \equirements.md\ defining validation rules and acceptance criteria
- Design should include validation pipeline with clear separation of concerns
- Tasks should cover: validation logic, error reporting, and test coverage
- Follow CQRS pattern with MediatR for commands/queries

**Service-Specific Considerations:**
- Follow \data-loader-service-rules.md\ for file processing patterns (if DataLoaderService)
- Use PostgreSQL database with pgvector extension (AITooling standard)
- Implement property-based tests for validation rules
- Ensure 80%+ coverage for Domain/Application layers
- Add XML documentation per coding standards
- Update Swagger documentation for API endpoints

## Spec Structure Recommendation

### 1. Requirements.md
**Location**: \Applications/AITooling/Services/DataLoaderService/.kiro/specs/add-data-validation-logic/requirements.md\

**Recommended Sections**:
- User Stories
- Acceptance Criteria
- Edge Cases

**Notes**: Review the issue description to identify user stories and acceptance criteria.

### 2. Design.md
**Location**: \Applications/AITooling/Services/DataLoaderService/.kiro/specs/add-data-validation-logic/design.md\

**Recommended Sections**:
- Architecture Decision
- Data Model
- API Endpoints
- Testing Strategy

**Notes**: Follow the four-level hierarchy standards. Review service-specific rules in \Applications/AITooling/Services/DataLoaderService/.kiro/steering/\.

### 3. Tasks.md
**Location**: \Applications/AITooling/Services/DataLoaderService/.kiro/specs/add-data-validation-logic/tasks.md\

**Recommended Tasks**:
- Create command/query and handler
- Add validation logic
- Implement business logic
- Add unit tests (80% coverage minimum)
- Add integration tests (70% coverage minimum)
- Update Swagger documentation
- Add XML documentation

**Notes**: Follow CQRS pattern with MediatR. Use xUnit for unit tests, Moq for mocking.

## Code Examples

### Command/Query Pattern (following your coding standards)
\\\csharp
/// <summary>
/// Add data validation logic
/// </summary>
public record UploadCsvCommand([Required] IFormFile File, [Required] Guid TenantId) : IRequest<CsvUploadResult>;

/// <summary>
/// Handler for UploadCsvCommand
/// </summary>
public class UploadCsvCommandHandler : IRequestHandler<UploadCsvCommand, CsvUploadResult>
{
    private readonly IRepository _repository;
    private readonly ILogger<UploadCsvCommandHandler> _logger;

    public async Task<CsvUploadResult> Handle(UploadCsvCommand command, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Handling UploadCsvCommand");
        
        // Implementation here
    }
}
\\\

## Related Files

- **Service Steering**: \Applications/AITooling/Services/DataLoaderService/.kiro/steering/\
- **AITooling Architecture**: \../../../../../.kiro/steering/app-architecture.md\
- **Business Unit Standards**: \../../../../../../.kiro/steering/wealth-and-fiduciary-*.md\

## Next Steps for Developer

1. **Review the recommendations above**
2. **Create the spec structure**:
   \\\powershell
   mkdir Applications/AITooling/Services/DataLoaderService/.kiro/specs/add-data-validation-logic
   \\\
3. **Create \equirements.md\** with user stories and acceptance criteria
4. **Create \design.md\** with architecture and implementation details
5. **Create \	asks.md\** with implementation tasks
6. **Follow the four-level hierarchy standards**
7. **Run pre-commit checks** before syncing to Jira

## Why This Approach?

- **Per-task granularity**: Each Jira task gets its own spec analysis document
- **Context-aware**: Kiro tailors recommendations based on the specific task
- **Developer-guided**: Kiro suggests, developer implements (no automatic changes)
- **Consistent**: All specs follow the same structure and your business unit standards
- **Educational**: Clear examples and explanations for developers

---
*Generated by Kiro AI - Step 4 Spec Analysis*
*Service: DataLoaderService | Issue: WEALTHFID-396 | Date: 2026-02-19 10:19:31*
