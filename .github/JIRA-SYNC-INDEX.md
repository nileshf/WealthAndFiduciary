# Jira Sync Workflow - Complete Index

## 📖 Documentation Overview

This folder contains comprehensive documentation for the bidirectional Jira sync workflow. Start here to find what you need.

---

## 🎯 Quick Navigation

### I Want To...

#### Get Started Quickly
→ **Read**: `.github/QUICK-REFERENCE.md` (5 minutes)
- Quick start guide
- Service labels
- Checkbox mapping
- Common errors

#### Configure GitHub Secrets
→ **Read**: `.github/GITHUB-SECRETS-SETUP.md` (10 minutes)
- Step-by-step setup
- How to find credentials
- Verification steps
- Security best practices

#### Understand What Was Fixed
→ **Read**: `.github/WORKFLOW-FIXES-APPLIED.md` (5 minutes)
- Issues found
- Fixes applied
- Files modified
- Next steps

#### Troubleshoot Issues
→ **Read**: `.github/WORKFLOW-TROUBLESHOOTING.md` (20 minutes)
- Common issues
- Detailed solutions
- Workflow execution flow
- Manual testing

#### Check Current Status
→ **Read**: `.github/JIRA-SYNC-STATUS.md` (10 minutes)
- Workflow status
- Configuration checklist
- Deployment steps
- Verification checklist

#### Understand the Workflow
→ **Read**: `.github/workflows/sync-project-tasks-to-jira.yml`
- Workflow definition
- Job configuration
- Triggers and conditions

#### Understand the Script
→ **Read**: `scripts/sync-jira-to-tasks.ps1`
- PowerShell script
- Service registry
- Jira API integration
- Task processing logic

---

## 📚 Document Guide

### `.github/QUICK-REFERENCE.md`
**Purpose**: Quick reference card for common tasks
**Length**: 2 pages
**Audience**: Everyone
**Contains**:
- Quick start (5 minutes)
- Service labels
- Checkbox mapping
- Troubleshooting table
- Documentation index

**When to Use**: You need a quick answer

---

### `.github/GITHUB-SECRETS-SETUP.md`
**Purpose**: Complete guide for configuring GitHub Secrets
**Length**: 5 pages
**Audience**: DevOps, Repository Admins
**Contains**:
- Required secrets
- Step-by-step setup
- Verification
- Troubleshooting
- Security best practices

**When to Use**: Setting up the workflow for the first time

---

### `.github/WORKFLOW-FIXES-APPLIED.md`
**Purpose**: Summary of issues fixed and changes made
**Length**: 3 pages
**Audience**: Technical leads, Reviewers
**Contains**:
- Issues found and fixed
- Files modified
- Issues requiring user action
- Next steps
- Verification checklist

**When to Use**: Understanding what was changed and why

---

### `.github/WORKFLOW-TROUBLESHOOTING.md`
**Purpose**: Comprehensive troubleshooting guide
**Length**: 15 pages
**Audience**: Developers, DevOps
**Contains**:
- Quick diagnosis steps
- 10 common issues with solutions
- Workflow execution flow
- Manual testing procedures
- Log analysis guide
- Getting help

**When to Use**: Workflow is failing or behaving unexpectedly

---

### `.github/JIRA-SYNC-STATUS.md`
**Purpose**: Current status and deployment guide
**Length**: 8 pages
**Audience**: Project managers, Developers
**Contains**:
- Executive summary
- Workflow status
- Issues fixed
- Configuration checklist
- Deployment steps
- Testing scenarios
- Verification checklist

**When to Use**: Planning deployment or checking overall status

---

### `.github/JIRA-SYNC-INDEX.md`
**Purpose**: This file - navigation guide
**Length**: 3 pages
**Audience**: Everyone
**Contains**:
- Quick navigation
- Document guide
- File structure
- Workflow overview
- Getting help

**When to Use**: Finding the right documentation

---

## 🗂️ File Structure

