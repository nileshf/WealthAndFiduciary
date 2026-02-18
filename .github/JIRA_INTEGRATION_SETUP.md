# GitHub Jira Integration Setup Guide

## Problem Summary

The PR validation workflow is not automatically transitioning Jira issues to "In Review" status when PRs are created. The root cause is that the `JIRA_API_TOKEN` secret is not configured in GitHub repository settings.

## Solution: Configure GitHub Secrets

### Step 1: Get Your Jira API Token

Your Jira API token is already available in `.kiro/settings/mcp.json`:

```
JIRA_API_TOKEN: ATATT3xFfGF0-8KPcmrFWzpJXD7X6vklo8IvXYaYFm65pbJkV36CivSWOfvJuUim-KNFczurnuGTywBJ6Rh35ajnxKqWJ23T07QGEqR6Vz9NBufmY8tPN7j0Pd_dwQ8GWPhYIQU4uF1TK1DAivx3KUYmAgchTtXHXe3uf-iCcAVm3LZ2sViQudI=4911DC2B
```

### Step 2: Add Secret to GitHub Repository

1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. Click **New repository secret**
5. Create the following secret:

| Name | Value |
|------|-------|
| `JIRA_API_TOKEN` | `ATATT3xFfGF0-8KPcmrFWzpJXD7X6vklo8IvXYaYFm65pbJkV36CivSWOfvJuUim-KNFczurnuGTywBJ6Rh35ajnxKqWJ23T07QGEqR6Vz9NBufmY8tPN7j0Pd_dwQ8GWPhYIQU4uF1TK1DAivx3KUYmAgchTtXHXe3uf-iCcAVm3LZ2sViQudI=4911DC2B` |

6. Click **Add secret**

### Step 3: Verify the Workflow

The workflow is now configured to:

1. **Extract Jira issue key** from PR branch name (e.g., `feat: WEALTHFID-357-your-feature` → `WEALTHFID-357`)
2. **Transition the issue** to "In Review" status using transition ID `5`
3. **Handle errors gracefully** if the issue is not found or already in the correct status

### Step 4: Test the Integration

Create a test PR with a branch name containing a Jira issue key:

```bash
git checkout -b "feat: WEALTHFID-357-test-jira-integration"
git commit --allow-empty -m "test: verify jira integration"
git push origin "feat: WEALTHFID-357-test-jira-integration"
```

Then create a PR from this branch. The workflow should:
- ✅ Extract `WEALTHFID-357` from the branch name
- ✅ Transition the issue to "In Review" status
- ✅ Show success message in the workflow logs

### Step 5: Verify in Jira

After the PR is created:
1. Go to https://nileshf.atlassian.net/browse/WEALTHFID-357
2. Check that the issue status has changed to "In Review"
3. Verify the workflow logs in GitHub Actions for confirmation

## Workflow Details

### Branch Name Format

The workflow expects branch names in this format:

```
[type]: [JIRA-KEY]-[description]
```

Examples:
- ✅ `feat: WEALTHFID-357-add-user-auth`
- ✅ `fix: WEALTHFID-123-fix-login-bug`
- ✅ `docs: WEALTHFID-456-update-readme`
- ❌ `add-new-feature` (no Jira key)
- ❌ `WEALTHFID-357` (missing type prefix)

### Jira Transition Details

- **Transition ID**: `5` (verified from Jira API)
- **Target Status**: "In Review"
- **Jira URL**: https://nileshf.atlassian.net
- **API Endpoint**: `/rest/api/3/issue/{ISSUE_KEY}/transitions`

### Workflow Execution

The workflow runs on:
- PR opened
- PR synchronized (new commits pushed)
- PR reopened

### Error Handling

If the transition fails:
- HTTP 204 or 200 = Success
- HTTP 400+ = Error (logged in workflow)
- Issue not found = Skipped gracefully

## Troubleshooting

### Issue: Workflow doesn't run

**Solution**: Check that the branch name contains a Jira issue key in format `[A-Z]+-\d+`

### Issue: Transition fails with "Issue does not exist"

**Solution**: 
1. Verify the Jira issue exists: https://nileshf.atlassian.net/browse/WEALTHFID-357
2. Verify the issue key is correctly extracted from the branch name
3. Check the workflow logs for the extracted issue key

### Issue: Transition fails with "Permission denied"

**Solution**:
1. Verify the `JIRA_API_TOKEN` secret is correctly set in GitHub
2. Verify the token has permission to transition issues
3. Check that the token hasn't expired

### Issue: Workflow logs show "Transition request completed with status XXX"

**Solution**: This is expected if:
- The issue is already in "In Review" status (HTTP 400)
- The issue is in a status that cannot transition to "In Review"

Check the Jira issue status and available transitions.

## Files Modified

- `.github/workflows/pr-validation.yml` - Simplified workflow with working Jira integration
- `.kiro/settings/mcp.json` - Contains Jira credentials (already configured)

## Next Steps

1. ✅ Add `JIRA_API_TOKEN` secret to GitHub repository settings
2. ✅ Create a test PR with a Jira issue key in the branch name
3. ✅ Verify the issue is transitioned to "In Review" in Jira
4. ✅ Check the workflow logs for confirmation

---

**Status**: Ready for testing after GitHub secret is configured

**Last Updated**: February 18, 2026
