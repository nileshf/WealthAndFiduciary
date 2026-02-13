# Automatic Bidirectional Jira Sync Guide

## Overview

The WealthAndFiduciary workspace now has **fully automatic bidirectional sync**
between Jira and project-task.md files. Changes in either system automatically
sync to the other.

## How It Works

### 1. Jira → project-task.md (Automatic Every 15 Minutes)

**Trigger**: Schedule (every 15 minutes) + Manual trigger

**Process**:

1. Workflow runs `scripts/sync-jira-to-tasks.ps1`
2. Script fetches all open Jira issues with service labels
3. Issues are added to the corresponding service's `project-task.md` file
4. Changes are committed and pushed automatically

**Service Label Mapping**:

- `ai-security-service` → `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
- `data-loader-service` → `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`

**Example**:

```powershell
When you create a Jira issue with label "ai-security-service":
1. Workflow detects the issue (every 15 minutes)
2. Issue is added to SecurityService project-task.md
3. Changes are automatically committed and pushed
```

### 2. project-task.md → Jira (Automatic on Push)

**Trigger**: Push to develop branch when project-task.md files change

**Process**:

1. Workflow detects changes to project-task.md files
2. Parses checkbox status changes
3. Maps checkbox status to Jira workflow status
4. Updates Jira issue status automatically

**Checkbox Status Mapping**:

- `[ ]` (space) → Jira status "To Do"
- `[-]` (dash) → Jira status "In Progress"
- `[~]` (tilde) → Jira status "Testing"
- `[x]` (x) → Jira status "Done"

**Example**:

```markdown
When you change a task in project-task.md:
- [ ] WEALTHFID-150 - Implement health check endpoints
↓ (change to)
- [x] WEALTHFID-150 - Implement health check endpoints

1. Workflow detects the change
2. Finds the transition from "To Do" to "Done"
3. Updates Jira issue status automatically
```

## Workflows

### `.github/workflows/sync-jira-to-project-tasks.yml`

**Jobs**:

1. `sync-jira-to-tasks` - Syncs Jira issues to project-task.md files
   - Runs on schedule (every 15 minutes)
   - Runs on manual trigger
   - Runs on push to develop (if project-task.md changed)

2. `sync-tasks-to-jira` - Syncs project-task.md status changes to Jira
   - Runs after sync-jira-to-tasks
   - Only runs on push events (not on schedule)
   - Detects checkbox status changes
   - Updates Jira issue statuses

3. `validate-sync` - Validates sync results
   - Checks that project-task.md files exist and have valid format
   - Runs after both sync jobs

### `.github/workflows/jira-sync.yml`

**Purpose**: Creates Jira issues from new tasks in project-task.md files

**Trigger**: Push to develop when tasks.md files change

**Note**: This workflow is separate from the bidirectional sync and handles
initial task creation.

## Setting Up Automatic Sync

### Prerequisites

1. **GitHub Secrets** (must be configured):
   - `JIRA_BASE_URL` - Your Jira instance URL (e.g., `https://yourcompany.atlassian.net`)
   - `JIRA_USER_EMAIL` - Email for Jira API authentication
   - `JIRA_API_TOKEN` - API token for Jira authentication

2. **Jira Setup**:
   - Create service labels on Jira issues:
     - `ai-security-service` for SecurityService tasks
     - `data-loader-service` for DataLoaderService tasks
   - Ensure Jira workflow has these statuses:
     - "To Do"
     - "In Progress"
     - "Testing"
     - "Done"

3. **project-task.md Files**:
   - Must exist in service directories
   - Must have valid task format: `- [ ] ISSUE-KEY - Task Title`

### Configuring GitHub Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Add these secrets:

```
JIRA_BASE_URL = https://yourcompany.atlassian.net
JIRA_USER_EMAIL = your-email@example.com
JIRA_API_TOKEN = your-api-token
```

### Creating Jira Issues with Labels

1. Create a new Jira issue in the WEALTHFID project
2. Add one of these labels:
   - `ai-security-service` - For SecurityService tasks
   - `data-loader-service` - For DataLoaderService tasks
3. Set the issue status to "To Do"
4. Wait for the next sync (up to 15 minutes)
5. Issue will appear in the corresponding project-task.md file

### Updating Task Status

1. Edit the project-task.md file
2. Change the checkbox status:
   - `[ ]` → `[-]` (mark as in progress)
   - `[-]` → `[~]` (mark as testing)
   - `[~]` → `[x]` (mark as done)
