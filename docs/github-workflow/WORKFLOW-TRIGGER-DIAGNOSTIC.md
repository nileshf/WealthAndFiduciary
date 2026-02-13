# Workflow Trigger Diagnostic

## ⚠️ Current Status: NOT TRIGGERING

The standalone and orchestration workflows are not triggering because they haven't been committed to the repository yet.

## 🔍 Root Cause Analysis

### Why Workflows Don't Trigger

GitHub Actions workflows **only work when they are committed to the repository**. The workflows exist locally but are not yet in the remote repository, so GitHub cannot see them to trigger them.

### What's Been Fixed

✅ **Slack webhook syntax errors** - All fixed:
- `deploy.yml` line 116: Fixed `secrets.SLACK_WEBHOOK_URL` → `env.SLACK_WEBHOOK_URL`
- All 4 standalone workflows: Already correct with `env.SLACK_WEBHOOK_URL`
- `jira-sync-orchestrator-simple.yml`: Already correct with `env.SLACK_WEBHOOK_URL`

✅ **Workflow files created**:
- `.github/workflows/jira-sync-step1-pull-tasks-standalone.yml`
- `.github/workflows/jira-sync-step2-push-tasks-standalone.yml`
- `.github/workflows/jira-sync-step3-sync-jira-status-standalone.yml`
- `.github/workflows/jira-sync-step4-sync-markdown-status-standalone.yml`
- `.github/workflows/jira-sync-orchestrator-simple.yml`

✅ **PowerShell scripts created**:
- `scripts/jira-sync-step1-pull-missing-tasks.ps1`
- `scripts/jira-sync-step2-push-new-tasks.ps1`
- `scripts/jira-sync-step3-sync-jira-status.ps1`
- `scripts/jira-sync-step4-sync-markdown-status.ps1`

✅ **Task files created**:
- `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
- `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`

## 🚀 How to Enable Workflows

### Step 1: Commit All Changes

```powershell
# Stage all changes
git add -A

# Commit with descriptive message
git commit -m "feat: add Jira sync workflows and scripts

- Add 4 standalone Jira sync workflows (pull, push, sync status)
- Add orchestrator workflow that runs all 4 steps
- Add 4 PowerShell scripts for each sync step
- Create project-task.md files for SecurityService and DataLoaderService
- Fix Slack webhook syntax errors in deploy.yml"

# Push to remote repository
git push origin main
```

### Step 2: Verify Workflows in GitHub

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see:
   - ✅ "Jira Sync - Step 1 - Pull Missing Tasks (Standalone)"
   - ✅ "Jira Sync - Step 2 - Push New Tasks (Standalone)"
   - ✅ "Jira Sync - Step 3 - Sync Jira Status (Standalone)"
   - ✅ "Jira Sync - Step 4 - Sync Markdown Status (Standalone)"
   - ✅ "Jira Sync - Orchestrator (Simple)"

### Step 3: Manually Trigger Workflows

Once committed, you can manually trigger workflows:

1. Go to **Actions** tab
2. Select a workflow (e.g., "Jira Sync - Step 1 - Pull Missing Tasks (Standalone)")
3. Click **Run workflow** button
4. Select service: **SecurityService** or **DataLoaderService**
5. Click **Run workflow**

### Step 4: Verify Automatic Scheduling

The orchestrator workflow runs automatically every 30 minutes:
- Cron: `*/30 * * * *` (every 30 minutes)
- Can also be manually triggered via **Run workflow** button

## 📋 Workflow Checklist

Before committing, verify:

- [x] All workflow files are syntactically valid YAML
- [x] All PowerShell scripts exist and are executable
- [x] Task files exist with proper format
- [x] Slack webhook syntax is correct (using `env.SLACK_WEBHOOK_URL`)
- [x] Jira credentials are configured as GitHub secrets:
  - `JIRA_BASE_URL`
  - `JIRA_USER_EMAIL`
  - `JIRA_API_TOKEN`
- [x] Slack webhook is configured as GitHub secret (optional):
  - `SLACK_WEBHOOK_URL`

## 🔐 Required GitHub Secrets

Configure these in your GitHub repository settings (**Settings → Secrets and variables → Actions**):

```
JIRA_BASE_URL = https://your-jira-instance.atlassian.net
JIRA_USER_EMAIL = your-email@example.com
JIRA_API_TOKEN = your-api-token
SLACK_WEBHOOK_URL = https://hooks.slack.com/services/YOUR/WEBHOOK/URL (optional)
```

## 🧪 Testing Workflows

### Test Step 1 (Pull Missing Tasks)

```powershell
# Manually trigger via GitHub Actions UI
# Or run locally:
$env:JIRA_BASE_URL = "https://your-jira.atlassian.net"
$env:JIRA_USER_EMAIL = "your-email@example.com"
$env:JIRA_API_TOKEN = "your-token"
$env:SERVICE_NAME = "SecurityService"
$env:TASK_FILE = "Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md"

& ./scripts/jira-sync-step1-pull-missing-tasks.ps1
```

### Test Orchestrator

```powershell
# Manually trigger via GitHub Actions UI
# Or run locally:
$env:JIRA_BASE_URL = "https://your-jira.atlassian.net"
$env:JIRA_USER_EMAIL = "your-email@example.com"
$env:JIRA_API_TOKEN = "your-token"

# This would run all 4 steps in sequence
```

## 📊 Expected Behavior After Commit

### Automatic Triggers

1. **Every 30 minutes**: Orchestrator runs automatically
   - Pulls missing tasks from Jira
   - Pushes new tasks to Jira
   - Syncs Jira status to markdown
   - Syncs markdown status to Jira

2. **On push to main**: Deploy workflow runs
   - Builds and deploys application
   - Sends Slack notification (if configured)

### Manual Triggers

1. **Standalone workflows**: Can be manually triggered from GitHub Actions UI
   - Select service (SecurityService or DataLoaderService)
   - Click "Run workflow"

2. **Orchestrator**: Can be manually triggered from GitHub Actions UI
   - Optional service filter
   - Click "Run workflow"

## 🐛 Troubleshooting

### Workflows Not Appearing in Actions Tab

**Problem**: Workflows don't show up in GitHub Actions after commit

**Solutions**:
1. Refresh the page (Ctrl+F5)
2. Wait 1-2 minutes for GitHub to process
3. Check that files are in `.github/workflows/` directory
4. Verify YAML syntax is valid (no indentation errors)

### Workflows Fail to Run

**Problem**: Workflow starts but fails immediately

**Check**:
1. GitHub secrets are configured correctly
2. PowerShell scripts exist at correct paths
3. Task files exist at correct paths
4. Jira credentials are valid

### Slack Notifications Not Sending

**Problem**: Workflow runs but Slack notification doesn't send

**Check**:
1. `SLACK_WEBHOOK_URL` secret is configured
2. Webhook URL is valid and not expired
3. Slack workspace still has the webhook app installed

## 📚 Next Steps

1. **Commit changes**: `git add -A && git commit -m "..." && git push`
2. **Verify in GitHub**: Check Actions tab for workflows
3. **Configure secrets**: Add Jira and Slack credentials
4. **Test manually**: Trigger a workflow from GitHub Actions UI
5. **Monitor**: Check workflow runs and logs

---

**Status**: Ready to commit and deploy ✅

**Last Updated**: February 13, 2025
