# GitHub Actions Workflow Diagnostic Guide

## Problem

The GitHub Actions workflow is not transitioning Jira issues, even though:
- ✅ The Jira API works (manual transition successful)
- ✅ The workflow syntax is valid
- ✅ The branch name extraction works
- ❌ The transition step is not executing or failing silently

## Root Cause: Missing GitHub Secret

The workflow uses `${{ secrets.JIRA_API_TOKEN }}` but this secret is **NOT configured** in your GitHub repository.

### Evidence

When the workflow runs, the `JIRA_API_TOKEN` secret is empty/undefined, so the curl command fails with authentication error.

## How to Verify

### Step 1: Check GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. Look for `JIRA_API_TOKEN` in the list

**If you don't see it**, that's the problem!

### Step 2: Check Workflow Logs

1. Go to **Actions** tab in GitHub
2. Click on the latest "PR Validation" workflow run
3. Click on the "Transition Jira Issue to In Review" step
4. Look for error messages like:
   - `curl: (6) Could not resolve host`
   - `HTTP Status: 401` (Unauthorized)
   - `HTTP Status: 403` (Forbidden)
   - `errorMessages: ["Issue does not exist or you do not have permission to see it."]`

### Step 3: Verify the Secret Value

The secret should be:
```
ATATT3xFfGF0-8KPcmrFWzpJXD7X6vklo8IvXYaYFm65pbJkV36CivSWOfvJuUim-KNFczurnuGTywBJ6Rh35ajnxKqWJ23T07QGEqR6Vz9NBufmY8tPN7j0Pd_dwQ8GWPhYIQU4uF1TK1DAivx3KUYmAgchTtXHXe3uf-iCcAVm3LZ2sViQudI=4911DC2B
```

## Solution

### Add the GitHub Secret

1. Go to: **GitHub Repo → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Fill in:
   - **Name**: `JIRA_API_TOKEN`
   - **Value**: `ATATT3xFfGF0-8KPcmrFWzpJXD7X6vklo8IvXYaYFm65pbJkV36CivSWOfvJuUim-KNFczurnuGTywBJ6Rh35ajnxKqWJ23T07QGEqR6Vz9NBufmY8tPN7j0Pd_dwQ8GWPhYIQU4uF1TK1DAivx3KUYmAgchTtXHXe3uf-iCcAVm3LZ2sViQudI=4911DC2B`
4. Click **Add secret**

### Verify the Secret Works

1. Create a new PR with a Jira issue key in the branch name
2. Go to **Actions** tab
3. Click on the latest workflow run
4. Check the "Transition Jira Issue to In Review" step
5. Look for: `✅ Successfully transitioned issue WEALTHFID-XXX to 'In Review'`

## Troubleshooting

### Issue: Secret is set but workflow still fails

**Check the workflow logs for the actual error:**

1. Go to **Actions** → Latest workflow run
2. Click "Transition Jira Issue to In Review" step
3. Look at the output

**Common errors:**

| Error | Cause | Solution |
|-------|-------|----------|
| `HTTP Status: 401` | Invalid token | Verify token value is correct |
| `HTTP Status: 403` | Permission denied | Token may have expired, regenerate it |
| `HTTP Status: 404` | Issue not found | Verify issue key is correct |
| `HTTP Status: 400` | Invalid transition | Issue may already be in target status |

### Issue: Workflow doesn't run at all

**Check:**
1. Branch name contains Jira issue key (format: `[A-Z]+-\d+`)
2. PR is created from the branch
3. Workflow trigger is set to `pull_request` events

### Issue: Issue key not extracted

**Check branch name format:**
- ✅ `feat: WEALTHFID-357-your-feature`
- ✅ `fix: WEALTHFID-123-fix-bug`
- ❌ `add-feature` (no Jira key)
- ❌ `WEALTHFID-357` (no type prefix)

## Manual Verification

To verify the Jira API works independently:

```bash
# Get issue status
curl -u "nileshf@gmail.com:TOKEN" \
  "https://nileshf.atlassian.net/rest/api/3/issue/WEALTHFID-357"

# Get available transitions
curl -u "nileshf@gmail.com:TOKEN" \
  "https://nileshf.atlassian.net/rest/api/3/issue/WEALTHFID-357/transitions"

# Transition to "In Review" (ID 5)
curl -X POST \
  -H "Content-Type: application/json" \
  -u "nileshf@gmail.com:TOKEN" \
  -d '{"transition":{"id":"5"}}' \
  "https://nileshf.atlassian.net/rest/api/3/issue/WEALTHFID-357/transitions"
```

Replace `TOKEN` with the actual Jira API token.

## Checklist

- [ ] GitHub secret `JIRA_API_TOKEN` is configured
- [ ] Secret value is correct (matches the token in `.kiro/settings/mcp.json`)
- [ ] Branch name contains Jira issue key
- [ ] PR is created from the branch
- [ ] Workflow runs successfully
- [ ] Workflow logs show success message
- [ ] Jira issue status changed to "In Review"

## Next Steps

1. **Add the GitHub secret** (if not already done)
2. **Create a test PR** with a Jira issue key
3. **Check the workflow logs** for success or error messages
4. **Verify the Jira issue status** changed to "In Review"

---

**Status**: Diagnostic guide ready

**Last Updated**: February 18, 2026
