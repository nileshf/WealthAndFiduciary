# Jira Sync Quick Start Guide

## Overview

The Jira Sync system keeps your project task files synchronized with Jira. It consists of 4 steps that can be run individually or together via orchestration.

## Prerequisites

- PowerShell 7+ (pwsh)
- `.env` file with Jira credentials (already present in the repo)
- Task file in your service directory (`.kiro/specs/{service}/project-task.md`)

## Quick Setup

### Option 1: Automated Setup (Recommended)

```powershell
./scripts/setup-jira-sync-auto.ps1 -ServiceName "SecurityService"
```

This will:
- Load Jira credentials from `.env`
- Select your service
- Verify the task file exists
- Set environment variables
- Save configuration to `.kiro/settings/jira-sync-config.json`

### Option 2: Interactive Setup

```powershell
./scripts/setup-jira-sync.ps1
```

This provides an interactive menu to:
- Load or enter Jira credentials
- Select a service
- Choose which operation to run
- Execute the selected operation

## Running Sync Operations

After setup, you can run individual steps or all steps together.

### Step 1: Pull Missing Tasks from Jira

Fetches tasks from Jira that don't exist in your markdown file and adds them.

```powershell
./scripts/jira-sync-step1-pull-missing-tasks.ps1
```

**What it does:**
- Fetches all Jira issues from the project
- Compares with existing tasks in markdown
- Adds missing tasks to markdown
- Matches tasks without Jira keys to Jira issues by similarity (60% threshold)

### Step 2: Push New Tasks to Jira

Creates Jira issues for tasks in markdown that don't have Jira keys.

```powershell
./scripts/jira-sync-step2-push-new-tasks.ps1
```

**What it does:**
- Reads tasks from markdown without Jira keys
- Creates new Jira issues for each task
- Updates markdown with the new Jira keys

### Step 3: Sync Jira Status to Markdown

Updates task status in markdown based on Jira status.

```powershell
./scripts/jira-sync-step3-sync-jira-status.ps1
```

**What it does:**
- Reads all tasks from markdown
- Fetches current status from Jira
- Updates checkbox status in markdown to match Jira

### Step 4: Sync Markdown Status to Jira

Updates Jira status based on task status in markdown.

```powershell
./scripts/jira-sync-step4-sync-markdown-status.ps1
```

**What it does:**
- Reads all tasks from markdown
- Extracts status from checkbox
- Updates Jira issue status to match markdown

### Run All Steps (Orchestration)

```powershell
./scripts/jira-sync-orchestration.ps1
```

This runs all 4 steps in sequence:
1. Pull missing tasks from Jira
2. Push new tasks to Jira
3. Sync Jira status to markdown
4. Sync markdown status to Jira

## Configuration

### .env File

Located at workspace root, contains Jira credentials:

```
JIRA_BASE_URL=https://nileshf.atlassian.net
JIRA_PROJECT_KEY=WEALTHFID
JIRA_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-api-token
```

### JSON Configuration

Saved to `.kiro/settings/jira-sync-config.json` after setup:

```json
{
  "JiraBaseUrl": "https://nileshf.atlassian.net",
  "JiraEmail": "your-email@example.com",
  "JiraToken": "your-api-token",
  "JiraProjectKey": "WEALTHFID",
  "ServiceName": "SecurityService",
  "TaskFile": "Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md"
}
```

## Task File Format

Tasks in markdown use this format:

```markdown
- [x] WEALTHFID-123 - Completed task
- [-] WEALTHFID-124 - In progress task
- [~] WEALTHFID-125 - Testing task
- [ ] WEALTHFID-126 - Not started task
- [ ] - Task without Jira key (will be matched or created)
```

### Checkbox Status Mapping

| Checkbox | Meaning | Jira Status |
|----------|---------|-------------|
| `[ ]` | Not started | To Do |
| `[-]` | In progress | In Progress |
| `[~]` | Testing | Testing |
| `[x]` | Done | Done |

## Supported Services

- SecurityService
- DataLoaderService
- FullViewSecurity
- INN8DataSource

## Troubleshooting

### "Task file not found"

Verify the service name is correct and the task file exists:

```powershell
Test-Path "Applications/AITooling/Services/SecurityService/.kiro/specs/security-service/project-task.md"
```

### "Missing Jira credentials"

Ensure `.env` file exists and contains:
- JIRA_BASE_URL
- JIRA_EMAIL
- JIRA_API_TOKEN
- JIRA_PROJECT_KEY

### "Failed to fetch Jira issues"

Check:
- Jira credentials are correct
- Jira API token is valid (not expired)
- Network connectivity to Jira
- Jira project key is correct

### "No matching Jira issue found"

Tasks without Jira keys require at least 60% word similarity to match. If no match is found:
- The task will be created as a new Jira issue in Step 2
- Or manually add the Jira key to the markdown

## Examples

### Complete Sync for SecurityService

```powershell
# Setup
./scripts/setup-jira-sync-auto.ps1 -ServiceName "SecurityService"

# Run all steps
./scripts/jira-sync-orchestration.ps1
```

### Sync Only Status Changes

```powershell
# Setup
./scripts/setup-jira-sync-auto.ps1 -ServiceName "SecurityService"

# Sync Jira status to markdown
./scripts/jira-sync-step3-sync-jira-status.ps1

# Sync markdown status to Jira
./scripts/jira-sync-step4-sync-markdown-status.ps1
```

### Add New Tasks from Jira

```powershell
# Setup
./scripts/setup-jira-sync-auto.ps1 -ServiceName "SecurityService"

# Pull missing tasks
./scripts/jira-sync-step1-pull-missing-tasks.ps1
```

## Environment Variables

After setup, these environment variables are available:

- `JIRA_BASE_URL` - Jira instance URL
- `JIRA_USER_EMAIL` - Jira user email
- `JIRA_API_TOKEN` - Jira API token
- `SERVICE_NAME` - Selected service name
- `TASK_FILE` - Path to task file

## Next Steps

1. Run setup: `./scripts/setup-jira-sync-auto.ps1 -ServiceName "SecurityService"`
2. Run orchestration: `./scripts/jira-sync-orchestration.ps1`
3. Review changes in your task file
4. Commit and push changes

## Support

For issues or questions, check:
- `.github/workflows/jira-sync-*.yml` - Workflow definitions
- `scripts/jira-sync-*.ps1` - Script implementations
- `.kiro/settings/jira-sync-config.json` - Configuration
