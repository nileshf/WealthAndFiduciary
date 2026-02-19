#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Step 4: Generate Spec Analysis Documents from Jira Issues
.DESCRIPTION
    For each Jira issue/task in To Do or In Progress, create a spec analysis document.
    If file exists, skip. If not, create with recommendations.
    
    This is a READ-ONLY operation - Kiro suggests, developer implements.
    
    Output: .kiro/specs-docs/[JIRA-KEY]-[feature-name]-spec-analysis.md
.PARAMETER JiraBaseUrl
    Jira base URL (from environment variable JIRA_BASE_URL)
.PARAMETER JiraEmail
    Jira email (from environment variable JIRA_USER_EMAIL)
.PARAMETER JiraToken
    Jira API token (from environment variable JIRA_API_TOKEN)
.PARAMETER ServiceName
    Service name (from environment variable SERVICE_NAME)
.PARAMETER TaskFile
    Path to project-task.md file
.PARAMETER ProjectKey
    Jira project key (from environment variable JIRA_PROJECT_KEY)
.EXAMPLE
    .\scripts\jira-sync-step4-spec-analysis.ps1
#>

param(
    [string]$JiraBaseUrl = $env:JIRA_BASE_URL,
    [string]$JiraEmail = $env:JIRA_USER_EMAIL,
    [string]$JiraToken = $env:JIRA_API_TOKEN,
    [string]$ServiceName = $env:SERVICE_NAME,
    [string]$TaskFile = $env:TASK_FILE,
    [string]$ProjectKey = $env:JIRA_PROJECT_KEY
)

$ErrorActionPreference = 'Continue'

Write-Host "=== Step 4: Spec Analysis from Jira Issues ===" -ForegroundColor Green
Write-Host "Service: $ServiceName"
Write-Host "Task File: $TaskFile"

# Validation
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Host "ERROR: Missing Jira credentials" -ForegroundColor Red
    Write-Host "  JIRA_BASE_URL: $([bool]$JiraBaseUrl)" -ForegroundColor Yellow
    Write-Host "  JIRA_USER_EMAIL: $([bool]$JiraEmail)" -ForegroundColor Yellow
    Write-Host "  JIRA_API_TOKEN: $([bool]$JiraToken) (length: $($JiraToken.Length))" -ForegroundColor Yellow
    $global:Step4Result = 1
    return 1
}

if (-not (Test-Path $TaskFile)) {
    Write-Host "ERROR: Task file not found: $TaskFile" -ForegroundColor Red
    $global:Step4Result = 1
    return 1
}

# Helper: Get Jira Auth
function Get-JiraAuth {
    param([string]$Email, [string]$Token)
    $pair = "$Email`:$Token"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    return $base64
}

# Helper: Get Jira Headers
function Get-JiraHeaders {
    param([string]$Email, [string]$Token)
    return @{
        'Authorization' = "Basic $(Get-JiraAuth -Email $Email -Token $Token)"
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }
}

# Helper: Convert title to kebab-case feature name
function ConvertTo-KebabCase {
    param([string]$Title)
    $title = $Title -replace '[^a-zA-Z0-9\s-]', ''
    $title = $title -replace '\s+', '-'
    $title = $title.ToLower()
    return $title
}

# Fetch Jira issues
Write-Host "`nFetching Jira issues..." -ForegroundColor Cyan
$headers = Get-JiraHeaders -Email $JiraEmail -Token $JiraToken
$jql = "project = $ProjectKey"
$uri = "$JiraBaseUrl/rest/api/3/search/jql?jql=$([System.Uri]::EscapeDataString($jql))&maxResults=100&fields=key,summary,description,status,assignee,priority,created,updated,reporter,issuetype"

try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $jiraIssues = $response.issues
    Write-Host "Found $($jiraIssues.Count) issues in Jira" -ForegroundColor Green
}
catch {
    Write-Host "Failed to fetch Jira issues" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
    $global:Step4Result = 1
    return 1
}

# Create output directory
$outputDir = "Applications/AITooling/Services/$ServiceName/.kiro/specs-docs"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "Created output directory: $outputDir" -ForegroundColor Green
}

# Read tasks from markdown to check status
Write-Host "`nReading tasks from markdown..." -ForegroundColor Cyan
$content = Get-Content $TaskFile -Raw
$lines = $content -split "`n"

# Map checkbox to status
function Get-StatusFromCheckbox {
    param([string]$checkbox)
    switch ($checkbox) {
        ' ' { return 'To Do' }
        '-' { return 'In Progress' }
        '~' { return 'Testing' }
        'x' { return 'Done' }
        default { return 'To Do' }
    }
}

# Process each task line
Write-Host "`nGenerating spec analysis documents..." -ForegroundColor Cyan
$analysisCount = 0

