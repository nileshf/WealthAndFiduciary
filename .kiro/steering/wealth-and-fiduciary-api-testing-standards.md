# BUSINESS UNIT API TESTING STANDARDS

> **Scope**: All microservices in the business unit
> **Precedence**: Service-specific API testing standards override these when conflicts exist

## 🎯 API TESTING PHILOSOPHY (MANDATORY)

All microservices MUST provide API testing collections for both Postman and Bruno to enable:
- Manual API testing during development
- Automated API testing in CI/CD pipelines
- API documentation through examples
- Onboarding for new developers

## 📁 PROJECT STRUCTURE (MANDATORY)

```
[ServiceName]/
├── API/
│   └── Controllers/
├── Postman/
│   ├── [ServiceName].postman_collection.json
│   ├── Development.postman_environment.json
│   ├── Staging.postman_environment.json
│   ├── Production.postman_environment.json
│   └── README.md
├── Bruno/
│   ├── [ServiceName]/
│   │   ├── bruno.json
│   │   ├── collection.bru
│   │   ├── environments/
│   │   │   ├── Development.bru
│   │   │   ├── Staging.bru
│   │   │   └── Production.bru
│   │   ├── Authentication/
│   │   │   ├── Login.bru
│   │   │   └── Refresh Token.bru
│   │   ├── [Resource]/
│   │   │   ├── Create [Resource].bru
│   │   │   ├── Get [Resource] by ID.bru
│   │   │   ├── Get All [Resources].bru
│   │   │   ├── Update [Resource].bru
│   │   │   └── Delete [Resource].bru
│   │   └── README.md
│   └── README.md
└── README.md
```

## 📋 POSTMAN STANDARDS (MANDATORY)

### Collection Structure

**Folder Organization:**
```
[ServiceName] Collection
├── Authentication
│   ├── Login
│   ├── Refresh Token
│   └── Logout
├── [Resource 1]
│   ├── Create [Resource]
│   ├── Get [Resource] by ID
│   ├── Get All [Resources]
│   ├── Update [Resource]
│   └── Delete [Resource]
├── [Resource 2]
│   └── ...
└── Health Checks
    ├── Health
    ├── Ready
    └── Live
```

### Collection Variables

**Required Variables:**
- `baseUrl` - API base URL (e.g., `https://localhost:5001`)
- `apiVersion` - API version (e.g., `v1`)
- `accessToken` - JWT access token (set by login request)
- `refreshToken` - JWT refresh token (set by login request)
- `tenantId` - Current tenant ID (for multi-tenant services)

### Pre-request Scripts

**Authentication Token Management:**
```javascript
// Check if token exists and is not expired
const token = pm.collectionVariables.get("accessToken");
const tokenExpiry = pm.collectionVariables.get("tokenExpiry");

if (!token || !tokenExpiry || Date.now() > tokenExpiry) {
    // Token expired or missing, refresh it
    pm.sendRequest({
        url: pm.collectionVariables.get("baseUrl") + "/api/v1/auth/refresh",
        method: 'POST',
        header: {
            'Content-Type': 'application/json'
        },
        body: {
            mode: 'raw',
            raw: JSON.stringify({
                refreshToken: pm.collectionVariables.get("refreshToken")
            })
        }
    }, function (err, response) {
        if (!err && response.code === 200) {
            const data = response.json();
            pm.collectionVariables.set("accessToken", data.accessToken);
            pm.collectionVariables.set("tokenExpiry", Date.now() + (data.expiresIn * 1000));
        }
    });
}
```

### Test Scripts

**Standard Response Tests:**
```javascript
// Test: Status code is 200
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

// Test: Response time is less than 500ms
pm.test("Response time is less than 500ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(500);
});

// Test: Response has required fields
pm.test("Response has required fields", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('id');
    pm.expect(jsonData).to.have.property('name');
});

// Test: Save ID for subsequent requests
pm.test("Save resource ID", function () {
    const jsonData = pm.response.json();
    pm.collectionVariables.set("resourceId", jsonData.id);
});
```

### Environment Files

**Development Environment:**
```json
{
  "name": "Development",
  "values": [
    {
      "key": "baseUrl",
      "value": "https://localhost:5001",
      "enabled": true
    },
    {
      "key": "apiVersion",
      "value": "v1",
      "enabled": true
    },
    {
      "key": "tenantSubdomain",
      "value": "dev-tenant",
      "enabled": true
    }
  ]
}
```

**Staging Environment:**
```json
{
  "name": "Staging",
  "values": [
    {
      "key": "baseUrl",
      "value": "https://staging-api.example.com",
      "enabled": true
    },
    {
      "key": "apiVersion",
      "value": "v1",
      "enabled": true
    },
    {
      "key": "tenantSubdomain",
      "value": "staging-tenant",
      "enabled": true
    }
  ]
}
```

