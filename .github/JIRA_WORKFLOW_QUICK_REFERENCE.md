# Jira GitHub Workflow - Quick Reference

## ⚡ Quick Setup (5 minutes)

### 1. Add GitHub Secret

Go to: **GitHub Repo → Settings → Secrets and variables → Actions → New repository secret**

| Name | Value |
|------|-------|
| `JIRA_API_TOKEN` | `ATATT3xFfGF0-8KPcmrFWzpJXD7X6vklo8IvXYaYFm65pbJkV36CivSWOfvJuUim-KNFczurnuGTywBJ6Rh35ajnxKqWJ23T07QGEqR6Vz9NBufmY8tPN7j0Pd_dwQ8GWPhYIQU4uF1TK1DAivx3KUYmAgchTtXHXe3uf-iCcAVm3LZ2sViQudI=4911DC2B` |

### 2. Create PR with Jira Issue Key

```bash
git checkout -b "feat: WEALTHFID-357-your-feature"
git commit --allow-empty -m "test"
git push origin "feat: WEALTHFID-357-your-feature"
# Create PR on GitHub
```

### 3. Verify

- ✅ Check GitHub Actions workflow logs
- ✅ Check Jira issue status changed to "In Review"

---

## 📋 Branch Name Format

```
[type]: [JIRA-KEY]-[description]
```

**Valid Examples:**
- `feat: WEALTHFID-357-add-auth`
- `fix: WEALTHFID-123-fix-bug`
- `docs: WEALTHFID-456-update-docs`

**Invalid Examples:**
- ❌ `add-feature` (no Jira key)
- ❌ `WEALTHFID-357` (no type prefix)

---

## 🔄 Workflow Steps

1. **Extract Jira Key** from branch name
2. **Transition Issue** to "In Review" (ID: 5)
3. **Log Result** in workflow

---

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| Workflow doesn't run | Branch name must contain `[A-Z]+-\d+` pattern |
| "Issue does not exist" | Verify issue exists at https://nileshf.atlassian.net/browse/WEALTHFID-357 |
| "Permission denied" | Verify `JIRA_API_TOKEN` secret is set in GitHub |
| Issue not transitioning | Check Jira issue status and available transitions |

---

## 📊 Workflow Configuration

| Setting | Value |
|---------|-------|
| **Trigger** | PR opened, synchronized, reopened |
| **Jira URL** | https://nileshf.atlassian.net |
| **Transition ID** | 5 (In Review) |
| **API Endpoint** | `/rest/api/3/issue/{KEY}/transitions` |
| **Auth Method** | Basic Auth (username + token) |

---

## ✅ Verification Checklist

- [ ] `JIRA_API_TOKEN` secret added to GitHub
- [ ] Branch name contains Jira issue key
- [ ] PR created from branch
- [ ] Workflow runs successfully
- [ ] Jira issue status changed to "In Review"
- [ ] Workflow logs show success message

---

**Status**: Ready to use after GitHub secret is configured

**Workflow File**: `.github/workflows/pr-validation.yml`

**Setup Guide**: `.github/JIRA_INTEGRATION_SETUP.md`
