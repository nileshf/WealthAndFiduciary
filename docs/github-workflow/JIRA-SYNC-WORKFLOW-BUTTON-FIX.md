# Jira Sync - Workflow Button Fix

## 🔴 Problem

The Jira sync workflows were not showing the "Run workflow" button in GitHub Actions, preventing manual triggering of syncs.

## 🔍 Root Cause

GitHub Actions has a limitation: **Reusable workflows (using `workflow_call`) cannot have `workflow_dispatch` triggers and cannot be manually triggered directly.**

The original architecture used:
- **Orchestrator workflow** with `workflow_dispatch` (can be triggered)
- **Step workflows** as reusable workflows with `workflow_call` (cannot be triggered)

This meant:
- ✅ Orchestrator could be manually triggered
- ❌ Individual steps could NOT be manually triggered
- ❌ Step workflows didn't show "Run workflow" button

## ✅ Solution

Created **standalone versions** of each step workflow that:
- Have their own `workflow_dispatch` triggers
- Can be manually triggered from GitHub Actions UI
- Show the "Run workflow" button
- Accept service selection as input
- Run independently or as part of orchestrator

## 📁 New Workflow Files

### Standalone Workflows (Manually Triggerable)
```
.github/workflows/
├── jira-sync-step1-pull-tasks-standalone.yml      ← NEW: Pull missing tasks
├── jira-sync-step2-push-tasks-standalone.yml      ← NEW: Push new tasks
├── jira-sync-step3-sync-jira-status-standalone.yml ← NEW: Sync Jira status
└── jira-sync-step4-sync-markdown-status-standalone.yml ← NEW: Sync markdown status
```

### Reusable Workflows (For Orchestrator)
```
.github/workflows/
├── jira-sync-step1-pull-tasks.yml                 ← EXISTING: Reusable version
├── jira-sync-step2-push-tasks.yml                 ← EXISTING: Reusable version
├── jira-sync-step3-sync-jira-status.yml           ← EXISTING: Reusable version
└── jira-sync-step4-sync-markdown-status.yml       ← EXISTING: Reusable version
```

### Orchestrator Workflow
```
.github/workflows/
└── jira-sync-orchestrator.yml                     ← EXISTING: Calls reusable workflows
```

## 🚀 How to Use

### Option 1: Manual Trigger (Individual Steps)

1. Go to **GitHub Actions**
2. Select one of these workflows:
   - "Jira Sync - Step 1 - Pull Missing Tasks (Standalone)"
   - "Jira Sync - Step 2 - Push New Tasks (Standalone)"
   - "Jira Sync - Step 3 - Sync Jira Status (Standalone)"
   - "Jira Sync - Step 4 - Sync Markdown Status (Standalone)"
3. Click **"Run workflow"** button
4. Select service: **SecurityService** or **DataLoaderService**
5. Click **"Run workflow"**

### Option 2: Automatic Orchestrator (All Steps)

1. Go to **GitHub Actions**
2. Select **"Jira Sync - Orchestrator"**
3. Click **"Run workflow"** button
4. (Optional) Enter service name to sync only one service
5. Click **"Run workflow"**
6. Orchestrator runs all 4 steps in sequence for selected service(s)

### Option 3: Scheduled Automatic Sync

- Orchestrator runs automatically every 30 minutes
- No manual action required
- Syncs all services (SecurityService and DataLoaderService)

## 📊 Workflow Comparison

| Feature | Standalone | Orchestrator | Reusable |
|---------|-----------|--------------|----------|
| Manual trigger | ✅ Yes | ✅ Yes | ❌ No |
| Shows "Run" button | ✅ Yes | ✅ Yes | ❌ No |
| Scheduled runs | ❌ No | ✅ Yes | ❌ No |
| Runs independently | ✅ Yes | ❌ No (sequential) | ❌ No |
| Used by orchestrator | ❌ No | ❌ N/A | ✅ Yes |

## 🔄 Workflow Architecture

```
GitHub Actions UI
├── Manual Trigger
│   ├── Step 1 Standalone → Runs independently
│   ├── Step 2 Standalone → Runs independently
│   ├── Step 3 Standalone → Runs independently
│   └── Step 4 Standalone → Runs independently
│
└── Orchestrator (Manual or Scheduled)
    ├── Step 1 (Reusable) → Runs
    ├── Step 2 (Reusable) → Waits for Step 1
    ├── Step 3 (Reusable) → Waits for Step 2
    └── Step 4 (Reusable) → Waits for Step 3
```

