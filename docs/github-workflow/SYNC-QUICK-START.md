# Automatic Jira Sync - Quick Start

## TL;DR

✅ **Automatic bidirectional sync between Jira and project-task.md**

- **Jira → project-task.md**: Every 15 minutes automatically
- **project-task.md → Jira**: Automatically when you push changes

## Creating a Task

### Option 1: Create in Jira (Recommended)

1. Create Jira issue in WEALTHFID project
2. Add label: `ai-security-service` or `data-loader-service`
3. Wait 15 minutes (or manually trigger sync)
4. Task appears in project-task.md ✓

### Option 2: Create in project-task.md

1. Edit `Applications/AITooling/Services/{Service}/.kiro/specs/{service}/project-task.md`
2. Add task: `- [ ] WEALTHFID-XXX - Task Title`
3. Commit and push
4. Jira issue is created automatically ✓

## Updating Task Status

1. Edit project-task.md
2. Change checkbox:
   - `[ ]` = To Do
   - `[-]` = In Progress
   - `[~]` = Testing
   - `[x]` = Done
3. Commit and push
4. Jira status updates automatically ✓

## Service Labels

| Service | Label |
|---------|-------|
| SecurityService | `ai-security-service` |
| DataLoaderService | `data-loader-service` |

## Workflow Status

Check GitHub Actions → "Sync Jira to Project Tasks" for:
- ✅ Successful syncs
- ⚠️ Errors or warnings
- ⏭️ Skipped runs

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Task not in project-task.md | Add service label to Jira issue |
| Jira status not updating | Verify checkbox format: `[x]` not `[X]` |
| Workflow fails | Check GitHub Actions logs |
| Secrets not configured | Add JIRA_BASE_URL, JIRA_USER_EMAIL, JIRA_API_TOKEN to GitHub Secrets |

## Manual Sync

Go to GitHub Actions → "Sync Jira to Project Tasks" → "Run workflow" → "Run workflow"

---

**Full Guide**: See `.github/AUTOMATIC-SYNC-GUIDE.md`
