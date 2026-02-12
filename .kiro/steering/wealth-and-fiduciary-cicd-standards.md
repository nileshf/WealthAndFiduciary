# BUSINESS UNIT CI/CD STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific CI/CD standards override these when conflicts exist

## 🎯 CI/CD PHILOSOPHY (MANDATORY)

All microservices MUST have automated CI/CD pipelines to enable:
- Automated testing on every commit
- Automated deployment to environments
- Integration with Jira for task tracking
- Integration with Confluence for documentation
- Quality gates before production deployment

## 🏗️ PIPELINE ARCHITECTURE (MANDATORY)

### GitHub Actions Workflow

```
Pull Request → CI Pipeline → Code Review → Merge → CD Pipeline → Deploy
     ↓              ↓             ↓           ↓          ↓          ↓
  Jira Task    Run Tests    Approve PR   Update Jira  Deploy   Update Confluence
```

## 📁 PROJECT STRUCTURE (MANDATORY)

```
[ServiceName]/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── cd-dev.yml
│   │   ├── cd-staging.yml
│   │   ├── cd-production.yml
│   │   └── pr-validation.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
├── scripts/
│   ├── deploy.ps1
│   ├── run-tests.ps1
│   └── update-jira.ps1
└── README.md
```

## 🔄 CI PIPELINE (MANDATORY)

### .github/workflows/ci.yml

```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

env:
  DOTNET_VERSION: '9.0.x'
  NODE_VERSION: '20.x'

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Full history for SonarCloud
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore --configuration Release
    
    - name: Run unit tests
      run: dotnet test --no-build --configuration Release --filter "Category=Unit" --logger "trx;LogFileName=unit-tests.trx"
    
    - name: Run integration tests
      run: dotnet test --no-build --configuration Release --filter "Category=Integration" --logger "trx;LogFileName=integration-tests.trx"
    
    - name: Run property-based tests
      run: dotnet test --no-build --configuration Release --filter "Category=Property" --logger "trx;LogFileName=property-tests.trx"
    
    - name: Code coverage
      run: |
        dotnet test --no-build --configuration Release \
          /p:CollectCoverage=true \
          /p:CoverletOutputFormat=opencover \
          /p:CoverletOutput=./coverage/
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/coverage.opencover.xml
        flags: unittests
        name: codecov-umbrella
    
    - name: SonarCloud Scan
      uses: SonarSource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    
    - name: Publish test results
      uses: dorny/test-reporter@v1
      if: always()
      with:
        name: Test Results
        path: '**/*.trx'
        reporter: dotnet-trx
    
    - name: Update Jira issue
      if: github.event_name == 'pull_request'
      uses: atlassian/gajira-transition@v3
      with:
        issue: ${{ github.event.pull_request.head.ref }}
        transition: "In Review"
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}

  security-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
    
    - name: Dependency check
      run: dotnet list package --vulnerable --include-transitive

  api-tests:
    runs-on: ubuntu-latest
    needs: build-and-test
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Start API
      run: |
        dotnet run --project [ServiceName].Api &
        sleep 30  # Wait for API to start
    
    - name: Install Newman
      run: npm install -g newman
    
    - name: Run Postman tests
      run: |
        newman run Postman/[ServiceName].postman_collection.json \
          -e Postman/Development.postman_environment.json \
          --reporters cli,junit \
          --reporter-junit-export postman-results.xml
    
    - name: Install Bruno CLI
      run: npm install -g @usebruno/cli
    
    - name: Run Bruno tests
      run: bru run Bruno/[ServiceName] --env Development --output bruno-results.json
    
    - name: Publish API test results
      uses: dorny/test-reporter@v1
      if: always()
      with:
        name: API Test Results
        path: 'postman-results.xml'
        reporter: java-junit
```

## 🚀 CD PIPELINE (MANDATORY)

### .github/workflows/cd-dev.yml

```yaml
name: CD - Development

on:
  push:
    branches: [ develop ]
  workflow_dispatch:

env:
  DOTNET_VERSION: '9.0.x'
  AZURE_WEBAPP_NAME: '[ServiceName]-dev'
  ENVIRONMENT: 'Development'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: development
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Build
      run: dotnet build --configuration Release
    
    - name: Publish
      run: dotnet publish --configuration Release --output ./publish
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_DEV }}
        package: ./publish
    
    - name: Run smoke tests
      run: |
        sleep 30  # Wait for deployment
        curl -f https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net/health || exit 1
    
    - name: Update Jira deployment
      uses: atlassian/gajira-cli@v3
      with:
        command: 'deployment create'
        environment: 'development'
        state: 'successful'
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
    
    - name: Notify team
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        text: 'Deployment to Development completed'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
      if: always()
```

