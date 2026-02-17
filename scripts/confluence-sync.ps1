# Helper: Get Confluence Auth
function Get-ConfluenceAuth {
    param([string]$Email, [string]$Token)
    $pair = "$Email`:$Token"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    return [System.Convert]::ToBase64String($bytes)
}

# Helper: Get Confluence Headers
function Get-ConfluenceHeaders {
    param([string]$Email, [string]$Token)
    return @{
        'Authorization' = "Basic $(Get-ConfluenceAuth -Email $Email -Token $Token)"
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
    }
}

# Validate Confluence configuration
function Test-ConfluenceConfig {
    param([string]$BaseUrl, [string]$Email, [string]$Token, [string]$SpaceKey)
    
    if (-not $BaseUrl -or -not $Email -or -not $Token) {
        Write-Host "ERROR: Missing Confluence credentials" -ForegroundColor Red
        Write-Host "  CONFLUENCE_BASE_URL: $([bool]$BaseUrl)" -ForegroundColor Yellow
        Write-Host "  CONFLUENCE_USER_EMAIL: $([bool]$Email)" -ForegroundColor Yellow
        Write-Host "  CONFLUENCE_API_TOKEN: $([bool]$Token)" -ForegroundColor Yellow
        return $false
    }
    
    if (-not $SpaceKey) {
        Write-Host "ERROR: Missing CONFLUENCE_SPACE_KEY" -ForegroundColor Red
        return $false
    }
    
    return $true
}

# Search for a page by title in a space
function Get-ConfluencePage {
    param(
        [string]$Title,
        [string]$BaseUrl = $env:CONFLUENCE_BASE_URL,
        [string]$Email = $env:CONFLUENCE_USER_EMAIL,
        [string]$Token = $env:CONFLUENCE_API_TOKEN,
        [string]$SpaceKey = $env:CONFLUENCE_SPACE_KEY
    )
    
    $headers = Get-ConfluenceHeaders -Email $Email -Token $Token
    $encodedTitle = [System.Uri]::EscapeDataString($Title)
    $uri = "$BaseUrl/wiki/rest/api/content?spaceKey=$SpaceKey&title=$encodedTitle&expand=body.storage"
    
    Write-Host "  Searching with URI: $uri" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        Write-Host "  Response keys: $($response.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray
        
        # Check for results property
        if ($response.PSObject.Properties.Name -contains 'results') {
            if ($response.results -and $response.results.Count -gt 0) {
                Write-Host "  Found $($response.results.Count) result(s)" -ForegroundColor Green
                return $response.results[0]
            }
            Write-Host "  No results found" -ForegroundColor Yellow
            return $null
        }
        
        # Check if response is a single page object
        if ($response.id) {
            Write-Host "  Found single page result" -ForegroundColor Green
            return $response
        }
        
        Write-Host "  Unexpected response format" -ForegroundColor Yellow
        return $null
    }
    catch {
        Write-Host "ERROR: Failed to search Confluence page: $_" -ForegroundColor Red
        Write-Host "  URI: $uri" -ForegroundColor Yellow
        Write-Host "  Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        return $null
    }
}

# Create a new page in Confluence
function New-ConfluencePage {
    param(
        [string]$Title,
        [string]$Content,
        [string]$ParentId = $null,
        [string]$BaseUrl = $env:CONFLUENCE_BASE_URL,
        [string]$Email = $env:CONFLUENCE_USER_EMAIL,
        [string]$Token = $env:CONFLUENCE_API_TOKEN,
        [string]$SpaceKey = $env:CONFLUENCE_SPACE_KEY
    )
    
    $headers = Get-ConfluenceHeaders -Email $Email -Token $Token
    
    $body = @{
        type = "page"
        title = $Title
        space = @{
            key = $SpaceKey
        }
        body = @{
            storage = @{
                value = $Content
                representation = "storage"
            }
        }
    }
    
    if ($ParentId) {
        $body.parent = @{
            type = "page"
            id = $ParentId
        }
    }
    
    $uri = "$BaseUrl/wiki/rest/api/content"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body ($body | ConvertTo-Json -Depth 10)
        return $response
    }
    catch {
        Write-Host "ERROR: Failed to create Confluence page: $_" -ForegroundColor Red
        Write-Host "  URI: $uri" -ForegroundColor Yellow
        Write-Host "  Response: $($_.Exception.Response)" -ForegroundColor Yellow
        return $null
    }
}

