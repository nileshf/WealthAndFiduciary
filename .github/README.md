# GitHub Workflows

This directory contains GitHub Actions workflows for the Simple Compliance Demo project.

## 📁 Workflows

### 1. PR Validation (`pr-validation.yml`)

**Triggers**: When a pull request is opened, synchronized, or reopened

**Purpose**: Validates pull requests and integrates with Jira

**Steps**:
1. ✅ Validates PR title follows semantic commit format (feat, fix, docs, etc.)
2. ✅ Extracts Jira issue key from branch name (e.g., `DEMO-101`)
3. ✅ Validates Jira issue exists
4. ✅ Transitions Jira issue to "In Review" status
5. ✅ Adds Jira link to PR comments

**Required Secrets**:
- `JIRA_BASE_URL` - Your Jira instance URL (e.g., `https://your-domain.atlassian.net`)
- `JIRA_USER_EMAIL` - Your Jira user email
- `JIRA_API_TOKEN` - Your Jira API token

**Example Branch Names**:
- `feature/DEMO-101-add-email-validation` ✅
- `bugfix/DEMO-102-fix-overflow` ✅
- `hotfix/DEMO-103-production-issue` ✅
- `feature/add-validation` ❌ (no Jira key)

---

### 2. CI Pipeline (`ci.yml`)

**Triggers**: 
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Purpose**: Runs automated tests and checks for regressions

**Jobs**:

#### Build and Test
1. ✅ Checkout code
2. ✅ Setup .NET 9.0
3. ✅ Restore dependencies
4. ✅ Lint code (dotnet format)
5. ✅ Build solution
6. ✅ Run unit tests
7. 🔍 **Check for regression tests** (if tests fail)
8. 💬 **Comment on PR with regression details** (if regression detected)
9. ✅ Calculate code coverage
10. ✅ Upload coverage to Codecov
11. ✅ Publish test results

#### Security Scan
1. ✅ Run Trivy vulnerability scanner
2. ✅ Upload results to GitHub Security
3. ✅ Check for vulnerable dependencies

**Regression Detection**:
- If a test named `RequiresApproval_WithExtremelyHighValue_HandlesCorrectly` fails, the workflow:
  - Detects it's a regression test for incident `DEMO-103`
  - Comments on the PR with:
    - Link to original Jira issue
    - Link to post-mortem document
    - Explanation of what happened before
    - How to fix the regression
  - Prevents PR from being merged

**Required Secrets**:
- `JIRA_BASE_URL` - For linking to Jira issues in regression comments
- `CONFLUENCE_URL` - For linking to post-mortem documents
- `CODECOV_TOKEN` - For uploading code coverage (optional)

---

### 3. Post-Mortem Upload (`post-mortem-upload.yml`)

**Triggers**: When a pull request is merged to `main` from a `hotfix/` branch

**Purpose**: Automatically creates and uploads post-mortem documents to Confluence

**Steps**:
1. ✅ Extracts Jira issue key from hotfix branch name
2. ✅ Fetches Jira issue details (summary, description, priority)
3. ✅ Generates post-mortem document from template
4. ✅ Uploads post-mortem to Confluence (space: `OPS`, parent: `Post-Mortems`)
5. ✅ Adds Confluence link to Jira issue comments
6. ✅ Transitions Jira issue to "Done" status

**Required Secrets**:
- `JIRA_BASE_URL` - Your Jira instance URL
- `JIRA_USER_EMAIL` - Your Jira user email
- `JIRA_API_TOKEN` - Your Jira API token
- `CONFLUENCE_URL` - Your Confluence instance URL (e.g., `https://your-domain.atlassian.net/wiki`)
- `CONFLUENCE_USERNAME` - Your Confluence username
- `CONFLUENCE_API_TOKEN` - Your Confluence API token

**Example Hotfix Branch**:
- `hotfix/DEMO-103-decimal-overflow-production` ✅

**Post-Mortem Template**:
The workflow generates a comprehensive post-mortem document with sections for:
- Executive Summary
- Timeline
- Root Cause Analysis
- Resolution
- Impact Assessment
- Lessons Learned
- Action Items
- Prevention Measures
- Related Documents
- Sign-Off

---

## 🔐 Setting Up Secrets

### GitHub Repository Secrets

Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

Add the following secrets:

#### Jira Integration
```
JIRA_BASE_URL=https://your-domain.atlassian.net
JIRA_USER_EMAIL=your.email@example.com
JIRA_API_TOKEN=your-jira-api-token
```

**How to get Jira API token**:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name (e.g., "GitHub Actions")
4. Copy the token

#### Confluence Integration
```
CONFLUENCE_URL=https://your-domain.atlassian.net/wiki
CONFLUENCE_USERNAME=your.email@example.com
CONFLUENCE_API_TOKEN=your-confluence-api-token
```

