# GitHub Actions Workflow Troubleshooting Guide

## Overview

This guide helps diagnose and fix issues with the Jira sync workflow (`sync-project-tasks-to-jira.yml`).

## Quick Diagnosis

### Step 1: Check Workflow Status

1. Go to **Actions** tab in GitHub
2. Click **Sync Project Tasks to Jira** workflow
3. Look at the most recent run
4. Check the status:
   - ✅ **Green checkmark**: Workflow succeeded
   - ❌ **Red X**: Workflow failed
   - ⏳ **Yellow circle**: Workflow in progress

### Step 2: Identify Which Job Failed

1. Click on the failed workflow run
2. Look at the three jobs:
   - **sync-jira-to-tasks**: Fetches Jira issues and updates project-task.md files
   - **sync-tasks-to-jira**: Detects checkbox changes and updates Jira
   - **validate-sync**: Validates project-task.md files exist and are valid

3. Click on the failed job to see detailed logs

### Step 3: Read the Error Message

Look for error messages in the logs. Common errors are listed below.

## Common Issues and Solutions

### Issue 1: "JiraBaseUrl is required"

**Error Message**:
```
JiraBaseUrl is required. Set JIRA_BASE_URL environment variable or pass -JiraBaseUrl parameter.
```

**Cause**: `JIRA_BASE_URL` secret is not configured in GitHub

**Solution**:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. **Name**: `JIRA_BASE_URL`
4. **Value**: `https://nileshf.atlassian.net`
5. Click **Add secret**
6. Re-run the workflow

**Verification**:
- Secret should appear in the secrets list
- Workflow should run without this error

---

### Issue 2: "JiraEmail is required"

**Error Message**:
```
JiraEmail is required. Set JIRA_USER_EMAIL environment variable or pass -JiraEmail parameter.
```

**Cause**: `JIRA_USER_EMAIL` secret is not configured in GitHub

**Solution**:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. **Name**: `JIRA_USER_EMAIL`
4. **Value**: Your Jira account email (e.g., `your-email@example.com`)
5. Click **Add secret**
6. Re-run the workflow

**Verification**:
- Secret should appear in the secrets list
- Workflow should run without this error

---

### Issue 3: "JiraToken is required"

**Error Message**:
```
JiraToken is required. Set JIRA_API_TOKEN environment variable or pass -JiraToken parameter.
```

**Cause**: `JIRA_API_TOKEN` secret is not configured in GitHub

**Solution**:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click **Create API token**
3. Name it "GitHub Actions Sync"
4. Click **Create**
5. Copy the token
6. Go to **Settings** → **Secrets and variables** → **Actions**
7. Click **New repository secret**
8. **Name**: `JIRA_API_TOKEN`
9. **Value**: Paste the token
10. Click **Add secret**
11. Re-run the workflow

**Verification**:
- Secret should appear in the secrets list
- Workflow should run without this error

---

### Issue 4: "401 Unauthorized"

**Error Message**:
```
Error fetching Jira issues: Response status code does not indicate success: 401 (Unauthorized).
```

**Cause**: Invalid Jira credentials (wrong email or API token)

**Solution**:
1. Verify your Jira email is correct:
   - Go to your Jira profile
   - Check the email address
   - Update `JIRA_USER_EMAIL` secret if needed

2. Generate a new API token:
   - Go to https://id.atlassian.com/manage-profile/security/api-tokens
   - Delete the old token
   - Click **Create API token**
   - Copy the new token
   - Update `JIRA_API_TOKEN` secret

3. Re-run the workflow

**Verification**:
- Workflow should authenticate successfully
- Should see "Found X issues" in logs

---

### Issue 5: "404 Not Found"

**Error Message**:
```
Error fetching Jira issues: Response status code does not indicate success: 404 (Not Found).
```

**Cause**: Incorrect Jira URL

**Solution**:
1. Verify your Jira URL:
   - Go to your Jira instance
   - Look at the URL in your browser
   - Should be `https://your-domain.atlassian.net`

2. Update `JIRA_BASE_URL` secret:
   - Go to **Settings** → **Secrets and variables** → **Actions**
   - Click on `JIRA_BASE_URL`
   - Click **Update secret**
   - Verify the URL is correct
   - Click **Update secret**

3. Re-run the workflow

**Verification**:
- Workflow should connect to Jira successfully
- Should see "Found X issues" in logs

---

### Issue 6: "pwsh: command not found"

**Error Message**:
```
/bin/bash: pwsh: command not found
```

**Cause**: PowerShell not available on the runner

**Solution**:
1. Check the runner OS in the workflow:
   - Should be `runs-on: ubuntu-latest` or `windows-latest`
   - Both have PowerShell available

2. If using a custom runner, ensure PowerShell is installed:
   ```bash
   # On Ubuntu
   sudo apt-get install -y powershell
   
   # On Windows
   # PowerShell is pre-installed
   ```

3. Re-run the workflow

**Verification**:
- Workflow should execute PowerShell scripts successfully

---

### Issue 7: "No changes from Jira sync"

**Error Message**:
```
No changes from Jira sync
```

**Cause**: No open Jira issues found with service labels

**Solution**:
1. Verify Jira issues exist:
   - Go to your Jira instance
   - Search for issues: `status NOT IN (Done, Closed, Resolved) AND labels is not EMPTY`
   - Should see open issues with labels

2. Verify service labels are set:
   - Each issue should have one of these labels:
     - `ai-security-service` (for SecurityService)
     - `data-loader-service` (for DataLoaderService)

3. Add labels to Jira issues:
   - Open the issue in Jira
   - Click **Labels** field
   - Add the appropriate service label
   - Save

