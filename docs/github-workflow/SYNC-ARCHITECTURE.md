# Automatic Jira Sync - Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    BIDIRECTIONAL JIRA SYNC SYSTEM                        │
└─────────────────────────────────────────────────────────────────────────┘

                              JIRA
                         (WEALTHFID Project)
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
        ┌─────────────────────┐  ┌─────────────────────┐
        │  Jira Issues with   │  │  Jira Workflow      │
        │  Service Labels     │  │  Statuses           │
        │                     │  │                     │
        │ - ai-security-      │  │ - To Do             │
        │   service           │  │ - In Progress       │
        │ - data-loader-      │  │ - Testing           │
        │   service           │  │ - Done              │
        └─────────────────────┘  └─────────────────────┘
                    │                       │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │  GitHub Actions       │
                    │  Workflow             │
                    │                       │
                    │ sync-project-tasks-   │
                    │ to-jira.yml           │
                    └───────────┬───────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
                ▼               ▼               ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │ Job 1:       │ │ Job 2:       │ │ Job 3:       │
        │ Sync Jira    │ │ Sync Tasks   │ │ Validate     │
        │ to Tasks     │ │ to Jira      │ │ Sync         │
        │              │ │              │ │              │
        │ Runs:        │ │ Runs:        │ │ Runs:        │
        │ - Every 15   │ │ - On push    │ │ - After      │
        │   minutes    │ │   to develop │ │   both jobs  │
        │ - On manual  │ │ - When       │ │              │
        │   trigger    │ │   project-   │ │              │
        │              │ │   task.md    │ │              │
        │              │ │   changes    │ │              │
        └──────────────┘ └──────────────┘ └──────────────┘
                │               │               │
                ▼               ▼               ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │ PowerShell   │ │ PowerShell   │ │ PowerShell   │
        │ Script:      │ │ Script:      │ │ Script:      │
        │              │ │              │ │              │
        │ sync-jira-   │ │ Inline:      │ │ Inline:      │
        │ to-tasks.ps1 │ │              │ │              │
        │              │ │ Parse diff   │ │ Validate     │
        │ Fetches:     │ │ Detect       │ │ project-     │
        │ - Open Jira  │ │ checkbox     │ │ task.md      │
        │   issues     │ │ changes      │ │ files        │
        │ - With       │ │              │ │              │
        │   service    │ │ Update Jira  │ │ Check:       │
        │   labels     │ │ status via   │ │ - Files      │
        │              │ │ transitions  │ │   exist      │
        │ Adds to:     │ │              │ │ - Valid      │
        │ - project-   │ │              │ │   format     │
        │   task.md    │ │              │ │              │
        │   files      │ │              │ │              │
        └──────────────┘ └──────────────┘ └──────────────┘
                │               │               │
                ▼               ▼               ▼
        ┌──────────────────────────────────────────────┐
        │  GitHub Repository                           │
        │                                              │
        │  Applications/AITooling/Services/            │
        │  ├── SecurityService/                        │
        │  │   └── .kiro/specs/security-service/       │
        │  │       └── project-task.md                 │
        │  │                                           │
        │  └── DataLoaderService/                      │
        │      └── .kiro/specs/data-loader-service/    │
        │          └── project-task.md                 │
        │                                              │
        │  Changes committed and pushed automatically  │
        └──────────────────────────────────────────────┘
```

## Data Flow

### Jira → project-task.md Flow

```
1. Scheduled Trigger (every 15 minutes)
   │
   ▼
2. Checkout repository
   │
   ▼
3. Run sync-jira-to-tasks.ps1
   │
   ├─ Authenticate to Jira API
   │
   ├─ Fetch open issues with JQL:
   │  status NOT IN (Done, Closed, Resolved) AND labels is not EMPTY
   │
   ├─ For each issue:
   │  ├─ Extract service label
   │  ├─ Identify service from label
   │  ├─ Check if task already exists
   │  └─ Add task to project-task.md if new
   │
   ▼
4. Commit changes
   │
   ▼
5. Push to develop branch
   │
   ▼
6. Task appears in project-task.md ✓
```

### project-task.md → Jira Flow

```
1. Push to develop branch
   │
   ├─ Detect changes to project-task.md files
   │
   ▼
