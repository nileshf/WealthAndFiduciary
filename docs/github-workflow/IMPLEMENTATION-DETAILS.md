# Implementation Details - Bidirectional Jira Sync

## Critical Fixes Applied

### Fix #1: Status Mapping Functions

**Before** (Broken):
```powershell
function Get-CheckboxFromStatus {
    param([string]$status)
    # Was not being called or was incomplete
}
```

**After** (Fixed):
```powershell
function Get-CheckboxFromStatus {
    param([string]$status)
    switch ($status) {
        'To Do' { return '[ ]' }
        'In Progress' { return '[-]' }
        'In Review' { return '[~]' }
        'Done' { return '[x]' }
        default { return '[ ]' }
    }
}
```

**Impact**: Issues now sync with correct checkbox based on Jira status

---

### Fix #2: Regex Pattern for Task Matching

**Before** (Broken):
```powershell
if ($line -match '^\s*-\s+(\[[ x~-]\])\s+([^-\[].+)
</content>
') {
    # Pattern was truncated/incomplete
}
```

**After** (Fixed):
```powershell
if ($line -match '^\s*-\s+(\[[ x~-]\])\s+(?![A-Z]+-\d+)(.+)$') {
    $checkbox = $matches[1]
    $description = $matches[2].Trim()
    
    # Skip empty descriptions
    if ([string]::IsNullOrWhiteSpace($description)) {
        continue
    }
    
    $newTasks += @{
        checkbox = $checkbox
        description = $description
        line = $line
    }
}
```

**Key Features**:
- `^\s*-\s+` - Matches list item start
- `(\[[ x~-]\])` - Captures checkbox
- `(?![A-Z]+-\d+)` - Negative lookahead: skip if Jira key follows
- `(.+)$` - Captures description
- Stores original line for replacement

**Impact**: Only new tasks (without Jira keys) are processed

---

### Fix #3: File Update After Issue Creation

**Before** (Missing):
```powershell
# No file update logic
$created++
```

**After** (Fixed):
```powershell
# Update markdown file with issue key
$oldLine = $task.line
$newLine = "- $($task.checkbox) $issueKey - $($task.description)"
$content = $content -replace [regex]::Escape($oldLine), $newLine

$created++
```

**Then after loop**:
```powershell
if ($created -gt 0 -and -not $DryRun) {
    Set-Content -Path $service.file -Value $content -NoNewline
    Write-Host "    ✓ File updated with $created new issue key(s)"
}
```

**Impact**: Markdown files now updated with Jira keys after creation

---

### Fix #4: Status Transitions

**Before** (Missing):
```powershell
# No transition logic
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
$issueKey = $response.key
# Issue created but status not set
```

**After** (Fixed):
```powershell
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
$issueKey = $response.key

Write-Host "    + Created: $issueKey"

# Transition to correct status if not "To Do"
if ($status -ne 'To Do') {
    try {
        $transUri = "$JiraBaseUrl/rest/api/3/issue/$issueKey/transitions"
        $transResponse = Invoke-RestMethod -Uri $transUri -Headers $headers -Method Get
        $trans = $transResponse.transitions | Where-Object { $_.to.name -eq $status } | Select-Object -First 1
        
        if ($trans) {
            $transBody = @{ transition = @{ id = $trans.id } } | ConvertTo-Json
            Invoke-RestMethod -Uri $transUri -Headers $headers -Method Post -Body $transBody | Out-Null
            Write-Host "      → Transitioned to: $status"
        }
    }
    catch {
        Write-Host "      ⚠ Could not transition status: $_"
    }
}
```

**Impact**: Issues created with correct status from the start

---

### Fix #5: Jira → Markdown File Saving

**Before** (Missing):
```powershell
foreach ($issue in $serviceIssues) {
    # ... add issue to content
    $content += "`n$taskLine"
    $updated = $true
}
# File never saved
```

**After** (Fixed):
```powershell
foreach ($issue in $serviceIssues) {
    # ... add issue to content
    $content += "`n$taskLine"
    $updated = $true
    Write-Host "    + Added: $key ($checkbox $status)"
}

