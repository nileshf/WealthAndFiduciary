# Jira Sync Workflow - Quick Reference

## 🚀 Quick Start (5 Minutes)

### 1. Configure Secrets (Required)
```
Settings → Secrets and variables → Actions → New repository secret
```

Add these three secrets:
- `JIRA_BASE_URL` = `https://nileshf.atlassian.net`
- `JIRA_USER_EMAIL` = Your Jira email
- `JIRA_API_TOKEN` = Your Jira API token

### 2. Test Workflow
```
Actions → Sync Project Tasks to Jira → Run workflow → develop → Run workflow
```

### 3. Verify Results
- Check workflow logs for success
- Verify tasks in project-task.md files
- Verify Jira issues have labels

---

## 📋 What It Does

### Jira → project-task.md
- Fetches open Jira issues with service labels
- Adds tasks to project-task.md files
- Runs every 15 minutes automatically

### project-task.md → Jira
- Detects checkbox status changes
- Updates Jira issue statuses
- Runs on push to develop

---

## 🏷️ Service Labels

| Service | Label | File |
|---------|-------|------|
| SecurityService | `ai-security-service` | `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md` |
| DataLoaderService | `data-loader-service` | `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md` |

---

## ✅ Checkbox Mapping

| Checkbox | Jira Status |
|----------|-------------|
| `[ ]` | To Do |
| `[-]` | In Progress |
| `[~]` | Testing |
| `[x]` | Done |

---

## 🔍 Check Status

### View Workflow Runs
```
Actions → Sync Project Tasks to Jira → [Select run]
```

### View Logs
```
[Workflow run] → [Job name] → [Expand logs]
```

### Common Log Messages
- ✅ "Found X issues" = Jira connection successful
- ✅ "Added task WEALTHFID-XXX" = Task synced
- ⏭️ "No status changes detected" = No checkbox changes
- ❌ "401 Unauthorized" = Invalid credentials

---

## 🐛 Troubleshooting

| Error | Solution |
|-------|----------|
| "JiraBaseUrl is required" | Add `JIRA_BASE_URL` secret |
| "JiraEmail is required" | Add `JIRA_USER_EMAIL` secret |
| "JiraToken is required" | Add `JIRA_API_TOKEN` secret |
| "401 Unauthorized" | Verify credentials are correct |
| "404 Not Found" | Verify Jira URL is correct |
| "pwsh: command not found" | Use Ubuntu or Windows runner |
| "git push" fails | Verify `GITHUB_TOKEN` is available |

**Full Guide**: See `.github/WORKFLOW-TROUBLESHOOTING.md`

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `.github/GITHUB-SECRETS-SETUP.md` | How to configure secrets |
| `.github/WORKFLOW-TROUBLESHOOTING.md` | How to troubleshoot issues |
| `.github/WORKFLOW-FIXES-APPLIED.md` | What was fixed |
| `.github/JIRA-SYNC-STATUS.md` | Current status & deployment |

---

## 🔧 Manual Testing

### Test Jira Connection
```powershell
$env:JIRA_BASE_URL = "https://nileshf.atlassian.net"
$env:JIRA_USER_EMAIL = "your-email@example.com"
$env:JIRA_API_TOKEN = "your-token"

.\scripts\sync-jira-to-tasks.ps1 -Verbose -DryRun
```

### Test Status Sync
1. Edit project-task.md
2. Change `[ ]` to `[-]`
3. Commit and push
4. Check Jira issue status

---

## 📊 Workflow Triggers

| Trigger | Frequency | Purpose |
|---------|-----------|---------|
| Schedule | Every 15 min | Keep files in sync |
| Push | On develop | Sync checkbox changes |
| Manual | On demand | Test or force sync |

---

## ✨ Features

- ✅ Automatic Jira → project-task.md sync
- ✅ Automatic project-task.md → Jira sync
- ✅ Service-based routing (labels)
- ✅ Scheduled runs (every 15 minutes)
- ✅ Manual trigger support
- ✅ Comprehensive logging
- ✅ Error handling and reporting
- ✅ Git integration

---

## 🎯 Status

| Component | Status |
|-----------|--------|
| Workflow | ✅ Ready |
| Script | ✅ Ready |
| Secrets | ⚠️ Pending |
| Documentation | ✅ Complete |

**Overall**: ✅ **READY** (configure secrets first)

---

## 🚀 Next Steps

1. ✅ Configure GitHub Secrets (5 min)
2. ✅ Test workflow (5 min)
3. ✅ Verify results (5 min)
4. ✅ Monitor scheduled runs

**Total Time**: ~15 minutes

---

**Last Updated**: January 2025
**Workflow**: `.github/workflows/sync-project-tasks-to-jira.yml`
**Script**: `scripts/sync-jira-to-tasks.ps1`
