# Workflow Documentation Index

## 📚 Quick Navigation

### 🚀 Start Here (5 minutes)
- **[ENABLE-WORKFLOWS-NOW.md](./ENABLE-WORKFLOWS-NOW.md)** - Quick action guide to get workflows running
  - 3 simple steps
  - Copy-paste commands
  - Verification checklist

### 🔍 Understanding the Issue
- **[WHY-WORKFLOWS-NOT-TRIGGERING.md](./WHY-WORKFLOWS-NOT-TRIGGERING.md)** - Complete explanation
  - Why workflows don't trigger
  - How GitHub Actions works
  - Common mistakes to avoid
  - Verification steps

### 📊 Status & Details
- **[WORKFLOW-STATUS-SUMMARY.md](./WORKFLOW-STATUS-SUMMARY.md)** - Current status overview
  - What's ready
  - What's fixed
  - Blocking issues
  - Next steps

### 🔧 Detailed Diagnostic
- **[WORKFLOW-TRIGGER-DIAGNOSTIC.md](./WORKFLOW-TRIGGER-DIAGNOSTIC.md)** - In-depth analysis
  - Root cause analysis
  - What's been fixed
  - How to enable workflows
  - Testing procedures
  - Troubleshooting guide

## 📋 What Was Created

### Workflows (5 Total)

1. **Jira Sync - Step 1 - Pull Missing Tasks (Standalone)**
   - File: `.github/workflows/jira-sync-step1-pull-tasks-standalone.yml`
   - Trigger: Manual (via GitHub Actions UI)
   - Services: SecurityService, DataLoaderService

2. **Jira Sync - Step 2 - Push New Tasks (Standalone)**
   - File: `.github/workflows/jira-sync-step2-push-tasks-standalone.yml`
   - Trigger: Manual (via GitHub Actions UI)
   - Services: SecurityService, DataLoaderService

3. **Jira Sync - Step 3 - Sync Jira Status (Standalone)**
   - File: `.github/workflows/jira-sync-step3-sync-jira-status-standalone.yml`
   - Trigger: Manual (via GitHub Actions UI)
   - Services: SecurityService, DataLoaderService

4. **Jira Sync - Step 4 - Sync Markdown Status (Standalone)**
   - File: `.github/workflows/jira-sync-step4-sync-markdown-status-standalone.yml`
   - Trigger: Manual (via GitHub Actions UI)
   - Services: SecurityService, DataLoaderService

5. **Jira Sync - Orchestrator (Simple)**
   - File: `.github/workflows/jira-sync-orchestrator-simple.yml`
   - Trigger: Automatic (every 30 minutes) + Manual
   - Services: All services

### PowerShell Scripts (4 Total)

1. **Step 1 - Pull Missing Tasks**
   - File: `scripts/jira-sync-step1-pull-missing-tasks.ps1`
   - Purpose: Pull tasks from Jira that are missing in markdown

2. **Step 2 - Push New Tasks**
   - File: `scripts/jira-sync-step2-push-new-tasks.ps1`
   - Purpose: Push new tasks from markdown to Jira

3. **Step 3 - Sync Jira Status**
   - File: `scripts/jira-sync-step3-sync-jira-status.ps1`
   - Purpose: Sync Jira status to markdown checkboxes

4. **Step 4 - Sync Markdown Status**
   - File: `scripts/jira-sync-step4-sync-markdown-status.ps1`
   - Purpose: Sync markdown checkboxes to Jira status

### Task Files (2 Total)

1. **SecurityService Tasks**
   - File: `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
   - Tasks: 15 tasks (implementation, testing, infrastructure)

2. **DataLoaderService Tasks**
   - File: `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`
   - Tasks: 15 tasks (implementation, testing, infrastructure)

## ✅ What Was Fixed

### Slack Webhook Syntax Error

**File**: `.github/workflows/deploy.yml`
**Issue**: `if: always() && secrets.SLACK_WEBHOOK_URL != ''`
**Fix**: `if: always() && env.SLACK_WEBHOOK_URL != ''`
**Reason**: `secrets` context not available in step-level `if` conditions

**Status**: ✅ Fixed

## 🎯 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| Workflows | ✅ Created | 5 workflows ready |
| Scripts | ✅ Created | 4 scripts ready |
| Task Files | ✅ Created | 2 task files ready |
| Syntax | ✅ Valid | All YAML is valid |
| Fixes | ✅ Applied | Slack webhook fixed |
| **Committed** | ❌ **NOT YET** | **BLOCKING** |
| **Visible** | ❌ **NOT YET** | Waiting for commit |
| **Triggerable** | ❌ **NOT YET** | Waiting for commit |

## 🚀 How to Enable (Quick Version)

```powershell
# 1. Commit all changes
git add -A
git commit -m "feat: add Jira sync automation"
git push origin main