### .github/workflows/cd-staging.yml

```yaml
name: CD - Staging

on:
  push:
    branches: [ main ]
  workflow_dispatch:

env:
  DOTNET_VERSION: '9.0.x'
  AZURE_WEBAPP_NAME: '[ServiceName]-staging'
  ENVIRONMENT: 'Staging'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Build
      run: dotnet build --configuration Release
    
    - name: Publish
      run: dotnet publish --configuration Release --output ./publish
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_STAGING }}
        package: ./publish
    
    - name: Run smoke tests
      run: |
        sleep 30
        curl -f https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net/health || exit 1
    
    - name: Run E2E tests
      run: |
        newman run Postman/[ServiceName].postman_collection.json \
          -e Postman/Staging.postman_environment.json
    
    - name: Update Jira deployment
      uses: atlassian/gajira-cli@v3
      with:
        command: 'deployment create'
        environment: 'staging'
        state: 'successful'
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
    
    - name: Create Confluence deployment page
      uses: atlassian/confluence-upload-action@v1
      with:
        url: ${{ secrets.CONFLUENCE_URL }}
        username: ${{ secrets.CONFLUENCE_USERNAME }}
        password: ${{ secrets.CONFLUENCE_API_TOKEN }}
        space: 'DEPLOYMENTS'
        title: '[ServiceName] Staging Deployment - ${{ github.run_number }}'
        file: './deployment-notes.md'
```

### .github/workflows/cd-production.yml

```yaml
name: CD - Production

on:
  release:
    types: [published]
  workflow_dispatch:

env:
  DOTNET_VERSION: '9.0.x'
  AZURE_WEBAPP_NAME: '[ServiceName]-prod'
  ENVIRONMENT: 'Production'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Build
      run: dotnet build --configuration Release
    
    - name: Publish
      run: dotnet publish --configuration Release --output ./publish
    
    - name: Create backup
      run: |
        # Backup current production deployment
        az webapp deployment slot create \
          --name ${{ env.AZURE_WEBAPP_NAME }} \
          --resource-group [ResourceGroup] \
          --slot backup-$(date +%Y%m%d-%H%M%S)
    
    - name: Deploy to Azure Web App (Blue-Green)
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        slot-name: 'staging'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE_PROD }}
        package: ./publish
    
    - name: Run smoke tests on staging slot
      run: |
        sleep 30
        curl -f https://${{ env.AZURE_WEBAPP_NAME }}-staging.azurewebsites.net/health || exit 1
    
    - name: Swap slots (Blue-Green deployment)
      run: |
        az webapp deployment slot swap \
          --name ${{ env.AZURE_WEBAPP_NAME }} \
          --resource-group [ResourceGroup] \
          --slot staging \
          --target-slot production
    
    - name: Verify production deployment
      run: |
        sleep 30
        curl -f https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net/health || exit 1
    
    - name: Update Jira deployment
      uses: atlassian/gajira-cli@v3
      with:
        command: 'deployment create'
        environment: 'production'
        state: 'successful'
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
    
    - name: Create Confluence release notes
      uses: atlassian/confluence-upload-action@v1
      with:
        url: ${{ secrets.CONFLUENCE_URL }}
        username: ${{ secrets.CONFLUENCE_USERNAME }}
        password: ${{ secrets.CONFLUENCE_API_TOKEN }}
        space: 'RELEASES'
        title: '[ServiceName] Production Release - ${{ github.event.release.tag_name }}'
        file: './RELEASE_NOTES.md'
    
    - name: Rollback on failure
      if: failure()
      run: |
        az webapp deployment slot swap \
          --name ${{ env.AZURE_WEBAPP_NAME }} \
          --resource-group [ResourceGroup] \
          --slot production \
          --target-slot staging
```

## 📋 PR VALIDATION (MANDATORY)

### .github/workflows/pr-validation.yml

