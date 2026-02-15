# Code Review System - Visual Diagram

## 🎯 Complete System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CODE REVIEW SYSTEM                               │
│                                                                           │
│  Three-Level Structure: Business Unit → GitHub → Service                │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    LEVEL 1: BUSINESS UNIT STANDARDS                      │
│                    (MANDATORY for ALL microservices)                     │
│                                                                           │
│  📄 .kiro/steering/org-code-review-standards.md                         │
│                                                                           │
│  Contains:                                                                │
│  ├── 🎯 Code Review Philosophy                                           │
│  │   ├── Quality (maintaining high standards)                            │
│  │   ├── Knowledge Sharing (learning from each other)                    │
│  │   ├── Consistency (ensuring patterns across services)                 │
│  │   ├── Security (catching vulnerabilities early)                       │
│  │   └── Mentorship (growing team skills)                                │
│  │                                                                        │
│  ├── 📋 5-Step Review Process                                            │
│  │   ├── 1. Automated Checks (before human review)                       │
│  │   ├── 2. Initial Review (5-10 minutes)                                │
│  │   ├── 3. Deep Review (20-40 minutes)                                  │
│  │   ├── 4. Provide Feedback (10-15 minutes)                             │
│  │   └── 5. Approval Decision                                            │
│  │                                                                        │
│  ├── ✅ Mandatory Review Checklist                                       │
│  │   ├── Pre-Review (automated checks passed?)                           │
│  │   ├── Architecture (Clean Architecture, SOLID)                        │
│  │   ├── Code Quality (readable, maintainable)                           │
│  │   ├── Security (PII, auth, multi-tenant)                              │
│  │   ├── Testing (coverage, quality, isolation)                          │
│  │   ├── Performance (N+1, async/await, caching)                         │
│  │   ├── Documentation (XML docs, README)                                │
│  │   └── Final (conversations resolved)                                  │
│  │                                                                        │
│  ├── 🚫 Common Anti-Patterns                                             │
│  │   ├── Architecture violations                                         │
│  │   ├── Security issues                                                 │
│  │   ├── Code quality issues                                             │
│  │   ├── Testing issues                                                  │
│  │   └── Performance issues                                              │
│  │                                                                        │
│  ├── ⏱️ Time Expectations                                                │
│  │   ├── Developers: 5-10 min pre-commit, 30-60 min feedback            │
│  │   └── Reviewers: 15-60 min based on PR size                           │
│  │                                                                        │
│  ├── 📏 PR Size Guidelines                                               │
│  │   ├── Small: < 100 lines (ideal)                                      │
│  │   ├── Medium: 100-300 lines (acceptable)                              │
│  │   ├── Large: 300-500 lines (needs justification)                      │
│  │   └── Too Large: > 500 lines (should be split)                        │
│  │                                                                        │
│  ├── 🔒 Security Review Requirements                                     │
│  ├── 🏗️ Architecture Review Requirements                                 │
│  ├── 🧪 Testing Review Requirements                                      │
│  ├── 📊 Metrics to Track                                                 │
│  ├── 🎓 Best Practices                                                   │
│  └── 🚨 Escalation Process                                               │
│                                                                           │
│  Applies to: FullViewSecurity, INN8DataSource, ALL future services      │
│  Precedence: Service-specific can extend but NOT contradict             │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
┌───────────────────────────────────┐   ┌───────────────────────────────────┐
│  LEVEL 2: GITHUB IMPLEMENTATION   │   │  LEVEL 3: SERVICE EXTENSIONS      │
│  (Enforces business unit standards)│   │  (Optional service-specific)      │
│                                   │   │                                   │
│  📁 .github/                      │   │  📁 [Service]/.kiro/steering/     │
│                                   │   │                                   │
│  ├── 🤖 workflows/                │   │  📄 code-review-standards.md      │
│  │   └── code-review-checks.yml  │   │                                   │
│  │       ├── Job 1: Linting       │   │  Can extend org standards with:   │
│  │       ├── Job 2: Build         │   │  ├── Additional security checks   │
│  │       ├── Job 3: Unit Tests    │   │  ├── Extra validation rules       │
│  │       ├── Job 4: Integration   │   │  ├── Service-specific patterns    │
│  │       ├── Job 5: Coverage      │   │  └── Domain-specific criteria     │
│  │       ├── Job 6: Security      │   │                                   │
│  │       ├── Job 7: Architecture  │   │  Example (FullViewSecurity):      │
│  │       ├── Job 8: Documentation │   │  ├── Multi-tenant isolation       │
│  │       └── Job 9: Summary       │   │  │   checks                       │
│  │                                │   │  ├── Financial compliance         │
│  │                                │   │  │   requirements                 │
│  ├── 📝 PULL_REQUEST_TEMPLATE.md │   │  └── Audit logging validation     │
│  │   └── Comprehensive checklist │   │                                   │
│  │                                │   │  Precedence: HIGHEST              │
│  ├── 📚 Documentation             │   │  (overrides business unit when    │
│  │   ├── CODE_REVIEW_GUIDE.md    │   │   conflicts exist)                │
│  │   ├── CODE_REVIEW_SETUP.md    │   │                                   │
│  │   ├── CODE_REVIEW_STRUCTURE.md│   │  Status: Not yet created          │
│  │   ├── CODE_REVIEW_QUICK_      │   │  (structure is ready)             │
│  │   │   REFERENCE.md             │   │                                   │
│  │   ├── CODE_REVIEW_             │   │                                   │
│  │   │   IMPLEMENTATION_          │   │                                   │
│  │   │   SUMMARY.md               │   │                                   │
│  │   └── README.md                │   │                                   │
│  │                                │   │                                   │
│  └── 💻 Local Checks              │   │                                   │
│      └── run-pre-commit-checks.ps1│   │                                   │
│          (workspace root)          │   │                                   │
│                                   │   │                                   │
│  References: org-code-review-     │   │  References: org-code-review-     │
│  standards.md                     │   │  standards.md                     │
└───────────────────────────────────┘   └───────────────────────────────────┘
```

## 🔄 Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                               │
└─────────────────────────────────────────────────────────────────────────┘

1. Write Code
   │
   ▼
2. Run Local Checks
   │  .\run-pre-commit-checks.ps1
   │  ├── Linting
   │  ├── Build
   │  ├── Tests
   │  ├── Coverage
   │  └── Security
   │
   ▼
3. Push Branch
   │
   ▼
4. Create PR
   │  Template auto-fills
   │  Complete checklist
   │
   ▼
5. Automated Checks (GitHub Actions)
   │  9 jobs run automatically
   │  ├── ✅ All pass → Continue
   │  └── ❌ Any fail → Fix and push
   │
   ▼
6. Request Review
   │
   ▼
7. Human Review
   │  Reviewer follows 5-step process
   │  ├── Initial Review (5-10 min)
   │  ├── Deep Review (20-40 min)
   │  ├── Provide Feedback (10-15 min)
   │  └── Decision
   │      ├── ✅ Approve → Merge
   │      ├── 🔄 Request Changes → Fix
   │      └── 💬 Comment → Discuss
   │
   ▼
8. Address Feedback
   │  (if needed)
   │
   ▼
9. Merge
   │
   ▼
10. Delete Branch

┌─────────────────────────────────────────────────────────────────────────┐
│                         REVIEWER WORKFLOW                                │
└─────────────────────────────────────────────────────────────────────────┘

1. Receive Review Request
   │
   ▼
2. Check Automated Results
   │  All GitHub Actions passed?
   │  ├── ✅ Yes → Continue
   │  └── ❌ No → Request fixes
   │
   ▼
3. Initial Review (5-10 min)
   │  ├── Read PR description
   │  ├── Check scope
   │  └── Review checklist
   │
   ▼
4. Deep Review (20-40 min)
   │  ├── Architecture
   │  ├── Code Quality
   │  ├── Security
   │  ├── Testing
   │  ├── Performance
   │  └── Documentation
   │
   ▼
5. Provide Feedback (10-15 min)
   │  Use labels:
   │  ├── 🐛 Bug
   │  ├── ⚠️ Security
   │  ├── 🔧 Refactor
   │  ├── 💡 Suggestion
   │  ├── ❓ Question
   │  ├── ✅ Praise
   │  ├── 📚 Documentation
   │  └── 🧪 Testing
   │
   ▼
6. Make Decision
   │  ├── ✅ Approve (all good)
   │  ├── 🔄 Request Changes (critical issues)
   │  └── 💬 Comment (non-blocking)
   │
   ▼
7. Follow Up
   │  ├── Re-review if significant changes
   │  └── Approve when ready
```

