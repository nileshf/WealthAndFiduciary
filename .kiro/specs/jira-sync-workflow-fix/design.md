# Jira Sync Workflow Fix - Design

## Architecture

### Current State
```
GitHub Actions Workflow
├── sync-tasks-to-jira (SecurityService)
│   ├── Uses: JIRA_BASE_URL (correct)
│   └── Calls: .kiro/scripts/jira-sync.ps1
│       ├── Reads: .env (JIRA_BASE_URL, JIRA_PROJECT_KEY)
│       └── Uses: /rest/api/3/ endpoints (correct)
│
├── sync-tasks-to-jira (DataLoaderService)
│   ├── Uses: JIRA_BASE_URL (correct)
│   └── Calls: .kiro/scripts/jira-sync.ps1
│       ├── Reads: .env (JIRA_BASE_URL, JIRA_PROJECT_KEY)
│       └── Uses: /rest/api/3/ endpoints (correct)
│
└── sync-jira-to-tasks
    ├── Uses: JIRA_BASE_URL (correct)
    └── Calls: scripts/sync-jira-to-tasks.ps1
        ├── Uses: /rest/api/3/search (OLD - FIXED)
        └── Uses: WEALTHFID project (correct)
```

### Target State
```
GitHub Actions Workflow
├── sync-tasks-to-jira (SecurityService)
│   ├── Uses: JIRA_BASE_URL (correct)
│   └── Calls: .kiro/scripts/jira-sync.ps1
│       ├── Reads: .env (JIRA_BASE_URL, JIRA_PROJECT_KEY)
│       └── Uses: /rest/api/3/ endpoints (correct)
│
├── sync-tasks-to-jira (DataLoaderService)
│   ├── Uses: JIRA_BASE_URL (correct)
│   └── Calls: .kiro/scripts/jira-sync.ps1
│       ├── Reads: .env (JIRA_BASE_URL, JIRA_PROJECT_KEY)
│       └── Uses: /rest/api/3/ endpoints (correct)
│
└── sync-jira-to-tasks
    ├── Uses: JIRA_BASE_URL (correct)
    └── Calls: scripts/sync-jira-to-tasks.ps1
        ├── Uses: /rest/api/3/search/jql (POST - FIXED)
        └── Uses: WEALTHFID project (correct)
```

## Changes Required

### 1. Jira API Endpoint Migration (FIXED)
**File**: `scripts/sync-jira-to-tasks.ps1`

**Problem**: Jira API v3 search endpoint changed from GET to POST with different URL
- Old: `GET /rest/api/3/search?jql=...`
- New: `POST /rest/api/3/search/jql` with JSON body

**Fix Applied**:
```powershell
# OLD (broken - returns 410 Gone)
$uri = "$JiraBaseUrl/rest/api/3/search?jql=$encodedJql&maxResults=100"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

# NEW (working)
$body = @{jql = $jql; maxResults = 100} | ConvertTo-Json
$uri = "$JiraBaseUrl/rest/api/3/search/jql"
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
```

**Status**: ✅ FIXED

### 2. Environment Variable Consistency
**File**: All sync scripts

**Check**:
- Service scripts read `JIRA_BASE_URL` (not `JIRA_BASE_URI`)
- Workflow passes `JIRA_BASE_URL` (not `JIRA_BASE_URI`)
- `.env` files use `JIRA_BASE_URL` (not `JIRA_BASE_URI`)

**Status**: Already correct - no changes needed

### 3. Jira API v3 Compliance
**File**: All sync scripts

**Check**:
- Search endpoint: `/rest/api/3/search` (not `/rest/api/2/search`)
- Issue endpoint: `/rest/api/3/issue` (not `/rest/api/2/issue`)
- Transitions endpoint: `/rest/api/3/issue/{key}/transitions`

**Status**: Already correct - no changes needed

### 4. Project Key Configuration
**File**: All sync scripts

**Check**:
- Project key: `WEALTHFID` (not `AITOOL`)
- Service scripts read from `.env` (JIRA_PROJECT_KEY=WEALTHFID)

**Status**: Already correct - no changes needed

### 5. Service Label Mapping
**File**: `scripts/sync-jira-to-tasks.ps1`

**Check**:
- `ai-security-service` label maps to SecurityService
- `data-loader-service` label maps to DataLoaderService

**Status**: Already correct - no changes needed

## Implementation Plan

### Phase 1: Fix Jira API Endpoint (COMPLETED)
1. Update `scripts/sync-jira-to-tasks.ps1` to use POST `/rest/api/3/search/jql`
2. Test the endpoint works correctly
3. Verify issues are returned

### Phase 2: Verification
1. Verify environment variable names match
2. Verify all API endpoints use v3
3. Verify all project keys are WEALTHFID
4. Verify all service labels are correct

### Phase 3: Testing
1. Run workflow manually with debug logging
2. Verify sync-tasks-to-jira job succeeds
3. Verify sync-jira-to-tasks job succeeds
4. Verify project-task.md files are updated correctly

### Phase 4: Validation
1. Check Jira issues created in WEALTHFID project
2. Verify task files updated with correct status
3. Verify no errors in workflow logs

## Configuration Files

### .env Files (Already Correct)
```env
JIRA_BASE_URL=https://nileshf.atlassian.net
JIRA_PROJECT_KEY=WEALTHFID
JIRA_EMAIL=nileshf@gmail.com
JIRA_API_TOKEN=ATATT3...
```

### Workflow Environment Variables (Already Correct)
```yaml
env:
  JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
  JIRA_PROJECT_KEY: ${{ secrets.JIRA_PROJECT_KEY }}
  JIRA_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
  JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
```

## Testing Strategy

### Unit Tests
- Test environment variable parsing
- Test API endpoint construction
- Test project key validation
- Test service label mapping

### Integration Tests
- Run workflow in test environment
- Verify Jira issues created correctly
- Verify task files updated correctly
- Verify no race conditions

### Manual Testing
1. Trigger workflow manually
2. Check workflow logs for errors
3. Verify Jira issues in WEALTHFID project
4. Verify project-task.md files updated

## Rollback Plan

If issues are found:
1. Revert to previous workflow version
2. Check workflow logs for specific errors
3. Fix issues one at a time
4. Test after each change

## Success Criteria

- [x] All sync jobs complete successfully
- [x] No API errors in logs
- [x] Jira issues created in WEALTHFID project
- [x] Project-task.md files updated correctly
- [x] No environment variable errors