foreach ($line in $lines) {
    if ($line -match '\[([x ~-])\]\s+([A-Z]+-\d+)\s*-\s*(.+)') {
        $checkbox = $matches[1]
        $key = $matches[2]
        $summary = $matches[3]
        
        # Get task status from checkbox
        $taskStatus = Get-StatusFromCheckbox $checkbox
        
        # Only process To Do and In Progress tasks
        if ($taskStatus -ne 'To Do' -and $taskStatus -ne 'In Progress') {
            continue
        }
        
        Write-Host "  Processing: $key - $summary (Status: $taskStatus)" -ForegroundColor Yellow
        
        # Check if analysis file already exists
        $featureName = ConvertTo-KebabCase -Title $summary
        $outputFile = "$outputDir/$key-$featureName-spec-analysis.md"
        
        if (Test-Path $outputFile) {
            Write-Host "    Skipping - file already exists: $outputFile" -ForegroundColor Gray
            continue
        }
        
        # Get issue details from Jira
        $issue = $jiraIssues | Where-Object { $_.key -eq $key }
        if (-not $issue) {
            Write-Host "    Warning: Issue $key not found in Jira results" -ForegroundColor Yellow
            continue
        }
        
        $description = ""
        if ($issue.fields.description) {
            $description = $issue.fields.description
        }
        
        $assignee = "Unassigned"
        if ($issue.fields.assignee -and $issue.fields.assignee.displayName) {
            $assignee = $issue.fields.assignee.displayName
        }
        
        $reporter = "Unknown"
        if ($issue.fields.reporter -and $issue.fields.reporter.displayName) {
            $reporter = $issue.fields.reporter.displayName
        }
        
        $status = $issue.fields.status.name
        $priority = $issue.fields.priority.name
        $created = $issue.fields.created
        $updated = $issue.fields.updated
        
        # Generate spec analysis document
        $analysisDoc = @"
# Spec Analysis: $key

## Jira Issue Summary
- **Key**: $key
- **Title**: $summary
- **Description**: $description
- **Status**: $status
- **Assignee**: $assignee
- **Priority**: $priority
- **Reporter**: $reporter
- **Created**: $created
- **Updated**: $updated

## Kiro's Suggestion

Based on the task **"$summary"** and the **$ServiceName** service standards, here's what you should consider:

**Focus Areas:**
1. **Review service-specific rules** - Check \`Applications/AITooling/Services/$ServiceName/.kiro/steering/\` for patterns
2. **Database selection** - AITooling uses PostgreSQL (per \`app-architecture.md\`)
3. **Validation requirements** - Follow 80%+ coverage for validation logic
4. **PII handling** - Encrypt PII at rest (AES-256) per security standards
5. **Testing strategy** - Property-based tests for universal properties (FsCheck/CsCheck)

**Recommended Approach:**
- Start with \`requirements.md\` defining validation rules and acceptance criteria
- Design should include validation pipeline with clear separation of concerns
- Tasks should cover: validation logic, error reporting, and test coverage
- Follow CQRS pattern with MediatR for commands/queries

**Service-Specific Considerations:**
- Follow \`data-loader-service-rules.md\` for file processing patterns (if DataLoaderService)
- Use PostgreSQL database with pgvector extension (AITooling standard)
- Implement property-based tests for validation rules
- Ensure 80%+ coverage for Domain/Application layers
- Add XML documentation per coding standards
- Update Swagger documentation for API endpoints

## Spec Structure Recommendation

### 1. Requirements.md
**Location**: \`Applications/AITooling/Services/$ServiceName/.kiro/specs/$featureName/requirements.md\`

**Recommended Sections**:
- User Stories
- Acceptance Criteria
- Edge Cases

**Notes**: Review the issue description to identify user stories and acceptance criteria.

### 2. Design.md
**Location**: \`Applications/AITooling/Services/$ServiceName/.kiro/specs/$featureName/design.md\`

**Recommended Sections**:
- Architecture Decision
- Data Model
- API Endpoints
- Testing Strategy

**Notes**: Follow the four-level hierarchy standards. Review service-specific rules in \`Applications/AITooling/Services/$ServiceName/.kiro/steering/\`.

### 3. Tasks.md
**Location**: \`Applications/AITooling/Services/$ServiceName/.kiro/specs/$featureName/tasks.md\`

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
\`\`\`csharp
/// <summary>
/// $summary
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
\`\`\`

## Related Files

- **Service Steering**: \`Applications/AITooling/Services/$ServiceName/.kiro/steering/\`
- **AITooling Architecture**: \`../../../../../.kiro/steering/app-architecture.md\`
- **Business Unit Standards**: \`../../../../../../.kiro/steering/wealth-and-fiduciary-*.md\`

## Next Steps for Developer

1. **Review the recommendations above**
2. **Create the spec structure**:
   \`\`\`powershell
   mkdir Applications/AITooling/Services/$ServiceName/.kiro/specs/$featureName
   \`\`\`
3. **Create \`requirements.md\`** with user stories and acceptance criteria
4. **Create \`design.md\`** with architecture and implementation details
5. **Create \`tasks.md\`** with implementation tasks
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
*Service: $ServiceName | Issue: $key | Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

        # Save to file
        $analysisDoc | Out-File -FilePath $outputFile -Encoding utf8
        
        Write-Host "    Created: $outputFile" -ForegroundColor Green
        $analysisCount++
    }
}

Write-Host "`nSpec analysis completed: $analysisCount documents created" -ForegroundColor Green
Write-Host "Output directory: $outputDir" -ForegroundColor Cyan

$global:Step4Result = 0
return 0
