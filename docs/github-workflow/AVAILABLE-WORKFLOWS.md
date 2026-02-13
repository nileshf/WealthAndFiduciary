# Available GitHub Actions Workflows

## 📋 Complete Workflow List

### Jira Sync Workflows

#### 🟢 Standalone Workflows (Manually Triggerable)
These workflows show the "Run workflow" button and can be triggered manually.

1. **Jira Sync - Step 1 - Pull Missing Tasks (Standalone)**
   - File: `.github/workflows/jira-sync-step1-pull-tasks-standalone.yml`
   - Purpose: Pull missing tasks from Jira to markdown
   - Trigger: Manual (workflow_dispatch)
   - Input: Service selection (SecurityService or DataLoaderService)
   - Status: ✅ Shows "Run workflow" button

2. **Jira Sync - Step 2 - Push New Tasks (Standalone)**
   - File: `.github/workflows/jira-sync-step2-push-tasks-standalone.yml`
   - Purpose: Push new tasks from markdown to Jira
   - Trigger: Manual (workflow_dispatch)
   - Input: Service selection (SecurityService or DataLoaderService)
   - Status: ✅ Shows "Run workflow" button

3. **Jira Sync - Step 3 - Sync Jira Status (Standalone)**
   - File: `.github/workflows/jira-sync-step3-sync-jira-status-standalone.yml`
   - Purpose: Sync task status from Jira to markdown
   - Trigger: Manual (workflow_dispatch)
   - Input: Service selection (SecurityService or DataLoaderService)
   - Status: ✅ Shows "Run workflow" button

4. **Jira Sync - Step 4 - Sync Markdown Status (Standalone)**
   - File: `.github/workflows/jira-sync-step4-sync-markdown-status-standalone.yml`
   - Purpose: Sync task status from markdown to Jira
   - Trigger: Manual (workflow_dispatch)
   - Input: Service selection (SecurityService or DataLoaderService)
   - Status: ✅ Shows "Run workflow" button

#### 🔵 Orchestrator Workflow (Scheduled + Manual)
This workflow runs all steps in sequence.

5. **Jira Sync - Orchestrator**
   - File: `.github/workflows/jira-sync-orchestrator.yml`
   - Purpose: Run all 4 sync steps in sequence
   - Trigger: Scheduled (every 30 minutes) + Manual (workflow_dispatch)
   - Input: Service selection (optional, defaults to all)
   - Status: ✅ Shows "Run workflow" button
   - Execution: Step 1 → Step 2 → Step 3 → Step 4

#### ⚪ Reusable Workflows (Called by Orchestrator)
These workflows are called by the orchestrator and cannot be triggered manually.

6. **Jira Sync - Step 1 - Pull Missing Tasks** (Reusable)
   - File: `.github/workflows/jira-sync-step1-pull-tasks.yml`
   - Type: Reusable workflow (workflow_call)
   - Used by: Orchestrator
   - Status: ❌ No "Run workflow" button (reusable only)

7. **Jira Sync - Step 2 - Push New Tasks** (Reusable)
   - File: `.github/workflows/jira-sync-step2-push-tasks.yml`
   - Type: Reusable workflow (workflow_call)
   - Used by: Orchestrator
   - Status: ❌ No "Run workflow" button (reusable only)

8. **Jira Sync - Step 3 - Sync Jira Status** (Reusable)
   - File: `.github/workflows/jira-sync-step3-sync-jira-status.yml`
   - Type: Reusable workflow (workflow_call)
   - Used by: Orchestrator
   - Status: ❌ No "Run workflow" button (reusable only)

9. **Jira Sync - Step 4 - Sync Markdown Status** (Reusable)
   - File: `.github/workflows/jira-sync-step4-sync-markdown-status.yml`
   - Type: Reusable workflow (workflow_call)
   - Used by: Orchestrator
   - Status: ❌ No "Run workflow" button (reusable only)

## 🎯 Quick Reference

### To Run All Steps (Recommended)
```
GitHub Actions → Jira Sync - Orchestrator → Run workflow
```

### To Run Individual Step
```
GitHub Actions → Jira Sync - Step X - [Name] (Standalone) → Run workflow
```

### To Run Specific Service Only
```
GitHub Actions → Jira Sync - Orchestrator → Run workflow
Input: service_name = SecurityService (or DataLoaderService)
```

## 📊 Workflow Status Summary

| Workflow | Type | Trigger | Button | Manual | Scheduled |
|----------|------|---------|--------|--------|-----------|
| Step 1 Standalone | Standalone | workflow_dispatch | ✅ | ✅ | ❌ |
| Step 2 Standalone | Standalone | workflow_dispatch | ✅ | ✅ | ❌ |
| Step 3 Standalone | Standalone | workflow_dispatch | ✅ | ✅ | ❌ |
| Step 4 Standalone | Standalone | workflow_dispatch | ✅ | ✅ | ❌ |
| Orchestrator | Orchestrator | workflow_dispatch + cron | ✅ | ✅ | ✅ |
| Step 1 Reusable | Reusable | workflow_call | ❌ | ❌ | ❌ |
| Step 2 Reusable | Reusable | workflow_call | ❌ | ❌ | ❌ |
| Step 3 Reusable | Reusable | workflow_call | ❌ | ❌ | ❌ |
| Step 4 Reusable | Reusable | workflow_call | ❌ | ❌ | ❌ |

