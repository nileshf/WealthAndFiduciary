# WealthAndFiduciary Business Unit Standards

> **Scope**: ALL applications and microservices in the WealthAndFiduciary business unit  
> **Location**: `WealthAndFiduciary/.kiro/steering/`  
> **Precedence**: Lowest (can be overridden by application and service standards)

## 🎯 Overview

This folder contains business-unit-wide standards that apply to **ALL** WealthAndFiduciary applications and microservices, including:
- FullView (FullViewSecurityService, INN8DataSourceService)
- AITooling (SecurityService, DataLoaderService)
- All future applications

## 📁 Folder Structure

```
.kiro/steering/
├── org-*.md files (Business Unit standards)
├── CODE-REVIEW-DIAGRAM.md
├── FOUR-LEVEL-STRUCTURE.md
├── DOCUMENTATION-REFERENCE.md
├── README-WEALTH-AND-FIDUCIARY-STANDARDS.md (this file)
│
└── Applications/
    ├── FullView/
    │   ├── app-*.md (Application-level standards)
    │   └── services/
    │       ├── FullViewSecurity/
    │       │   └── *.md (Service-level standards)
    │       └── INN8DataSource/
    │           └── *.md (Service-level standards)
    │
    └── AITooling/
        ├── app-*.md (Application-level standards)
        └── services/
            ├── SecurityService/
            │   └── *.md (Service-level standards)
            └── DataLoaderService/
                └── *.md (Service-level standards)
```

## 🏗️ Four-Level Hierarchy

```
WealthAndFiduciary (BusinessUnit) ← YOU ARE HERE
├── FullView (Application)
│   ├── FullViewSecurityService (Service)
│   └── INN8DataSourceService (Service)
└── AITooling (Application)
    ├── SecurityService (Service)
    └── DataLoaderService (Service)
```

## 📊 Precedence Rules

```
Service-Level (HIGHEST PRECEDENCE)
    ↓
Application-Level
    ↓
BusinessUnit-Level (THIS LEVEL)
    ↓
Implementation / Kiro Defaults (LOWEST)
```

### How It Works

When working on **{service}**:

1. **Service-Level** (HIGHEST): `{service}/.kiro/steering/*.md`
   - security-business-rules.md
   - entity-specifications.md
   - etc.

2. **Application-Level**: `.kiro/steering/app-*.md`
   - app-architecture.md (Multi-tenant, SQL Server)
   - app-security-standards.md (JWT, RBAC)
   - app-integration-patterns.md

3. **BusinessUnit-Level** (THIS LEVEL): `WealthAndFiduciary/.kiro/steering/org-*.md`
   - org-architecture.md (Clean Architecture, SOLID)
   - org-coding-standards.md
   - org-testing-standards.md
   - org-code-review-standards.md

4. **Implementation**: `.github/workflows/*.yml`

## 🔄 How Kiro Loads These Files

### Option 1: Symbolic Link (Recommended)

Create a symbolic link from application `.kiro/steering/` to `WealthAndFiduciary/.kiro/steering/`:

```powershell
# Windows (run as Administrator)
cd .kiro/steering
New-Item -ItemType SymbolicLink -Name "org-architecture.md" -Target "../../WealthAndFiduciary/.kiro/steering/org-architecture.md"
New-Item -ItemType SymbolicLink -Name "org-coding-standards.md" -Target "../../WealthAndFiduciary/.kiro/steering/org-coding-standards.md"
New-Item -ItemType SymbolicLink -Name "org-testing-standards.md" -Target "../../WealthAndFiduciary/.kiro/steering/org-testing-standards.md"
New-Item -ItemType SymbolicLink -Name "org-code-review-standards.md" -Target "../../WealthAndFiduciary/.kiro/steering/org-code-review-standards.md"
```

### Option 2: Copy Files (Simpler)

Copy business unit standards to application `.kiro/steering/`:

```powershell
Copy-Item "WealthAndFiduciary/.kiro/steering/org-*.md" ".kiro/steering/" -Force
```

**Note**: With this option, you need to manually sync when business unit standards change.