**Production Environment:**
```json
{
  "name": "Production",
  "values": [
    {
      "key": "baseUrl",
      "value": "https://api.example.com",
      "enabled": true
    },
    {
      "key": "apiVersion",
      "value": "v1",
      "enabled": true
    },
    {
      "key": "tenantSubdomain",
      "value": "prod-tenant",
      "enabled": true
    }
  ]
}
```

## 📋 BRUNO STANDARDS (MANDATORY)

### Collection Structure

**bruno.json:**
```json
{
  "version": "1",
  "name": "[ServiceName]",
  "type": "collection"
}
```

**collection.bru:**
```
meta {
  name: [ServiceName] API
  type: collection
}

headers {
  Content-Type: application/json
  Accept: application/json
}

auth {
  mode: bearer
}

auth:bearer {
  token: {{accessToken}}
}

script:pre-request {
  // Auto-refresh token if expired
  const tokenExpiry = bru.getEnvVar("tokenExpiry");
  if (!tokenExpiry || Date.now() > tokenExpiry) {
    // Refresh token logic
  }
}
```

### Request File Format

**Example: Create Resource.bru**
```
meta {
  name: Create Resource
  type: http
  seq: 1
}

post {
  url: {{baseUrl}}/api/{{apiVersion}}/resources
  body: json
  auth: bearer
}

auth:bearer {
  token: {{accessToken}}
}

body:json {
  {
    "name": "Test Resource",
    "description": "Created via Bruno",
    "value": 100
  }
}

assert {
  res.status: eq 201
  res.body.id: isDefined
  res.body.name: eq "Test Resource"
}

script:post-response {
  if (res.status === 201) {
    bru.setEnvVar("resourceId", res.body.id);
  }
}

docs {
  Creates a new resource in the system.
  
  **Required Fields:**
  - name: Resource name (string, 1-100 characters)
  - description: Resource description (string, optional)
  - value: Numeric value (number, optional)
  
  **Returns:**
  - 201 Created: Resource created successfully
  - 400 Bad Request: Validation error
  - 401 Unauthorized: Missing or invalid token
  - 403 Forbidden: Insufficient permissions
}
```

### Environment Files

**Development.bru:**
```
vars {
  baseUrl: https://localhost:5001
  apiVersion: v1
  tenantSubdomain: dev-tenant
}

vars:secret [
  accessToken,
  refreshToken
]
```

**Staging.bru:**
```
vars {
  baseUrl: https://staging-api.example.com
  apiVersion: v1
  tenantSubdomain: staging-tenant
}

vars:secret [
  accessToken,
  refreshToken
]
```

**Production.bru:**
```
vars {
  baseUrl: https://api.example.com
  apiVersion: v1
  tenantSubdomain: prod-tenant
}

vars:secret [
  accessToken,
  refreshToken
]
```

## 📝 REQUEST DOCUMENTATION (MANDATORY)

### Request Naming Convention

**Pattern:** `[HTTP Method] [Resource] [Optional: by ID/Action]`

**Examples:**
- `POST Create User`
- `GET User by ID`
- `GET All Users`
- `PUT Update User`
- `DELETE User`
- `POST Trigger Verification`
- `POST Approve Entity`

### Request Description

**Required Information:**
- Purpose of the request
- Required fields and their types
- Optional fields and their defaults
- Expected response codes
- Example request body
- Example response body

**Example:**
```markdown
## Create User

Creates a new user in the system.

**Required Fields:**
- email: Valid email address (string)
- password: Password meeting complexity requirements (string, min 12 chars)
- role: User role (string: "Agent" or "Manager")

**Optional Fields:**
- firstName: User's first name (string)
- lastName: User's last name (string)

**Response Codes:**
- 201 Created: User created successfully
- 400 Bad Request: Validation error
- 401 Unauthorized: Missing or invalid token
- 403 Forbidden: Insufficient permissions
- 409 Conflict: Email already exists

**Example Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "role": "Agent",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Example Response:**
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "email": "user@example.com",
  "role": "Agent",
  "firstName": "John",
  "lastName": "Doe",
  "createdDate": "2025-01-15T10:30:00Z"
}
```
```

## 🧪 AUTOMATED TESTING (MANDATORY)

### Newman (Postman CLI)

**Run Collection:**
```bash
# Install Newman
npm install -g newman

# Run collection with environment
newman run Postman/[ServiceName].postman_collection.json \
  -e Postman/Development.postman_environment.json \
  --reporters cli,json,html \
  --reporter-html-export newman-report.html
```

**CI/CD Integration:**
```yaml
# GitHub Actions example
- name: Run Postman Tests
  run: |
    npm install -g newman
    newman run Postman/[ServiceName].postman_collection.json \
      -e Postman/Development.postman_environment.json \
      --reporters cli,junit \
      --reporter-junit-export test-results.xml
