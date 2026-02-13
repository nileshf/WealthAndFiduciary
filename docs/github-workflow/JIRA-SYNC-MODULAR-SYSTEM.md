# Jira Sync - Modular System

## 🎯 Overview

The Jira Sync system is a modular, automated workflow that keeps Jira and microservice project task files in sync. The system consists of 4 independent steps that run in strict sequence, with Jira as the source of truth.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Jira Sync Orchestrator                        │
│                  (Runs every 30 minutes)                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │  Security    │ │  DataLoader  │ │   Future     │
        │  Service     │ │  Service     │ │  Services    │
        └──────────────┘ └──────────────┘ └──────────────┘
                │               │               │
                ▼               ▼               ▼
        ┌──────────────────────────────────────────────┐
        │  Step 1: Pull Missing Tasks from Jira        │
        │  (Add tasks to markdown if in Jira)          │
        └──────────────────────────────────────────────┘
                │
                ▼
        ┌──────────────────────────────────────────────┐
        │  Step 2: Push New Tasks to Jira              │
        │  (Create tasks in Jira if in markdown)       │
        └──────────────────────────────────────────────┘
                │
                ▼
        ┌──────────────────────────────────────────────┐
        │  Step 3: Sync Status from Jira to Markdown   │
        │  (Update checkboxes from Jira status)        │
        └──────────────────────────────────────────────┘
                │
                ▼
        ┌──────────────────────────────────────────────┐
        │  Step 4: Sync Status from Markdown to Jira   │
        │  (Update Jira status from checkboxes)        │
        └──────────────────────────────────────────────┘
```

## 📋 The 4 Steps

### Step 1: Pull Missing Tasks from Jira
**File**: `scripts/jira-sync-step1-pull-missing-tasks.ps1`

**Purpose**: If a task exists in Jira but not in the microservice's `project-task.md`, add it to the markdown file.

**Process**:
1. Fetch all tasks from Jira (project = WEALTHFID)
2. Read existing tasks from `project-task.md`
3. Find tasks in Jira that are missing from markdown
4. Add missing tasks to markdown with correct checkbox status
5. Commit changes

**Status Mapping** (Jira → Checkbox):
- `To Do` → `[ ]`
- `In Progress` or `In Review` → `[-]`
- `Testing` or `Ready to Merge` → `[~]`
- `Done` → `[x]`

### Step 2: Push New Tasks to Jira
**File**: `scripts/jira-sync-step2-push-new-tasks.ps1`

**Purpose**: If a task exists in `project-task.md` but not in Jira, create it in Jira and update the markdown with the Jira key.

**Process**:
1. Fetch all tasks from Jira
2. Read tasks from `project-task.md`
3. Find tasks in markdown without Jira keys
4. Create new tasks in Jira with appropriate status
5. Update markdown with new Jira keys
6. Commit changes

**Example**:
```markdown
# Before
- [ ] Implement JWT authentication

# After
- [ ] WEALTHFID-191 - Implement JWT authentication
```

### Step 3: Sync Status from Jira to Markdown
**File**: `scripts/jira-sync-step3-sync-jira-status.ps1`

**Purpose**: If a task's status changes in Jira, update the checkbox in `project-task.md` to reflect the new status.

**Process**:
1. Fetch all tasks from Jira with their current status
2. Read tasks from `project-task.md`
3. Compare Jira status with markdown checkbox
4. Update checkboxes where status has changed
5. Commit changes

**Example**:
```markdown
# Before (Jira status changed to "In Progress")
- [ ] WEALTHFID-191 - Implement JWT authentication

