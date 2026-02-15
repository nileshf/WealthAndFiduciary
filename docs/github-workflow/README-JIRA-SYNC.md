# Jira Sync Workflow - Complete Guide

## 🎯 Quick Start

The bidirectional Jira sync workflow is **ready to use**. Follow these 3 steps to activate it:

### 1️⃣ Configure GitHub Secrets (5 min)
Go to **Settings → Secrets and variables → Actions** and add:
- `JIRA_BASE_URL` = `https://nileshf.atlassian.net`
- `JIRA_USER_EMAIL` = Your Jira email
- `JIRA_API_TOKEN` = Your Jira API token

👉 **Detailed instructions**: See `GITHUB-SECRETS-SETUP.md`

### 2️⃣ Test the Workflow (2 min)
Go to **Actions → Sync Project Tasks to Jira → Run workflow** on main branch

### 3️⃣ Verify It Works (5 min)
- Check that Jira issues appear in project-task.md files
- Change a checkbox and verify Jira updates

**Total time**: ~12 minutes ⏱️

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **GITHUB-SECRETS-SETUP.md** | Step-by-step guide to configure GitHub Secrets |
| **JIRA-SYNC-WORKFLOW-FIXED.md** | Technical details of the workflow and fix |
| **JIRA-SYNC-ACTION-CHECKLIST.md** | Action items and verification steps |
| **JIRA-SYNC-COMPLETE-SUMMARY.md** | Complete technical summary |
| **README-JIRA-SYNC.md** | This file - quick reference |

---

## 🔄 How It Works

### Automatic Sync (Every 15 Minutes)
```
Jira Issues → Workflow → project-task.md files → Commit to main
```

### Manual Sync (On Checkbox Change)
```
Edit project-task.md → Commit to main → Workflow → Update Jira
```

### Checkbox Status Mapping
| Checkbox | Jira Status |
|----------|-------------|
| `[ ]` | To Do |
| `[-]` | In Progress |
| `[~]` | Testing |
| `[x]` | Done |

---

## 📋 Project Task Files

### SecurityService
- **File**: `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
- **Service Label**: `ai-security-service`

### DataLoaderService
- **File**: `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`
- **Service Label**: `data-loader-service`

---

## 🚀 Workflow Triggers

- **Push to main** - When project-task.md files change
- **Every 15 minutes** - Automatic scheduled sync
- **Manual** - Click "Run workflow" in GitHub Actions

---

## ✅ What's Fixed

✅ GitHub Actions permission issue (git push authentication)  
✅ Workflow configured for main branch  
✅ Service labels properly mapped  
✅ Bidirectional sync implemented  
✅ Comprehensive documentation created  

---

## ⚠️ What You Need to Do

1. Configure three GitHub Secrets
2. Test the workflow
3. Verify bidirectional sync works

**That's it!** The workflow will then run automatically.

---

## 🆘 Troubleshooting

**Workflow won't run?**
- Check GitHub Secrets are configured (Settings → Secrets and variables → Actions)

**Jira issues not syncing?**
- Verify issues have correct service labels (`ai-security-service` or `data-loader-service`)
- Verify issues are in "open" status (not Done/Closed/Resolved)

**Changes not syncing to Jira?**
- Verify you're on main branch
- Verify you committed and pushed the change
- Wait 1-2 minutes for workflow to run

**Still having issues?**
- Check workflow logs in GitHub Actions
- See `JIRA-SYNC-WORKFLOW-FIXED.md` for technical details

---

## 📞 Support

- **Setup Help**: `GITHUB-SECRETS-SETUP.md`
- **Technical Details**: `JIRA-SYNC-WORKFLOW-FIXED.md`
- **Action Items**: `JIRA-SYNC-ACTION-CHECKLIST.md`
- **Complete Summary**: `JIRA-SYNC-COMPLETE-SUMMARY.md`

---

## 🎉 Status

✅ **Workflow**: Fixed and ready  
✅ **Documentation**: Complete  
⏳ **Activation**: Awaiting GitHub Secrets configuration  

**Next Step**: Configure GitHub Secrets and test! 🚀

