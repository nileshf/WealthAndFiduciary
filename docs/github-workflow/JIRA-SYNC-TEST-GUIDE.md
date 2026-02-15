# Jira Sync Workflow - Testing Guide

## 🎯 Quick Test (5 minutes)

### Step 1: Trigger Workflow Manually
1. Go to your GitHub repository: https://github.com/nileshf/WealthAndFiduciary
2. Click **Actions** tab
3. Click **Sync Project Tasks to Jira** workflow (left sidebar)
4. Click **Run workflow** button (right side)
5. Select **main** branch from dropdown
6. Click **Run workflow** button

### Step 2: Monitor Workflow Execution
1. Wait for workflow to start (usually within 10 seconds)
2. Click on the running workflow to see details
3. Watch the jobs execute:
   - `sync-jira-to-tasks` - Fetches Jira issues and syncs to project-task.md
   - `sync-tasks-to-jira` - Detects checkbox changes and updates Jira
   - `validate-sync` - Validates file format

### Step 3: Check for Success
Look for these indicators:

**✅ Success Indicators**:
- All three jobs show green checkmarks
- No red X marks or errors
- "Commit Jira sync changes" step shows:
  ```
  git push origin main
  ```
  (without any 403 errors)

**❌ Failure Indicators**:
- Red X on any job
- Error message: "Permission to nileshf/WealthAndFiduciary.git denied"
- Error message: "The requested URL returned error: 403"

### Step 4: Verify Changes
1. Go to **Code** tab
2. Look for recent commit: "chore: sync Jira tasks to project-task.md files [skip ci]"
3. Click on the commit to see what changed
4. Verify project-task.md files were updated with Jira issues

---

## 📊 What to Expect

### If Fix Works ✅
```
Workflow Run: Sync Project Tasks to Jira
├── sync-jira-to-tasks ✅
│   ├── Checkout code ✅
│   ├── Run Jira to project-task.md sync ✅
│   ├── Commit Jira sync changes ✅
│   │   └── git push origin main ✅ (SUCCESS)
│   └── Report Jira sync status ✅
├── sync-tasks-to-jira ✅
│   ├── Checkout code ✅
│   ├── Get changed files ✅
│   ├── Detect status changes ✅
│   ├── Update Jira issue statuses ✅
│   └── Report status sync results ✅
└── validate-sync ✅
    ├── Checkout code ✅
    └── Validate project-task.md files ✅

Result: All jobs passed ✅
```

### If Fix Doesn't Work ❌
```
Workflow Run: Sync Project Tasks to Jira
├── sync-jira-to-tasks ❌
│   ├── Checkout code ✅
│   ├── Run Jira to project-task.md sync ✅
│   ├── Commit Jira sync changes ❌
│   │   └── Error: Permission to nileshf/WealthAndFiduciary.git denied to github-actions[bot]
│   │   └── fatal: unable to access 'https://github.com/nileshf/WealthAndFiduciary.git/': The requested URL returned error: 403
│   └── Report Jira sync status ⏭️ (skipped)
└── ...

Result: Job failed ❌
```

---

## 🔍 Detailed Workflow Logs

### To View Detailed Logs

1. Click on the workflow run
2. Click on **sync-jira-to-tasks** job
3. Expand **Commit Jira sync changes** step
4. Look for these lines:

**Expected Output (Success)**:
```
git config --global user.email "action@github.com"
git config --global user.name "GitHub Action"
git add Applications/*/Services/*/.kiro/specs/*/project-task.md
git commit -m "chore: sync Jira tasks to project-task.md files [skip ci]"
git push origin main

[main 8e05e2a] chore: sync Jira tasks to project-task.md files [skip ci]
 1 file changed, 4 insertions(+)
```

**Unexpected Output (Failure)**:
```
remote: Permission to nileshf/WealthAndFiduciary.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/nileshf/WealthAndFiduciary.git/': The requested URL returned error: 403
Error: Process completed with exit code 128.
```