4. Re-run the workflow

**Verification**:
- Workflow should find issues
- Should see "Found X issues" in logs
- Tasks should be added to project-task.md files

---

### Issue 8: "File not found: Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md"

**Error Message**:
```
File not found: Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md
```

**Cause**: Project task file doesn't exist

**Solution**:
1. Create the missing file:
   ```bash
   mkdir -p Applications/AITooling/Services/SecurityService/.kiro/specs/security-service
   touch Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md
   ```

2. Add initial content:
   ```markdown
   # SecurityService Project Tasks

   ## Implementation Tasks
   - [ ] Task 1
   - [ ] Task 2

   ## Testing Tasks
   - [ ] Test 1
   - [ ] Test 2
   ```

3. Commit and push:
   ```bash
   git add Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md
   git commit -m "chore: create project-task.md for SecurityService"
   git push
   ```

4. Re-run the workflow

**Verification**:
- File should exist in the repository
- Workflow should validate successfully

---

### Issue 9: "git push" fails with authentication error

**Error Message**:
```
fatal: could not read Username for 'https://github.com': No such file or directory
```

**Cause**: Git authentication not configured in workflow

**Solution**:
1. The workflow should use `GITHUB_TOKEN` for authentication
2. Verify the workflow has this in the commit step:
   ```yaml
   env:
     GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

3. If not present, update the workflow file

4. Re-run the workflow

**Verification**:
- Workflow should push changes successfully
- Changes should appear in the repository

---

### Issue 10: "No status changes detected"

**Error Message**:
```
⏭️ No status changes detected in project-task.md files
```

**Cause**: No checkbox status changes in project-task.md files

**Solution**:
This is not an error - it means:
- No tasks had their checkbox status changed
- This is expected on the first run
- To test, manually change a checkbox:
  1. Edit a project-task.md file
  2. Change a checkbox from `[ ]` to `[-]` or `[x]`
  3. Commit and push
  4. Workflow will detect the change and update Jira

**Verification**:
- Make a checkbox change
- Push to develop branch
- Workflow should detect the change
- Jira issue status should update

---

## Workflow Execution Flow

### Successful Execution

```
1. Workflow triggered (schedule, push, or manual)
   ↓
2. sync-jira-to-tasks job
   ├─ Checkout code
   ├─ Fetch Jira issues with service labels
   ├─ Add tasks to project-task.md files
   ├─ Commit changes
   └─ Push to develop
   ↓
3. sync-tasks-to-jira job (only on push)
   ├─ Checkout code
   ├─ Detect changed files
   ├─ Parse checkbox status changes
   ├─ Update Jira issue statuses
   └─ Report results
   ↓
4. validate-sync job
   ├─ Validate project-task.md files exist
   ├─ Validate task format
   └─ Report validation results
   ↓
5. Workflow complete ✅
```

### Failed Execution

```
1. Workflow triggered
   ↓
2. sync-jira-to-tasks job
   ├─ Checkout code
   ├─ Try to fetch Jira issues
   └─ ❌ FAIL: Missing secret or invalid credentials
   ↓
3. Workflow stops ❌
   (sync-tasks-to-jira and validate-sync are skipped)
```

## Manual Testing

### Test 1: Verify Jira Connection

1. Go to **Actions** tab
2. Click **Sync Project Tasks to Jira** workflow
3. Click **Run workflow**
4. Select **develop** branch
5. Click **Run workflow**
6. Wait for completion
7. Check logs for "Found X issues"

### Test 2: Verify Task Sync

1. Create a new Jira issue with label `ai-security-service`
2. Manually trigger the workflow
3. Check `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
4. New task should appear

### Test 3: Verify Status Sync

1. Edit `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
2. Change a checkbox from `[ ]` to `[-]`
3. Commit and push to develop
4. Workflow should run automatically
5. Check Jira issue status - should change to "In Progress"

## Checking Logs

### Access Workflow Logs

1. Go to **Actions** tab
2. Click **Sync Project Tasks to Jira** workflow
3. Click on the workflow run
4. Click on a job to expand it
5. Scroll through the logs

### Key Log Sections

**Jira Connection**:
```
[INFO] Fetching Jira issues: status NOT IN (Done, Closed, Resolved) AND labels is not EMPTY
[OK] Found 5 issues
```

**Task Processing**:
```
[INFO] Processing issue: WEALTHFID-152 for service: SecurityService
[OK] Added task WEALTHFID-152 to Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md
```

**Sync Completion**:
```
[INFO] Sync completed: 3 synced, 0 skipped, 0 errors
```

## Getting Help

If you're still having issues:

1. **Check the logs**: Most errors are clearly described in the workflow logs
2. **Verify secrets**: Ensure all three secrets are configured
3. **Verify Jira setup**: Ensure Jira issues have service labels
4. **Check file paths**: Ensure project-task.md files exist
5. **Test manually**: Run the PowerShell script locally to debug

### Local Testing

Run the sync script locally:

```powershell
# Set environment variables
$env:JIRA_BASE_URL = "https://nileshf.atlassian.net"
$env:JIRA_USER_EMAIL = "your-email@example.com"
$env:JIRA_API_TOKEN = "your-api-token"

# Run the script
.\scripts\sync-jira-to-tasks.ps1 -Verbose -DryRun
```

The `-DryRun` flag shows what would be changed without making actual changes.

---

**Last Updated**: January 2025
**Workflow File**: `.github/workflows/sync-project-tasks-to-jira.yml`
**Script File**: `scripts/sync-jira-to-tasks.ps1`
