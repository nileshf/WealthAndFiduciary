# Jira Sync - Quick Start Guide

## ⚡ 5-Minute Setup

### Step 1: Configure Jira Secrets (2 minutes)

1. Go to GitHub repository settings
2. Click "Secrets and variables" → "Actions"
3. Add these secrets:

| Secret | Value |
|--------|-------|
| `JIRA_BASE_URL` | `https://your-jira-instance.atlassian.net` |
| `JIRA_USER_EMAIL` | Your Jira email |
| `JIRA_API_TOKEN` | Your Jira API token |
| `SLACK_WEBHOOK_URL` | (Optional) Your Slack webhook |

**How to get Jira API token**:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the token

### Step 2: Verify Task Files Exist (1 minute)

Ensure these files exist:
- ✅ `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
- ✅ `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`

### Step 3: Run First Sync (2 minutes)

1. Go to GitHub Actions
2. Click "Jira Sync - Orchestrator"
3. Click "Run workflow"
4. Click "Run workflow" button
5. Wait for completion (usually 2-3 minutes)

### Step 4: Verify Results (Optional)

1. Check GitHub Actions logs for any errors
2. Verify task files were updated
3. Check Jira for new tasks

## 🎯 Common Tasks

### Run Sync for All Services
```
GitHub Actions → Jira Sync - Orchestrator → Run workflow → Run workflow
```

### Run Sync for Specific Service
```
GitHub Actions → Jira Sync - Orchestrator → Run workflow
Input: service_name = SecurityService
Click: Run workflow
```

### View Sync Logs
```
GitHub Actions → Jira Sync - Orchestrator → [Latest run] → [Step name]
```

### Add New Task to Jira
1. Edit `project-task.md`
2. Add line: `- [ ] New task description`
3. Commit and push
4. Wait for next sync (or run manually)
5. Task will be created in Jira with key

### Update Task Status
**Option 1: Update in Markdown**
1. Edit `project-task.md`
2. Change checkbox: `[ ]` → `[-]` → `[~]` → `[x]`
3. Commit and push
4. Wait for next sync
5. Jira status will be updated

**Option 2: Update in Jira**
1. Update task status in Jira
2. Wait for next sync (or run manually)
3. Markdown checkbox will be updated

## 📊 Status Reference

| Checkbox | Meaning | Jira Status |
|----------|---------|-------------|
| `[ ]` | Not started | To Do |
| `[-]` | In progress | In Progress |
| `[~]` | Testing | Testing |
| `[x]` | Done | Done |

## 🔄 Automatic Sync Schedule

- **Frequency**: Every 30 minutes
- **Time**: Runs at :00 and :30 of every hour
- **Services**: SecurityService, DataLoaderService
- **Notifications**: Slack (if configured)

## ✅ Verification Checklist

After setup, verify:
- [ ] Secrets are configured
- [ ] Task files exist
- [ ] First manual sync completed successfully
- [ ] No errors in GitHub Actions logs
- [ ] Tasks appear in Jira (if new tasks were in markdown)
- [ ] Markdown updated with Jira keys (if tasks were created)

## 🆘 Troubleshooting

### Sync Failed with "Missing Jira credentials"
**Solution**: Verify secrets are configured correctly
```
Settings → Secrets and variables → Actions
Check: JIRA_BASE_URL, JIRA_USER_EMAIL, JIRA_API_TOKEN
```

### Sync Failed with "Task file not found"
**Solution**: Verify task file path is correct
```
Check: Applications/AITooling/Services/[ServiceName]/.kiro/specs/[service-name]/project-task.md
```

### Tasks Not Syncing
**Solution**: Check GitHub Actions logs
```
GitHub Actions → Jira Sync - Orchestrator → [Latest run] → View logs
```

### Jira Transitions Not Working
**Solution**: Verify Jira workflow allows the transition
```
Jira → Project settings → Workflows
Check: Transitions are available for status changes
```

## 📚 Full Documentation

For complete documentation, see:
- **JIRA-SYNC-MODULAR-SYSTEM.md**: Complete system documentation
- **JIRA-SYNC-IMPLEMENTATION-COMPLETE.md**: Implementation details
- **AUTOMATIC-SYNC-GUIDE.md**: Automatic sync guide

## 🚀 Next Steps

1. ✅ Configure secrets
2. ✅ Run first manual sync
3. ✅ Verify results
4. ✅ Monitor automatic syncs
5. ✅ Add more services (optional)

## 💡 Tips

- **Sync Frequency**: Adjust cron schedule in orchestrator if needed
- **Service-Specific Sync**: Use manual trigger with service_name input
- **Slack Notifications**: Configure SLACK_WEBHOOK_URL for notifications
- **New Services**: Follow "Adding a New Service" guide in full documentation

## 📞 Support

For issues or questions:
1. Check troubleshooting section above
2. Review GitHub Actions logs
3. Check full documentation
4. Contact DevOps team

---

**Quick Links**:
- [GitHub Actions](../../actions)
- [Jira](https://your-jira-instance.atlassian.net)
- [Full Documentation](./JIRA-SYNC-MODULAR-SYSTEM.md)

**Last Updated**: January 2025