## 🔄 Workflow Relationships

```
GitHub Actions UI
│
├── Standalone Workflows (Manual Trigger)
│   ├── Step 1 Standalone ──→ Runs independently
│   ├── Step 2 Standalone ──→ Runs independently
│   ├── Step 3 Standalone ──→ Runs independently
│   └── Step 4 Standalone ──→ Runs independently
│
└── Orchestrator (Manual or Scheduled)
    ├── Calls Step 1 Reusable ──→ Runs
    ├── Calls Step 2 Reusable ──→ Waits for Step 1
    ├── Calls Step 3 Reusable ──→ Waits for Step 2
    └── Calls Step 4 Reusable ──→ Waits for Step 3
```

## 📁 Workflow Files Location

```
.github/workflows/
├── jira-sync-step1-pull-tasks-standalone.yml          ✅ Manual trigger
├── jira-sync-step2-push-tasks-standalone.yml          ✅ Manual trigger
├── jira-sync-step3-sync-jira-status-standalone.yml    ✅ Manual trigger
├── jira-sync-step4-sync-markdown-status-standalone.yml ✅ Manual trigger
├── jira-sync-orchestrator.yml                         ✅ Manual + Scheduled
├── jira-sync-step1-pull-tasks.yml                     ⚪ Reusable only
├── jira-sync-step2-push-tasks.yml                     ⚪ Reusable only
├── jira-sync-step3-sync-jira-status.yml               ⚪ Reusable only
└── jira-sync-step4-sync-markdown-status.yml           ⚪ Reusable only
```

## 🚀 Usage Scenarios

### Scenario 1: Run All Steps for All Services
```
1. Go to GitHub Actions
2. Click "Jira Sync - Orchestrator"
3. Click "Run workflow"
4. Click "Run workflow"
5. Wait for all 4 steps to complete
```

### Scenario 2: Run All Steps for Specific Service
```
1. Go to GitHub Actions
2. Click "Jira Sync - Orchestrator"
3. Click "Run workflow"
4. Enter service_name: SecurityService
5. Click "Run workflow"
6. Wait for all 4 steps to complete
```

### Scenario 3: Run Individual Step
```
1. Go to GitHub Actions
2. Click "Jira Sync - Step 1 - Pull Missing Tasks (Standalone)"
3. Click "Run workflow"
4. Select service: SecurityService
5. Click "Run workflow"
6. Wait for step to complete
```

### Scenario 4: Debug Specific Step
```
1. Go to GitHub Actions
2. Click "Jira Sync - Step 3 - Sync Jira Status (Standalone)"
3. Click "Run workflow"
4. Select service: DataLoaderService
5. Click "Run workflow"
6. Check logs for debugging
```

### Scenario 5: Automatic Scheduled Sync
```
1. Orchestrator runs automatically every 30 minutes
2. All 4 steps run in sequence
3. All services synced
4. Slack notification sent (if configured)
5. No manual action required
```

## ✅ Verification Checklist

After deployment, verify all workflows:

- [ ] Step 1 Standalone shows "Run workflow" button
- [ ] Step 2 Standalone shows "Run workflow" button
- [ ] Step 3 Standalone shows "Run workflow" button
- [ ] Step 4 Standalone shows "Run workflow" button
- [ ] Orchestrator shows "Run workflow" button
- [ ] Step 1 Reusable does NOT show "Run workflow" button
- [ ] Step 2 Reusable does NOT show "Run workflow" button
- [ ] Step 3 Reusable does NOT show "Run workflow" button
- [ ] Step 4 Reusable does NOT show "Run workflow" button

## 📚 Documentation

- **WORKFLOW-BUTTON-ISSUE-RESOLVED.md** - Issue explanation and solution
- **JIRA-SYNC-WORKFLOW-BUTTON-FIX.md** - Detailed technical documentation
- **JIRA-SYNC-QUICK-START.md** - Quick start guide
- **JIRA-SYNC-MODULAR-SYSTEM.md** - Complete system documentation
- **AVAILABLE-WORKFLOWS.md** - This file

## 🆘 Troubleshooting

### "Run workflow" button not showing for standalone workflow
- Refresh page (Ctrl+Shift+R)
- Clear browser cache
- Try different browser
- Check workflow file is valid YAML

### Workflow fails with missing secrets
- Go to Settings → Secrets and variables → Actions
- Verify all required secrets are configured
- Check secret names match exactly (case-sensitive)

### Workflow fails with task file not found
- Verify task file path is correct
- Check file exists in repository
- Verify file path in workflow matches actual path

## 📞 Support

For issues or questions:
1. Check troubleshooting section above
2. Review GitHub Actions logs
3. Check documentation files
4. Contact DevOps team

---

**Last Updated**: January 2025
**Total Workflows**: 9 (4 standalone + 1 orchestrator + 4 reusable)
**Status**: ✅ All workflows operational

