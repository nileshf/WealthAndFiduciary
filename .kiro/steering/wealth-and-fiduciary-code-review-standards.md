# BUSINESS UNIT CODE REVIEW STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific code review rules override these when conflicts exist

## 🎯 CODE REVIEW PHILOSOPHY (MANDATORY)

Code review is about:
- **Quality**: Maintaining high code quality standards
- **Knowledge Sharing**: Learning from each other
- **Consistency**: Ensuring consistent patterns across services
- **Security**: Catching security vulnerabilities early
- **Mentorship**: Growing team skills

Code review is NOT about:
- Finding fault or blame
- Nitpicking minor style issues (let linters handle it)
- Blocking progress unnecessarily
- Showing superiority

## 📋 REVIEW PROCESS (MANDATORY)

### 1. Automated Checks (Before Human Review)

All services MUST have automated checks that run before human review:

**Required Checks**:
- ✅ **Linting**: Code formatting is correct
- ✅ **Build**: Solution builds without errors or warnings
- ✅ **Unit Tests**: All unit tests pass
- ✅ **Integration Tests**: All integration tests pass (if applicable)
- ✅ **Code Coverage**: Meets minimum threshold (80% Domain/Application, 70% Infrastructure/API)
- ✅ **Security Scan**: No vulnerable dependencies
- ✅ **Architecture Validation**: Clean Architecture rules followed
- ✅ **Documentation**: All public types have XML docs

**Rule**: If any automated check fails, request fixes before proceeding with manual review.

### 2. Initial Review (5-10 minutes)

Quick scan to understand the change:

**Check**:
- [ ] PR description is clear and complete
- [ ] Related issues are linked (Jira, GitHub)
- [ ] PR is focused on one thing
- [ ] PR is reasonable size (< 500 lines preferred)
- [ ] Author completed the PR checklist

**Action**: If PR is too large or unfocused, request split into smaller PRs.

### 3. Deep Review (20-40 minutes)

Thorough examination of the code:

**Review Areas** (in order of importance):
1. **Architecture** - Follows Clean Architecture and SOLID principles
2. **Security** - No vulnerabilities, PII protected, authentication/authorization correct
3. **Testing** - Comprehensive tests, good coverage, tests what they claim
4. **Code Quality** - Readable, maintainable, no duplication
5. **Performance** - No obvious performance issues
6. **Documentation** - Clear and complete

### 4. Provide Feedback (10-15 minutes)

**Feedback Guidelines**:

**DO**:
- ✅ Be specific and constructive
- ✅ Explain the "why" behind your comments
- ✅ Suggest alternatives or improvements
- ✅ Acknowledge good code
- ✅ Ask questions if something is unclear
- ✅ Link to documentation or examples

**DON'T**:
- ❌ Be vague ("This doesn't look right")
- ❌ Be condescending or rude
- ❌ Nitpick minor style issues (let linter handle it)
- ❌ Demand changes without explanation
- ❌ Approve without actually reviewing

**Feedback Categories** (use these labels):
- 🐛 **Bug**: Code that will cause errors or incorrect behavior
- ⚠️ **Security**: Security vulnerability or concern
- 🔧 **Refactor**: Code that works but could be improved
- 💡 **Suggestion**: Optional improvement or alternative approach
- ❓ **Question**: Need clarification or explanation
- ✅ **Praise**: Acknowledge good code or approach
- 📚 **Documentation**: Missing or incorrect documentation
- 🧪 **Testing**: Test coverage or quality issue

### 5. Approval Decision

**Approve** ✅ when:
- All automated checks pass
- No critical issues found
- Minor issues have been addressed or documented
- Code meets quality standards
- Tests are comprehensive
- Documentation is complete

**Request Changes** 🔄 when:
- Critical bugs found
- Security vulnerabilities present
- Architecture violations
- Insufficient test coverage
- Breaking changes not documented
- Major code quality issues

**Comment Only** 💬 when:
- Minor suggestions for improvement
- Questions for clarification
- Non-critical issues
- Learning opportunities

## ✅ REVIEW CHECKLIST (MANDATORY)

Use this checklist for every review:

### Pre-Review
- [ ] All automated checks passed
- [ ] PR description is clear
- [ ] Related issues are linked
- [ ] PR is reasonable size

### Architecture
- [ ] Follows Clean Architecture (Domain → Application → Infrastructure → API)
- [ ] SOLID principles applied
- [ ] Proper separation of concerns
- [ ] No architectural violations
- [ ] Dependencies point inward only