# After
- [-] WEALTHFID-191 - Implement JWT authentication
```

### Step 4: Sync Status from Markdown to Jira
**File**: `scripts/jira-sync-step4-sync-markdown-status.ps1`

**Purpose**: If a task's checkbox changes in `project-task.md`, update the status in Jira to reflect the new status.

**Process**:
1. Fetch all tasks from Jira with available transitions
2. Read tasks from `project-task.md`
3. Compare markdown checkbox with Jira status
4. Transition tasks in Jira where checkbox has changed
5. No markdown changes (Jira is updated)

**Example**:
```markdown
# Before (Developer marks as done in markdown)
- [-] WEALTHFID-191 - Implement JWT authentication

# After (Jira status updated to "Done")
- [x] WEALTHFID-191 - Implement JWT authentication
```

## 🔄 Workflow Execution

### Automatic Execution
The orchestrator runs automatically every 30 minutes via GitHub Actions schedule:
```yaml
schedule:
  - cron: '*/30 * * * *'
```

### Manual Execution
Trigger manually from GitHub Actions UI:
```
Actions → Jira Sync - Orchestrator → Run workflow
```

Optional: Specify a service to sync only that service:
```
Input: service_name = SecurityService
```

## 📁 File Structure

```
.github/
├── workflows/
│   ├── jira-sync-orchestrator.yml           # Main orchestrator
│   ├── jira-sync-step1-pull-tasks.yml       # Step 1 workflow
│   ├── jira-sync-step2-push-tasks.yml       # Step 2 workflow
│   ├── jira-sync-step3-sync-jira-status.yml # Step 3 workflow
│   └── jira-sync-step4-sync-markdown-status.yml # Step 4 workflow
└── JIRA-SYNC-MODULAR-SYSTEM.md              # This file

scripts/
├── jira-sync-step1-pull-missing-tasks.ps1   # Step 1 script
├── jira-sync-step2-push-new-tasks.ps1       # Step 2 script
├── jira-sync-step3-sync-jira-status.ps1     # Step 3 script
└── jira-sync-step4-sync-markdown-status.ps1 # Step 4 script

Applications/AITooling/Services/
├── SecurityService/
│   └── .kiro/specs/security-service/
│       └── project-task.md                  # Task file
└── DataLoaderService/
    └── .kiro/specs/data-loader-service/
        └── project-task.md                  # Task file
```

## 🔐 Required Secrets

The following GitHub secrets must be configured:

| Secret | Description |
|--------|-------------|
| `JIRA_BASE_URL` | Jira instance URL (e.g., `https://jira.example.com`) |
| `JIRA_USER_EMAIL` | Jira user email for API authentication |
| `JIRA_API_TOKEN` | Jira API token for authentication |
| `SLACK_WEBHOOK_URL` | (Optional) Slack webhook for notifications |

## 📝 Task File Format

Task files use standard markdown checkbox syntax:

```markdown
# ServiceName Project Tasks

## Implementation Tasks
- [ ] WEALTHFID-191 - Implement JWT authentication
- [-] WEALTHFID-192 - Add user registration endpoint
- [~] WEALTHFID-193 - Create role-based authorization
- [x] WEALTHFID-194 - Implement password hashing

## Testing Tasks
- [ ] WEALTHFID-195 - Write unit tests
```

### Checkbox Meanings

| Checkbox | Meaning | Jira Status |
|----------|---------|-------------|
| `[ ]` | Not started | To Do |
| `[-]` | In progress | In Progress / In Review |
| `[~]` | Testing/Ready | Testing / Ready to Merge |
| `[x]` | Completed | Done |

## 🚀 Adding a New Service

To add a new microservice to the sync system:

1. **Create task file** in the service:
   ```
   Applications/[Application]/Services/[ServiceName]/.kiro/specs/[service-name]/project-task.md
   ```

