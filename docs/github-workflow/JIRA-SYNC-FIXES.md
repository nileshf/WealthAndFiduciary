# Jira Sync Bidirectional Fixes

## Issues Fixed

### 1. **Workflow Not Calling Sync Script**
**Problem**: The workflow only validated files but never executed the sync script.
**Fix**: Updated `.github/workflows/sync-project-tasks-to-jira.yml` to:
- Call `sync-jira-bidirectional.ps1` script
- Use `PAT_TOKEN` for git push (required for github-actions[bot])
- Re-enabled automatic triggers (push, schedule)
- Added proper git commit and push logic

### 2. **Status Mapping Broken**
**Problem**: All synced issues showed as `[ ]` (To Do) regardless of actual Jira status.
**Fix**: 
- Fixed `Get-CheckboxFromStatus` function to properly map Jira statuses to checkboxes
- Mapping: `To Do` → `[ ]`, `In Progress` → `[-]`, `In Review` → `[~]`, `Done` → `[x]`
- Now correctly reads issue status from Jira and applies proper checkbox

### 3. **Regex Pattern Incomplete**
**Problem**: The regex pattern for matching markdown tasks was truncated/broken.
**Fix**: 
- Rewrote complete regex: `^\s*-\s+(\[[ x~-]\])\s+(?![A-Z]+-\d+)(.+)$`
- Negative lookahead `(?![A-Z]+-\d+)` ensures we only match NEW tasks (without Jira keys)
- Properly captures checkbox and description

### 4. **File Updates Not Happening**
**Problem**: After creating Jira issues, the markdown files weren't updated with issue keys.
**Fix**:
- Added logic to update markdown file after issue creation
- Replaces original line with new line containing Jira key
- Saves updated content back to file

### 5. **Status Transitions Not Working**
**Problem**: Issues created from markdown weren't transitioning to correct status.
**Fix**:
- Added status transition logic after issue creation
- Fetches available transitions from Jira
- Transitions to correct status if not "To Do"
- Includes error handling for transition failures

## Key Changes

### Workflow File (`.github/workflows/sync-project-tasks-to-jira.yml`)
```yaml
# Now calls the sync script
- name: Run bidirectional sync
  shell: pwsh
  env:
    JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
    JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
    JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
  run: |
    & ./scripts/sync-jira-bidirectional.ps1

# Commits and pushes changes
- name: Commit changes
  shell: pwsh
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    
    if (git diff --quiet) {
      Write-Host "No changes to commit"
      exit 0
    }
    
    git add 'Applications/AITooling/Services/*/project-task.md'
    git commit -m "chore: sync Jira issues to project-task.md files"
    git push
```

### Sync Script (`scripts/sync-jira-bidirectional.ps1`)

**Jira → Markdown Sync**:
- Fetches issues with service labels
- Maps Jira status to checkbox correctly
- Adds issues to markdown file with proper format
- Saves updated file

**Markdown → Jira Sync**:
- Finds new tasks (without Jira keys) using improved regex
- Creates Jira issues with proper Atlassian Document Format
- Transitions issues to correct status
- Updates markdown file with new Jira keys

## Testing the Fix

### Manual Test
```powershell
# Test with dry-run first
./scripts/sync-jira-bidirectional.ps1 -DryRun

# Then run actual sync
./scripts/sync-jira-bidirectional.ps1
```

### Verify Results
1. **Jira → Markdown**: Check that issues appear in project-task.md with correct checkboxes
   - `[ ]` for To Do issues
   - `[-]` for In Progress issues
   - `[~]` for In Review issues
   - `[x]` for Done issues

2. **Markdown → Jira**: Add new task to project-task.md and run sync
   - New Jira issue should be created
   - Issue should have correct status
   - Markdown file should be updated with Jira key

3. **File Updates**: Verify project-task.md files are updated after sync
   - New Jira keys added to tasks
   - Correct status checkboxes applied

## Workflow Triggers

The workflow now runs on:
- **Manual**: `workflow_dispatch` (click "Run workflow" in GitHub)
- **Push**: When project-task.md files are modified
- **Schedule**: Every hour (can be adjusted in cron expression)

## Troubleshooting

If sync fails:
1. Check Jira credentials in GitHub Secrets
2. Verify PAT_TOKEN has `repo` scope
3. Check workflow logs for detailed error messages
4. Run script locally with `-DryRun` flag to test

## Files Modified
- `.github/workflows/sync-project-tasks-to-jira.yml` - Updated workflow
- `scripts/sync-jira-bidirectional.ps1` - Fixed and improved sync script
- `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md` - Cleaned up
- `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md` - Cleaned up