```
.github/
├── workflows/
│   └── sync-project-tasks-to-jira.yml ← Main workflow file
├── QUICK-REFERENCE.md ← Start here for quick answers
├── GITHUB-SECRETS-SETUP.md ← Setup guide
├── WORKFLOW-FIXES-APPLIED.md ← What was fixed
├── WORKFLOW-TROUBLESHOOTING.md ← Troubleshooting guide
├── JIRA-SYNC-STATUS.md ← Current status
└── JIRA-SYNC-INDEX.md ← This file

scripts/
└── sync-jira-to-tasks.ps1 ← PowerShell sync script

Applications/AITooling/Services/
├── SecurityService/.kiro/specs/security-service/
│   └── project-task.md ← SecurityService tasks
└── DataLoaderService/.kiro/specs/data-loader-service/
    └── project-task.md ← DataLoaderService tasks
```

---

## 🔄 Workflow Overview

### What It Does

**Jira → project-task.md Sync**
- Fetches open Jira issues with service labels
- Adds tasks to project-task.md files
- Runs every 15 minutes automatically

**project-task.md → Jira Sync**
- Detects checkbox status changes
- Updates Jira issue statuses
- Runs on push to develop

### How It Works

```
1. Workflow triggered (schedule, push, or manual)
   ↓
2. Fetch Jira issues with service labels
   ↓
3. Route to correct service based on label
   ↓
4. Add tasks to project-task.md files
   ↓
5. Commit and push changes
   ↓
6. Detect checkbox changes (if any)
   ↓
7. Update Jira issue statuses
   ↓
8. Validate results
   ↓
9. Report status
```

### Service Labels

| Service | Label | File |
|---------|-------|------|
| SecurityService | `ai-security-service` | `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md` |
| DataLoaderService | `data-loader-service` | `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md` |

---

## ✅ Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Workflow File | ✅ Ready | All fixes applied |
| PowerShell Script | ✅ Ready | Tested locally |
| Service Labels | ✅ Ready | Configured in Jira |
| Project Task Files | ✅ Ready | Files exist and valid |
| GitHub Secrets | ⚠️ Pending | Requires user action |
| Documentation | ✅ Complete | 5 comprehensive guides |

**Overall Status**: ✅ **READY FOR DEPLOYMENT** (pending secrets configuration)

---

## 🚀 Getting Started

### For First-Time Users

1. **Read**: `.github/QUICK-REFERENCE.md` (5 min)
2. **Read**: `.github/GITHUB-SECRETS-SETUP.md` (10 min)
3. **Do**: Configure GitHub Secrets (5 min)
4. **Do**: Test the workflow (5 min)
5. **Verify**: Check results (5 min)

**Total Time**: ~30 minutes

### For Troubleshooting

1. **Read**: `.github/QUICK-REFERENCE.md` (find your error)
2. **Read**: `.github/WORKFLOW-TROUBLESHOOTING.md` (detailed solution)
3. **Do**: Follow the solution steps
4. **Verify**: Re-run the workflow

**Total Time**: ~15 minutes

### For Understanding Changes

1. **Read**: `.github/WORKFLOW-FIXES-APPLIED.md` (what was fixed)
2. **Read**: `.github/JIRA-SYNC-STATUS.md` (current status)
3. **Review**: `.github/workflows/sync-project-tasks-to-jira.yml` (workflow file)
4. **Review**: `scripts/sync-jira-to-tasks.ps1` (script file)

**Total Time**: ~20 minutes

---

## 🎯 Key Concepts

### Service Labels
Each Jira issue must have a service label to be synced:
- `ai-security-service` → SecurityService project-task.md
- `data-loader-service` → DataLoaderService project-task.md

### Checkbox Status
Project-task.md checkboxes map to Jira statuses:
- `[ ]` = To Do
- `[-]` = In Progress
- `[~]` = Testing
- `[x]` = Done

### Workflow Triggers
- **Schedule**: Every 15 minutes (automatic)
- **Push**: On push to develop (automatic)
- **Manual**: On demand (manual trigger)

### GitHub Secrets
Three secrets required for authentication:
- `JIRA_BASE_URL`: Your Jira instance URL
- `JIRA_USER_EMAIL`: Your Jira account email
- `JIRA_API_TOKEN`: Your Jira API token

---

## 🔍 Finding Help