2. **Add to orchestrator** in `.github/workflows/jira-sync-orchestrator.yml`:
   ```yaml
   sync-new-service:
     if: github.event.inputs.service_name == '' || github.event.inputs.service_name == 'NewService'
     uses: ./.github/workflows/jira-sync-step1-pull-tasks.yml
     with:
       service_name: 'NewService'
       task_file: 'Applications/[Application]/Services/NewService/.kiro/specs/[service-name]/project-task.md'
     secrets: inherit

   sync-new-service-step2:
     needs: sync-new-service
     if: github.event.inputs.service_name == '' || github.event.inputs.service_name == 'NewService'
     uses: ./.github/workflows/jira-sync-step2-push-tasks.yml
     with:
       service_name: 'NewService'
       task_file: 'Applications/[Application]/Services/NewService/.kiro/specs/[service-name]/project-task.md'
       project_key: 'WEALTHFID'
     secrets: inherit

   # ... repeat for steps 3 and 4
   ```

3. **Add to notify-completion** dependencies:
   ```yaml
   needs: [sync-security-service-step4, sync-data-loader-service-step4, sync-new-service-step4]
   ```

## 🔍 Monitoring and Troubleshooting

### View Sync Logs
1. Go to GitHub Actions
2. Click "Jira Sync - Orchestrator"
3. Click the latest run
4. View logs for each step

### Common Issues

**Issue**: Step fails with "Missing Jira credentials"
- **Solution**: Verify `JIRA_BASE_URL`, `JIRA_USER_EMAIL`, and `JIRA_API_TOKEN` secrets are configured

**Issue**: Step fails with "Task file not found"
- **Solution**: Verify task file path is correct in workflow inputs

**Issue**: Tasks not syncing
- **Solution**: Check Jira project key matches `JIRA_PROJECT_KEY` in workflow

**Issue**: Status transitions fail
- **Solution**: Verify Jira workflow allows the transition (e.g., To Do → Done may not be allowed)

## 📊 Sync Flow Example

### Scenario: New task created in markdown

```
1. Developer creates task in project-task.md:
   - [ ] Implement new feature

2. Orchestrator runs (Step 1):
   ✓ No missing tasks from Jira

3. Orchestrator runs (Step 2):
   ✓ Creates WEALTHFID-300 in Jira
   ✓ Updates markdown: - [ ] WEALTHFID-300 - Implement new feature

4. Orchestrator runs (Step 3):
   ✓ No status changes from Jira

5. Orchestrator runs (Step 4):
   ✓ No status changes from markdown

Result: Task synced to Jira with Jira key
```

### Scenario: Task status changed in Jira

```
1. Task in Jira: WEALTHFID-300 (status: To Do)
   Task in markdown: - [ ] WEALTHFID-300 - Implement new feature

2. Developer moves task to "In Progress" in Jira

3. Orchestrator runs (Step 1):
   ✓ No missing tasks

4. Orchestrator runs (Step 2):
   ✓ No new tasks

5. Orchestrator runs (Step 3):
   ✓ Detects status change: To Do → In Progress
   ✓ Updates markdown: - [-] WEALTHFID-300 - Implement new feature

6. Orchestrator runs (Step 4):
   ✓ No status changes from markdown

Result: Markdown reflects Jira status
```

## 🔄 Sync Frequency

- **Automatic**: Every 30 minutes
- **Manual**: On-demand via GitHub Actions UI
- **On-Demand**: Trigger specific service sync

## 📚 Related Documentation

- [Jira Integration Guide](./JIRA-INTEGRATION-GUIDE.md)
- [GitHub Workflow Guide](./GITHUB-WORKFLOW-GUIDE.md)
- [Automatic Sync Guide](./AUTOMATIC-SYNC-GUIDE.md)

## ✅ Checklist for Implementation

- [x] Create 4 PowerShell scripts (steps 1-4)
- [x] Create 4 GitHub workflows (steps 1-4)
- [x] Create orchestrator workflow
- [x] Configure Jira secrets
- [x] Test with SecurityService
- [x] Test with DataLoaderService
- [ ] Monitor first 24 hours of automatic syncs
- [ ] Document any issues or improvements

---

**Last Updated**: January 2025
**Maintained By**: DevOps Team
