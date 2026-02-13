# Jira Sync Workflow - Action Checklist

## ✅ Completed by Kiro

- [x] Fixed GitHub Actions permission issue (git push authentication)
- [x] Verified workflow configuration for `main` branch
- [x] Verified PowerShell sync script functionality
- [x] Verified project-task.md file structure
- [x] Verified service label mapping
- [x] Created comprehensive documentation
- [x] Committed all fixes to main branch

## 📋 Your Action Items (Required to Activate)

### Step 1: Configure GitHub Secrets ⚠️ REQUIRED
**Time**: 5 minutes  
**Location**: GitHub Repository Settings

1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. Click **Secrets and variables** (left sidebar)
4. Click **Actions**
5. Click **New repository secret** and add these three secrets:

#### Secret 1: JIRA_BASE_URL
- **Name**: `JIRA_BASE_URL`
- **Value**: `https://nileshf.atlassian.net`
- **Click**: Add secret

#### Secret 2: JIRA_USER_EMAIL
- **Name**: `JIRA_USER_EMAIL`
- **Value**: Your Jira account email (e.g., `your-email@example.com`)
- **Click**: Add secret

#### Secret 3: JIRA_API_TOKEN
- **Name**: `JIRA_API_TOKEN`
- **Value**: Your Jira API token
  - Go to: https://id.atlassian.com/manage-profile/security/api-tokens
  - Click: Create API token
  - Name it: "GitHub Actions Sync"
  - Copy the token (you can only see it once!)
- **Click**: Add secret

**Verification**: After adding all three, you should see:
- ✅ `JIRA_BASE_URL`
- ✅ `JIRA_USER_EMAIL`
- ✅ `JIRA_API_TOKEN`

### Step 2: Test the Workflow ⚠️ REQUIRED
**Time**: 2 minutes  
**Location**: GitHub Actions Tab

1. Go to your GitHub repository
2. Click **Actions** tab
3. Click **Sync Project Tasks to Jira** workflow (left sidebar)
4. Click **Run workflow** button
5. Select **main** branch from dropdown
6. Click **Run workflow** button
7. Wait for workflow to complete (usually 1-2 minutes)
8. Check the logs:
   - ✅ `sync-jira-to-tasks` job should show "✅ Jira tasks successfully synced"
   - ✅ `sync-tasks-to-jira` job should show "⏭️ No status changes detected"
   - ✅ `validate-sync` job should show "✓ All project-task.md files validated"

### Step 3: Verify Bidirectional Sync ⚠️ RECOMMENDED
**Time**: 5 minutes  
**Location**: GitHub + Jira

#### Part A: Verify Jira → project-task.md
1. After workflow completes, check the project-task.md files:
   - `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
   - `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`
2. You should see Jira issues synced (format: `- [ ] ISSUE-KEY - Issue Title`)
3. If you see issues, ✅ inbound sync is working!

#### Part B: Verify project-task.md → Jira
1. Edit one of the project-task.md files
2. Change a checkbox from `[ ]` to `[x]` (mark as done)
3. Commit and push to main branch
4. Wait 1-2 minutes for workflow to run
5. Check the corresponding Jira issue
6. The status should have changed to "Done"
7. If it changed, ✅ outbound sync is working!

## 🎯 Expected Behavior After Setup

### Automatic Sync (Every 15 Minutes)
- Workflow runs automatically every 15 minutes
- Fetches new/updated Jira issues
- Syncs them to project-task.md files
- Commits changes to main branch

### On Push to main
- If you change a checkbox in project-task.md
- Workflow detects the change
- Updates the corresponding Jira issue status
- Reflects in Jira immediately

### Manual Trigger
- You can manually trigger the workflow anytime
- Go to Actions → Sync Project Tasks to Jira → Run workflow

## 📊 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Workflow File | ✅ Fixed | Using GitHub token for authentication |
| Sync Script | ✅ Ready | PowerShell script functional |
| Project Task Files | ✅ Ready | Both services have files |
| Service Labels | ✅ Mapped | ai-security-service, data-loader-service |
| GitHub Secrets | ⚠️ Pending | **You need to configure these** |
| Bidirectional Sync | ⚠️ Pending | **Will work after secrets are configured** |

## 🚨 Important Notes

1. **Secrets are required**: The workflow will fail without the three GitHub Secrets
2. **Jira labels matter**: Issues must have the correct service labels to sync
3. **Checkbox format**: Use `[ ]`, `[-]`, `[~]`, `[x]` for status
4. **Main branch only**: Workflow only triggers on `main` branch (not `develop`)
5. **Automatic runs**: Workflow runs every 15 minutes automatically

## 📞 Troubleshooting

### Workflow Still Failing?
1. Check GitHub Actions logs for specific error
2. Verify all three secrets are configured
3. Verify Jira credentials are correct
4. Check that Jira issues have service labels

### Jira Issues Not Appearing?
1. Verify issues have correct service labels:
   - `ai-security-service` for SecurityService
   - `data-loader-service` for DataLoaderService
2. Verify issues are in "open" status (not Done/Closed/Resolved)
3. Check workflow logs for errors

### Changes Not Syncing?
1. Verify you're on `main` branch
2. Verify you changed the checkbox status
3. Verify you committed and pushed the change
4. Wait 1-2 minutes for workflow to run

## 📚 Documentation

- **Setup Guide**: `.github/GITHUB-SECRETS-SETUP.md`
- **Workflow Status**: `.github/JIRA-SYNC-WORKFLOW-FIXED.md`
- **Workflow File**: `.github/workflows/sync-project-tasks-to-jira.yml`
- **Sync Script**: `scripts/sync-jira-to-tasks.ps1`

## ✨ Summary

The Jira sync workflow is **fully configured and ready to use**. All you need to do is:

1. ✅ Configure the three GitHub Secrets (5 minutes)
2. ✅ Test the workflow (2 minutes)
3. ✅ Verify bidirectional sync works (5 minutes)

**Total time**: ~12 minutes to full activation

---

**Status**: 🟡 Awaiting GitHub Secrets Configuration  
**Next Action**: Configure the three GitHub Secrets in repository settings  
**Questions?**: See `.github/GITHUB-SECRETS-SETUP.md` for detailed instructions

