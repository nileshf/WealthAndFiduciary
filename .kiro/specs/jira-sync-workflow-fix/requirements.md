# Jira Sync Workflow Fix - Requirements

## Overview

Fix the Jira sync workflow that synchronizes tasks between `project-task.md` files and Jira issues. The workflow has two jobs:
1. `sync-tasks-to-jira` - Creates/updates Jira issues from project-task.md files
2. `sync-jira-to-tasks` - Updates project-task.md files from Jira issues

## Current Issues

### Issue 1: Jira API v3 Search Endpoint (FIXED)
- **Problem**: Jira API v3 search endpoint changed from GET to POST
- **Old endpoint**: `GET /rest/api/3/search?jql=...`
- **New endpoint**: `POST /rest/api/3/search/jql` with JSON body
- **Error**: `410 Gone` - API returns this error when using the old GET endpoint
- **Impact**: `sync-jira-to-tasks` job fails completely
- **Location**: `scripts/sync-jira-to-tasks.ps1`
- **Status**: ✅ FIXED

### Issue 2: Missing Service Labels (FIXED)
- **Problem**: Jira issues created by sync scripts don't have service labels
- **Impact**: `sync-jira-to-tasks` script cannot identify which service the issue belongs to
- **Solution**: Add service labels when creating issues:
  - `ai-security-service` for SecurityService
  - `data-loader-service` for DataLoaderService
- **Location**: Service-specific sync scripts
- **Status**: ✅ FIXED

### Issue 3: Environment Variable Mismatch
- **Problem**: The workflow uses `JIRA_BASE_URL` but the service-specific sync scripts expect `JIRA_BASE_URI`
- **Impact**: Service-specific sync jobs fail with "ERROR: .env file not found" or connection errors
- **Location**: `.github/workflows/sync-jira-to-project-tasks.yml`
- **Status**: Already correct - no changes needed

### Issue 4: Project Key Configuration
- **Problem**: Some scripts reference `AITOOL` project key instead of `WEALTHFID`
- **Impact**: Jira issues created in wrong project or API calls fail
- **Location**: All sync scripts
- **Status**: Already correct - no changes needed

### Issue 5: Service Labels
- **Problem**: Service labels don't match expected values (`ai-security-service`, `data-loader-service`)
- **Impact**: Tasks not synced to correct service project-task.md files
- **Location**: `scripts/sync-jira-to-tasks.ps1`
- **Status**: Already correct - no changes needed

## Acceptance Criteria

### AC1: Environment Variable Consistency
- [x] All sync scripts use `JIRA_BASE_URL` environment variable
- [x] Workflow passes `JIRA_BASE_URL` to service-specific scripts
- [x] Service-specific scripts read from `.env` file in parent directory
- [x] No "environment variable not found" errors in logs

### AC2: Jira API v3 Compliance
- [x] All API calls use `/rest/api/3/` endpoints
- [x] Search endpoint uses POST method with `/rest/api/3/search/jql`
- [x] No references to deprecated v2 endpoints
- [x] API calls succeed without migration warnings

### AC3: Correct Project Key
- [x] All scripts use `WEALTHFID` as the Jira project key
- [x] No hardcoded `AITOOL` project references
- [x] Jira issues created in correct project

### AC4: Service Label Mapping
- [x] `ai-security-service` label maps to SecurityService
- [x] `data-loader-service` label maps to DataLoaderService
- [x] Tasks synced to correct project-task.md files
- [x] New issues automatically get service labels

### AC5: Sync Order
- [x] `sync-tasks-to-jira` runs first (project-task.md → Jira)
- [x] `sync-jira-to-tasks` runs second (Jira → project-task.md)
- [x] No race conditions between sync jobs

### AC6: Database Configuration
- [x] AITooling services use SQL Server (not PostgreSQL)
- [x] Database configuration correct in service specs

## User Stories

### US1: Automated Jira Sync
**As a** developer  
**I want to** run the Jira sync workflow automatically  
**So that** my project-task.md files stay in sync with Jira issues

**Acceptance Criteria:**
- Workflow runs without manual intervention
- All sync jobs complete successfully
- Changes committed to repository

### US2: Error-Free Sync
**As a** developer  
**I want to** see clear error messages when sync fails  
**So that** I can quickly identify and fix issues

**Acceptance Criteria:**
- No cryptic API errors
- Environment variable issues clearly reported
- File path issues clearly reported

### US3: Correct Project Mapping
**As a** developer  
**I want to** Jira issues created in the correct project  
**So that** I don't have to manually move issues

**Acceptance Criteria:**
- All AITooling issues in WEALTHFID project
- No issues in AITOOL project
- Project key consistent across all scripts

### US4: Service Label Tracking
**As a** developer  
**I want to** Jira issues automatically labeled by service  
**So that** sync-jira-to-tasks can correctly identify which service each issue belongs to

**Acceptance Criteria:**
- SecurityService issues have `ai-security-service` label
- DataLoaderService issues have `data-loader-service` label
- No manual label assignment required

## Non-Functional Requirements

### Reliability
- Workflow should handle transient API errors with retry logic
- Failed sync jobs should not block subsequent jobs
- Clear error messages for debugging

### Maintainability
- Configuration centralized in `.env` files
- Scripts follow consistent patterns
- Documentation in script headers

### Security
- API tokens stored in GitHub secrets
- No credentials in logs
- Environment variables properly masked

## Out of Scope

- FullView service sync (handled in separate repository)
- Jira project configuration changes
- API token management
- Workflow scheduling (manual trigger only)

## References

- Current workflow: `.github/workflows/sync-jira-to-project-tasks.yml`
- SecurityService sync: `Applications/AITooling/Services/SecurityService/.kiro/scripts/jira-sync.ps1`
- DataLoaderService sync: `Applications/AITooling/Services/DataLoaderService/.kiro/scripts/jira-sync.ps1`
- Jira API docs: https://developer.atlassian.com/cloud/jira/platform/rest/v3/