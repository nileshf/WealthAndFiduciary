# DataLoaderService - Kiro Configuration

This directory contains Kiro-specific configuration and specifications for the DataLoaderService microservice.

## Directory Structure

```
.kiro/
├── specs/
│   └── data-loader-service/
│       ├── requirements.md    # Requirements with acceptance criteria
│       ├── design.md          # Design document with architecture
│       └── tasks.md           # Implementation tasks
└── README.md                  # This file
```

## Specs

The `specs/` directory contains the complete specification for this microservice:

- **requirements.md**: 12 requirements with user stories and acceptance criteria
- **design.md**: Comprehensive design including architecture, CSV processing, and 6 correctness properties
- **tasks.md**: 11 phases with 75+ implementation and testing tasks

## Usage

### View Requirements
```bash
# Open requirements document
code .kiro/specs/data-loader-service/requirements.md
```

### View Design
```bash
# Open design document
code .kiro/specs/data-loader-service/design.md
```

### Start Implementation
```bash
# Open tasks document
code .kiro/specs/data-loader-service/tasks.md
```

## Related Documentation

- **Business Unit Standards**: `../../../../.kiro/steering/org-*.md`
- **Application Standards**: `../../../../.kiro/steering/Applications/AITooling/app-*.md`
- **Service Standards**: `../../../../.kiro/steering/Applications/AITooling/services/FileReader/`
- **Code**: `../` (parent directory)

## Spec Workflow

This service follows the **requirements-first workflow**:

1. ✅ **Requirements** - Define what needs to be built
2. ✅ **Design** - Define how it will be built
3. ✅ **Tasks** - Define implementation steps
4. ⏳ **Implementation** - Execute the tasks
5. ⏳ **Testing** - Verify correctness with property-based tests

## Integration

This service integrates with SecurityService for JWT authentication:
- JWT configuration must match SecurityService exactly
- See Phase 5 in `tasks.md` for integration tasks
- See Phase 10 in `tasks.md` for end-to-end testing

## Next Steps

To begin implementation:
1. Review `requirements.md` to understand what needs to be built
2. Review `design.md` to understand the architecture
3. Open `tasks.md` and start with Phase 1
4. Update task status as you progress: `[ ]` → `[-]` → `[x]`

## Questions?

- For requirements questions, see `requirements.md`
- For design questions, see `design.md`
- For implementation guidance, see `tasks.md`
- For coding standards, see `../../../../.kiro/steering/org-coding-standards.md`
- For testing standards, see `../../../../.kiro/steering/org-testing-standards.md`
