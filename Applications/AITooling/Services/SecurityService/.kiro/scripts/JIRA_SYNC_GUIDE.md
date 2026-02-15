# Jira Sync Script Guide

## Overview

The `jira-sync.ps1` script provides **bidirectional synchronization** between `project-task.md` and Jira issues. Jira is the **source of truth** for task status, while the markdown file displays the current status.

## Key Concepts

### Checkbox Status Mapping

The markdown checkboxes reflect the Jira status:

| Checkbox | Jira Status | Meaning |
|----------|-------------|---------|
| `[ ]` | TO DO | Not started |
| `[-]` | IN PROGRESS or IN REVIEW | In progress or under review |
| `[~]` | TESTING or READY TO MERGE | Testing or ready to merge |
| `[x]` | DONE | Completed |

### Status Flow

```
TO DO → IN PROGRESS → IN REVIEW → TESTING → READY TO MERGE → DONE
```

**Important**: Status transitions are automatically managed by:
- CI/CD pipelines
- Pull request workflows
- Code review processes
- Git flow automation

**You should NOT manually transition issues** - let the automation handle it.

## Usage

### Create New Issues

```powershell
# Manual mode (asks for confirmation)
.\jira-sync.ps1 -Mode Manual

# Auto mode (creates without confirmation)
.\jira-sync.ps1 -Mode Auto
```

**What happens:**
1. Script reads `project-task.md` for tasks without Jira links
2. Creates new Jira issues for each task
3. Transitions issues to "To Do" status
4. Updates `project-task.md` with issue keys and status
5. All new tasks show `[ ]` (To Do) checkbox

### Sync Status from Jira

```powershell
# Sync existing issues with current Jira status
.\jira-sync.ps1 -SyncOnly

# Or with explicit mode
.\jira-sync.ps1 -Mode Auto -SyncOnly
```

**What happens:**
1. Script reads all tasks with Jira links
2. Fetches current status from Jira for each issue
3. Updates `project-task.md` checkboxes to match Jira status
4. Shows which tasks changed status

### Typical Workflow

```bash
# 1. Create new tasks in project-task.md
# 2. Create Jira issues
.\jira-sync.ps1 -Mode Manual

# 3. Commit changes
git add .kiro/specs/*/project-task.md
git commit -m "Create Jira issues for SecurityService tasks"

# 4. Work on tasks (CI/CD automatically updates Jira status)

# 5. Periodically sync status from Jira
.\jira-sync.ps1 -SyncOnly

# 6. Commit status updates
git add .kiro/specs/*/project-task.md
git commit -m "Sync task status from Jira"
```

## Task File Format

### New Task (No Jira Issue)

```markdown
- [ ] Implement JWT authentication
```

### Task with Jira Issue

```markdown
- [ ] Implement JWT authentication (Jira: WEALTHFID-101, Status: To Do)
```

### Task Status Examples

```markdown
# Not started
- [ ] Task name (Jira: PROJ-123, Status: To Do)

# In progress or under review
- [-] Task name (Jira: PROJ-123, Status: In Progress)

# Testing or ready to merge
- [~] Task name (Jira: PROJ-123, Status: Testing)

# Completed
- [x] Task name (Jira: PROJ-123, Status: Done)
```

## Configuration

### Environment Variables (.env)

```env
JIRA_BASE_URI=https://your-instance.atlassian.net
JIRA_PROJECT_KEY=WEALTHFID
JIRA_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-api-token
```

**Get your API token:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Copy the token to `.env`

## Troubleshooting

### Issue: "Task line not found"

**Cause**: Task name in markdown doesn't match exactly

**Solution**: 
- Check for extra spaces or special characters
- Ensure task name matches exactly between markdown and Jira

### Issue: "Could not fetch status"

**Cause**: Network error or invalid Jira credentials

**Solution**:
- Verify `.env` file has correct credentials
- Check network connectivity
- Verify Jira API token is valid

### Issue: "No transition found to 'To Do'"

**Cause**: Jira workflow doesn't support transition to "To Do"

**Solution**:
- Check Jira project workflow configuration
- Verify available transitions for your issue type
- Script will show available transitions in debug output

## Advanced Usage

### Debug Mode

Add debug output to see what's happening:

```powershell
# Run with verbose output
.\jira-sync.ps1 -Mode Auto -Verbose
```

### Manual Status Transition

If you need to manually transition an issue in Jira:

1. Go to Jira issue (e.g., WEALTHFID-101)
2. Click "Transition" button
3. Select new status
4. Run sync to update markdown:
   ```powershell
   .\jira-sync.ps1 -SyncOnly
   ```

## Best Practices

✅ **DO:**
- Run sync regularly to keep markdown in sync with Jira
- Let CI/CD and git flow manage status transitions
- Commit status updates to git
- Use meaningful task names

❌ **DON'T:**
- Manually edit Jira status (let automation handle it)
- Manually edit markdown Jira links (use script)
- Create tasks without running sync
- Use special characters in task names

## Examples

### Example 1: Create New Tasks

```bash
# Add new tasks to project-task.md
- [ ] Implement user authentication
- [ ] Add password reset functionality
- [ ] Create admin dashboard

# Run sync to create Jira issues
.\jira-sync.ps1 -Mode Manual

# Result:
# - [ ] Implement user authentication (Jira: WEALTHFID-201, Status: To Do)
# - [ ] Add password reset functionality (Jira: WEALTHFID-202, Status: To Do)
# - [ ] Create admin dashboard (Jira: WEALTHFID-203, Status: To Do)
```

### Example 2: Sync Status After PR Merge

```bash
# After PR is merged and CI/CD runs:
# - Jira issue transitions to "READY TO MERGE"
# - Then to "DONE"

# Sync to update markdown
.\jira-sync.ps1 -SyncOnly

# Result:
# - [x] Implement user authentication (Jira: WEALTHFID-201, Status: Done)
```

### Example 3: Check Current Status

```bash
# Just run sync to see current status
.\jira-sync.ps1 -SyncOnly

# Output shows:
# Fetching status for: WEALTHFID-101
#   Current Jira status: In Progress
#   Status unchanged
```

## Integration with CI/CD

The script is designed to work with automated CI/CD pipelines:

1. **PR Created**: Issue transitions to "IN REVIEW"
2. **Code Review**: Issue stays in "IN REVIEW"
3. **PR Approved**: Issue transitions to "TESTING"
4. **Tests Pass**: Issue transitions to "READY TO MERGE"
5. **PR Merged**: Issue transitions to "DONE"

Run sync after each stage to update markdown:

```bash
# In CI/CD pipeline
.\jira-sync.ps1 -SyncOnly
git add .kiro/specs/*/project-task.md
git commit -m "Sync task status from Jira [skip ci]"
git push
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Verify `.env` configuration
3. Check Jira project workflow settings
4. Review script output for error messages