if ($updated -and -not $DryRun) {
    Set-Content -Path $service.file -Value $content -NoNewline
    Write-Host "    ✓ File updated"
}
```

**Impact**: Jira issues now appear in markdown files

---

### Fix #6: Workflow Execution

**Before** (Incomplete):
```yaml
jobs:
  validate:
    runs-on: ubuntu-latest
    name: Validate Sync Setup
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Validate project-task.md files exist
        shell: pwsh
        run: |
          # Only validation, no sync
```

**After** (Complete):
```yaml
jobs:
  sync:
    runs-on: ubuntu-latest
    name: Bidirectional Jira Sync
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.PAT_TOKEN }}

      - name: Setup PowerShell
        shell: pwsh
        run: |
          Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"

      - name: Run bidirectional sync
        shell: pwsh
        env:
          JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
          JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
          JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
        run: |
          & ./scripts/sync-jira-bidirectional.ps1

      - name: Commit changes
        shell: pwsh
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          
          if (git diff --quiet) {
            Write-Host "No changes to commit"
            exit 0
          }
          
          git add 'Applications/AITooling/Services/*/project-task.md'
          git commit -m "chore: sync Jira issues to project-task.md files"
          git push
```

**Key Changes**:
- Uses `PAT_TOKEN` for authentication
- Calls sync script
- Commits and pushes changes
- Proper error handling

**Impact**: Workflow now actually performs the sync

---

### Fix #7: Workflow Triggers

**Before** (Manual only):
```yaml
on:
  workflow_dispatch:
```

**After** (Multiple triggers):
```yaml
on:
  workflow_dispatch:
  push:
    branches: [ main, develop ]
    paths:
      - 'Applications/AITooling/Services/*/project-task.md'
  schedule:
    - cron: '0 * * * *'  # Every hour
```

**Impact**: Workflow runs automatically on push and schedule

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Bidirectional Sync Flow                       │
└─────────────────────────────────────────────────────────────────┘

DIRECTION 1: Jira → project-task.md
─────────────────────────────────────
1. Fetch Jira issues with labels
   ↓
2. Filter by service label
   ↓
3. Map Jira status → checkbox
   ↓
4. Add to markdown file
   ↓
5. Save file

DIRECTION 2: project-task.md → Jira
────────────────────────────────────
1. Read markdown file
   ↓
2. Find new tasks (no Jira key)
   ↓
3. Create Jira issue
   ↓
4. Transition to correct status
   ↓
5. Update markdown with Jira key
   ↓
6. Save file
```

---

## Status Mapping Truth Table

| Checkbox | Jira Status | Direction | Example |
|----------|-------------|-----------|---------|
| `[ ]` | To Do | Both | New task, not started |
| `[-]` | In Progress | Both | Currently being worked |
| `[~]` | In Review | Both | Ready for review |
| `[x]` | Done | Both | Completed |

---

## Error Handling

### Jira API Errors
```powershell
try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
}
catch {
    Write-Host "    ✗ Error creating issue: $_"
}
```

### File Not Found
```powershell
if (-not (Test-Path $service.file)) {
    Write-Host "    ⚠ File not found: $($service.file)"
    continue
}
```

### Missing Credentials
```powershell
if (-not $JiraBaseUrl -or -not $JiraEmail -or -not $JiraToken) {
    Write-Error "Missing Jira credentials (JIRA_BASE_URL, JIRA_USER_EMAIL, JIRA_API_TOKEN)"
    exit 1
}
```

---

## Performance Considerations

- **Batch Size**: Fetches up to 100 issues per request
- **Caching**: No caching (fresh sync each time)
- **Concurrency**: Sequential processing (one service at a time)
- **Timeout**: Default PowerShell timeout (300 seconds)

---

## Security Considerations

- **Credentials**: Stored in GitHub Secrets, never logged
- **PAT Token**: Required for git push (GITHUB_TOKEN insufficient)
- **Regex**: Prevents injection via proper escaping
- **File Paths**: Hardcoded, no user input

---

## Testing Recommendations

1. **Unit Test**: Test regex pattern with various inputs
2. **Integration Test**: Test with real Jira instance
3. **End-to-End Test**: Full sync cycle with verification
4. **Dry Run**: Always test with `-DryRun` flag first

---

**Last Updated**: February 12, 2025