## 📊 Precedence Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         PRECEDENCE HIERARCHY                             │
└─────────────────────────────────────────────────────────────────────────┘

                    When Working on FullViewSecurity
                                │
                                ▼
        ┌───────────────────────────────────────────┐
        │  Kiro Loads Rules in Order:               │
        └───────────────────────────────────────────┘
                                │
                ┌───────────────┴───────────────┐
                │                               │
                ▼                               ▼
┌───────────────────────────┐   ┌───────────────────────────┐
│  1. Service-Level         │   │  2. Business Unit-Level   │
│     (HIGHEST PRECEDENCE)  │   │     (LOWER PRECEDENCE)    │
│                           │   │                           │
│  FullViewSecurity/        │   │  /workspace-root/         │
│  .kiro/steering/          │   │  .kiro/steering/          │
│  code-review-standards.md │   │  org-code-review-         │
│                           │   │  standards.md             │
│  If exists:               │   │                           │
│  ├── Multi-tenant checks  │   │  Always applies:          │
│  ├── Financial compliance │   │  ├── 5-step process       │
│  └── Audit logging        │   │  ├── Mandatory checklist  │
│                           │   │  ├── Time expectations    │
│  ✅ Wins on conflicts     │   │  └── Best practices       │
│  ✅ Service-specific      │   │                           │
│                           │   │  ✅ Applies when no       │
│  Status: Not yet created  │   │     conflict              │
│                           │   │  ✅ Business Unit-wide    │
└───────────────────────────┘   └───────────────────────────┘
                │                               │
                └───────────────┬───────────────┘
                                │
                                ▼
                ┌───────────────────────────┐
                │  3. GitHub Implementation │
                │     (FOLLOWS BU)          │
                │                           │
                │  .github/                 │
                │  ├── Automated checks     │
                │  ├── PR template          │
                │  └── Documentation        │
                │                           │
                │  ✅ Enforces business     │
                │     unit standards        │
                └───────────────────────────┘
                                │
                                ▼
                ┌───────────────────────────┐
                │  4. Kiro Defaults         │
                │     (LOWEST PRECEDENCE)   │
                │                           │
                │  ✅ Applies when no       │
                │     business unit or      │
                │     service rules exist   │
                └───────────────────────────┘
