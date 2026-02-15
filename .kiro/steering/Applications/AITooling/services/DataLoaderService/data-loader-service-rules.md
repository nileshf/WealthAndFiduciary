# DataLoaderService Business Rules

> **Scope**: DataLoaderService only
> **Level**: Service-level (Level 3)
> **Precedence**: HIGHEST - overrides application and business unit when conflicts exist

## 🎯 Overview

DataLoaderService is the data ingestion and processing service for the AITooling application. This service handles CSV file uploads, data validation, parsing, and storage for AI/ML workflows.

## 📄 Supported File Types

### CSV Files
- **Format**: `.csv` (comma-separated values)
- **Encoding**: UTF-8, UTF-16, ASCII
- **Delimiter**: Comma (`,`), semicolon (`;`), tab (`\t`)
- **Quote Character**: Double quote (`"`)
- **Escape Character**: Backslash (`\`)

## 📏 File Size Limits

### Size Constraints
- **Maximum File Size**: 50 MB per file
- **Maximum Row Count**: 100,000 rows per file
- **Maximum Column Count**: 100 columns per file

### Timeout Limits
- **Upload Timeout**: 2 minutes
- **Processing Timeout**: 5 minutes per file

## 🔐 Security Rules

### File Validation
- **File Type Validation**: Validate file extension and MIME type
- **Content Validation**: Validate CSV structure and format
- **Malicious Content**: Reject files with scripts or macros
- **Size Validation**: Enforce file size limits

### Data Protection
- **PII Detection**: Detect and flag PII in uploaded data
- **Data Encryption**: All uploaded files encrypted at rest (AES-256)
- **Temporary Storage**: Files deleted after processing (configurable retention)

### Access Control
- **User Isolation**: Users can only access their own data
- **Audit Logging**: All file uploads and data access logged

## 📊 Processing Pipeline

### Upload Flow
1. **Upload**: User uploads CSV file via API
2. **Validate**: Validate file size, type, and format
3. **Parse**: Parse CSV content and extract data
4. **Validate Data**: Validate data types and constraints
5. **Store**: Store data in database
6. **Notify**: Notify user of completion

### CSV Parsing
- **Header Detection**: Auto-detect header row
- **Type Inference**: Infer column data types
- **Null Handling**: Handle empty cells and null values
- **Error Handling**: Report parsing errors with line numbers

### Data Validation
- **Required Fields**: Validate required columns are present
- **Data Types**: Validate data types match schema
- **Constraints**: Validate data constraints (min, max, regex)
- **Duplicates**: Detect and handle duplicate rows

## 📦 Storage Rules

### Database Schema
- **Schema Name**: `DataLoader`
- **Rationale**: Clear separation from other services

### Data Storage
- **Database**: PostgreSQL (per application standards)
- **Table Structure**: Dynamic tables based on CSV structure
- **Indexing**: Auto-create indexes on key columns
- **Partitioning**: Partition large tables by date

### Metadata Storage
- **File Metadata**: Name, size, upload date, user ID, row count
- **Column Metadata**: Name, data type, nullable, constraints
- **Processing Metadata**: Status, start time, end time, errors

## 🔄 Processing Queue

### Queue Configuration
- **Queue**: In-memory queue for small files, Azure Service Bus for large files
- **Priority Levels**: High, Normal, Low
- **Retry Policy**: 3 retries with exponential backoff
- **Dead Letter Queue**: Failed files moved to DLQ after 3 retries

### Processing Workers
- **Worker Count**: 2 concurrent workers
- **Worker Type**: Background service
- **Concurrency**: 1 file processed per worker at a time

## 🧪 Testing Requirements

### Unit Testing
- **CSV Parsing**: Test parsing for various CSV formats
- **Data Validation**: Test validation rules
- **Error Handling**: Test error scenarios

### Integration Testing
- **End-to-End**: Test complete upload-to-storage flow
- **Database**: Test data storage and retrieval
- **API**: Test all API endpoints

### Property-Based Testing
- **File Integrity**: Verify uploaded data matches parsed data
- **Data Validation**: Verify validation rules are consistent
- **Idempotency**: Verify re-uploading same file produces same result

## 📊 Monitoring and Alerting

### Metrics to Track
- **Upload Rate**: Files uploaded per minute
- **Processing Rate**: Files processed per minute
- **Success Rate**: Percentage of successful uploads
- **Error Rate**: Percentage of failed uploads
- **Processing Time**: Average and P95 processing time

### Alerts
- **High Error Rate**: Alert if error rate > 5%
- **Long Processing Time**: Alert if processing time > 10 minutes
- **Storage Full**: Alert if storage > 90% capacity

## 📚 References

- **Application Architecture**: `../../app-architecture.md`
- **Business Unit Architecture**: `../../../../wealth-and-fiduciary-architecture.md`
- **Business Unit Coding Standards**: `../../../../wealth-and-fiduciary-coding-standards.md`

---

**Note**: These rules are specific to DataLoaderService and override application and business unit standards when conflicts exist.

**Last Updated**: January 2025
**Maintained By**: DataLoaderService Team
