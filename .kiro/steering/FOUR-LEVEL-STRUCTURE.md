# WealthAndFiduciary Four-Level Structure - Complete Guide

## 🎯 Overview

WealthAndFiduciary (Business Unit) uses a **four-level hierarchy** for managing standards across multiple applications and microservices:

```
WealthAndFiduciary (Business Unit)
├── FullView (Application)
│   ├── FullViewSecurity (Microservice)
│   ├── INN8DataSource (Microservice)
│   └── [other FullView services]
└── AITooling (Application)
    ├── SecurityService (Microservice)
    ├── DataLoaderService (Microservice)
    └── [other AITooling services]
```

## 🏗️ Four-Level Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LEVEL 1: BUSINESS UNIT (WealthAndFiduciary)           │
│                    Applies to ALL applications and services              │
│                                                                           │
│  Location: wealthandfiduciary-standards repo OR copied to each app repo  │
│  Files: wealth-and-fiduciary-architecture.md, wealth-and-fiduciary-coding-standards.md, etc.              │
│                                                                           │
│  Defines:                                                                 │
│  ├── .NET 9.0 for all services                                          │
│  ├── Clean Architecture mandatory                                        │
│  ├── SOLID principles                                                    │
│  ├── Testing standards (80% coverage)                                    │
│  ├── Code review process                                                 │
│  └── Security baseline                                                   │
│                                                                           │
│  Applies to: FullView, AITooling, ALL future applications               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
┌───────────────────────────────────┐   ┌───────────────────────────────────┐
│  LEVEL 2: APPLICATION (FullView)  │   │  LEVEL 2: APPLICATION (AITooling) │
│  Applies to FullView services     │   │  Applies to AITooling services    │
│                                   │   │                                   │
│  Location: fullview-repo/         │   │  Location: ai-tooling-repo/       │
│  .kiro/steering/                  │   │  .kiro/steering/                  │
│                                   │   │                                   │
│  Files:                           │   │  Files:                           │
│  ├── app-architecture.md          │   │  ├── app-architecture.md          │
│  ├── app-security-standards.md    │   │  ├── app-ai-standards.md          │
│  └── app-integration-patterns.md  │   │  └── app-ml-patterns.md           │
│                                   │   │                                   │
│  Defines:                         │   │  Defines:                         │
│  ├── SQL Server for FullView      │   │  ├── AI/ML frameworks             │
│  ├── Multi-tenant isolation       │   │  ├── File processing patterns     │
│  ├── Financial compliance         │   │  ├── Model deployment             │
│  ├── Audit logging                │   │  └── Data pipeline standards      │
│  └── FullView API contracts       │   │                                   │
│                                   │   │  Applies to: SecurityService,   │
│  Applies to: FullViewSecurity,    │   │  DataLoaderService, all AITooling        │
│  INN8DataSource, all FullView     │   │  services                         │
│  services                         │   │                                   │
└───────────────────────────────────┘   └───────────────────────────────────┘
                    │                               │
        ┌───────────┴───────────┐       ┌───────────┴───────────┐
        │                       │       │                       │
        ▼                       ▼       ▼                       ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ LEVEL 3:        │   │ LEVEL 3:        │   │ LEVEL 3:        │   │ LEVEL 3:        │