**How to get Confluence API token**:
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name (e.g., "GitHub Actions Confluence")
4. Copy the token

#### Code Coverage (Optional)
```
CODECOV_TOKEN=your-codecov-token
```

**How to get Codecov token**:
1. Go to https://codecov.io/
2. Sign in with GitHub
3. Add your repository
4. Copy the upload token

---

## 🧪 Testing Workflows Locally

### Using Act (GitHub Actions Local Runner)

```bash
# Install act
# Windows: choco install act-cli
# Mac: brew install act
# Linux: See https://github.com/nektos/act#installation

# Run PR validation workflow
act pull_request -W .github/workflows/pr-validation.yml

# Run CI pipeline
act push -W .github/workflows/ci.yml

# Run with secrets
act -s JIRA_BASE_URL=https://your-domain.atlassian.net \
    -s JIRA_USER_EMAIL=your.email@example.com \
    -s JIRA_API_TOKEN=your-token
```

### Manual Testing

```bash
# Test PR validation locally
gh pr create --title "feat: Test PR" --body "Test"

# Check workflow status
gh run list --workflow=pr-validation.yml

# View workflow logs
gh run view --log
```

---

## 📊 Workflow Status Badges

Add these badges to your README.md:

```markdown
![PR Validation](https://github.com/your-org/simple-compliance-demo/actions/workflows/pr-validation.yml/badge.svg)
![CI Pipeline](https://github.com/your-org/simple-compliance-demo/actions/workflows/ci.yml/badge.svg)
![Post-Mortem Upload](https://github.com/your-org/simple-compliance-demo/actions/workflows/post-mortem-upload.yml/badge.svg)
```

---

## 🔧 Customization

### Changing Jira Transition IDs

Jira transition IDs vary by project. To find your transition IDs:

```bash
# Get available transitions for an issue
curl -u "$JIRA_USER_EMAIL:$JIRA_API_TOKEN" \
  "$JIRA_BASE_URL/rest/api/3/issue/DEMO-101/transitions"
```

Update the transition IDs in the workflows:
- `pr-validation.yml`: Line 35 (transition to "In Review")
- `post-mortem-upload.yml`: Line 145 (transition to "Done")

### Changing Confluence Space

Update the `space` parameter in `post-mortem-upload.yml`:

```yaml
- name: Upload to Confluence
  with:
    space: 'YOUR_SPACE_KEY'  # Change this
    parent: 'YOUR_PARENT_PAGE'  # Change this
```

### Adding More Regression Detection

Update the "Check for regression tests" step in `ci.yml`:

```yaml
- name: Check for regression tests
  run: |
    # Check for multiple regression patterns
    if grep -q "RegressionTest" **/test-results.trx; then
      echo "regression_detected=true" >> $GITHUB_OUTPUT
      
      # Extract which regression test failed
      FAILED_TEST=$(grep -oP 'testName=".*RegressionTest.*"' **/test-results.trx | head -1)
      echo "regression_test=$FAILED_TEST" >> $GITHUB_OUTPUT
      
      # Map test to incident
      case "$FAILED_TEST" in
        *"ExtremelyHighValue"*)
          echo "related_issue=DEMO-103" >> $GITHUB_OUTPUT
          ;;
        *"AnotherRegression"*)
          echo "related_issue=DEMO-XXX" >> $GITHUB_OUTPUT
          ;;
      esac
    fi
```

---

## 📚 Resources

- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **Jira REST API**: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- **Confluence REST API**: https://developer.atlassian.com/cloud/confluence/rest/v1/
- **Act (Local Testing)**: https://github.com/nektos/act

---

## 🆘 Troubleshooting

### Workflow doesn't run

**Check**:
1. Workflow file is in `.github/workflows/` directory
2. Workflow file has `.yml` or `.yaml` extension
3. GitHub Actions are enabled for the repository
4. Branch protection rules don't block workflows

### Jira integration fails

**Check**:
1. Secrets are set correctly
2. Jira API token is valid
3. User has permission to access Jira API
4. Jira issue key format is correct (e.g., `DEMO-101`)

### Confluence upload fails

**Check**:
1. Confluence space exists
2. User has permission to create pages in the space
3. Parent page exists (or remove `parent` parameter)
4. Confluence API token is valid

### Regression detection doesn't work

**Check**:
1. Test results file exists (`test-results.trx`)
2. Test name matches the pattern in the workflow
3. Test actually failed (not skipped)
4. Grep pattern is correct

---

**For more details, see the [Hands-On Workflow Testing Guide](../HANDS-ON-WORKFLOW-TESTING.md)**