# 2. Wait 1-2 minutes

# 3. Go to GitHub Actions tab
# 4. Should see 5 new workflows
# 5. Click "Run workflow" to test
```

## 📖 Documentation by Use Case

### "I want to understand what happened"
→ Read: [WHY-WORKFLOWS-NOT-TRIGGERING.md](./WHY-WORKFLOWS-NOT-TRIGGERING.md)

### "I want to enable workflows right now"
→ Read: [ENABLE-WORKFLOWS-NOW.md](./ENABLE-WORKFLOWS-NOW.md)

### "I want to see the current status"
→ Read: [WORKFLOW-STATUS-SUMMARY.md](./WORKFLOW-STATUS-SUMMARY.md)

### "I want detailed technical information"
→ Read: [WORKFLOW-TRIGGER-DIAGNOSTIC.md](./WORKFLOW-TRIGGER-DIAGNOSTIC.md)

### "I want to troubleshoot issues"
→ Read: [WORKFLOW-TRIGGER-DIAGNOSTIC.md](./WORKFLOW-TRIGGER-DIAGNOSTIC.md) (Troubleshooting section)

## 🔐 Required GitHub Secrets

Configure these in **Settings → Secrets and variables → Actions**:

```
JIRA_BASE_URL = https://your-jira-instance.atlassian.net
JIRA_USER_EMAIL = your-email@example.com
JIRA_API_TOKEN = your-api-token
SLACK_WEBHOOK_URL = https://hooks.slack.com/services/YOUR/WEBHOOK/URL (optional)
```

## 📊 Workflow Execution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Orchestrator Workflow                         │
│                  (Runs every 30 minutes)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                │             │             │
                ▼             ▼             ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │   Step 1     │ │   Step 2     │ │   Step 3     │
        │ Pull Missing │ │ Push New     │ │ Sync Jira    │
        │   Tasks      │ │   Tasks      │ │   Status     │
        └──────────────┘ └──────────────┘ └──────────────┘
                │             │             │
                └─────────────┼─────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │   Step 4     │
                        │ Sync Markdown│
                        │   Status     │
                        └──────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │ Commit & Push│
                        │   Changes    │
                        └──────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │ Send Slack   │
                        │ Notification │
                        └──────────────┘
```

## 🧪 Testing Workflows

### Test Step 1 (Pull Missing Tasks)

1. Go to **Actions** tab
2. Click "Jira Sync - Step 1 - Pull Missing Tasks (Standalone)"
3. Click **Run workflow**
4. Select service: **SecurityService**
5. Click **Run workflow**
6. Watch execution

### Test Orchestrator

1. Go to **Actions** tab
2. Click "Jira Sync - Orchestrator (Simple)"
3. Click **Run workflow**
4. Leave service empty (runs all)
5. Click **Run workflow**
6. Watch all 4 steps execute

## 📞 Support

### Workflows Not Appearing

1. Refresh GitHub page (Ctrl+F5)
2. Wait 1-2 minutes after commit
3. Check that files are in `.github/workflows/`
4. Verify YAML syntax is valid

### Workflows Fail to Run

1. Check GitHub secrets are configured
2. Verify Jira credentials are valid
3. Check PowerShell scripts exist
4. Review workflow logs for errors

### Slack Notifications Not Sending

1. Verify `SLACK_WEBHOOK_URL` secret is configured
2. Check webhook URL is valid
3. Verify Slack app is still installed

## 📚 Related Documentation

- **Jira Sync Quick Start**: `.github/JIRA-SYNC-QUICK-START.md`
- **Available Workflows**: `.github/AVAILABLE-WORKFLOWS.md`
- **Workflow Button Fix**: `.github/JIRA-SYNC-WORKFLOW-BUTTON-FIX.md`

## ✨ Summary

Everything is ready to go! All you need to do is:

1. **Commit and push** your changes
2. **Wait 1-2 minutes** for GitHub to process
3. **Verify** workflows appear in Actions tab
4. **Configure secrets** (if not already done)
5. **Test** by manually triggering a workflow

---

**Status**: Ready to deploy ✅
**Blocking Issue**: Commit required ⚠️
**Time to Enable**: ~5 minutes ⏱️

**Last Updated**: February 13, 2025