```

### Bruno CLI

**Run Collection:**
```bash
# Install Bruno CLI
npm install -g @usebruno/cli

# Run collection
bru run Bruno/[ServiceName] --env Development
```

**CI/CD Integration:**
```yaml
# GitHub Actions example
- name: Run Bruno Tests
  run: |
    npm install -g @usebruno/cli
    bru run Bruno/[ServiceName] --env Development --output bruno-results.json
```

## 📚 README FILES (MANDATORY)

### Postman/README.md

```markdown
# [ServiceName] Postman Collection

## Overview

This folder contains Postman collections and environments for testing the [ServiceName] API.

## Files

- `[ServiceName].postman_collection.json` - Main API collection
- `Development.postman_environment.json` - Development environment
- `Staging.postman_environment.json` - Staging environment
- `Production.postman_environment.json` - Production environment

## Setup

1. Install Postman: https://www.postman.com/downloads/
2. Import collection: File → Import → Select `[ServiceName].postman_collection.json`
3. Import environment: File → Import → Select environment file
4. Select environment from dropdown in top-right corner

## Usage

### Authentication

1. Run `Authentication → Login` request
2. Access token will be automatically saved to collection variables
3. All subsequent requests will use this token

### Testing Workflow

1. **Create Resource**: Run `[Resource] → Create [Resource]`
2. **Get Resource**: Run `[Resource] → Get [Resource] by ID`
3. **Update Resource**: Run `[Resource] → Update [Resource]`
4. **Delete Resource**: Run `[Resource] → Delete [Resource]`

## Running Tests

### Manual Testing
- Click "Run" button in collection
- Select environment
- Click "Run [ServiceName]"

### Automated Testing (Newman)
```bash
newman run [ServiceName].postman_collection.json \
  -e Development.postman_environment.json
```

## Troubleshooting

**Issue**: 401 Unauthorized
- **Solution**: Run `Authentication → Login` to get new token

**Issue**: 404 Not Found
- **Solution**: Verify `baseUrl` in environment matches running API

**Issue**: Token expired
- **Solution**: Token auto-refreshes, but you can manually run `Authentication → Refresh Token`
```

### Bruno/README.md

```markdown
# [ServiceName] Bruno Collection

## Overview

This folder contains Bruno collections and environments for testing the [ServiceName] API.

## Files

- `[ServiceName]/` - Main collection folder
  - `bruno.json` - Collection metadata
  - `collection.bru` - Collection settings
  - `environments/` - Environment files
  - `Authentication/` - Auth requests
  - `[Resource]/` - Resource requests

## Setup

1. Install Bruno: https://www.usebruno.com/downloads
2. Open Bruno
3. Click "Open Collection"
4. Select `Bruno/[ServiceName]` folder
5. Select environment from dropdown

## Usage

### Authentication

1. Run `Authentication → Login`
2. Access token will be automatically saved to environment
3. All subsequent requests will use this token

### Testing Workflow

1. **Create Resource**: Run `[Resource] → Create [Resource]`
2. **Get Resource**: Run `[Resource] → Get [Resource] by ID`
3. **Update Resource**: Run `[Resource] → Update [Resource]`
4. **Delete Resource**: Run `[Resource] → Delete [Resource]`

## Running Tests

### Manual Testing
- Click request in sidebar
- Click "Send" button
- View response in right panel

### Automated Testing (Bruno CLI)
```bash
bru run [ServiceName] --env Development
```

## Troubleshooting

**Issue**: 401 Unauthorized
- **Solution**: Run `Authentication → Login` to get new token

**Issue**: 404 Not Found
- **Solution**: Verify `baseUrl` in environment matches running API

**Issue**: Token expired
- **Solution**: Token auto-refreshes, but you can manually run `Authentication → Refresh Token`
```

## 🎓 BEST PRACTICES

### Do's
- ✅ Keep collections in sync with API changes
- ✅ Use environment variables for all URLs and tokens
- ✅ Add tests to all requests
- ✅ Document all requests with examples
- ✅ Use pre-request scripts for authentication
- ✅ Save response data to variables for chaining requests
- ✅ Version control collections and environments

### Don'ts
- ❌ Don't hardcode URLs or tokens in requests
- ❌ Don't commit secrets to version control
- ❌ Don't skip request documentation
- ❌ Don't create duplicate requests
- ❌ Don't ignore test failures

## 📊 MAINTENANCE

### When to Update Collections

**API Changes:**
- New endpoints added
- Existing endpoints modified
- Request/response formats changed
- Authentication flow changed

**Environment Changes:**
- New environment added (e.g., QA)
- Base URLs changed
- API version updated

### Review Frequency

- **Weekly**: Review and update during sprint
- **Monthly**: Full collection audit
- **Release**: Verify all requests work before release

---

**Note**: Service-specific API testing standards can extend these standards but should not contradict them.

ALWAYS provide Postman and Bruno collections for ALL microservices.