### Code Quality
- [ ] Code is readable and maintainable
- [ ] Methods are focused and small (< 50 lines preferred)
- [ ] No code duplication
- [ ] Proper error handling
- [ ] Appropriate logging (no PII logged)
- [ ] No magic numbers or strings
- [ ] Meaningful variable/method names

### Security
- [ ] PII encrypted at rest (if applicable)
- [ ] Passwords hashed (never plain text)
- [ ] Input validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (proper encoding)
- [ ] Authentication/authorization correct
- [ ] Multi-tenant isolation maintained (if applicable)
- [ ] No sensitive data in logs

### Testing
- [ ] Unit tests comprehensive (80% coverage minimum for Domain/Application)
- [ ] Integration tests present (if applicable)
- [ ] Property-based tests for universal properties (if applicable)
- [ ] Edge cases covered
- [ ] Error scenarios tested
- [ ] Tests are isolated (no shared state)
- [ ] Test names follow convention: `MethodName_Scenario_ExpectedBehavior`

### Performance
- [ ] No N+1 query problems
- [ ] Async/await used properly for I/O
- [ ] Efficient database queries
- [ ] Appropriate use of caching (if applicable)
- [ ] No unnecessary loops or iterations

### Documentation
- [ ] XML docs on all public members
- [ ] README updated (if needed)
- [ ] API documentation updated (if needed)
- [ ] Breaking changes documented
- [ ] Deployment notes provided (if needed)

### Final
- [ ] All conversations resolved
- [ ] Feedback addressed
- [ ] Ready to merge

## 🚫 COMMON ANTI-PATTERNS TO REJECT

### Architecture Violations
- ❌ Business logic in controllers
- ❌ Infrastructure code in Domain layer
- ❌ Application layer referencing Infrastructure
- ❌ Circular dependencies

### Security Issues
- ❌ Plain text passwords
- ❌ Unencrypted PII
- ❌ String concatenation in SQL queries
- ❌ Missing authentication/authorization
- ❌ Cross-tenant data access
- ❌ Logging passwords, tokens, or PII

### Code Quality Issues
- ❌ Magic numbers or strings
- ❌ Long methods (> 100 lines)
- ❌ Deeply nested code (> 3 levels)
- ❌ Copy-pasted code
- ❌ Commented-out code
- ❌ TODO/FIXME without issue tracking

### Testing Issues
- ❌ No tests for new code
- ❌ Tests that always pass (testing nothing)
- ❌ Tests with shared state
- ❌ Tests that depend on execution order
- ❌ Tests that mock everything

### Performance Issues
- ❌ Queries in loops (N+1 problem)
- ❌ Loading entire tables into memory
- ❌ Synchronous I/O operations
- ❌ Missing database indexes

## ⏱️ TIME EXPECTATIONS (MANDATORY)

### For Developers
- **Pre-commit checks**: 5-10 minutes
- **Addressing review feedback**: 30-60 minutes
- **Total PR time**: 2-4 hours (including implementation)

### For Reviewers
- **Small PR (< 100 lines)**: 15-20 minutes
- **Medium PR (100-300 lines)**: 30-45 minutes
- **Large PR (300-500 lines)**: 45-60 minutes
- **Very Large PR (> 500 lines)**: Request split into smaller PRs

**Rule**: Reviews should be completed within 24 hours of request.

## 📏 PR SIZE GUIDELINES (MANDATORY)

**Preferred Sizes**:
- **Small**: < 100 lines (ideal for quick review)
- **Medium**: 100-300 lines (acceptable)
- **Large**: 300-500 lines (requires justification)
- **Too Large**: > 500 lines (should be split)

**Exceptions**:
- Generated code (migrations, DTOs)
- Large refactoring (must be discussed first)
- New feature with comprehensive tests

**Rule**: If PR is > 500 lines, reviewer can request split into smaller PRs.

## 🔒 SECURITY REVIEW (MANDATORY)

Every PR MUST be reviewed for security:

**Check**:
- [ ] No hardcoded secrets (passwords, API keys, tokens)
- [ ] PII is encrypted (not stored in plain text)
- [ ] Passwords are hashed (PBKDF2, bcrypt, Argon2)
- [ ] Input validation on all user inputs
- [ ] SQL injection prevention (parameterized queries, ORM)
- [ ] XSS prevention (proper encoding, sanitization)
- [ ] Authentication on protected endpoints
- [ ] Authorization checks (user can access this resource?)
- [ ] Multi-tenant isolation (tenant A cannot access tenant B data)
- [ ] No sensitive data in logs (passwords, tokens, PII, keys)
- [ ] HTTPS enforced (no HTTP)
- [ ] CORS configured correctly
- [ ] Rate limiting on public endpoints