---

## 🧪 Full Bidirectional Sync Test (10 minutes)

### Part 1: Jira → project-task.md (Inbound)
1. Trigger workflow manually (see Step 1 above)
2. Wait for completion
3. Go to **Code** tab
4. Open `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
5. Verify Jira issues appear in the file
6. Look for tasks with format: `- [ ] WEALTHFID-XXX - Task description`

### Part 2: project-task.md → Jira (Outbound)
1. Edit `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
2. Find a task with `[ ]` (not started)
3. Change it to `[x]` (completed)
4. Commit and push to main:
   ```bash
   git add Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md
   git commit -m "test: mark task as complete"
   git push origin main
   ```
5. Workflow automatically triggers
6. Wait for completion
7. Go to Jira and verify the issue status changed to "Done"

---

## 📋 Troubleshooting

### Issue: Workflow doesn't run
**Solution**: 
- Check that GitHub Secrets are configured (Settings → Secrets)
- Verify `JIRA_BASE_URL`, `JIRA_USER_EMAIL`, `JIRA_API_TOKEN` are all set

### Issue: "Permission denied" error still appears
**Solution**:
- Check that workflow file has `token: ${{ secrets.GITHUB_TOKEN }}` in checkout action
- Verify repository settings: Settings → Actions → General
- Set "Workflow permissions" to "Read and write permissions"

### Issue: No Jira issues appear in project-task.md
**Solution**:
- Verify Jira issues have correct service labels:
  - `ai-security-service` for SecurityService
  - `data-loader-service` for DataLoaderService
- Verify issues are in "open" status (not Done/Closed)
- Check workflow logs for errors

### Issue: Changes to project-task.md don't sync to Jira
**Solution**:
- Verify you changed the checkbox format: `[ ]` → `[x]`
- Verify you committed and pushed to main
- Wait for workflow to run (automatic every 15 minutes or manual trigger)
- Check workflow logs for errors

---

## ✅ Success Checklist

After running the test, verify:

- [ ] Workflow triggered successfully
- [ ] All three jobs completed with green checkmarks
- [ ] No "Permission denied" errors in logs
- [ ] Git push succeeded (no 403 errors)
- [ ] Recent commit appears in repository
- [ ] Jira issues appear in project-task.md files
- [ ] Checkbox changes sync to Jira (optional advanced test)

---

## 📞 Next Steps

### If Test Passes ✅
1. Workflow is working correctly
2. Bidirectional sync is operational
3. No further action needed
4. Workflow will run automatically every 15 minutes

### If Test Fails ❌
1. Check troubleshooting section above
2. Review workflow logs for specific error
3. Verify GitHub Secrets are configured
4. Check repository settings for workflow permissions
5. If still failing, check `.github/JIRA-SYNC-GIT-PUSH-FIX.md` for detailed troubleshooting

---

## 🎯 Expected Timeline

| Step | Time | Status |
|------|------|--------|
| Trigger workflow | 0 min | Manual |
| Workflow starts | 0-1 min | Automatic |
| Jira sync completes | 1-2 min | Automatic |
| Git push completes | 2-3 min | Automatic |
| Changes visible in repo | 3-5 min | Automatic |
| **Total** | **~5 min** | ✅ |

---

## 📚 Related Documentation

- **Fix Details**: `.github/JIRA-SYNC-GIT-PUSH-FIX.md`
- **Setup Guide**: `.github/GITHUB-SECRETS-SETUP.md`
- **Workflow Details**: `.github/JIRA-SYNC-WORKFLOW-FIXED.md`
- **Complete Summary**: `.github/JIRA-SYNC-COMPLETE-SUMMARY.md`
- **Quick Reference**: `.github/README-JIRA-SYNC.md`

---

**Status**: Ready for Testing  
**Date**: January 2025  
**Estimated Test Time**: 5-10 minutes  
**Expected Result**: ✅ All jobs pass, no permission errors
