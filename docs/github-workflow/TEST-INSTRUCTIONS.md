# Testing Instructions - Bidirectional Jira Sync

## Prerequisites

You need:
1. Jira instance URL (e.g., `https://your-domain.atlassian.net`)
2. Jira user email
3. Jira API token (generate from Jira account settings)

---

## Step 1: Get Your Jira Credentials

### Get Jira Base URL
- Go to your Jira instance
- Copy the base URL (e.g., `https://nileshf.atlassian.net`)

### Get Jira Email
- Your Jira account email address

### Get Jira API Token
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name (e.g., "GitHub Sync")
4. Copy the token

---

## Step 2: Test Locally (Dry Run)

### PowerShell Command
```powershell
$env:JIRA_BASE_URL = "https://your-domain.atlassian.net"
$env:JIRA_USER_EMAIL = "your-email@example.com"
$env:JIRA_API_TOKEN = "your-api-token-here"

./scripts/sync-jira-bidirectional.ps1 -DryRun
```

### Expected Output
```
Starting bidirectional Jira sync... 
Base URL: https://your-domain.atlassian.net
[DRY RUN MODE]

=== Syncing Jira to project-task.md ===
Fetching Jira issues...
Found X Jira issues
  SecurityService: X issue(s)
    ADDED: WEALTHFID-XXX with status To Do
    ...
  DataLoaderService: X issue(s)
    ...

=== Syncing project-task.md to Jira ===
  SecurityService: No new tasks
  DataLoaderService: No new tasks
  Total created: 0

Sync complete
```

---

## Step 3: Test Locally (Real Sync)

### PowerShell Command
```powershell
$env:JIRA_BASE_URL = "https://your-domain.atlassian.net"
$env:JIRA_USER_EMAIL = "your-email@example.com"
$env:JIRA_API_TOKEN = "your-api-token-here"

./scripts/sync-jira-bidirectional.ps1
```

### What Happens
1. Fetches Jira issues
2. Adds them to project-task.md files
3. Finds new tasks in markdown
4. Creates Jira issues
5. Updates markdown with Jira keys
6. Saves files

### Verify Results
1. Check `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
   - Should have Jira issues with correct checkboxes
2. Check `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`
   - Should have Jira issues with correct checkboxes
3. Check Jira for new issues created from markdown

---

## Step 4: Configure GitHub Secrets

### Add Secrets to GitHub
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `JIRA_BASE_URL` | `https://your-domain.atlassian.net` |
| `JIRA_USER_EMAIL` | `your-email@example.com` |
| `JIRA_API_TOKEN` | Your API token |
| `PAT_TOKEN` | Your GitHub Personal Access Token |

### Create GitHub Personal Access Token
1. Go to https://github.com/settings/tokens
2. Click **Generate new token** → **Generate new token (classic)**
3. Give it a name (e.g., "Jira Sync")
4. Select scopes: `repo` (full control of private repositories)
5. Click **Generate token**
6. Copy the token and add to GitHub Secrets as `PAT_TOKEN`

---

## Step 5: Test via GitHub Workflow

### Run Workflow Manually
1. Go to **Actions** tab
2. Select **"Sync Project Tasks to Jira"**
3. Click **"Run workflow"**
4. Select branch (usually `main` or `develop`)
5. Click **"Run workflow"**

### Monitor Execution
1. Click on the workflow run
2. Check the logs for each step
3. Verify:
   - Sync script executed
   - Files updated
   - Changes committed
   - Changes pushed

---

## Troubleshooting

### Error: "Missing Jira credentials"
**Cause**: Environment variables not set
**Solution**: Set all three environment variables before running script

### Error: "401 Unauthorized"
**Cause**: Invalid Jira credentials
**Solution**: 
- Verify email is correct
- Verify API token is correct
- Verify token hasn't expired

### Error: "404 Not Found"
**Cause**: Jira URL is incorrect
**Solution**: Verify Jira base URL (should be `https://domain.atlassian.net`)

### Error: "Git push failed"
**Cause**: PAT_TOKEN doesn't have proper permissions
**Solution**: 
- Verify PAT_TOKEN has `repo` scope
- Verify token hasn't expired
- Regenerate token if needed

### No issues synced
**Cause**: Issues don't have service labels
**Solution**: 
- Add labels to Jira issues:
  - `ai-security-service` for SecurityService
  - `data-loader-service` for DataLoaderService

### Markdown files not updated
**Cause**: Script didn't save files
**Solution**: 
- Check script output for errors
- Verify file paths are correct
- Check file permissions

---

## Example Workflow

### Scenario 1: Sync Jira Issues to Markdown
1. Create Jira issue: `WEALTHFID-100 - Implement feature X`
2. Add label: `ai-security-service`
3. Run sync script
4. Check `project-task.md`: Should have `- [ ] WEALTHFID-100 - Implement feature X`

### Scenario 2: Create Jira Issue from Markdown
1. Add to `project-task.md`: `- [ ] New feature Y`
2. Run sync script
3. Check Jira: Should have new issue `WEALTHFID-101 - New feature Y`
4. Check `project-task.md`: Should have `- [ ] WEALTHFID-101 - New feature Y`

### Scenario 3: Status Mapping
1. Create Jira issue with status "In Progress"
2. Add label: `ai-security-service`
3. Run sync script
4. Check `project-task.md`: Should have `- [-] WEALTHFID-102 - Issue title`

---

## Status Mapping Reference

| Checkbox | Jira Status | Meaning |
|----------|-------------|---------|
| `[ ]` | To Do | Not started |
| `[-]` | In Progress | Currently being worked |
| `[~]` | In Review | Ready for review |
| `[x]` | Done | Completed |

---

## Tips

1. **Always test with `-DryRun` first** to see what would happen
2. **Check file permissions** if script can't write files
3. **Verify Jira labels** are exactly correct (case-sensitive)
4. **Monitor workflow logs** for detailed error messages
5. **Keep API tokens secure** - never commit them to git

---

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review workflow logs in GitHub Actions
3. Run script locally with `-DryRun` to debug
4. Check Jira API documentation for status transitions

---

**Last Updated**: February 12, 2025