**Rule**: Any security issue MUST block merge until fixed.

## 🏗️ ARCHITECTURE REVIEW (MANDATORY)

Every PR MUST follow Clean Architecture:

**Check**:
- [ ] Domain layer has no external dependencies (except logging)
- [ ] Application layer depends only on Domain
- [ ] Infrastructure layer implements Application interfaces
- [ ] API layer delegates to Application (no business logic)
- [ ] Dependencies point inward (Domain ← Application ← Infrastructure ← API)
- [ ] No circular dependencies
- [ ] Proper use of CQRS (Commands for writes, Queries for reads)
- [ ] Repository pattern used correctly
- [ ] Dependency injection used properly

**Rule**: Architecture violations MUST be fixed before merge.

## 🧪 TESTING REVIEW (MANDATORY)

Every PR MUST include appropriate tests:

**Required Tests**:
- **Unit Tests**: For all business logic (80% coverage minimum for Domain/Application)
- **Integration Tests**: For data access and API endpoints (70% coverage minimum for Infrastructure/API)
- **Property-Based Tests**: For universal properties (when applicable)

**Test Quality Checks**:
- [ ] Tests actually test what they claim to test
- [ ] Tests are isolated (no shared state)
- [ ] Tests don't depend on execution order
- [ ] Test names are descriptive: `MethodName_Scenario_ExpectedBehavior`
- [ ] Edge cases are tested
- [ ] Error scenarios are tested
- [ ] Tests are fast (unit tests < 100ms, integration tests < 1s)

**Rule**: PRs without tests MUST be rejected (except documentation-only changes).

## 📊 METRICS TO TRACK

Business units should track these metrics:

**Quality Metrics**:
- PR size (average lines changed)
- Review time (time from PR creation to approval)
- Defect rate (bugs found in review vs production)
- Coverage trend (code coverage over time)
- Review thoroughness (comments per PR)

**Process Metrics**:
- Time to first review (should be < 24 hours)
- Time to merge (from approval to merge)
- Number of review cycles (should be < 3)
- PR rejection rate (should be < 10%)

**Team Metrics**:
- Review participation (all team members reviewing)
- Knowledge sharing (cross-team reviews)
- Mentorship (senior reviewing junior code)

## 🎓 BEST PRACTICES

### For Developers

**Before Creating PR**:
1. Run all checks locally
2. Ensure all tests pass
3. Review your own code first
4. Write clear PR description
5. Link to related issues

**During Review**:
1. Respond to feedback promptly (within 24 hours)
2. Ask questions if feedback is unclear
3. Don't take feedback personally
4. Learn from the review
5. Thank the reviewer

**After Approval**:
1. Ensure all conversations resolved
2. Ensure all checks still pass
3. Merge promptly
4. Delete the branch
5. Update related issues

### For Reviewers

**Before Reviewing**:
1. Ensure automated checks passed
2. Allocate sufficient time
3. Understand the context
4. Review with fresh mind

**During Review**:
1. Be thorough but not pedantic
2. Focus on important issues
3. Explain the "why"
4. Acknowledge good code
5. Be constructive and kind

**After Review**:
1. Follow up on conversations
2. Re-review if significant changes
3. Approve when ready
4. Learn from the code

## 🚨 ESCALATION PROCESS

### When to Escalate

Escalate to tech lead when:
- Fundamental architecture disagreement
- Security concern not being addressed
- Repeated violations of standards
- PR blocked for > 3 days
- Team conflict over review feedback

### How to Escalate

1. Document the issue clearly
2. Provide context and examples
3. Suggest potential solutions
4. Tag tech lead in PR comments
5. Schedule meeting if needed

## 📚 RESOURCES

- **Coding Standards**: `.kiro/steering/wealth-and-fiduciary-coding-standards.md`
- **Architecture Guide**: `.kiro/steering/wealth-and-fiduciary-architecture.md`
- **Testing Standards**: `.kiro/steering/wealth-and-fiduciary-testing-standards.md`
- **Service-Specific Rules**: `[Service]/.kiro/steering/`

---

**Note**: Service-specific code review rules can extend these standards with additional checks but should not contradict these baseline requirements. When conflicts arise, service-specific rules take precedence for that service only.

**Remember**: Code review is about maintaining quality and sharing knowledge, not finding fault. Be thorough, be constructive, and be kind.

ALWAYS follow these code review standards when reviewing ANY pull request in ANY microservice.