2. Checkout repository
   │
   ▼
3. Get changed files
   │
   ├─ Use tj-actions/changed-files
   │
   ▼
4. Detect status changes
   │
   ├─ Parse git diff
   │
   ├─ Find checkbox changes:
   │  [ ] → [-] → [~] → [x]
   │
   ├─ Extract Jira issue keys
   │
   ├─ Map checkbox to Jira status:
   │  [ ] = "To Do"
   │  [-] = "In Progress"
   │  [~] = "Testing"
   │  [x] = "Done"
   │
   ▼
5. Update Jira issue status
   │
   ├─ Authenticate to Jira API
   │
   ├─ Get available transitions
   │
   ├─ Find transition to target status
   │
   ├─ Execute transition
   │
   ▼
6. Jira issue status updated ✓
```

## Service Routing

```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE LABEL ROUTING                         │
└─────────────────────────────────────────────────────────────────┘

Jira Issue Created
        │
        ├─ Label: "ai-security-service"
        │  │
        │  ▼
        │  Route to: SecurityService
        │  │
        │  ├─ Application: AITooling
        │  ├─ Service: SecurityService
        │  ├─ Path: Applications/AITooling/Services/SecurityService
        │  ├─ File: .kiro/specs/security-service/project-task.md
        │  ├─ Schema: Security
        │  └─ Jira Project: WEALTHFID
        │
        ├─ Label: "data-loader-service"
        │  │
        │  ▼
        │  Route to: DataLoaderService
        │  │
        │  ├─ Application: AITooling
        │  ├─ Service: DataLoaderService
        │  ├─ Path: Applications/AITooling/Services/DataLoaderService
        │  ├─ File: .kiro/specs/data-loader-service/project-task.md
        │  ├─ Schema: FileProcessing
        │  └─ Jira Project: WEALTHFID
        │
        └─ No Label
           │
           ▼
           Skip (not synced)
```

## Checkbox Status Mapping

```
┌─────────────────────────────────────────────────────────────────┐
│              CHECKBOX TO JIRA STATUS MAPPING                     │
└─────────────────────────────────────────────────────────────────┘

project-task.md Checkbox    →    Jira Status
─────────────────────────────────────────────
[ ] (space)                 →    "To Do"
[-] (dash)                  →    "In Progress"
[~] (tilde)                 →    "Testing"
[x] (x)                     →    "Done"

Example Workflow:
─────────────────

Initial State:
- [ ] WEALTHFID-150 - Implement health check endpoints
  (Jira status: "To Do")

Developer starts work:
- [-] WEALTHFID-150 - Implement health check endpoints
  (Jira status: "In Progress")

Code review:
- [~] WEALTHFID-150 - Implement health check endpoints
  (Jira status: "Testing")

Completed:
- [x] WEALTHFID-150 - Implement health check endpoints
  (Jira status: "Done")
```

## Workflow Triggers

```
┌─────────────────────────────────────────────────────────────────┐
│                    WORKFLOW TRIGGERS                             │
└─────────────────────────────────────────────────────────────────┘

Workflow: sync-project-tasks-to-jira.yml

Job 1: sync-jira-to-tasks
├─ Trigger 1: Schedule (every 15 minutes)
│  └─ Runs automatically at: 0, 15, 30, 45 minutes of each hour
│
├─ Trigger 2: Manual (workflow_dispatch)
│  └─ Run manually from GitHub Actions UI
│
└─ Trigger 3: Push to develop (when project-task.md changes)
   └─ Runs when any project-task.md file is modified

Job 2: sync-tasks-to-jira
├─ Dependency: Requires Job 1 to complete
│
└─ Trigger: Push to develop (when project-task.md changes)
   └─ Only runs on push events, not on schedule
   └─ Detects checkbox status changes
   └─ Updates Jira issue statuses

Job 3: validate-sync
├─ Dependency: Requires both Job 1 and Job 2 to complete
│
└─ Trigger: Always (after both sync jobs)
   └─ Validates project-task.md files exist
   └─ Validates file format is correct
```

## Error Handling

```
┌─────────────────────────────────────────────────────────────────┐
│                    ERROR HANDLING FLOW                           │
└─────────────────────────────────────────────────────────────────┘