3. Commit and push to develop
4. Workflow automatically updates Jira issue status

## Workflow Execution Timeline

### Scenario 1: Create Jira Issue

```
Time 0:00 - You create Jira issue WEALTHFID-150 with label "ai-security-service"
Time 0:15 - Scheduled workflow runs
         - Fetches WEALTHFID-150 from Jira
         - Adds to SecurityService project-task.md
         - Commits and pushes changes
Time 0:16 - You see the task in project-task.md
```

### Scenario 2: Update Task Status

```
Time 0:00 - You change task status in project-task.md from [ ] to [x]
Time 0:01 - You commit and push to develop
Time 0:02 - Workflow detects the change
         - Parses checkbox status change
         - Finds Jira issue WEALTHFID-150
         - Updates Jira status to "Done"
Time 0:03 - Jira issue status is updated
```

### Scenario 3: Full Cycle

```
Time 0:00 - You create Jira issue WEALTHFID-150 with label "ai-security-service"
Time 0:15 - Scheduled sync adds task to project-task.md
Time 0:20 - You change task status from [ ] to [-] and push
Time 0:21 - Workflow updates Jira status to "In Progress"
Time 0:30 - You change task status from [-] to [x] and push
Time 0:31 - Workflow updates Jira status to "Done"
```

## Troubleshooting

### Issue: Tasks not appearing in project-task.md

**Possible causes**:
1. Jira issue doesn't have a service label
2. Service label is misspelled (must be exactly `ai-security-service` or `data-loader-service`)
3. GitHub secrets not configured
4. Jira API token is invalid or expired

**Solution**:
1. Verify Jira issue has correct label
2. Check GitHub Actions logs for errors
3. Verify GitHub secrets are configured correctly
4. Test Jira API connection manually

### Issue: Jira status not updating when task status changes

**Possible causes**:
1. Jira workflow doesn't have the target status
2. Transition not allowed in Jira workflow
3. GitHub secrets not configured
4. Task format is invalid

**Solution**:
1. Verify Jira workflow has all required statuses
2. Check Jira workflow transitions
3. Verify GitHub secrets are configured
4. Ensure task format is: `- [ ] ISSUE-KEY - Task Title`

### Issue: Workflow fails with "File not found"

**Possible causes**:
1. project-task.md file doesn't exist
2. File path is incorrect
3. File was deleted

**Solution**:
1. Create project-task.md file in service directory
2. Verify file path matches workflow configuration
3. Restore file from git history if deleted

## Manual Sync Trigger

To manually trigger the sync workflow:

1. Go to GitHub Actions
2. Select "Sync Jira to Project Tasks" workflow
3. Click "Run workflow"
4. Select branch: `develop`
5. Click "Run workflow"

The workflow will run immediately and sync all Jira issues to project-task.md files.

## Monitoring Sync Status

### GitHub Actions

1. Go to repository → Actions
2. Select "Sync Jira to Project Tasks" workflow
3. View recent runs and their status
4. Click on a run to see detailed logs

### Workflow Notifications

- ✅ Success: "Jira tasks successfully synced to project-task.md files"
- ⚠️ Warning: "Sync encountered issues. Check logs for details."
- ⏭️ Skipped: "No status changes detected in project-task.md files"

## Best Practices

1. **Always use service labels** on Jira issues
2. **Keep task format consistent** in project-task.md files
3. **Don't manually edit Jira issue keys** in project-task.md
4. **Use checkbox status** to track progress (don't edit status field manually)
5. **Check GitHub Actions logs** if sync doesn't work as expected
6. **Test with one task** before creating many tasks

## FAQ

**Q: How often does Jira → project-task.md sync run?**
A: Every 15 minutes automatically, or manually via GitHub Actions.

**Q: How often does project-task.md → Jira sync run?**
A: Automatically when you push changes to project-task.md files.

**Q: Can I have multiple service labels on one Jira issue?**
A: No, each issue should have exactly one service label for proper routing.

**Q: What if I change a task status in Jira directly?**
A: The next scheduled sync (every 15 minutes) will update project-task.md to match.

**Q: Can I use different checkbox statuses?**
A: Only these are supported: `[ ]`, `[-]`, `[~]`, `[x]`. Others will be treated as "To Do".

**Q: What happens if a Jira issue doesn't have a label?**
A: It will be skipped during sync. Add a service label to include it.

---

**Last Updated**: January 2025
**Maintained By**: WealthAndFiduciary DevOps Team
