# Testing Jira Sync Flow

## Overview

This guide covers testing the complete Jira sync flow for both happy path and failure scenarios.

## Prerequisites

1. Jira project `WEALTHFID` exists
2. GitHub repository with PR validation workflow
3. Environment variables configured:
   - `JIRA_BASE_URL`
   - `JIRA_USER_EMAIL`
   - `JIRA_API_TOKEN`

## Happy Path Test

### Step 1: Create a new Jira issue

```bash
# Create a new task in Jira
# Issue key: WEALTHFID-XXX
# Summary: "Test: PR Validation Flow"
# Status: "To Do"
```

### Step 2: Create a PR branch with the issue key

```bash
# Create a branch with the issue key in the name
git checkout -b feature/WEALTHFID-XXX-test-pr-validation
```

### Step 3: Create a PR

1. Push the branch to GitHub
2. Create a PR from the branch
3. **Expected**: Jira issue transitions to "In Review"

### Step 4: Verify PR validation workflow

1. Check GitHub Actions → PR Validation workflow
2. **Expected**: 
   - "Extract Jira issue key" step finds `WEALTHFID-XXX`
   - "Transition Jira to In Review" step succeeds
   - Jira issue status is "In Review"

### Step 5: Run Jira sync (Step 4 only)

```bash
# Run the sync script manually
.\scripts\jira-sync-step4-jira-to-markdown.ps1
```

**Expected**: Markdown file is updated to match Jira status

### Step 6: Code review success

1. Get approval from a reviewer
2. **Expected**: Jira issue transitions to "Testing"

### Step 7: CI/CD success

1. All CI/CD checks pass
2. **Expected**: Jira issue stays in "Testing" or moves to "Done"

## Failure Path Test

### Scenario 1: CI/CD fails

1. Create a PR with failing tests
2. **Expected**: Jira issue transitions to "Changes Requested"

### Scenario 2: Code review fails

1. Create a PR with review comments
2. Request changes from reviewer
3. **Expected**: Jira issue transitions to "Changes Requested"

### Scenario 3: PR title validation fails

1. Create a PR with invalid title (no conventional commit prefix)
2. **Expected**: PR validation fails, Jira issue stays in "To Do"

## Manual Testing Commands

### Test Jira transitions

```bash
# Get available transitions for an issue
curl -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}/rest/api/3/issue/WEALTHFID-XXX/transitions?expand=transitions"

# Transition to In Review (find the correct transition ID first)
curl -X POST \
  -H "Content-Type: application/json" \
  -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  -d '{"transition":{"id":"31"}}' \
  "${JIRA_BASE_URL}/rest/api/3/issue/WEALTHFID-XXX/transitions"
```

### Test markdown sync

```bash
# Run the sync script
.\scripts\jira-sync-step4-jira-to-markdown.ps1

# Check the markdown file
Get-Content "Applications/AITooling/Services/DataLoaderService/.kiro/specs/data-loader-service/project-task.md"
```

## Troubleshooting

### Issue: Jira issue doesn't transition to "In Review"

**Check**:
1. PR branch name contains issue key (format: `feature/WEALTHFID-XXX`)
2. Jira user has permission to transition issues
3. "In Review" transition exists in the workflow

**Fix**:
1. Rename branch to include issue key
2. Check Jira permissions
3. Update transition ID in workflow

### Issue: Markdown file not updated

**Check**:
1. Jira issue exists and has a status
2. Script has correct permissions
3. File path is correct

**Fix**:
1. Verify Jira issue status
2. Check environment variables
3. Verify file path

### Issue: Transition ID not found

**Check**:
1. Get available transitions for the issue
2. Find the correct "In Review" transition ID

**Fix**:
```bash
# Get transitions
curl -u "${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}" \
  "${JIRA_BASE_URL}/rest/api/3/issue/WEALTHFID-XXX/transitions?expand=transitions"

# Find the ID for "In Review" and update workflow
```

## Summary

| Scenario | Expected Jira Status |
|----------|---------------------|
| PR created | In Review |
| CI/CD fails | Changes Requested |
| Code review fails | Changes Requested |
| CI/CD + review success | Testing → Done |