│ SERVICE         │   │ SERVICE         │   │ SERVICE         │   │ SERVICE         │
│                 │   │                 │   │                 │   │                 │
│ FullView        │   │ INN8Data        │   │ AITooling       │   │ DataLoaderService      │
│ Security        │   │ Source          │   │ Security        │   │                 │
│                 │   │                 │   │                 │   │                 │
│ Location:       │   │ Location:       │   │ Location:       │   │ Location:       │
│ FullView        │   │ INN8DataSource/ │   │ AITooling       │   │ DataLoaderService/     │
│ Security/       │   │ .kiro/steering/ │   │ Security/       │   │ .kiro/steering/ │
│ .kiro/steering/ │   │                 │   │ .kiro/steering/ │   │                 │
│                 │   │ Files:          │   │                 │   │ Files:          │
│ Files:          │   │ ├── data-source-│   │ Files:          │   │ ├── file-reader-│
│ ├── security-   │   │ │   rules.md    │   │ ├── ai-security-│   │ │   rules.md    │
│ │   business-   │   │ └── integration-│   │ │   rules.md    │   │ └── processing- │
│ │   rules.md    │   │     patterns.md │   │ └── auth-       │   │     patterns.md │
│ ├── entity-     │   │                 │   │     patterns.md │   │                 │
│ │   specs.md    │   │ Defines:        │   │                 │   │ Defines:        │
│ └── impl-       │   │ ├── INN8 API    │   │ Defines:        │   │ ├── File types  │
│     patterns.md │   │ │   integration │   │ ├── AI-specific │   │ ├── Parsing     │
│                 │   │ ├── Data sync   │   │ │   auth        │   │ │   strategies  │
│ Defines:        │   │ │   patterns    │   │ ├── Model       │   │ ├── Storage     │
│ ├── JWT auth    │   │ └── DataSource  │   │ │   validation  │   │ │   patterns    │
│ ├── 16 role     │   │     schema      │   │ └── Token mgmt  │   │ └── Error       │
│ │   types       │   │                 │   │                 │   │     handling    │
│ ├── Auth schema │   │                 │   │                 │   │                 │
│ └── User entity │   │                 │   │                 │   │                 │
└─────────────────┘   └─────────────────┘   └─────────────────┘   └─────────────────┘
        │                       │                       │                       │
        └───────────────────────┴───────────────────────┴───────────────────────┘
                                            │
                                            ▼
                    ┌───────────────────────────────────────────┐
                    │  LEVEL 4: IMPLEMENTATION                  │
                    │  (GitHub Actions, CI/CD, Tooling)         │
                    │                                           │
                    │  Per Application Repo:                    │
                    │  ├── .github/workflows/                   │
                    │  ├── run-pre-commit-checks.ps1            │
                    │  └── deployment scripts                   │
                    │                                           │
                    │  Implements and enforces levels 1-3       │
                    └───────────────────────────────────────────┘
```

## 📋 Precedence Rules

```
Service-Level (HIGHEST PRECEDENCE)
    ↓
Application-Level
    ↓
Business Unit-Level
    ↓
Implementation / Kiro Defaults (LOWEST PRECEDENCE)
```

### Example Precedence Flow

**Scenario**: Database schema naming

1. **Business Unit (WealthAndFiduciary)** says: "Use service-specific schemas"
2. **Application (FullView)** says: "All FullView services use descriptive schemas"
3. **Service (FullViewSecurity)** says: "Use 'Auth' schema"
4. **Result**: FullViewSecurity uses `Auth` schema ✅

**Scenario**: Code coverage requirements

1. **Business Unit (WealthAndFiduciary)** says: "80% coverage for Domain/Application"
2. **Application (FullView)** says: "85% coverage for financial services"
3. **Service (FullViewSecurity)** says: "90% coverage for authentication code"
4. **Result**: FullViewSecurity requires 90% coverage ✅

## 🗂️ Steering Folder Structure

### New Hierarchical Structure (Recommended)

```
.kiro/steering/
├── wealth-and-fiduciary-architecture.md (Level 1: Business Unit)
├── wealth-and-fiduciary-coding-standards.md (Level 1: Business Unit)
├── wealth-and-fiduciary-testing-standards.md (Level 1: Business Unit)
├── wealth-and-fiduciary-code-review-standards.md (Level 1: Business Unit)
├── CODE-REVIEW-DIAGRAM.md
├── FOUR-LEVEL-STRUCTURE.md
├── DOCUMENTATION-REFERENCE.md
├── README-WEALTH-AND-FIDUCIARY-STANDARDS.md
│
└── Applications/
    ├── FullView/
    │   ├── app-architecture.md (Level 2: Application)
    │   ├── app-security-standards.md (Level 2: Application)
    │   ├── app-integration-patterns.md (Level 2: Application)
    │   └── services/
    │       ├── FullViewSecurity/
    │       │   ├── security-business-rules.md (Level 3: Service)
    │       │   ├── entity-specifications.md (Level 3: Service)
    │       │   └── implementation-patterns.md (Level 3: Service)
    │       └── INN8DataSource/
    │           ├── data-source-rules.md (Level 3: Service)
    │           └── integration-patterns.md (Level 3: Service)
    │
    └── AITooling/
        ├── app-architecture.md (Level 2: Application)
        ├── app-ai-standards.md (Level 2: Application)
        ├── app-ml-patterns.md (Level 2: Application)
        └── services/
            ├── SecurityService/
            │   ├── ai-security-rules.md (Level 3: Service)
            │   └── auth-patterns.md (Level 3: Service)
            └── DataLoaderService/
                ├── file-reader-rules.md (Level 3: Service)
                └── processing-patterns.md (Level 3: Service)
