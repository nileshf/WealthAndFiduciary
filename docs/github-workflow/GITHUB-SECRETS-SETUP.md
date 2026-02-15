# GitHub Secrets Configuration Guide

## Overview

The Jira sync workflow requires three GitHub Secrets to be configured before it can run successfully. This guide walks you through setting up these secrets.

## Required Secrets

### 1. `JIRA_BASE_URL`
**Purpose**: Base URL of your Jira instance

**Value Format**: `https://your-domain.atlassian.net`

**Example**: `https://nileshf.atlassian.net`

**How to Find**:
- Go to your Jira instance
- Look at the URL in your browser
- Copy everything up to (but not including) `/browse/` or `/jira/`

### 2. `JIRA_USER_EMAIL`
**Purpose**: Email address for Jira API authentication

**Value Format**: Your Jira account email address

**Example**: `your-email@example.com`

**How to Find**:
- Go to your Jira profile (click your avatar in top-right)
- Look for "Email address" field
- Use the email associated with your Jira account

### 3. `JIRA_API_TOKEN`
**Purpose**: API token for secure authentication

**Value Format**: A 24-character token generated in Jira

**How to Generate**:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name like "GitHub Actions Sync"
4. Click "Create"
5. Copy the token (you can only see it once!)
6. Store it securely

## Step-by-Step Setup

### Step 1: Navigate to GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. Click **Secrets and variables** (left sidebar)
4. Click **Actions**

### Step 2: Add JIRA_BASE_URL

1. Click **New repository secret**
2. **Name**: `JIRA_BASE_URL`
3. **Value**: `https://nileshf.atlassian.net` (or your Jira URL)
4. Click **Add secret**

### Step 3: Add JIRA_USER_EMAIL

1. Click **New repository secret**
2. **Name**: `JIRA_USER_EMAIL`
3. **Value**: Your Jira account email
4. Click **Add secret**

### Step 4: Add JIRA_API_TOKEN

1. Click **New repository secret**
2. **Name**: `JIRA_API_TOKEN`
3. **Value**: Your API token from Jira
4. Click **Add secret**

## Verification

After adding all three secrets:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. You should see three secrets listed:
   - ✅ `JIRA_BASE_URL`
   - ✅ `JIRA_USER_EMAIL`
   - ✅ `JIRA_API_TOKEN`

## Testing the Workflow

### Manual Trigger

1. Go to **Actions** tab in GitHub
2. Click **Sync Project Tasks to Jira** workflow
3. Click **Run workflow**
4. Select **develop** branch
5. Click **Run workflow**

### Check Logs

1. Wait for the workflow to complete
2. Click on the workflow run
3. Expand each job to see logs:
   - **sync-jira-to-tasks**: Should show "✅ Jira tasks successfully synced"
   - **sync-tasks-to-jira**: Should show "⏭️ No status changes detected" (on first run)
   - **validate-sync**: Should show "✓ All project-task.md files validated"

## Troubleshooting

### Error: "JiraBaseUrl is required"
- **Cause**: `JIRA_BASE_URL` secret not configured
- **Fix**: Add the secret following Step 2 above

### Error: "JiraEmail is required"
- **Cause**: `JIRA_USER_EMAIL` secret not configured
- **Fix**: Add the secret following Step 3 above

### Error: "JiraToken is required"
- **Cause**: `JIRA_API_TOKEN` secret not configured
- **Fix**: Add the secret following Step 4 above

### Error: "401 Unauthorized"
- **Cause**: Invalid email or API token
- **Fix**: 
  - Verify email matches your Jira account
  - Generate a new API token and update the secret

### Error: "404 Not Found"
- **Cause**: Incorrect Jira URL
- **Fix**: Verify `JIRA_BASE_URL` is correct (should be `https://your-domain.atlassian.net`)

### Error: "pwsh: command not found"
- **Cause**: PowerShell not available on runner
- **Fix**: Workflow uses `shell: pwsh` which should work on all runners
- **Workaround**: Check that runner is `ubuntu-latest` or `windows-latest`

### Workflow Doesn't Run on Schedule
- **Cause**: Scheduled workflows are disabled on forked repositories
- **Fix**: This is a GitHub security feature. Workflows run on manual trigger and push events.

## Security Best Practices

1. **Never commit secrets**: Secrets are encrypted and never visible in logs
2. **Rotate tokens regularly**: Generate new API tokens every 90 days
3. **Use minimal permissions**: API token should only have permissions needed for sync
4. **Monitor usage**: Check Jira audit logs for API token usage

## Next Steps

After configuring secrets:

1. ✅ Manually trigger the workflow to test
2. ✅ Verify tasks are synced to project-task.md files
3. ✅ Make a checkbox change in project-task.md
4. ✅ Verify Jira issue status updates automatically
5. ✅ Monitor scheduled runs (every 15 minutes)

## Support

If you encounter issues:

1. Check the workflow logs in GitHub Actions
2. Verify all three secrets are configured
3. Verify Jira credentials are correct
4. Check that Jira issues have service labels (`ai-security-service`, `data-loader-service`)

---

**Last Updated**: January 2025
**Workflow File**: `.github/workflows/sync-project-tasks-to-jira.yml`
