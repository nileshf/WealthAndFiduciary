# Documentation Reference

> **Purpose**: Guide Kiro to human-readable documentation
> **Type**: Reference file (not a steering rule)

## 📚 Documentation Locations

### AI Guidance Files (This Folder)
**Location**: `.kiro/steering/`

These files guide Kiro's behavior when generating code and reviewing:
- `org-architecture.md` - Architecture standards
- `org-coding-standards.md` - Coding standards
- `org-testing-standards.md` - Testing standards
- `org-code-review-standards.md` - Code review standards
- `CODE-REVIEW-DIAGRAM.md` - Code review system diagrams
- `FOUR-LEVEL-STRUCTURE.md` - Four-level hierarchy guide
- `README-WEALTH-AND-FIDUCIARY-STANDARDS.md` - Business unit overview

### Human-Readable Documentation
**Location**: `docs/`

These files are for developers, reviewers, and stakeholders:

#### GitHub Workflow (`docs/github-workflow/`)
- `QUICK-START-GITHUB.md` - 5-minute quick start guide
- `GITHUB-WORKFLOW-GUIDE.md` - Complete workflow guide (50+ pages)
- `GITHUB-WORKFLOW-DIAGRAM.md` - Visual diagrams and flowcharts
- `GITHUB-SETUP-COMPLETE.md` - Setup summary and training plan

#### Future Documentation
- `docs/deployment/` - Deployment guides (to be created)
- `docs/architecture/` - Architecture documentation (to be created)
- `docs/api/` - API documentation (to be created)

## 🤖 For Kiro AI

When users ask about:

**"How do I create a PR?"**
→ Point them to: `docs/github-workflow/QUICK-START-GITHUB.md`

**"What's the complete GitHub workflow?"**
→ Point them to: `docs/github-workflow/GITHUB-WORKFLOW-GUIDE.md`

**"Show me visual diagrams"**
→ Point them to: `docs/github-workflow/GITHUB-WORKFLOW-DIAGRAM.md`

**"What are the coding standards?"**
→ Use: `.kiro/steering/org-coding-standards.md` (apply these when generating code)

**"What are the architecture rules?"**
→ Use: `.kiro/steering/org-architecture.md` (enforce these when generating code)

**"What are the testing requirements?"**
→ Use: `.kiro/steering/org-testing-standards.md` (apply these when generating tests)

**"How do I review code?"**
→ Point them to: `.kiro/steering/org-code-review-standards.md` AND `docs/github-workflow/GITHUB-WORKFLOW-GUIDE.md`

**"What are the FullView application standards?"**
→ Use: `.kiro/steering/Applications/FullView/app-architecture.md`

**"What are the AITooling application standards?"**
→ Use: `.kiro/steering/Applications/AITooling/app-architecture.md`

**"What are the FullViewSecurity service rules?"**
→ Use: `.kiro/steering/Applications/FullView/services/FullViewSecurity/` (all files)

**"What are the INN8DataSource service rules?"**
→ Use: `.kiro/steering/Applications/FullView/services/INN8DataSource/` (all files)

**"What are the SecurityService service rules?"**
→ Use: `.kiro/steering/Applications/AITooling/services/SecurityService/` (all files)

**"What are the DataLoaderService service rules?"**
→ Use: `.kiro/steering/Applications/AITooling/services/DataLoaderService/` (all files)

## 📝 Key Distinction

**AI Guidance (`.kiro/steering/`)**:
- Rules and standards Kiro must follow
- Patterns for code generation
- Requirements for testing
- Architecture constraints

**Human Documentation (`docs/`)**:
- Guides and tutorials
- Step-by-step instructions
- Visual diagrams
- Training materials

## 🔍 Navigation

**For developers learning the workflow**:
1. Start: `docs/github-workflow/QUICK-START-GITHUB.md`
2. Then: `docs/github-workflow/GITHUB-WORKFLOW-GUIDE.md`
3. Visual: `docs/github-workflow/GITHUB-WORKFLOW-DIAGRAM.md`

**For developers learning standards**:
1. Architecture: `.kiro/steering/org-architecture.md`
2. Coding: `.kiro/steering/org-coding-standards.md`
3. Testing: `.kiro/steering/org-testing-standards.md`
4. Review: `.kiro/steering/org-code-review-standards.md`

**For understanding the structure**:
1. Four-level hierarchy: `.kiro/steering/FOUR-LEVEL-STRUCTURE.md`
2. Business unit overview: `.kiro/steering/README-WEALTH-AND-FIDUCIARY-STANDARDS.md`
3. Documentation index: `docs/README.md`

**For service-specific implementation**:
1. FullViewSecurity: `.kiro/steering/Applications/FullView/services/FullViewSecurity/`
   - `security-business-rules.md` - Authentication, authorization, audit logging
   - `entity-specifications.md` - Database entities and schema
   - `implementation-patterns.md` - Code patterns and examples

2. INN8DataSource: `.kiro/steering/Applications/FullView/services/INN8DataSource/`
   - `data-source-rules.md` - Sync rules, API integration, monitoring
   - `integration-patterns.md` - HTTP client, sync service, testing

3. SecurityService: `.kiro/steering/Applications/AITooling/services/SecurityService/`
   - `ai-security-rules.md` - AI-specific security, model access, API keys
   - `auth-patterns.md` - JWT, API key, model access patterns

4. DataLoaderService: `.kiro/steering/Applications/AITooling/services/DataLoaderService/`
   - `file-reader-rules.md` - File types, processing, PII detection
   - `processing-patterns.md` - Upload, extraction, queue processing

---

**Remember**: This file is a reference for Kiro. The actual documentation is in the locations listed above.