```

### Benefits of This Structure

1. **Clear Hierarchy**: Physical folder structure mirrors logical hierarchy
2. **Easy Navigation**: Find standards by navigating folders
3. **Scalability**: Easy to add new applications and services
4. **Separation**: Business unit, application, and service standards clearly separated
5. **Kiro-Friendly**: Kiro can load all relevant standards based on context

## 📁 Detailed File Structure

### Complete Workspace Structure

```
WealthAndFiduciary/ (workspace root)
├── .kiro/
│   ├── steering/
│   │   ├── wealth-and-fiduciary-architecture.md (Level 1: Business Unit)
│   │   ├── wealth-and-fiduciary-coding-standards.md (Level 1: Business Unit)
│   │   ├── wealth-and-fiduciary-testing-standards.md (Level 1: Business Unit)
│   │   ├── wealth-and-fiduciary-code-review-standards.md (Level 1: Business Unit)
│   │   ├── CODE-REVIEW-DIAGRAM.md
│   │   ├── FOUR-LEVEL-STRUCTURE.md
│   │   ├── DOCUMENTATION-REFERENCE.md
│   │   ├── README-WEALTH-AND-FIDUCIARY-STANDARDS.md
│   │   │
│   │   └── Applications/
│   │       ├── FullView/
│   │       │   ├── app-architecture.md (Level 2)
│   │       │   ├── app-security-standards.md (Level 2)
│   │       │   ├── app-integration-patterns.md (Level 2)
│   │       │   └── services/
│   │       │       ├── FullViewSecurity/
│   │       │       │   ├── security-business-rules.md (Level 3)
│   │       │       │   ├── entity-specifications.md (Level 3)
│   │       │       │   └── implementation-patterns.md (Level 3)
│   │       │       └── INN8DataSource/
│   │       │           ├── data-source-rules.md (Level 3)
│   │       │           └── integration-patterns.md (Level 3)
│   │       │
│   │       └── AITooling/
│   │           ├── app-architecture.md (Level 2)
│   │           ├── app-ai-standards.md (Level 2)
│   │           ├── app-ml-patterns.md (Level 2)
│   │           └── services/
│   │               ├── SecurityService/
│   │               │   ├── ai-security-rules.md (Level 3)
│   │               │   └── auth-patterns.md (Level 3)
│   │               └── DataLoaderService/
│   │                   ├── file-reader-rules.md (Level 3)
│   │                   └── processing-patterns.md (Level 3)
│   │
│   └── settings/
│       └── mcp.json
│
├── .github/
│   ├── workflows/
│   │   └── pr-checks.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── README.md
│
├── docs/
│   ├── README.md
│   └── github-workflow/
│       ├── GITHUB-WORKFLOW-GUIDE.md
│       ├── GITHUB-WORKFLOW-DIAGRAM.md
│       ├── QUICK-START-GITHUB.md
│       └── GITHUB-SETUP-COMPLETE.md
│
├── Conversations/
│   └── Documentation Reorganization Complete.md
│
├── run-pre-commit-checks.ps1
└── WealthAndFiduciary.code-workspace
```

## 🎯 How Standards Are Applied

### When Working on FullViewSecurity

Kiro loads steering files in this order:

1. **Service-Level** (HIGHEST): `.kiro/steering/Applications/FullView/services/FullViewSecurity/*.md`
2. **Application-Level**: `.kiro/steering/Applications/FullView/app-*.md`
3. **Business Unit-Level**: `.kiro/steering/wealth-and-fiduciary-*.md`
4. **Implementation**: `.github/workflows/*.yml`

### When Working on SecurityService

Kiro loads steering files in this order:

1. **Service-Level** (HIGHEST): `.kiro/steering/Applications/AITooling/services/SecurityService/*.md`
2. **Application-Level**: `.kiro/steering/Applications/AITooling/app-*.md`
3. **Business Unit-Level**: `.kiro/steering/wealth-and-fiduciary-*.md`
4. **Implementation**: `.github/workflows/*.yml`

## 📊 Standards Inheritance

```
┌─────────────────────────────────────────────────────────────────┐
│  FullViewSecurity inherits:                                      │
│                                                                   │
│  1. Business Unit (WealthAndFiduciary) standards                 │
│     ├── .NET 9.0                                                 │
│     ├── Clean Architecture                                       │
│     ├── 80% code coverage                                        │
│     └── Code review process                                      │
│                                                                   │
│  2. Application (FullView) standards                             │
│     ├── SQL Server                                               │
│     ├── Multi-tenant isolation                                   │
│     ├── Financial compliance                                     │
│     └── Audit logging                                            │
│                                                                   │
│  3. Service (FullViewSecurity) standards                         │
│     ├── JWT authentication                                       │
│     ├── 16 role types                                            │
│     ├── Auth schema                                              │
│     └── User entity specifications                               │
│                                                                   │
│  Result: FullViewSecurity follows ALL three levels              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  DataLoaderService inherits:                                            │
│                                                                   │
│  1. Business Unit (WealthAndFiduciary) standards                 │
│     ├── .NET 9.0                                                 │
│     ├── Clean Architecture                                       │
│     ├── 80% code coverage                                        │
│     └── Code review process                                      │
│                                                                   │
│  2. Application (AITooling) standards                            │
│     ├── AI/ML frameworks                                         │
│     ├── File processing patterns                                 │
│     ├── Model deployment                                         │
│     └── Data pipeline standards                                  │
│                                                                   │
│  3. Service (DataLoaderService) standards                               │
│     ├── File type support                                        │
│     ├── Parsing strategies                                       │
│     ├── Storage patterns                                         │
│     └── Error handling                                           │
│                                                                   │
│  Result: DataLoaderService follows ALL three levels                    │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Benefits of Four-Level Structure

### For WealthAndFiduciary (Business Unit)
- ✅ Consistent standards across ALL applications
- ✅ Single source of truth for business unit-wide rules
- ✅ Easy to update standards for all applications
- ✅ Clear governance and compliance

### For FullView (Application)
- ✅ Application-specific standards for all FullView services
- ✅ Shared libraries and patterns within FullView
- ✅ Independent deployment from AITooling
- ✅ Clear application boundaries

### For AITooling (Application)
- ✅ Application-specific standards for all AITooling services
- ✅ AI/ML-specific patterns and frameworks
- ✅ Independent deployment from FullView
- ✅ Specialized tooling and infrastructure

### For Services (FullViewSecurity, INN8DataSource, etc.)
- ✅ Service-specific rules and patterns
- ✅ Inherits business unit and application standards
- ✅ Can override when necessary (with documentation)
- ✅ Clear ownership and boundaries

## 📝 File Naming Conventions

### Business Unit-Level Files
- Prefix: `wealth-and-fiduciary-`
- Examples: `wealth-and-fiduciary-architecture.md`, `wealth-and-fiduciary-coding-standards.md`
- Location: Application repo root `.kiro/steering/`

### Application-Level Files
- Prefix: `app-`
- Examples: `app-architecture.md`, `app-security-standards.md`
- Location: Application repo root `.kiro/steering/`

### Service-Level Files
- No prefix (service name is implicit from location)
- Examples: `security-business-rules.md`, `entity-specifications.md`
- Location: Service folder `.kiro/steering/`

## 🎓 Best Practices

### Business Unit-Level Standards
- ✅ Keep focused on universal requirements
- ✅ Update when standards change for ALL applications
- ✅ Communicate changes to all teams
- ❌ Don't include application-specific rules
- ❌ Don't include service-specific rules

### Application-Level Standards
- ✅ Define application-wide patterns
- ✅ Document shared libraries and contracts
- ✅ Specify application-specific technologies
- ❌ Don't duplicate business unit standards
- ❌ Don't include service-specific rules

### Service-Level Standards
- ✅ Only add what's truly service-specific
- ✅ Document why it's service-specific
- ✅ Reference application and business unit standards
- ❌ Don't duplicate application standards
- ❌ Don't duplicate business unit standards

## 🔍 Quick Reference

### "Where do I define...?"

**Technology stack (.NET version, frameworks)**: Business Unit-level (`wealth-and-fiduciary-architecture.md`)

**Application-wide patterns (multi-tenant, audit logging)**: Application-level (`app-architecture.md`)

**Service-specific rules (JWT auth, 16 roles)**: Service-level (`security-business-rules.md`)

**Shared libraries**: Application-level `Shared/` folder

**CI/CD workflows**: Application repo `.github/workflows/`

### "What applies to me?"

**All developers**: Business Unit standards

**FullView developers**: Business Unit + FullView application standards

**FullViewSecurity developers**: Business Unit + FullView + FullViewSecurity service standards

**AITooling developers**: Business Unit + AITooling application standards

**DataLoaderService developers**: Business Unit + AITooling + DataLoaderService service standards

## 📚 Related Documentation

- **Business Unit Standards**: `.kiro/steering/wealth-and-fiduciary-*.md`
- **Application Standards**: `.kiro/steering/Applications/[Application]/app-*.md`
- **Service Standards**: `.kiro/steering/Applications/[Application]/services/[Service]/*.md`
- **Structure Diagram**: `.kiro/steering/FOUR-LEVEL-STRUCTURE.md`
- **Documentation Reference**: `.kiro/steering/DOCUMENTATION-REFERENCE.md`

---

**Remember**: This is a four-level system with clear precedence. Business Unit standards are MANDATORY for all. Application standards apply to all services in that application. Service standards are service-specific. Each level can extend but not contradict higher levels.

**Questions?** See the documentation reference or ask your tech lead.