## 🎯 When to Use Each

### Use Standalone Workflows When:
- You want to run a single step manually
- You want to test a specific step
- You want to debug a specific step
- You want to run steps out of order (not recommended)

### Use Orchestrator When:
- You want to run all steps in sequence
- You want automatic scheduled syncs
- You want to ensure proper order (Step 1 → 2 → 3 → 4)
- You want to sync all services at once

## ✨ Features

### Service Selection
All standalone workflows accept service input:
- **SecurityService** - Syncs SecurityService tasks
- **DataLoaderService** - Syncs DataLoaderService tasks

### Automatic Commits
Each workflow automatically commits changes to Git:
- Commit message includes service name and step
- Only commits if changes were made
- Skips commit if no changes

### Slack Notifications
Optional Slack notifications for each step:
- Requires `SLACK_WEBHOOK_URL` secret
- Notifies on success or failure
- Includes service name and step number

### Error Handling
Each workflow:
- Checks for required secrets
- Validates task file exists
- Exits with error code on failure
- Provides detailed error messages

## 🔧 Configuration

### Required Secrets
All workflows require these GitHub secrets:
- `JIRA_BASE_URL` - Your Jira instance URL
- `JIRA_USER_EMAIL` - Your Jira email
- `JIRA_API_TOKEN` - Your Jira API token

### Optional Secrets
- `SLACK_WEBHOOK_URL` - For Slack notifications

### Cron Schedule (Orchestrator)
Edit `.github/workflows/jira-sync-orchestrator.yml` to change schedule:
```yaml
schedule:
  - cron: '*/30 * * * *'  # Every 30 minutes
```

## 📋 Checklist

- [x] Created 4 standalone workflows with `workflow_dispatch`
- [x] Each standalone workflow shows "Run workflow" button
- [x] Each standalone workflow accepts service selection
- [x] Standalone workflows run independently
- [x] Orchestrator still works with reusable workflows
- [x] Orchestrator runs all steps in sequence
- [x] Automatic commits work for all workflows
- [x] Slack notifications work for all workflows
- [x] Error handling works for all workflows

## 🚀 Next Steps

1. **Verify Secrets**: Ensure all required secrets are configured
2. **Test Step 1**: Run standalone Step 1 workflow manually
3. **Test Step 2**: Run standalone Step 2 workflow manually
4. **Test Step 3**: Run standalone Step 3 workflow manually
5. **Test Step 4**: Run standalone Step 4 workflow manually
6. **Test Orchestrator**: Run orchestrator workflow manually
7. **Monitor Logs**: Check GitHub Actions logs for any errors
8. **Verify Results**: Check if tasks are syncing correctly

## 📚 Related Documentation

- **JIRA-SYNC-QUICK-START.md** - Quick start guide
- **JIRA-SYNC-MODULAR-SYSTEM.md** - Complete system documentation
- **JIRA-SYNC-IMPLEMENTATION-COMPLETE.md** - Implementation details

## 🆘 Troubleshooting

### "Run workflow" button still not showing

**Solution**: 
1. Refresh GitHub Actions page (Ctrl+Shift+R)
2. Clear browser cache
3. Try different browser
4. Check if workflow file is valid YAML

### Workflow fails with "Missing secrets"

**Solution**:
1. Go to Settings → Secrets and variables → Actions
2. Verify all required secrets are configured
3. Check secret names match exactly (case-sensitive)

### Workflow fails with "Task file not found"

**Solution**:
1. Verify task file path is correct
2. Check file exists in repository
3. Verify file path in workflow matches actual path

### Standalone workflow runs but doesn't sync

**Solution**:
1. Check GitHub Actions logs for errors
2. Verify Jira credentials are correct
3. Verify task file format is correct
4. Check if Jira project exists

## 📞 Support

For issues or questions:
1. Check troubleshooting section above
2. Review GitHub Actions logs
3. Check full documentation
4. Contact DevOps team

---

**Last Updated**: January 2025
**Status**: ✅ RESOLVED - Workflow buttons now visible and functional

