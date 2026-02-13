# Deploy Workflow - Fixed

## Issue
The `.github/workflows/deploy.yml` workflow had a syntax error: duplicate `if` condition on the "Send Slack notification" step.

**Error Message:**
```
Invalid workflow file: .github/workflows/deploy.yml#L1(Line: 156, Col: 7): 'if' is already defined
```

## Root Cause
The "Send Slack notification" step had `if` defined twice:
- Line 151: `if: secrets.SLACK_WEBHOOK_URL != ''`
- Line 156: `if: always()`

This is invalid YAML syntax - a step can only have one `if` condition.

## Solution
Combined both conditions into a single `if` statement using logical AND (`&&`):

```yaml
if: always() && secrets.SLACK_WEBHOOK_URL != ''
```

This ensures:
- ✅ The step always runs (even if previous steps fail)
- ✅ The step only sends notification if the webhook URL is configured
- ✅ Valid YAML syntax with single `if` condition

## Changes Made

**Before:**
```yaml
- name: Send Slack notification
  if: secrets.SLACK_WEBHOOK_URL != ''
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    # ... payload ...
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
  if: always()  # ❌ DUPLICATE - INVALID
```

**After:**
```yaml
- name: Send Slack notification
  if: always() && secrets.SLACK_WEBHOOK_URL != ''
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    # ... payload ...
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## Status
✅ **FIXED** - The workflow is now valid and ready to use.

## Files Modified
- ✅ `.github/workflows/deploy.yml` - Removed duplicate `if` condition

## Next Steps
1. The workflow will now validate successfully
2. Slack notifications will be sent after production deployment (if webhook is configured)
3. Notifications will be sent even if deployment fails (due to `always()` condition)