Sync Jira to Tasks
├─ Error: Jira API authentication fails
│  └─ Action: Log error, skip sync, notify via GitHub Actions
│
├─ Error: Issue has no service label
│  └─ Action: Skip issue, log warning, continue with next issue
│
├─ Error: project-task.md file not found
│  └─ Action: Log warning, skip file, continue with next service
│
└─ Error: Git commit/push fails
   └─ Action: Log error, notify via GitHub Actions

Sync Tasks to Jira
├─ Error: Jira API authentication fails
│  └─ Action: Log error, skip sync, notify via GitHub Actions
│
├─ Error: Checkbox format is invalid
│  └─ Action: Skip change, log warning, continue with next change
│
├─ Error: Jira issue key not found
│  └─ Action: Log error, skip update, continue with next issue
│
└─ Error: Transition not available
   └─ Action: Log error, skip transition, continue with next issue

Validate Sync
├─ Error: project-task.md file missing
│  └─ Action: Log error, fail validation, notify via GitHub Actions
│
└─ Error: Invalid file format
   └─ Action: Log warning, continue validation
```

## Performance Characteristics

```
┌─────────────────────────────────────────────────────────────────┐
│                    PERFORMANCE METRICS                           │
└─────────────────────────────────────────────────────────────────┘

Sync Jira to Tasks
├─ Trigger Frequency: Every 15 minutes
├─ Average Duration: 30-60 seconds
├─ Max Issues Fetched: 100 per run
├─ Jira API Calls: 1 (search) + 1 per new issue
└─ Latency: Up to 15 minutes for new Jira issues to appear

Sync Tasks to Jira
├─ Trigger Frequency: On push to develop
├─ Average Duration: 10-30 seconds
├─ Max Changes Processed: Unlimited
├─ Jira API Calls: 1 (get transitions) + 1 (update) per change
└─ Latency: 1-2 minutes for status updates

Validate Sync
├─ Trigger Frequency: After each sync
├─ Average Duration: 5-10 seconds
├─ Files Validated: 2 (SecurityService, DataLoaderService)
└─ Latency: Immediate
```

## Security Considerations

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────┘

Authentication
├─ Jira API: Basic Auth (email + API token)
│  └─ Credentials stored in GitHub Secrets
│  └─ Never logged or exposed
│
└─ GitHub: GITHUB_TOKEN (automatic)
   └─ Scoped to repository
   └─ Expires after workflow completes

Authorization
├─ Jira: User must have permission to:
│  ├─ View issues
│  ├─ Transition issues
│  └─ Search issues
│
└─ GitHub: Workflow must have permission to:
   ├─ Read repository
   ├─ Write to repository
   └─ Create commits

Data Protection
├─ Jira API Token: Stored in GitHub Secrets
│  └─ Not visible in logs
│  └─ Not visible in workflow files
│
├─ Credentials: Never logged
│  └─ Masked in GitHub Actions logs
│
└─ Data: Transmitted over HTTPS
   └─ TLS 1.2+ encryption
```

## Scalability

```
┌─────────────────────────────────────────────────────────────────┐
│                    SCALABILITY CONSIDERATIONS                    │
└─────────────────────────────────────────────────────────────────┘

Current Capacity
├─ Services: 2 (SecurityService, DataLoaderService)
├─ Issues per sync: 100 (Jira API limit)
├─ Sync frequency: Every 15 minutes
└─ Concurrent workflows: 1 (sequential)

Scaling to More Services
├─ Add new service label to serviceRegistry in sync-jira-to-tasks.ps1
├─ Create new project-task.md file in service directory
├─ Add new service label to Jira issues
└─ Workflow automatically routes to new service

Scaling to More Issues
├─ Increase maxResults in sync-jira-to-tasks.ps1 (up to 100)
├─ Implement pagination for > 100 issues
├─ Consider increasing sync frequency if needed
└─ Monitor GitHub Actions usage

Scaling to More Frequent Syncs
├─ Change cron schedule in workflow (currently every 15 minutes)
├─ Monitor Jira API rate limits
├─ Monitor GitHub Actions usage
└─ Consider implementing incremental sync
```

---

**Last Updated**: January 2025  
**Maintained By**: WealthAndFiduciary DevOps Team