```

## 🎯 What Gets Checked Where

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AUTOMATED CHECKS                                 │
│                         (GitHub Actions)                                 │
└─────────────────────────────────────────────────────────────────────────┘

Job 1: Linting                    Job 6: Security Scan
├── dotnet format                 ├── Vulnerable packages
├── Code style                    ├── Known security issues
└── Formatting                    └── Outdated dependencies

Job 2: Build                      Job 7: Architecture Validation
├── Compiles without errors       ├── Domain dependencies
├── No warnings                   ├── Application dependencies
└── All projects build            └── Clean Architecture rules

Job 3: Unit Tests                 Job 8: Documentation Check
├── All tests pass                ├── XML docs on public types
├── No failures                   ├── Parameter descriptions
└── Tests run successfully        └── Return value docs

Job 4: Integration Tests          Job 9: Quality Summary
├── All tests pass                ├── Overall status
├── Database operations           └── Next steps
└── API endpoints

Job 5: Code Coverage
├── Domain: ≥ 80%
├── Application: ≥ 80%
├── Infrastructure: ≥ 70%
└── API: ≥ 70%

┌─────────────────────────────────────────────────────────────────────────┐
│                         MANUAL CHECKS                                    │
│                         (Human Review)                                   │
└─────────────────────────────────────────────────────────────────────────┘

Architecture                      Performance
├── Clean Architecture            ├── No N+1 queries
├── SOLID principles              ├── Async/await used properly
├── Separation of concerns        ├── Efficient queries
└── No violations                 └── Appropriate caching

Code Quality                      Documentation
├── Readable                      ├── XML docs clear
├── Maintainable                  ├── README updated
├── No duplication                ├── Breaking changes documented
└── Proper error handling         └── Deployment notes

Security                          Testing
├── PII encrypted                 ├── Tests comprehensive
├── Passwords hashed              ├── Coverage adequate
├── Input validated               ├── Tests isolated
├── Auth/authz correct            └── Test quality high
└── Multi-tenant isolation
```

