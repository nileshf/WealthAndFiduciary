# Workflow Authentication Fix

## Problem

Workflows were failing with:
```
remote: Permission to nileshf/WealthAndFiduciary.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/nileshf/WealthAndFiduciary.git': The requested URL returned error: 403
```

## Root Cause

The workflows were trying to push changes using `git push origin main` without proper authentication. The `github-actions[bot]` user doesn't have write permissions by default.

## Solution

### 1. Added Permissions Block

All workflows now include:
```yaml
permissions:
  contents: write
  pull-requests: write
```

This grants the workflow the necessary permissions to write to the repository.

### 2. Fixed Git Push Authentication

Changed from:
```powershell
git push origin main
```

To:
```powershell
$remoteUrl = "https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }}.git"
git remote set-url origin $remoteUrl
git push origin ${{ github.ref_name }}
```

This uses the automatically-provided `GITHUB_TOKEN` secret which has the necessary permissions.

### 3. Updated All Workflows

Fixed in:
- `.github/workflows/jira-sync-orchestrator-simple.yml`
- `.github/workflows/jira-sync-step1-pull-tasks-standalone.yml`
- `.github/workflows/jira-sync-step2-push-tasks-standalone.yml`
- `.github/workflows/jira-sync-step3-sync-jira-status-standalone.yml`
- `.github/workflows/jira-sync-step4-sync-markdown-status-standalone.yml`

## How It Works

1. **GITHUB_TOKEN**: GitHub automatically provides a token with limited permissions
2. **x-access-token**: Special format for git authentication using a token
3. **github.repository**: Automatically populated with `owner/repo` format
4. **github.ref_name**: Automatically populated with the current branch name

## Testing

Run any workflow manually:
1. Go to **Actions** tab
2. Select a workflow
3. Click **Run workflow**
4. Select service (for standalone workflows)
5. Click **Run workflow**

The workflow should now complete successfully without authentication errors.

## Security Notes

- `GITHUB_TOKEN` is automatically provided and scoped to the current repository
- Token is only valid for the duration of the workflow run
- Token permissions are limited to what's specified in the `permissions` block
- No additional secrets need to be configured

## References

- [GitHub Actions: Automatic token authentication](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
- [GitHub Actions: Permissions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#permissions)

---

**Status**: ✅ Fixed and ready to use

**Last Updated**: February 13, 2025
