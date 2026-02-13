# ⚡ Enable Workflows NOW - Quick Action Guide

## The Problem

Workflows are created but **not committed to the repository**, so GitHub can't see them.

## The Solution (3 Steps)

### Step 1: Commit Everything

```powershell
cd your-repo-root

# Stage all changes
git add -A

# Commit
git commit -m "feat: add Jira sync automation

- Add 4 standalone Jira sync workflows
- Add orchestrator workflow (runs every 30 min)
- Add 4 PowerShell sync scripts
- Create project-task.md files
- Fix Slack webhook syntax errors"

# Push to GitHub
git push origin main
```

### Step 2: Wait 1-2 Minutes

GitHub needs time to process the new workflows.

### Step 3: Verify in GitHub

1. Go to your GitHub repo
2. Click **Actions** tab
3. You should see 5 new workflows:
   - ✅ Jira Sync - Step 1 - Pull Missing Tasks (Standalone)
   - ✅ Jira Sync - Step 2 - Push New Tasks (Standalone)
   - ✅ Jira Sync - Step 3 - Sync Jira Status (Standalone)
   - ✅ Jira Sync - Step 4 - Sync Markdown Status (Standalone)
   - ✅ Jira Sync - Orchestrator (Simple)

## Verify Secrets Are Configured

Go to **Settings → Secrets and variables → Actions** and verify:

- ✅ `JIRA_BASE_URL` = your Jira URL
- ✅ `JIRA_USER_EMAIL` = your email
- ✅ `JIRA_API_TOKEN` = your API token
- ✅ `SLACK_WEBHOOK_URL` = (optional) your Slack webhook

## Test It

1. Go to **Actions** tab
2. Click "Jira Sync - Step 1 - Pull Missing Tasks (Standalone)"
3. Click **Run workflow** button
4. Select service: **SecurityService**
5. Click **Run workflow**
6. Watch it execute!

## What Happens Next

### Automatic (Every 30 Minutes)
- Orchestrator runs automatically
- Pulls missing tasks from Jira
- Pushes new tasks to Jira
- Syncs status both ways

### Manual (Anytime)
- Click "Run workflow" on any standalone workflow
- Select service
- Watch it execute

## Files That Were Created

✅ Workflows:
- `.github/workflows/jira-sync-step1-pull-tasks-standalone.yml`
- `.github/workflows/jira-sync-step2-push-tasks-standalone.yml`
- `.github/workflows/jira-sync-step3-sync-jira-status-standalone.yml`
- `.github/workflows/jira-sync-step4-sync-markdown-status-standalone.yml`
- `.github/workflows/jira-sync-orchestrator-simple.yml`

✅ Scripts:
- `scripts/jira-sync-step1-pull-missing-tasks.ps1`
- `scripts/jira-sync-step2-push-new-tasks.ps1`
- `scripts/jira-sync-step3-sync-jira-status.ps1`
- `scripts/jira-sync-step4-sync-markdown-status.ps1`

✅ Task Files:
- `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
- `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`

✅ Fixes:
- `deploy.yml` - Fixed Slack webhook syntax error

## That's It! 🎉

Once you commit and push, the workflows will be live and ready to use.

---

**Time to enable**: ~5 minutes
**Difficulty**: Easy ✅
