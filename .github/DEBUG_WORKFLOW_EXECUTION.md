# Debug Workflow Execution

## Problem

The workflow has the secret configured but still isn't transitioning the Jira issue.

## Updated Workflow Changes

The workflow has been updated to:
1. **Remove the `if:` condition** that was preventing execution
2. **Always run the transition step** (but exit gracefully if no issue key)
3. **Add detailed logging** to show exactly what's happening

## How to Test

### Step 1: Create a Test PR

```bash
# Create a branch with a Jira issue key
git checkout -b "feat: WEALTHFID-357-test-workflow-debug"

# Make an empty commit
git commit --allow-empty -m "test: debug workflow"

# Push the branch
git push origin "feat: WEALTHFID-357-test-workflow-debug"

# Create PR on GitHub
```

### Step 2: Check Workflow Logs

1. Go to **Actions** tab in GitHub
2. Click on the latest "PR Validation" workflow run
3. Click on "Transition Jira Issue to In Review" step
4. Look for the output

### Step 3: Analyze the Output

**Expected output if working:**
```
=== Jira Transition Step ===
Issue Key: 'WEALTHFID-357'
Token exists: yes
Attempting to transition WEALTHFID-357 to 'In Review'...
HTTP Status: 204
Response: 
✅ Successfully transitioned WEALTHFID-357 to 'In Review'
```

**If issue key not extracted:**
```
=== Jira Transition Step ===
Issue Key: ''
Token exists: yes
⚠️  No Jira issue key found in branch name
Branch name format should be: feat: JIRA-123-description
```

**If token missing:**
```
=== Jira Transition Step ===
Issue Key: 'WEALTHFID-357'
Token exists: no
```

**If HTTP error:**
```
HTTP Status: 400
Response: {"errorMessages":["Issue does not exist or you do not have permission to see it."],"errors":{}}
```

## Troubleshooting

### Issue: "No Jira issue key found in branch name"

**Cause**: Branch name doesn't contain a Jira issue key

**Solution**: Use branch name format: `feat: WEALTHFID-357-description`

### Issue: "Token exists: no"

**Cause**: GitHub secret `JIRA_API_TOKEN` is not set

**Solution**: 
1. Go to GitHub Repo → Settings → Secrets and variables → Actions
2. Verify `JIRA_API_TOKEN` secret exists
3. Verify the value is correct

### Issue: "HTTP Status: 401"

**Cause**: Authentication failed (invalid token or username)

**Solution**:
1. Verify token value is correct
2. Verify username is correct (`nileshf@gmail.com`)
3. Token may have expired - regenerate it

### Issue: "HTTP Status: 403"

**Cause**: Permission denied

**Solution**:
1. Verify the token has permission to transition issues
2. Check Jira user permissions

### Issue: "HTTP Status: 404"

**Cause**: Issue not found

**Solution**:
1. Verify issue exists: https://nileshf.atlassian.net/browse/WEALTHFID-357
2. Verify issue key is correct

### Issue: "HTTP Status: 400"

**Cause**: Invalid transition (issue may already be in target status)

**Solution**:
1. Check current issue status in Jira
2. Verify transition is valid from current status to "In Review"

## What to Report

If the workflow still doesn't work, provide:

1. **Branch name used**: (e.g., `feat: WEALTHFID-357-test`)
2. **Workflow log output**: (copy the entire "Transition Jira Issue to In Review" step output)
3. **Current Jira issue status**: (check in Jira)
4. **Available transitions**: (check in Jira issue transitions)

## Files Modified

- `.github/workflows/pr-validation.yml` - Updated with better debugging and removed blocking condition

## Next Steps

1. Create a test PR with the updated workflow
2. Check the workflow logs
3. Report the output if it still doesn't work

---

**Status**: Workflow updated with better debugging

**Last Updated**: February 18, 2026
