# Requirements Document

## Introduction

DataLoaderService is a CSV file processing microservice for the AITooling application within the WealthAndFiduciary business unit. This service provides secure file upload capabilities with JWT authentication, CSV parsing, and data storage. The service accepts CSV files, parses them into data records, and stores them in a SQL Server database.

## Glossary

- **System**: The DataLoaderService microservice
- **User**: An authenticated user uploading CSV files
- **Data_Record**: A parsed row from a CSV file containing Name, Value, and CreatedAt fields
- **CSV_File**: A comma-separated values file uploaded by the user

## Requirements

### Requirement 1: Authenticated File Upload

**User Story:** As an authenticated user, I want to upload CSV files, so that I can import data into the system.

#### Acceptance Criteria

1. WHEN a user uploads a file, THE System SHALL require JWT authentication
2. WHEN an unauthenticated user attempts upload, THE System SHALL return 401 Unauthorized
3. WHEN a file is uploaded, THE System SHALL accept IFormFile from multipart/form-data
4. WHEN no file is provided, THE System SHALL return 400 Bad Request with message "No file uploaded"
5. WHEN an empty file is provided, THE System SHALL return 400 Bad Request with message "No file uploaded"
6. WHEN a file is successfully uploaded, THE System SHALL return 200 OK with record count

### Requirement 2: CSV File Parsing

**User Story:** As a user, I want my CSV files parsed automatically, so that data is extracted and stored.

#### Acceptance Criteria

1. WHEN a CSV file is uploaded, THE System SHALL parse it using CsvHelper library
2. WHEN parsing CSV, THE System SHALL use InvariantCulture for consistent parsing
3. WHEN parsing CSV, THE System SHALL expect columns: Name and Value
4. WHEN a CSV row is parsed, THE System SHALL create a DataRecord with Name, Value, and CreatedAt
5. WHEN CreatedAt is set, THE System SHALL use UTC timestamp
6. WHEN all rows are parsed, THE System SHALL return the total count of records loaded

### Requirement 3: Data Storage

**User Story:** As a system administrator, I want uploaded data persisted to SQL Server, so that data is durable and queryable.

#### Acceptance Criteria

1. THE System SHALL store DataRecord entities in SQL Server database
2. WHEN records are saved, THE System SHALL use Entity Framework Core
3. WHEN multiple records are parsed, THE System SHALL save them in a single batch using AddRangeAsync
4. THE System SHALL use DataDbContext for database operations
5. THE System SHALL use DataRepository for data access
6. THE System SHALL support database migrations for schema management

### Requirement 4: Data Retrieval

**User Story:** As an authenticated user, I want to retrieve all uploaded data, so that I can view what has been imported.

#### Acceptance Criteria

1. WHEN a user requests all data, THE System SHALL require JWT authentication
2. WHEN an authenticated user requests data, THE System SHALL return all DataRecord entities
3. WHEN data is retrieved, THE System SHALL return records with Id, Name, Value, and CreatedAt
4. WHEN no data exists, THE System SHALL return an empty array
5. THE System SHALL expose GET /api/data endpoint for data retrieval

### Requirement 5: Data Model

**User Story:** As a developer, I want a simple data model, so that CSV data is stored consistently.

#### Acceptance Criteria

1. THE System SHALL store record ID as an integer
2. THE System SHALL store Name as a string
3. THE System SHALL store Value as a string
4. THE System SHALL store CreatedAt as a DateTime
5. THE System SHALL persist DataRecord entities to SQL Server database

### Requirement 6: API Endpoints

**User Story:** As a client application, I want RESTful API endpoints, so that I can integrate file upload into my application.

#### Acceptance Criteria

1. THE System SHALL expose POST /api/data/upload endpoint for file upload
2. THE System SHALL expose GET /api/data endpoint for data retrieval
3. WHEN /api/data/upload is called, THE System SHALL accept multipart/form-data with file
4. WHEN upload succeeds, THE System SHALL return 200 OK with message and count
5. WHEN data retrieval succeeds, THE System SHALL return 200 OK with array of records
6. THE System SHALL require [Authorize] attribute on all endpoints

### Requirement 7: JWT Authentication Integration

**User Story:** As a security officer, I want JWT authentication enforced, so that only authorized users can upload files.

#### Acceptance Criteria

1. THE System SHALL configure JWT Bearer authentication
2. THE System SHALL validate token issuer, audience, lifetime, and signing key
3. WHEN a request includes a valid JWT token, THE System SHALL authenticate the request
4. WHEN a request includes an invalid JWT token, THE System SHALL reject the request
5. WHEN a request includes an expired JWT token, THE System SHALL reject the request
6. THE System SHALL use the same JWT configuration as SecurityService

### Requirement 8: Database Integration

**User Story:** As a system administrator, I want data persisted to SQL Server, so that uploaded data is durable.

#### Acceptance Criteria

1. THE System SHALL use Entity Framework Core for database access
2. THE System SHALL connect to SQL Server using configured connection string
3. THE System SHALL use DataDbContext for database operations
4. THE System SHALL use DataRepository for data access
5. THE System SHALL support database migrations for schema management

### Requirement 9: Swagger Documentation

**User Story:** As a developer, I want API documentation, so that I can understand how to use the file upload endpoints.

#### Acceptance Criteria

1. THE System SHALL expose Swagger UI in development environment
2. THE System SHALL document all API endpoints with Swagger
3. THE System SHALL include request/response schemas in Swagger documentation
4. WHEN Swagger UI is accessed, THE System SHALL display all available endpoints

### Requirement 10: Dependency Injection

**User Story:** As a developer, I want proper dependency injection, so that services are loosely coupled and testable.

#### Acceptance Criteria

1. THE System SHALL register FileLoaderService as scoped service
2. THE System SHALL register IDataRepository as scoped service
3. THE System SHALL register DataRepository as implementation of IDataRepository
4. THE System SHALL inject dependencies via constructor injection
5. THE System SHALL use built-in ASP.NET Core DI container

### Requirement 11: Error Handling

**User Story:** As a developer, I want consistent error responses, so that I can handle errors appropriately in client applications.

#### Acceptance Criteria

1. WHEN no file is uploaded, THE System SHALL return 400 Bad Request
2. WHEN authentication fails, THE System SHALL return 401 Unauthorized
3. WHEN an internal error occurs during parsing, THE System SHALL return 500 Internal Server Error
4. WHEN CSV parsing fails, THE System SHALL return appropriate error message
5. THE System SHALL not expose sensitive error details to clients

### Requirement 12: CSV Format Requirements

**User Story:** As a user, I want to know the expected CSV format, so that I can prepare my files correctly.

#### Acceptance Criteria

1. THE System SHALL expect CSV files with headers: Name, Value
2. THE System SHALL parse CSV using comma as delimiter
3. THE System SHALL support standard CSV escaping rules
4. WHEN CSV has additional columns, THE System SHALL ignore them
5. WHEN CSV is missing required columns, THE System SHALL fail with appropriate error
