# Workflow Debugging Guide

## How to Check GitHub Actions Logs

### Step 1: Access GitHub Actions
1. Go to your GitHub repository
2. Click the **Actions** tab (top menu)
3. Click **Sync Project Tasks to Jira** workflow

### Step 2: Find the Failed Run
1. Look for the most recent workflow run
2. Click on it to open the details
3. You'll see three jobs listed:
   - sync-jira-to-tasks
   - sync-tasks-to-jira
   - validate-sync

### Step 3: Expand the Failed Job
1. Click on the job that failed (red X)
2. Expand each step to see the logs
3. Look for error messages

### Step 4: Read the Error Message
The error message will tell you exactly what went wrong. Common errors:

---

## Common Errors and Solutions

### Error 1: "JiraBaseUrl is required"
```
JiraBaseUrl is required. Set JIRA_BASE_URL environment variable or pass -JiraBaseUrl parameter.
```

**Cause**: `JIRA_BASE_URL` secret not configured

**Solution**:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `JIRA_BASE_URL`
4. Value: `https://nileshf.atlassian.net`
5. Click **Add secret**

---

### Error 2: "JiraEmail is required"
```
JiraEmail is required. Set JIRA_USER_EMAIL environment variable or pass -JiraEmail parameter.
```

**Cause**: `JIRA_USER_EMAIL` secret not configured

**Solution**:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `JIRA_USER_EMAIL`
4. Value: Your Jira email
5. Click **Add secret**

---

### Error 3: "JiraToken is required"
```
JiraToken is required. Set JIRA_API_TOKEN environment variable or pass -JiraToken parameter.
```

**Cause**: `JIRA_API_TOKEN` secret not configured

**Solution**:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click **Create API token**
3. Name: "GitHub Actions Sync"
4. Click **Create**
5. Copy the token
6. Go to **Settings** → **Secrets and variables** → **Actions**
7. Click **New repository secret**
8. Name: `JIRA_API_TOKEN`
9. Value: Paste the token
10. Click **Add secret**

---

### Error 4: "401 Unauthorized"
```
Error fetching Jira issues: Response status code does not indicate success: 401 (Unauthorized).
```

**Cause**: Invalid Jira credentials

**Solution**:
1. Verify your Jira email is correct
2. Generate a new API token
3. Update the secrets in GitHub

---

### Error 5: "404 Not Found"
```
Error fetching Jira issues: Response status code does not indicate success: 404 (Not Found).
```

**Cause**: Incorrect Jira URL

**Solution**:
1. Verify `JIRA_BASE_URL` is correct
2. Should be: `https://your-domain.atlassian.net`
3. Update the secret in GitHub

---

### Error 6: "pwsh: command not found"
```
/bin/bash: pwsh: command not found
```

**Cause**: PowerShell not available on runner

**Solution**:
- This shouldn't happen on ubuntu-latest
- Check that `runs-on: ubuntu-latest` is set in workflow
- PowerShell is pre-installed on ubuntu-latest

---

### Error 7: "git push" fails
```
fatal: could not read Username for 'https://github.com': No such file or directory
```

**Cause**: Git authentication not configured

**Solution**:
- Verify workflow has `GITHUB_TOKEN` in environment
- This should be automatic in GitHub Actions
- Check that the commit step has the token configured

---

## Recent Fixes Applied

### Fix 1: JSON Handling
**Issue**: Empty array conversion to JSON could fail
**Fix**: Added check for empty array before JSON conversion
```powershell
if ($allChanges.Count -gt 0) {
  $changesJson = $allChanges | ConvertTo-Json -Compress
} else {
  $changesJson = "[]"
}
```

### Fix 2: Git Diff on First Run
**Issue**: `git diff HEAD~1 HEAD` fails when there's no previous commit
**Fix**: Added error handling for first run
```powershell
$diff = git diff HEAD~1 HEAD -- $file 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "No previous commit, skipping diff for $file"
  continue
}
```

