# ⚠️ IMMEDIATE ACTION REQUIRED

## The Problem

The GitHub Actions workflow is failing because **three GitHub Secrets are not configured**.

This is NOT a code problem - the code is fixed. This is a configuration problem.

---

## The Solution (5 Minutes)

### Step 1: Go to GitHub Settings
1. Open your GitHub repository
2. Click **Settings** (top menu)
3. Click **Secrets and variables** (left sidebar)
4. Click **Actions**

### Step 2: Add Secret #1 - JIRA_BASE_URL
1. Click **New repository secret**
2. **Name**: `JIRA_BASE_URL`
3. **Value**: `https://nileshf.atlassian.net`
4. Click **Add secret**

### Step 3: Add Secret #2 - JIRA_USER_EMAIL
1. Click **New repository secret**
2. **Name**: `JIRA_USER_EMAIL`
3. **Value**: Your Jira account email (e.g., `your-email@example.com`)
4. Click **Add secret**

### Step 4: Add Secret #3 - JIRA_API_TOKEN
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click **Create API token**
3. Name: `GitHub Actions Sync`
4. Click **Create**
5. Copy the token (you can only see it once!)
6. Go back to GitHub Settings
7. Click **New repository secret**
8. **Name**: `JIRA_API_TOKEN`
9. **Value**: Paste the token
10. Click **Add secret**

### Step 5: Verify Secrets Are Added
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. You should see three secrets:
   - ✅ `JIRA_BASE_URL`
   - ✅ `JIRA_USER_EMAIL`
   - ✅ `JIRA_API_TOKEN`

---

## Test It (5 Minutes)

### Step 1: Trigger the Workflow
1. Go to **Actions** tab
2. Click **Sync Project Tasks to Jira** workflow
3. Click **Run workflow**
4. Select **develop** branch
5. Click **Run workflow**

### Step 2: Wait for Completion
- Workflow usually completes in 1-2 minutes
- You'll see a green checkmark when it succeeds

### Step 3: Check the Results
1. Click on the workflow run
2. Expand each job to see logs
3. Look for success messages:
   ```
   ✅ Jira tasks successfully synced to project-task.md files
   ✓ All project-task.md files validated
   ```

---

## Verify It Works (5 Minutes)

### Check 1: Workflow Logs
- Go to Actions tab
- Click on the workflow run
- Look for "Found X issues" message
- Look for "Added task WEALTHFID-XXX" messages

### Check 2: Project Task Files
- Open `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
- Should see new tasks from Jira

### Check 3: Jira Issues
- Go to your Jira instance
- Verify issues have service labels:
  - `ai-security-service` for SecurityService
  - `data-loader-service` for DataLoaderService

---

## That's It!

Once you've configured the three secrets, the workflow will:
- ✅ Run automatically every 15 minutes
- ✅ Sync Jira issues to project-task.md files
- ✅ Sync checkbox changes back to Jira
- ✅ Validate everything is working

---

## If It Still Fails

### Check the Error Message
1. Go to Actions tab
2. Click on the failed workflow run
3. Expand the failed job
4. Look for error messages
5. Common errors:
   - "401 Unauthorized" → Verify credentials
   - "404 Not Found" → Verify Jira URL
   - "No issues found" → Verify Jira issues have labels

### Get Help
- Read `.github/WORKFLOW-DEBUGGING.md` for detailed troubleshooting
- Read `.github/QUICK-REFERENCE.md` for quick answers

---

## Timeline

| Step | Time | Status |
|------|------|--------|
| Configure secrets | 5 min | ⏳ DO THIS NOW |
| Test workflow | 5 min | ⏳ DO THIS NEXT |
| Verify results | 5 min | ⏳ DO THIS AFTER |
| Monitor runs | Ongoing | ✅ AUTOMATIC |

**Total Time**: ~15 minutes to full deployment

---

## What You're Configuring

These three secrets allow the workflow to:
1. **Connect to Jira** - Using your Jira instance URL
2. **Authenticate** - Using your Jira account email
3. **Access Jira API** - Using your API token

Without these, the workflow can't do anything.

---

## Security Note

- Secrets are encrypted and never visible in logs
- Only the workflow can access them
- You can rotate them anytime
- Generate new API tokens every 90 days

---

## Questions?

- **Quick answers**: See `.github/QUICK-REFERENCE.md`
- **Setup help**: See `.github/GITHUB-SECRETS-SETUP.md`
- **Troubleshooting**: See `.github/WORKFLOW-DEBUGGING.md`
- **Full details**: See `.github/JIRA-SYNC-STATUS.md`

---

## Next Action

👉 **Configure the three GitHub Secrets NOW** (5 minutes)

Then test the workflow and verify it works.

---

**Last Updated**: January 2025
**Workflow File**: `.github/workflows/sync-project-tasks-to-jira.yml`

**DO THIS NOW**: Configure GitHub Secrets ⭐
