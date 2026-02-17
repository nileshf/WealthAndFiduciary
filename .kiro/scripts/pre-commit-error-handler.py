#!/usr/bin/env python3
"""
Pre-commit error handler using MCP tools
Searches Confluence and local error database for build errors
"""

import sys
import json
import subprocess
from pathlib import Path

# Confluence configuration
CONFLUENCE_PAGE_URL = "https://nileshf.atlassian.net/wiki/spaces/WEALTHFID/pages/9175041"
LOCAL_ERROR_DB = ".kiro/post-mortems/confluence-pre-commit-errors.md"

def search_confluence(error_code):
    """Search Confluence for similar errors using MCP"""
    try:
        # Use MCP to search Confluence
        result = subprocess.run([
            "mcp", "call", "mcp_mcp_atlassian_confluence_search",
            "--query", f"{error_code} Pre-Commit",
            "--limit", "5"
        ], capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            return json.loads(result.stdout)
        return None
    except Exception as e:
        print(f"Could not search Confluence: {e}")
        return None

def search_local_db(error_code):
    """Search local error database for error"""
    local_db_path = Path(LOCAL_ERROR_DB)
    
    if not local_db_path.exists():
        return None
    
    content = local_db_path.read_text()
    
    # Look for error section
    search_pattern = f"## {error_code} -"
    if search_pattern in content:
        # Extract the error section
        lines = content.split('\n')
        in_section = False
        error_lines = []
        
        for line in lines:
            if line.startswith(f"## {error_code} -"):
                in_section = True
            
            if in_section:
                if line.startswith("## ") and not line.startswith(f"## {error_code} -"):
                    break
                error_lines.append(line)
        
        return '\n'.join(error_lines)
    
    return None

def get_kiro_fix_suggestion(error_code):
    """Get Kiro's fix suggestion for common errors"""
    fixes = {
        "CS0161": {
            "title": "Not all code paths return a value",
            "root_cause": "A non-void method is missing a return statement for one or more code paths.",
            "fix": "Add a return statement for all code paths.",
            "example_before": """public string GetName()
{
    if (condition)
    {
        return "value";
    }
    // Missing return for else case
}""",
            "example_after": """public string GetName()
{
    if (condition)
    {
        return "value";
    }
    return "default";  // Add default return
}"""
        },
        "CS1061": {
            "title": "Type does not contain a definition",
            "root_cause": "Trying to access a property or method that doesn't exist on a type.",
            "fix": "Check the type definition and use the correct member name.",
            "example_before": """var user = new User();
var name = user.Nmae;  // Typo: should be Name""",
            "example_after": """var user = new User();
var name = user.Name;  // Fixed typo"""
        },
        "CS0246": {
            "title": "Type or namespace not found",
            "root_cause": "Missing using directive or assembly reference.",
            "fix": "Add the missing using directive at the top of the file.",
            "example_before": """public class MyClass
{
    private ILogger _logger;  // Missing using directive
}""",
            "example_after": """using Microsoft.Extensions.Logging;
public class MyClass
{
    private ILogger _logger;
}"""
        },
        "CS0103": {
            "title": "Name does not exist in current context",
            "root_cause": "Using a variable, method, or class that hasn't been defined.",
            "fix": "Define the identifier or check for typos.",
            "example_before": """public void MyMethod()
{
    var result = CalculateSum(1, 2);  // CalculateSum doesn't exist
}""",
            "example_after": """public void MyMethod()
{
    var result = Add(1, 2);  // Fixed method name
}

private int Add(int a, int b)
{
    return a + b;
}"""
        }
    }
    
    return fixes.get(error_code)

def update_local_db(error_code, error_details, service_name, file_path, line_number):
    """Update local error database with new error"""
    local_db_path = Path(LOCAL_ERROR_DB)
    
    # Check if error already exists
    if search_local_db(error_code):
        # Error exists, just update with new info
        return False  # Not a new error
    
    # Create new entry
    entry = f"""
## {error_code} - {error_details.get('title', 'Build Error')}

**Error Message**: {error_details.get('message', 'Build error occurred')}

**Service**: {service_name}

**File**: {file_path}

**Line**: {line_number}

**Date**: {error_details.get('date', 'Unknown')}

**Root Cause**: {error_details.get('root_cause', 'Unknown')}

**Quick Fix**: {error_details.get('fix', 'Investigate the error')}

**Code Example**:

```csharp
// BEFORE (broken):
{error_details.get('example_before', 'N/A')}
```

```csharp
// AFTER (fixed):
{error_details.get('example_after', 'N/A')}
```

**Prevention**: Run 'dotnet build' before committing to catch errors early.

---
"""
    
    # Append to local DB
    if local_db_path.exists():
        content = local_db_path.read_text()
        content += entry
        local_db_path.write_text(content)
    else:
        local_db_path.write_text("# Pre-Commit Build Errors - Confluence Reference\n\n" + entry)
    
    return True  # New error added

def update_confluence(error_code, error_details):
    """Update Confluence page with new error"""
    # This would use MCP to update Confluence
    # For now, just print instructions
    print(f"\nTo update Confluence:")
    print(f"1. Visit: {CONFLUENCE_PAGE_URL}")
    print(f"2. Add a new section for {error_code}")
    print(f"3. Include: {error_details}")

def main():
    if len(sys.argv) < 2:
        print("Usage: pre-commit-error-handler.py <error_code> [service_name] [file_path] [line_number]")
        sys.exit(1)
    
    error_code = sys.argv[1]
    service_name = sys.argv[2] if len(sys.argv) > 2 else "Unknown"
    file_path = sys.argv[3] if len(sys.argv) > 3 else "Unknown"
    line_number = sys.argv[4] if len(sys.argv) > 4 else "Unknown"
    
    print("=" * 60)
    print("Build Error Handler")
    print("=" * 60)
    print()
    
    # Search local DB first
    print("=" * 60)
    print(f"Searching for error: {error_code}")
    print("=" * 60)
    print()
    
    local_error = search_local_db(error_code)
    if local_error:
        print("Found in Local Error Database:")
        print("-" * 40)
        print(local_error)
        print()
    else:
        print(f"Error {error_code} not found in local database.")
        print()
    
    # Get Kiro's fix suggestion
    print("=" * 60)
    print("Kiro's Fix Suggestion")
    print("=" * 60)
    print()
    
    kiro_fix = get_kiro_fix_suggestion(error_code)
    if kiro_fix:
        print(f"Error: {error_code} - {kiro_fix['title']}")
        print()
        print("Root Cause:")
        print(f"  {kiro_fix['root_cause']}")
        print()
        print("Quick Fix:")
        print(f"  {kiro_fix['fix']}")
        print()
        print("Code Example:")
        print()
        print("  // BEFORE (broken):")
        print(kiro_fix['example_before'])
        print()
        print("  // AFTER (fixed):")
        print(kiro_fix['example_after'])
        print()
    else:
        print(f"Error: {error_code}")
        print()
        print("Kiro's Analysis:")
        print("  This is a build error that requires investigation.")
        print()
        print("Suggested Steps:")
        print("  1. Check the full error message in the build output")
        print("  2. Search Confluence for the error code")
        print("  3. Check the local error database")
        print()
    
    # Search Confluence
    print("=" * 60)
    print("Confluence Search Results")
    print("=" * 60)
    print()
    
    confluence_results = search_confluence(error_code)
    if confluence_results and confluence_results.get('results'):
        print("Found similar errors on Confluence:")
        print()
        for result in confluence_results['results']:
            print(f"Title: {result.get('title', 'N/A')}")
            print(f"URL: https://nileshf.atlassian.net/wiki{result.get('_links', {}).get('webui', '')}")
            print()
    else:
        print("No similar errors found on Confluence.")
        print()
        print(f"You can create a new Confluence page at:")
        print(f"{CONFLUENCE_PAGE_URL}")
        print()
    
    # Error location
    print("=" * 60)
    print("Error Location")
    print("=" * 60)
    print()
    print(f"Service: {service_name}")
    print(f"File: {file_path}")
    print(f"Line: {line_number}")
    print()
    
    # Next steps
    print("=" * 60)
    print("Next Steps")
    print("=" * 60)
    print()
    print("1. Review the error details above")
    print("2. Apply the suggested fix to your code")
    print("3. Run 'dotnet build' to verify the fix")
    print("4. Commit and push your changes")
    print()

if __name__ == "__main__":
    main()