```yaml
name: PR Validation

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  validate-pr:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Validate PR title
      uses: amannn/action-semantic-pull-request@v5
      with:
        types: |
          feat
          fix
          docs
          style
          refactor
          perf
          test
          chore
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract Jira issue key
      id: jira
      run: |
        ISSUE_KEY=$(echo "${{ github.event.pull_request.head.ref }}" | grep -oP '[A-Z]+-\d+' || echo "")
        echo "issue_key=$ISSUE_KEY" >> $GITHUB_OUTPUT
    
    - name: Validate Jira issue exists
      if: steps.jira.outputs.issue_key != ''
      uses: atlassian/gajira-find-issue-key@v3
      with:
        string: ${{ steps.jira.outputs.issue_key }}
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
    
    - name: Transition Jira issue to "In Review"
      if: steps.jira.outputs.issue_key != ''
      uses: atlassian/gajira-transition@v3
      with:
        issue: ${{ steps.jira.outputs.issue_key }}
        transition: "In Review"
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
    
    - name: Add Jira link to PR
      if: steps.jira.outputs.issue_key != ''
      uses: actions/github-script@v7
      with:
        script: |
          const issueKey = '${{ steps.jira.outputs.issue_key }}';
          const jiraUrl = '${{ secrets.JIRA_BASE_URL }}';
          const body = `🔗 **Jira Issue**: [${issueKey}](${jiraUrl}/browse/${issueKey})`;
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: body
          });
```

## 🐛 BUG FIX WORKFLOW (MANDATORY)

### Bug Fix Process

1. **Create Jira Bug Ticket**
   - Type: Bug
   - Priority: Based on severity
   - Description: Steps to reproduce, expected vs actual behavior
   - Attachments: Screenshots, logs

2. **Create Git Branch**
   - Format: `bugfix/[JIRA-KEY]-short-description`
   - Example: `bugfix/PROJ-123-fix-login-error`

3. **Fix Bug and Create PR**
   - PR title: `fix: [JIRA-KEY] Short description`
   - PR description: Link to Jira ticket, describe fix
   - Add tests to prevent regression

4. **Automated Actions**
   - CI pipeline runs tests
   - Jira ticket transitions to "In Review"
   - Code coverage checked

5. **Code Review and Merge**
   - Reviewer approves PR
   - Jira ticket transitions to "Done"
   - Bug fix documentation uploaded to Confluence

### Bug Fix Documentation Template

**BUGFIX_TEMPLATE.md:**
```markdown
# Bug Fix: [JIRA-KEY] - [Short Description]

## Bug Description

**Jira Ticket**: [JIRA-KEY](https://jira.example.com/browse/[JIRA-KEY])

**Severity**: [Critical/High/Medium/Low]

**Reported By**: [Name]

**Reported Date**: [Date]

## Problem

Describe the bug in detail:
- What was happening?
- Steps to reproduce
- Expected behavior
- Actual behavior

## Root Cause

Explain what caused the bug:
- Which component/module?
- What was the underlying issue?
- Why did it happen?

## Solution

Describe the fix:
- What changes were made?
- Why does this fix the issue?
- Are there any side effects?

## Testing

How was the fix tested?
- Unit tests added/modified
- Integration tests added/modified
- Manual testing performed
- Regression testing performed

## Prevention

How can we prevent this in the future?
- Additional tests
- Code review checklist updates
- Documentation updates
- Process improvements

## Related Changes

- PR: [Link to PR]
- Commits: [List of commit SHAs]
- Files Changed: [List of files]

## Deployment Notes

Any special considerations for deployment?
- Database migrations required?
- Configuration changes required?
- Rollback plan?
```

### Automated Bug Fix Documentation Upload

