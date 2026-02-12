# Jira Sync Workflow Fix - Tasks

## Verification Tasks
- [x] 1. Verify environment variable names across all scripts
  - Check service scripts read JIRA_BASE_URL (not JIRA_BASE_URI)
  - Check workflow passes JIRA_BASE_URL (not JIRA_BASE_URI)
  - Check .env files use JIRA_BASE_URL (not JIRA_BASE_URI)
  - Run workflow and verify no environment variable errors

- [x] 2. Verify Jira API endpoints use v3
  - Check scripts/sync-jira-to-tasks.ps1 uses /rest/api/3/search
  - Check service scripts use /rest/api/3/issue
  - Check service scripts use /rest/api/3/issue/{key}/transitions
  - Run workflow and verify no API deprecation warnings

- [x] 3. Verify project key is WEALTHFID
  - Check all scripts use WEALTHFID (not AITOOL)
  - Check .env files have JIRA_PROJECT_KEY=WEALTHFID
  - Run workflow and verify issues created in WEALTHFID project

- [x] 4. Verify service labels are correct
  - Check ai-security-service maps to SecurityService
  - Check data-loader-service maps to DataLoaderService
  - Run workflow and verify tasks synced to correct files

## Testing Tasks
- [x] 5. Run workflow manually with debug logging
  - Trigger workflow_dispatch
  - Enable verbose logging
  - Check all jobs complete successfully
  - Verify no errors in logs

- [x] 6. Verify sync-tasks-to-jira job
  - Check SecurityService tasks synced to Jira
  - Check DataLoaderService tasks synced to Jira
  - Verify issues created in WEALTHFID project
  - Verify issues have correct status

- [x] 7. Verify sync-jira-to-tasks job
  - Check Jira issues synced to SecurityService project-task.md
  - Check Jira issues synced to DataLoaderService project-task.md
  - Verify checkboxes updated correctly
  - Verify issue keys added to tasks

## Validation Tasks
- [x] 8. Validate project-task.md files
  - Check SecurityService file updated correctly
  - Check DataLoaderService file updated correctly
  - Verify no duplicate tasks
  - Verify no missing tasks

- [x] 9. Validate Jira issues
  - Check all tasks have corresponding Jira issues
  - Verify issues in WEALTHFID project
  - Verify issue status matches task status
  - Verify issue descriptions correct

- [x] 10. Run workflow again to verify idempotency
  - Run workflow without changes
  - Verify no duplicate issues created
  - Verify no duplicate tasks added
  - Verify status sync works correctly

## Implementation Tasks
- [x] 11. Fix Jira API endpoint in sync-jira-to-tasks.ps1
  - Change from GET /rest/api/3/search to POST /rest/api/3/search/jql
  - Update request body to use JSON format
  - Test endpoint works correctly
  - Verify issues are returned

## Checkpoint Tasks
- [x] X. Checkpoint - Verify all verification tasks pass
  - All environment variables correct
  - All API endpoints use v3
  - All project keys are WEALTHFID
  - All service labels correct
  - Ask user if questions arise

- [x] X. Checkpoint - Verify all testing tasks pass
  - Workflow runs without errors
  - sync-tasks-to-jira succeeds
  - sync-jira-to-tasks succeeds
  - Ask user if questions arise

- [x] X. Checkpoint - Verify all validation tasks pass
  - Project-task.md files updated correctly
  - Jira issues created correctly
  - No duplicates or missing items
  - Ask user if questions arise