### Option 3: Kiro Configuration (Future)

Configure Kiro to load from multiple locations:

```json
// .kiro/settings/kiro.json
{
  "steeringPaths": [
    "WealthAndFiduciary/.kiro/steering",
    ".kiro/steering",
    "{service}/.kiro/steering"
  ]
}
```

## 📝 Updating Business Unit Standards

### When to Update

Update Business Unit standards when:
- Technology stack changes (e.g., .NET version upgrade)
- Business Unit-wide coding conventions change
- New testing requirements apply to all services
- Security baseline changes

### How to Update

1. **Edit files in `WealthAndFiduciary/.kiro/steering/`**
2. **Sync to application repos** (if using Option 2):
   ```powershell
   Copy-Item "WealthAndFiduciary/.kiro/steering/org-*.md" ".kiro/steering/" -Force
   ```
3. **Communicate changes** to all teams
4. **Update application/service standards** if they conflict

### What NOT to Put Here

❌ Application-specific rules (e.g., FullView multi-tenant isolation)  
❌ Service-specific rules (e.g., FullViewSecurity 16 role types)  
❌ Implementation details (e.g., specific database schemas)

✅ Only Business Unit-wide standards that apply to ALL applications

## 🎓 Best Practices

### Do's
- ✅ Keep Business Unit standards minimal and focused
- ✅ Update when standards change for ALL applications
- ✅ Communicate changes to all teams
- ✅ Document why standards exist

### Don'ts
- ❌ Don't include application-specific rules
- ❌ Don't include service-specific rules
- ❌ Don't change frequently (causes disruption)
- ❌ Don't contradict industry best practices

## 📚 Related Documentation

### Business Unit Level (This Level)
- `WealthAndFiduciary/.kiro/steering/org-architecture.md`
- `WealthAndFiduciary/.kiro/steering/org-coding-standards.md`
- `WealthAndFiduciary/.kiro/steering/org-testing-standards.md`
- `WealthAndFiduciary/.kiro/steering/org-code-review-standards.md`
- `WealthAndFiduciary/.kiro/steering/FOUR-LEVEL-STRUCTURE.md`
- `WealthAndFiduciary/.kiro/steering/CODE-REVIEW-DIAGRAM.md`

### Application Level
- **FullView**: `.kiro/steering/app-*.md`
- **AITooling**: `../ai-tooling/.kiro/steering/app-*.md` (when created)

### Service Level
- **FullViewSecurity**: `FullViewSecurity/.kiro/steering/`
- **INN8DataSource**: `INN8DataSource/.kiro/steering/`
- **SecurityService**: `../ai-tooling/SecurityService/.kiro/steering/` (when created)
- **DataLoaderService**: `../ai-tooling/DataLoaderService/.kiro/steering/` (when created)

## 🔍 Quick Reference

**"Where do I define...?"**

- **Technology stack** (.NET version, frameworks): HERE (org-architecture.md)
- **Coding conventions** (naming, documentation): HERE (org-coding-standards.md)
- **Testing standards** (test pyramid, coverage): HERE (org-testing-standards.md)
- **Code review process**: HERE (org-code-review-standards.md)
- **Application patterns** (multi-tenant, JWT): Application level (app-*.md)
- **Service-specific rules** (16 roles, Auth schema): Service level

## 🆘 Troubleshooting

### Issue: Kiro not loading business unit standards

**Solution**: 
- Check if symbolic links exist in `.kiro/steering/`
- OR check if files are copied to `.kiro/steering/`
- Verify file paths are correct

### Issue: Conflicts between business unit and application standards

**Solution**: 
- Application standards have higher precedence
- Document the override in application steering
- Consider if business unit standard needs updating

### Issue: Need to update standards across all applications

**Solution**:
- Update files in `Business Unit/.kiro/steering/`
- Sync to all application repos
- Communicate changes to all teams

---

**Remember**: These are Business Unit standards. They apply to ALL applications and services. Keep them minimal, focused, and stable.

**Questions?** See FOUR-LEVEL-STRUCTURE.md or ask your business unit tech lead.