## 📚 Documentation Map

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DOCUMENTATION STRUCTURE                          │
└─────────────────────────────────────────────────────────────────────────┘

Business Unit-Level
├── 📄 org-code-review-standards.md ⭐ PRIMARY REFERENCE
│   └── Complete standards for ALL services
│
└── 📄 CODE-REVIEW-DIAGRAM.md (this file)
    └── Visual diagrams and workflows

GitHub Implementation
├── 📁 .github/
│   ├── 📄 README.md
│   │   └── GitHub folder overview
│   │
│   ├── 📄 CODE_REVIEW_QUICK_REFERENCE.md 📄 PRINT THIS
│   │   └── Quick reference card
│   │
│   ├── 📄 CODE_REVIEW_SETUP.md
│   │   └── Setup and usage guide
│   │
│   ├── 📄 CODE_REVIEW_GUIDE.md
│   │   └── Review guide with examples
│   │
│   ├── 📄 CODE_REVIEW_STRUCTURE.md
│   │   └── Complete structure overview
│   │
│   ├── 📄 CODE_REVIEW_IMPLEMENTATION_SUMMARY.md
│   │   └── Implementation details
│   │
│   ├── 📄 PULL_REQUEST_TEMPLATE.md
│   │   └── PR template
│   │
│   └── 🤖 workflows/code-review-checks.yml
│       └── Automated checks

Workspace Root
└── 📄 CODE-REVIEW-COMPLETE.md
    └── Complete summary

Service-Level (Optional)
└── 📁 [Service]/.kiro/steering/
    └── 📄 code-review-standards.md
        └── Service-specific extensions
```

## 🎓 Quick Navigation

```
"I want to..."                    "Go to..."
─────────────────────────────────────────────────────────────────────────
Understand the standards          .kiro/steering/org-code-review-standards.md
Get quick answers                 .github/CODE_REVIEW_QUICK_REFERENCE.md
Learn the setup                   .github/CODE_REVIEW_SETUP.md
See examples                      .github/CODE_REVIEW_GUIDE.md
Understand structure              .github/CODE_REVIEW_STRUCTURE.md
See visual diagrams               .kiro/steering/CODE-REVIEW-DIAGRAM.md
Read complete summary             CODE-REVIEW-COMPLETE.md
Run local checks                  run-pre-commit-checks.ps1
View automated checks             .github/workflows/code-review-checks.yml
```

---

**Remember**: This is a three-level system with clear precedence. Business Unit standards are MANDATORY. GitHub implementation enforces them. Service-specific rules can extend but not contradict.

**Start here**: `.kiro/steering/org-code-review-standards.md` ⭐