# Update an existing page in Confluence
function Update-ConfluencePage {
    param(
        [string]$PageId,
        [string]$Title,
        [string]$Content,
        [int]$VersionNumber,
        [string]$BaseUrl = $env:CONFLUENCE_BASE_URL,
        [string]$Email = $env:CONFLUENCE_USER_EMAIL,
        [string]$Token = $env:CONFLUENCE_API_TOKEN
    )
    
    $headers = Get-ConfluenceHeaders -Email $Email -Token $Token
    
    $body = @{
        id = $PageId
        type = "page"
        title = $Title
        version = @{
            number = $VersionNumber + 1
        }
        body = @{
            storage = @{
                value = $Content
                representation = "storage"
            }
        }
    }
    
    $uri = "$BaseUrl/wiki/rest/api/content/$PageId"
    $jsonBody = $body | ConvertTo-Json -Depth 10 -Compress
    
    # Ensure proper UTF-8 encoding
    $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
    
    Write-Host "  Sending update request..." -ForegroundColor Gray
    Write-Host "  Body size: $($utf8Bytes.Length) bytes" -ForegroundColor Gray
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $utf8Bytes -ContentType "application/json; charset=utf-8"
        Write-Host "  Update successful" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "ERROR: Failed to update Confluence page: $_" -ForegroundColor Red
        Write-Host "  URI: $uri" -ForegroundColor Yellow
        Write-Host "  Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        
        # Try to read error details
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorBody = $reader.ReadToEnd()
            Write-Host "  Error Details: $errorBody" -ForegroundColor Yellow
        } catch {
            Write-Host "  Could not read error details" -ForegroundColor Yellow
        }
        
        return $null
    }
}

# Append content to a page
function Append-ConfluencePage {
    param(
        [string]$PageId,
        [string]$ContentToAdd,
        [string]$BaseUrl = $env:CONFLUENCE_BASE_URL,
        [string]$Email = $env:CONFLUENCE_USER_EMAIL,
        [string]$Token = $env:CONFLUENCE_API_TOKEN
    )
    
    # Validate PageId
    if (-not $PageId) {
        Write-Host "ERROR: PageId is empty or null" -ForegroundColor Red
        return $null
    }
    
    Write-Host "  Appending to page ID: $PageId" -ForegroundColor Cyan
    
    # Get current page content by ID
    $uri = "$BaseUrl/wiki/rest/api/content/$PageId" + "?expand=body.storage,version"
    
    try {
        $headers = Get-ConfluenceHeaders -Email $Email -Token $Token
        Write-Host "  Getting page with URI: $uri" -ForegroundColor Gray
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        
        if (-not $response.id) {
            Write-Host "ERROR: Page not found for appending content" -ForegroundColor Red
            return $null
        }
        
        Write-Host "  Page title: $($response.title)" -ForegroundColor Green
        
        # Extract version number safely
        $versionNumber = $null
        if ($response.version -and $response.version.number) {
            $versionNumber = $response.version.number
        } elseif ($response.PSObject.Properties.Name -contains 'version') {
            $versionNumber = $response.version
        }
        
        Write-Host "  Current version: $versionNumber" -ForegroundColor Gray
        
        if (-not $versionNumber) {
            Write-Host "ERROR: Could not extract version number from response" -ForegroundColor Red
            Write-Host "  Response version property: $($response.version | ConvertTo-Json)" -ForegroundColor Yellow
            return $null
        }
        
        $currentContent = $response.body.storage.value
        $newContent = "$currentContent`n`n$ContentToAdd"
        
        return Update-ConfluencePage -PageId $PageId -Title $response.title -Content $newContent -VersionNumber $versionNumber
    }
    catch {
        Write-Host "ERROR: Failed to get page for appending content: $_" -ForegroundColor Red
        Write-Host "  URI: $uri" -ForegroundColor Yellow
        Write-Host "  Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        return $null
    }
}

# Get or create a page, then append content
function GetOrCreate-ConfluencePageAndAppend {
    param(
        [string]$Title,
        [string]$ContentToAdd,
        [string]$ParentId = $null,
        [string]$BaseUrl = $env:CONFLUENCE_BASE_URL,
        [string]$Email = $env:CONFLUENCE_USER_EMAIL,
        [string]$Token = $env:CONFLUENCE_API_TOKEN,
        [string]$SpaceKey = $env:CONFLUENCE_SPACE_KEY
    )
    
    # Try to find existing page
    $existingPage = Get-ConfluencePage -Title $Title -BaseUrl $BaseUrl -Email $Email -Token $Token -SpaceKey $SpaceKey
    
    if ($existingPage) {
        Write-Host "Found existing page: $($existingPage.title) (ID: $($existingPage.id))" -ForegroundColor Green
        
        # Append to existing page
        $appendResult = Append-ConfluencePage -PageId $existingPage.id -ContentToAdd $ContentToAdd -BaseUrl $BaseUrl -Email $Email -Token $Token
        return $appendResult
    }
    else {
        Write-Host "Creating new page: $Title" -ForegroundColor Cyan
        return New-ConfluencePage -Title $Title -Content $ContentToAdd -ParentId $ParentId -BaseUrl $BaseUrl -Email $Email -Token $Token -SpaceKey $SpaceKey
    }
}