# DataLoaderService Design

## Architecture

### Layers
- **API Layer**: REST endpoints for file upload and data access
- **Application Layer**: Commands and queries for file processing
- **Domain Layer**: File, Data, Column entities
- **Infrastructure Layer**: Database access, file storage, CSV parsing

### Database Schema
- **Database**: SQL Server
- **Schema**: `DataLoader`
- **Tables**: Files, FileColumns, FileData, ProcessingLogs

## API Endpoints

### File Upload
- `POST /api/v1/files/upload` - Upload CSV file
- `GET /api/v1/files/{id}/status` - Get upload status

### File Management
- `GET /api/v1/files` - List all files
- `GET /api/v1/files/{id}` - Get file details
- `GET /api/v1/files/{id}/preview` - Preview file contents
- `DELETE /api/v1/files/{id}` - Delete file
- `GET /api/v1/files/{id}/download` - Download file

### Data Access
- `GET /api/v1/files/{id}/data` - Query file data
- `GET /api/v1/files/{id}/data/export` - Export data
- `GET /api/v1/files/{id}/columns` - Get column information

## Data Models

### File
```
- Id: Guid
- UserId: Guid
- FileName: string
- FileSize: long
- RowCount: int
- ColumnCount: int
- Status: string (Uploading, Processing, Ready, Failed)
- UploadDate: DateTime
- ProcessingDate: DateTime?
- ErrorMessage: string?
- Delimiter: string
- HasHeader: bool
```

### FileColumn
```
- Id: Guid
- FileId: Guid
- ColumnName: string
- ColumnIndex: int
- DataType: string (string, int, decimal, datetime, bool)
- IsNullable: bool
- SampleValues: string[]
```

### FileData
```
- Id: Guid
- FileId: Guid
- RowNumber: int
- Data: Dictionary<string, object>
```

### ProcessingLog
```
- Id: Guid
- FileId: Guid
- Status: string
- Message: string
- StartTime: DateTime
- EndTime: DateTime?
- ErrorMessage: string?
```

## File Processing Flow

1. User uploads CSV file
2. System validates file (size, type, format)
3. System stores file temporarily
4. System queues file for processing
5. Background worker processes file:
   - Detects delimiter
   - Detects header row
   - Infers column types
   - Validates data
   - Stores in database
6. System notifies user of completion
7. User can access data via API

## CSV Parsing Strategy

1. Read file in chunks (1 MB at a time)
2. Detect delimiter (comma, semicolon, tab)
3. Detect header row (first row)
4. Parse each row
5. Infer column data types from sample rows
6. Validate data against inferred types
7. Store in database

## Data Validation

- Required fields: Check for empty values
- Data types: Validate against inferred type
- Constraints: Check min/max values
- Duplicates: Detect duplicate rows
- PII: Flag potential PII (email, phone, SSN)

## Security Considerations

- All files encrypted at rest (AES-256)
- User isolation enforced at database level
- PII detection and flagging
- All file access logged
- Temporary files deleted after processing
- File retention: 30 days (configurable)

## Testing Strategy

### Unit Tests
- CSV parsing for various formats
- Data type inference
- Data validation rules
- Error handling

### Integration Tests
- File upload endpoint
- File processing pipeline
- Data query endpoint
- File deletion

### Property-Based Tests
- Uploaded data matches parsed data
- Data validation is consistent
- Re-uploading same file produces same result

## Deployment

- Docker container with .NET 9.0
- SQL Server database
- File storage (local or cloud)
- Background processing service
- Health check endpoints
- Monitoring and alerting

## Performance Targets

- File upload: < 2 minutes for 50 MB
- CSV parsing: < 5 minutes for 100,000 rows
- Data query: < 1 second for 10,000 rows
- API response: < 500ms
- 1,000+ concurrent uploads
- 99.9% uptime
