# DataLoaderService Implementation Tasks

## Phase 1: Performance Optimization Setup (Do First!)
- [x] 1.1 Configure parallel builds
  - Add `<PropertyGroup><TreatWarningsAsErrors>false</TreatWarningsAsErrors></PropertyGroup>` to project files
  - Use `dotnet build -m` for multi-threaded compilation
  - Expected improvement: 20-30% faster builds
  - **Do this FIRST** - enables all subsequent builds to be faster
- [x] 1.2 Configure NuGet caching
  - Document NuGet cache location
  - Add .nuget folder to .gitignore if using local cache
  - Expected improvement: Faster subsequent builds and restores
  - **Do this SECOND** - speeds up all package operations
- [x] 1.3 Add in-memory database for tests
  - Add Microsoft.EntityFrameworkCore.InMemory package to test project
  - Create test fixture using InMemoryDatabase instead of PostgreSQL
  - Update test configuration to use in-memory provider
  - Expected improvement: 60-70% faster test execution
  - **Do this THIRD** - biggest impact on test speed
- [x] 1.4 Optimize test execution configuration
  - Reduce property-based test iterations from 100 to 50 for development
  - Configure tests to run in parallel with `dotnet test --parallel`
  - Expected improvement: 40-50% faster test runs
  - **Do this FOURTH** - works best after in-memory DB is set up
- [x] 1.5 Create build optimization script
  - Create PowerShell script that runs: `dotnet restore`, `dotnet build -m`, `dotnet test --parallel`
  - Add script to project root for one-command builds
  - Expected improvement: Streamlined workflow, 5-8 minute total execution time
  - **Do this LAST** - automates all previous optimizations