**.github/workflows/upload-bugfix-docs.yml:**
```yaml
name: Upload Bug Fix Documentation

on:
  pull_request:
    types: [closed]
    branches: [ main, develop ]

jobs:
  upload-docs:
    if: github.event.pull_request.merged == true && startsWith(github.event.pull_request.head.ref, 'bugfix/')
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Extract Jira issue key
      id: jira
      run: |
        ISSUE_KEY=$(echo "${{ github.event.pull_request.head.ref }}" | grep -oP '[A-Z]+-\d+' || echo "")
        echo "issue_key=$ISSUE_KEY" >> $GITHUB_OUTPUT
    
    - name: Generate bug fix documentation
      run: |
        # Create bug fix documentation from template
        sed -e "s/\[JIRA-KEY\]/${{ steps.jira.outputs.issue_key }}/g" \
            -e "s/\[Short Description\]/${{ github.event.pull_request.title }}/g" \
            BUGFIX_TEMPLATE.md > bugfix-${{ steps.jira.outputs.issue_key }}.md
        
        # Add PR details
        echo "" >> bugfix-${{ steps.jira.outputs.issue_key }}.md
        echo "## Pull Request" >> bugfix-${{ steps.jira.outputs.issue_key }}.md
        echo "- **PR**: #${{ github.event.pull_request.number }}" >> bugfix-${{ steps.jira.outputs.issue_key }}.md
        echo "- **Author**: ${{ github.event.pull_request.user.login }}" >> bugfix-${{ steps.jira.outputs.issue_key }}.md
        echo "- **Merged**: ${{ github.event.pull_request.merged_at }}" >> bugfix-${{ steps.jira.outputs.issue_key }}.md
    
    - name: Upload to Confluence
      uses: atlassian/confluence-upload-action@v1
      with:
        url: ${{ secrets.CONFLUENCE_URL }}
        username: ${{ secrets.CONFLUENCE_USERNAME }}
        password: ${{ secrets.CONFLUENCE_API_TOKEN }}
        space: 'BUGFIXES'
        title: 'Bug Fix: ${{ steps.jira.outputs.issue_key }} - ${{ github.event.pull_request.title }}'
        file: './bugfix-${{ steps.jira.outputs.issue_key }}.md'
        parent: 'Bug Fixes'
    
    - name: Add Confluence link to Jira
      uses: atlassian/gajira-comment@v3
      with:
        issue: ${{ steps.jira.outputs.issue_key }}
        comment: |
          Bug fix documentation uploaded to Confluence:
          ${{ secrets.CONFLUENCE_URL }}/display/BUGFIXES/Bug+Fix+${{ steps.jira.outputs.issue_key }}
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
    
    - name: Transition Jira issue to Done
      uses: atlassian/gajira-transition@v3
      with:
        issue: ${{ steps.jira.outputs.issue_key }}
        transition: "Done"
      env:
        JIRA_BASE_URL: ${{ secrets.JIRA_BASE_URL }}
        JIRA_USER_EMAIL: ${{ secrets.JIRA_USER_EMAIL }}
        JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
```

## 📚 PULL REQUEST TEMPLATE (MANDATORY)

### .github/PULL_REQUEST_TEMPLATE.md

```markdown
## Description

<!-- Provide a brief description of the changes -->

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Test coverage improvement

## Jira Ticket

<!-- Link to Jira ticket -->
**Jira**: [PROJ-XXX](https://jira.example.com/browse/PROJ-XXX)

## Changes Made

<!-- List the specific changes made -->
- Change 1
- Change 2
- Change 3

## Testing

<!-- Describe the tests you ran -->
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Property-based tests pass
- [ ] Manual testing performed
- [ ] API tests pass (Postman/Bruno)

## Code Coverage

<!-- Paste code coverage results -->
- Domain: XX%
- Application: XX%
- Infrastructure: XX%
- API: XX%

## Screenshots (if applicable)

<!-- Add screenshots for UI changes -->

## Checklist

- [ ] My code follows the coding standards
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Deployment Notes

<!-- Any special considerations for deployment? -->
- [ ] Database migrations required
- [ ] Configuration changes required
- [ ] Breaking API changes
- [ ] Requires coordination with other services

## Rollback Plan

<!-- How to rollback if deployment fails -->
```

## 🎓 BEST PRACTICES

### Do's
- ✅ Run CI pipeline on every commit
- ✅ Require passing tests before merge
- ✅ Use blue-green deployment for production
- ✅ Automate Jira ticket transitions
- ✅ Upload bug fix documentation to Confluence
- ✅ Use semantic versioning for releases
- ✅ Maintain deployment rollback capability

### Don'ts
- ❌ Don't skip tests in CI pipeline
- ❌ Don't deploy without code review
- ❌ Don't merge PRs with failing tests
- ❌ Don't deploy to production without staging validation
- ❌ Don't forget to update Jira tickets
- ❌ Don't skip bug fix documentation

---

**Note**: Service-specific CI/CD standards can extend these standards but should not contradict them.

ALWAYS implement CI/CD pipelines for ALL microservices.
