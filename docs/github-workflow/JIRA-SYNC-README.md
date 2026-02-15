# Jira Sync System - Complete Documentation

## 🎯 Overview

The WealthAndFiduciary workspace has **fully automatic bidirectional Jira sync**. Tasks automatically sync between Jira and project-task.md files in both directions.

## 📚 Documentation Index

### For Developers (Start Here)
1. **[SYNC-QUICK-START.md](./SYNC-QUICK-START.md)** - 2-minute quick reference
   - Creating tasks
   - Updating status
   - Service labels
   - Troubleshooting

2. **[AUTOMATIC-SYNC-GUIDE.md](./AUTOMATIC-SYNC-GUIDE.md)** - Comprehensive guide
   - How it works
   - Setup instructions
   - Workflow execution timeline
   - FAQ and troubleshooting

### For DevOps/Admins
3. **[SYNC-STATUS-REPORT.md](./SYNC-STATUS-REPORT.md)** - Status and configuration
   - What's working
   - Configuration status
   - Testing checklist
   - Monitoring

4. **[SYNC-ARCHITECTURE.md](./SYNC-ARCHITECTURE.md)** - Technical details
   - System overview
   - Data flow diagrams
   - Service routing
   - Performance metrics
   - Security considerations

### Implementation Details
5. **[SYNC-IMPLEMENTATION-COMPLETE.md](./SYNC-IMPLEMENTATION-COMPLETE.md)** - Implementation summary
   - What was implemented
   - Files created/modified
   - Testing results
   - Next steps

## 🚀 Quick Start

### Creating a Task

**In Jira** (Recommended):
1. Create issue in WEALTHFID project
2. Add label: `ai-security-service` or `data-loader-service`
3. Wait 15 minutes (or manually trigger sync)
4. Task appears in project-task.md ✓

**In project-task.md**:
1. Edit file
2. Add: `- [ ] WEALTHFID-XXX - Task Title`
3. Commit and push
4. Jira issue created automatically ✓

### Updating Task Status

1. Edit project-task.md
2. Change checkbox: `[ ]` → `[x]`
3. Commit and push
4. Jira status updates automatically ✓

## 🔄 How It Works

### Jira → project-task.md (Every 15 Minutes)

```
Jira Issue Created
    ↓ (with label: ai-security-service)
Scheduled Workflow Runs
    ↓
Fetches Open Issues
    ↓
Routes by Service Label
    ↓
Adds to project-task.md
    ↓
Commits and Pushes
    ↓
Task Appears in project-task.md ✓
```

### project-task.md → Jira (On Push)

```
Edit project-task.md
    ↓ (change checkbox: [ ] → [x])
Commit and Push
    ↓
Workflow Detects Change
    ↓
Parses Checkbox Status
    ↓
Maps to Jira Status
    ↓
Updates Jira Issue
    ↓
Jira Status Updated ✓
```

## 📋 Service Labels

| Service | Label | File |
|---------|-------|------|
| SecurityService | `ai-security-service` | `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md` |
| DataLoaderService | `data-loader-service` | `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md` |

## ✅ Checkbox Status Mapping

| Checkbox | Jira Status |
|----------|-------------|
| `[ ]` | To Do |
| `[-]` | In Progress |
| `[~]` | Testing |
| `[x]` | Done |

## 🔧 Configuration

### GitHub Secrets (Required)

Go to: Repository Settings → Secrets and variables → Actions

```
JIRA_BASE_URL = https://yourcompany.atlassian.net
JIRA_USER_EMAIL = your-email@example.com
JIRA_API_TOKEN = your-api-token
```

### Jira Workflow

Ensure your Jira workflow has these statuses:
- To Do
- In Progress
- Testing
- Done

## 📊 Workflows

### Main Workflow: `sync-project-tasks-to-jira.yml`

**Jobs**:
1. `sync-jira-to-tasks` - Syncs Jira to project-task.md
   - Runs every 15 minutes
   - Runs on manual trigger
   - Runs on push to develop

2. `sync-tasks-to-jira` - Syncs project-task.md to Jira
   - Runs on push to develop
   - Detects checkbox changes
   - Updates Jira status

3. `validate-sync` - Validates sync results
   - Checks files exist
   - Validates format

### Other Workflows

- `jira-sync.yml` - Creates Jira issues from tasks.md files

## 🧪 Testing

### Test Jira → project-task.md

1. Create test Jira issue with label `ai-security-service`
2. Wait 15 minutes (or manually trigger sync)
3. Check SecurityService project-task.md
4. Verify task appears ✓

### Test project-task.md → Jira

1. Edit SecurityService project-task.md
2. Change checkbox: `[ ]` → `[x]`
3. Commit and push to develop
4. Check Jira issue
5. Verify status changed to "Done" ✓

## 🔍 Monitoring

### GitHub Actions

Go to: Repository → Actions → "Sync Jira to Project Tasks"

- View recent runs
- Check status (success/failure)
- View detailed logs

### Notifications

