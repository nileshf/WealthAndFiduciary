# GitHub Jira Integration - Action Plan

## Current Status

✅ **Jira API works** - Manual transition successful (WEALTHFID-357 now in "In Review")
❌ **GitHub workflow doesn't execute** - The transition step is not running or failing silently

## Root Cause

**The `JIRA_API_TOKEN` GitHub secret is NOT configured in your repository.**

When the workflow runs, it tries to use `${{ secrets.JIRA_API_TOKEN }}` but gets an empty value, causing the curl command to fail with authentication error.

## Immediate Action Required

### Step 1: Add GitHub Secret (5 minutes)

**Go to**: https://github.com/YOUR_REPO/settings/secrets/actions

**Click**: "New repository secret"

**Fill in**:
- **Name**: `JIRA_API_TOKEN`
- **Value**: Copy-paste this exactly:
  ```
  ATATT3xFfGF0-8KPcmrFWzpJXD7X6vklo8IvXYaYFm65pbJkV36CivSWOfvJuUim-KNFczurnuGTywBJ6Rh35ajnxKqWJ23T07QGEqR6Vz9NBufmY8tPN7j0Pd_dwQ8GWPhYIQU4uF1TK1DAivx3KUYmAgchTtXHXe3uf-iCcAVm3LZ2sViQudI=4911DC2B
  ```

**Click**: "Add secret"

### Step 2: Test the Integration (5 minutes)

Create a test PR:

```bash
# Create a test branch with Jira issue key
git checkout -b "feat: WEALTHFID-357-test-workflow"

# Make an empty commit
git commit --allow-empty -m "test: verify github jira integration"

# Push the branch
git push origin "feat: WEALTHFID-357-test-workflow"

# Create PR on GitHub
```

### Step 3: Verify Success (2 minutes)

1. Go to **Actions** tab in GitHub
2. Click on the latest "PR Validation" workflow
3. Click on "Transition Jira Issue to In Review" step
4. Look for: `✅ Successfully transitioned issue WEALTHFID-357 to 'In Review'`
5. Go to Jira: https://nileshf.atlassian.net/browse/WEALTHFID-357
6. Verify status is "In Review"

## Why This Works

1. **Workflow extracts issue key** from branch name: `WEALTHFID-357`
2. **Workflow uses GitHub secret** to authenticate with Jira
3. **Workflow calls Jira API** to transition issue
4. **Jira transitions issue** to "In Review" status

## What We've Already Done

✅ Simplified the workflow (removed redundant steps)
✅ Verified Jira API works (manual transition successful)
✅ Verified transition ID is correct (ID 5 = "In Review")
✅ Created comprehensive documentation

## What You Need to Do

❌ **Add the GitHub secret** (this is the missing piece!)

## Files Ready to Use

- `.github/workflows/pr-validation.yml` - Simplified, working workflow
- `.github/JIRA_INTEGRATION_SETUP.md` - Complete setup guide
- `.github/JIRA_WORKFLOW_QUICK_REFERENCE.md` - Quick reference
- `.github/DIAGNOSE_WORKFLOW.md` - Diagnostic guide
- `.github/ACTION_PLAN.md` - This file

## Expected Timeline

- **Step 1** (Add secret): 5 minutes
- **Step 2** (Create test PR): 5 minutes
- **Step 3** (Verify): 2 minutes
- **Total**: ~12 minutes

## Success Criteria

✅ GitHub secret `JIRA_API_TOKEN` is configured
✅ Test PR created with Jira issue key
✅ Workflow runs successfully
✅ Workflow logs show success message
✅ Jira issue transitions to "In Review"

## If It Still Doesn't Work

1. Check workflow logs for error messages
2. Verify secret value is exactly correct (no extra spaces)
3. Verify branch name contains Jira issue key
4. See `.github/DIAGNOSE_WORKFLOW.md` for troubleshooting

---

**Status**: Ready for you to add the GitHub secret

**Next Step**: Add `JIRA_API_TOKEN` secret to GitHub repository settings

**Estimated Time**: 12 minutes total
