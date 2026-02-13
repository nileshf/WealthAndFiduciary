# Quick Start - Bidirectional Jira Sync

## ✅ What Was Fixed

| Issue | Status | Fix |
|-------|--------|-----|
| Workflow not calling sync script | ✅ Fixed | Now executes `sync-jira-bidirectional.ps1` |
| All issues created as "IN PROGRESS" | ✅ Fixed | Status mapping now works correctly |
| project-task.md not updated with Jira keys | ✅ Fixed | File update logic added |
| Jira → markdown not updating files | ✅ Fixed | File saving logic added |
| Regex pattern broken | ✅ Fixed | Complete regex rewritten |
| Status transitions not working | ✅ Fixed | Transition logic added |
| Git push failing | ✅ Fixed | Using PAT_TOKEN now |

---

## 🚀 How to Test

### Option 1: Dry Run (Recommended First)
```powershell
./scripts/sync-jira-bidirectional.ps1 -DryRun
```
Shows what would happen without making changes.

### Option 2: Real Sync
```powershell
./scripts/sync-jira-bidirectional.ps1
```
Performs actual sync and updates files.

### Option 3: GitHub Workflow
1. Go to **Actions** tab
2. Select **"Sync Project Tasks to Jira"**
3. Click **"Run workflow"**
4. Check logs for results

---

## 📋 What Gets Synced

### Jira → project-task.md
- Fetches all Jira issues with service labels
- Maps status to checkbox:
  - `To Do` → `[ ]`
  - `In Progress` → `[-]`
  - `In Review` → `[~]`
  - `Done` → `[x]`
- Adds to markdown file

### project-task.md → Jira
- Finds new tasks (without Jira keys)
- Creates Jira issue
- Sets correct status
- Updates markdown with Jira key

---

## ✨ Status Mapping

```
Checkbox    Jira Status    Meaning
─────────────────────────────────────
[ ]         To Do          Not started
[-]         In Progress    Being worked on
[~]         In Review      Ready for review
[x]         Done           Completed
```

---

## 🔍 Verify It Works

After running sync, check:

1. **Jira → Markdown**
   - [ ] Issues appear in project-task.md
   - [ ] Correct checkboxes applied
   - [ ] Issue keys visible

2. **Markdown → Jira**
   - [ ] New Jira issues created
   - [ ] Correct status set
   - [ ] Markdown updated with keys

3. **File Updates**
   - [ ] project-task.md files saved
   - [ ] Changes committed to git
   - [ ] Changes pushed to GitHub

---

## 🐛 Troubleshooting

### "Missing Jira credentials"
Check GitHub Secrets:
- `JIRA_BASE_URL`
- `JIRA_USER_EMAIL`
- `JIRA_API_TOKEN`
- `PAT_TOKEN`

### "Git push failed"
- Verify `PAT_TOKEN` has `repo` scope
- Verify token not expired

### "No issues synced"
- Check Jira project is `WEALTHFID`
- Check issues have labels:
  - `ai-security-service` (SecurityService)
  - `data-loader-service` (DataLoaderService)

### "Regex not matching"
- Ensure format: `- [ ] Description`
- No extra spaces or characters

---

## 📁 Files Modified

- `.github/workflows/sync-project-tasks-to-jira.yml` - Workflow updated
- `scripts/sync-jira-bidirectional.ps1` - Script fixed
- `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md` - Cleaned
- `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md` - Cleaned

---

## 📚 Documentation

- **Summary**: `.github/SYNC-FIXES-SUMMARY.md`
- **Details**: `.github/IMPLEMENTATION-DETAILS.md`
- **Fixes**: `.github/JIRA-SYNC-FIXES.md`

---

## ⚡ Next Steps

1. ✅ Verify GitHub Secrets configured
2. ✅ Run script locally with `-DryRun`
3. ✅ Review output
4. ✅ Run actual sync
5. ✅ Verify files updated
6. ✅ Check Jira for new issues
7. ✅ Monitor workflow runs

---

**Status**: Ready for testing
**Last Updated**: February 12, 2025