### Fix 3: Empty Changes Handling
**Issue**: Trying to process empty changes array
**Fix**: Added check before processing
```yaml
if: steps.detect.outputs.changes != '' && steps.detect.outputs.changes != '[]'
```

---

## How to Debug Locally

### Test the PowerShell Script

```powershell
# Set environment variables
$env:JIRA_BASE_URL = "https://nileshf.atlassian.net"
$env:JIRA_USER_EMAIL = "your-email@example.com"
$env:JIRA_API_TOKEN = "your-api-token"

# Run the script in dry-run mode (no changes)
.\scripts\sync-jira-to-tasks.ps1 -Verbose -DryRun

# Run the script for real
.\scripts\sync-jira-to-tasks.ps1 -Verbose
```

### Check Jira Connection

```powershell
# Test Jira API connection
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("email:token"))
$headers = @{
  'Authorization' = "Basic $auth"
  'Content-Type' = 'application/json'
}

$body = @{
  jql = 'status NOT IN (Done, Closed, Resolved) AND labels is not EMPTY'
  maxResults = 10
  fields = @("key", "summary", "status", "labels")
} | ConvertTo-Json

Invoke-RestMethod `
  -Uri "https://nileshf.atlassian.net/rest/api/3/search/jql" `
  -Headers $headers `
  -Method Post `
  -Body $body
```

---

## Workflow Execution Steps

### Step 1: Checkout Code
- Downloads the repository
- Sets up git

### Step 2: Run Jira Sync Script
- Fetches Jira issues
- Adds tasks to project-task.md files
- **This is where most errors occur**

### Step 3: Commit Changes
- Commits changes to git
- Pushes to develop branch

### Step 4: Detect Status Changes
- Looks for checkbox changes
- Parses Jira issue keys
- **This can fail if no previous commit exists**

### Step 5: Update Jira Statuses
- Updates Jira issue statuses
- **This only runs if changes are detected**

### Step 6: Validate Results
- Checks that project-task.md files exist
- Validates task format

---

## Checking Specific Errors

### If sync-jira-to-tasks fails:
1. Check for "JiraBaseUrl is required" → Configure JIRA_BASE_URL
2. Check for "JiraEmail is required" → Configure JIRA_USER_EMAIL
3. Check for "JiraToken is required" → Configure JIRA_API_TOKEN
4. Check for "401 Unauthorized" → Verify credentials
5. Check for "404 Not Found" → Verify Jira URL
6. Check for "pwsh: command not found" → Check runner OS

### If sync-tasks-to-jira fails:
1. Check for git diff errors → Normal on first run
2. Check for JSON parsing errors → Check recent fixes
3. Check for Jira API errors → Verify credentials

### If validate-sync fails:
1. Check for "File not found" → Create missing files
2. Check for "no valid tasks" → Check file format

---

## What to Look For in Logs

### Success Indicators
```
[INFO] Fetching Jira issues: status NOT IN (Done, Closed, Resolved) AND labels is not EMPTY
[OK] Found 5 issues
[INFO] Processing issue: WEALTHFID-152 for service: SecurityService
[OK] Added task WEALTHFID-152 to Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md
[INFO] Sync completed: 3 synced, 0 skipped, 0 errors
```

### Error Indicators
```
[ERROR] JiraBaseUrl is required
[ERROR] Error fetching Jira issues: 401 (Unauthorized)
[ERROR] Error adding task to file: Permission denied
```

---

## Next Steps

1. **Check the logs** - Go to Actions tab and look at the most recent run
2. **Find the error** - Look for [ERROR] messages
3. **Match the error** - Find it in this guide
4. **Apply the solution** - Follow the steps
5. **Re-run the workflow** - Click "Re-run jobs" button

---

**Last Updated**: January 2025
**Workflow File**: `.github/workflows/sync-project-tasks-to-jira.yml`
**Script File**: `scripts/sync-jira-to-tasks.ps1`