### Quick Questions
→ Check `.github/QUICK-REFERENCE.md`

### Setup Issues
→ Check `.github/GITHUB-SECRETS-SETUP.md`

### Workflow Failures
→ Check `.github/WORKFLOW-TROUBLESHOOTING.md`

### Understanding Changes
→ Check `.github/WORKFLOW-FIXES-APPLIED.md`

### Current Status
→ Check `.github/JIRA-SYNC-STATUS.md`

### Still Need Help?
1. Check the relevant documentation
2. Review the workflow logs
3. Verify GitHub Secrets are configured
4. Test locally with the PowerShell script

---

## 📞 Support Resources

### Documentation Files
- `.github/QUICK-REFERENCE.md` - Quick answers
- `.github/GITHUB-SECRETS-SETUP.md` - Setup guide
- `.github/WORKFLOW-FIXES-APPLIED.md` - What was fixed
- `.github/WORKFLOW-TROUBLESHOOTING.md` - Troubleshooting
- `.github/JIRA-SYNC-STATUS.md` - Current status

### Code Files
- `.github/workflows/sync-project-tasks-to-jira.yml` - Workflow definition
- `scripts/sync-jira-to-tasks.ps1` - Sync script

### Project Task Files
- `Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md`
- `Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md`

---

## 📋 Checklist

### Before First Run
- [ ] Read `.github/QUICK-REFERENCE.md`
- [ ] Read `.github/GITHUB-SECRETS-SETUP.md`
- [ ] Configure `JIRA_BASE_URL` secret
- [ ] Configure `JIRA_USER_EMAIL` secret
- [ ] Configure `JIRA_API_TOKEN` secret
- [ ] Verify secrets appear in GitHub Settings

### After First Run
- [ ] Check workflow logs for success
- [ ] Verify tasks appear in project-task.md files
- [ ] Verify Jira issues have service labels
- [ ] Test checkbox status sync
- [ ] Monitor scheduled runs

### Ongoing
- [ ] Monitor workflow runs
- [ ] Maintain Jira issue labels
- [ ] Update documentation as needed
- [ ] Report any issues

---

## 🎓 Learning Path

### Beginner
1. `.github/QUICK-REFERENCE.md` - Understand what it does
2. `.github/GITHUB-SECRETS-SETUP.md` - Set it up
3. Test the workflow manually

### Intermediate
1. `.github/WORKFLOW-TROUBLESHOOTING.md` - Understand how to troubleshoot
2. `.github/JIRA-SYNC-STATUS.md` - Understand the status
3. Review the workflow file

### Advanced
1. `.github/workflows/sync-project-tasks-to-jira.yml` - Understand the workflow
2. `scripts/sync-jira-to-tasks.ps1` - Understand the script
3. Modify and extend as needed

---

## 📊 Document Statistics

| Document | Pages | Read Time | Audience |
|----------|-------|-----------|----------|
| QUICK-REFERENCE.md | 2 | 5 min | Everyone |
| GITHUB-SECRETS-SETUP.md | 5 | 10 min | DevOps, Admins |
| WORKFLOW-FIXES-APPLIED.md | 3 | 5 min | Tech leads |
| WORKFLOW-TROUBLESHOOTING.md | 15 | 20 min | Developers |
| JIRA-SYNC-STATUS.md | 8 | 10 min | Managers |
| JIRA-SYNC-INDEX.md | 3 | 5 min | Everyone |

**Total**: 36 pages, ~55 minutes of documentation

---

## 🎯 Next Steps

1. **Read**: `.github/QUICK-REFERENCE.md` (5 minutes)
2. **Read**: `.github/GITHUB-SECRETS-SETUP.md` (10 minutes)
3. **Do**: Configure GitHub Secrets (5 minutes)
4. **Do**: Test the workflow (5 minutes)
5. **Verify**: Check results (5 minutes)

**Total Time**: ~30 minutes to full deployment

---

**Last Updated**: January 2025
**Workflow File**: `.github/workflows/sync-project-tasks-to-jira.yml`
**Script File**: `scripts/sync-jira-to-tasks.ps1`

**Start Here**: `.github/QUICK-REFERENCE.md` ⭐