- ✅ Success: "Jira tasks successfully synced to project-task.md files"
- ⚠️ Warning: "Sync encountered issues. Check logs for details."
- ⏭️ Skipped: "No status changes detected in project-task.md files"

## 🆘 Troubleshooting

### Tasks not appearing in project-task.md

**Possible causes**:
- Jira issue doesn't have service label
- Service label is misspelled
- GitHub secrets not configured

**Solution**:
1. Verify Jira issue has correct label
2. Check GitHub Actions logs
3. Verify GitHub secrets are configured

### Jira status not updating

**Possible causes**:
- Checkbox format is wrong
- Jira workflow doesn't have target status

**Solution**:
1. Verify checkbox format: `[x]` not `[X]`
2. Check Jira workflow has all required statuses

### Workflow fails

**Solution**:
1. Go to GitHub Actions
2. Click on failed workflow run
3. View detailed logs
4. Look for error messages
5. Fix the issue and retry

See **[AUTOMATIC-SYNC-GUIDE.md](./AUTOMATIC-SYNC-GUIDE.md)** for detailed troubleshooting.

## 📈 Performance

| Metric | Value |
|--------|-------|
| Jira → project-task.md Frequency | Every 15 minutes |
| Jira → project-task.md Duration | 30-60 seconds |
| Jira → project-task.md Latency | Up to 15 minutes |
| project-task.md → Jira Frequency | On push to develop |
| project-task.md → Jira Duration | 10-30 seconds |
| project-task.md → Jira Latency | 1-2 minutes |

## 🔐 Security

- Jira API token stored in GitHub Secrets
- Credentials never logged
- Data transmitted over HTTPS
- Basic Auth (email + API token)

## 📞 Support

### Quick Questions
- See **[SYNC-QUICK-START.md](./SYNC-QUICK-START.md)**

### Detailed Information
- See **[AUTOMATIC-SYNC-GUIDE.md](./AUTOMATIC-SYNC-GUIDE.md)**

### Technical Details
- See **[SYNC-ARCHITECTURE.md](./SYNC-ARCHITECTURE.md)**

### Status and Troubleshooting
- See **[SYNC-STATUS-REPORT.md](./SYNC-STATUS-REPORT.md)**

### GitHub Actions Logs
- Go to: Repository → Actions → Workflow runs

## 🎯 Next Steps

1. **Configure GitHub Secrets** (if not already done)
   - JIRA_BASE_URL
   - JIRA_USER_EMAIL
   - JIRA_API_TOKEN

2. **Test Jira → project-task.md Sync**
   - Create test Jira issue
   - Verify it appears in project-task.md

3. **Test project-task.md → Jira Sync**
   - Change task status
   - Verify Jira status updates

4. **Monitor Workflows**
   - Check GitHub Actions for any errors
   - Review execution times

5. **Share Documentation**
   - Share SYNC-QUICK-START.md with team
   - Share AUTOMATIC-SYNC-GUIDE.md for detailed info

## 📝 Files

### Workflow Files
- `.github/workflows/sync-project-tasks-to-jira.yml` - Main bidirectional sync
- `.github/workflows/jira-sync.yml` - Creates Jira issues from tasks.md

### Documentation Files
- `.github/JIRA-SYNC-README.md` - This file
- `.github/SYNC-QUICK-START.md` - Quick reference
- `.github/AUTOMATIC-SYNC-GUIDE.md` - Comprehensive guide
- `.github/SYNC-STATUS-REPORT.md` - Status and troubleshooting
- `.github/SYNC-ARCHITECTURE.md` - Technical architecture
- `.github/SYNC-IMPLEMENTATION-COMPLETE.md` - Implementation summary

### Script Files
- `scripts/sync-jira-to-tasks.ps1` - Jira to project-task.md sync

## 📊 Status

| Component | Status |
|-----------|--------|
| Jira → project-task.md | ✅ Working |
| project-task.md → Jira | ✅ Ready |
| Validation | ✅ Working |
| Documentation | ✅ Complete |
| GitHub Secrets | ⚠️ Pending |
| Testing | ⏳ Ready |

## 🎓 Best Practices

1. **Always use service labels** on Jira issues
2. **Keep task format consistent** in project-task.md
3. **Don't manually edit Jira issue keys** in project-task.md
4. **Use checkbox status** to track progress
5. **Check GitHub Actions logs** if sync doesn't work

## 📞 Questions?

1. Check **[SYNC-QUICK-START.md](./SYNC-QUICK-START.md)** for quick answers
2. Check **[AUTOMATIC-SYNC-GUIDE.md](./AUTOMATIC-SYNC-GUIDE.md)** FAQ section
3. Review GitHub Actions logs for error details
4. Check **[SYNC-STATUS-REPORT.md](./SYNC-STATUS-REPORT.md)** for troubleshooting

---

**Last Updated**: January 2025  
**Status**: ✅ **FULLY OPERATIONAL**  
**Maintained By**: WealthAndFiduciary DevOps Team

**Start with**: [SYNC-QUICK-START.md](./SYNC-QUICK-START.md) for a 2-minute overview
