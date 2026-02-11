# DataLoaderService Deployment Guide

**Version**: 1.0  
**Last Updated**: January 28, 2026  
**Service**: DataLoaderService  
**Application**: AITooling

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Configuration](#configuration)
4. [Database Setup](#database-setup)
5. [Deployment Options](#deployment-options)
   - [Option 1: IIS Deployment](#option-1-iis-deployment)
   - [Option 2: Docker Deployment](#option-2-docker-deployment)
   - [Option 3: Azure App Service](#option-3-azure-app-service)
6. [Post-Deployment](#post-deployment)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)

---

## Overview

DataLoaderService is a microservice for loading and retrieving CSV data. It provides:
- CSV file upload and parsing
- Data storage in SQL Server
- RESTful API for data retrieval
- JWT authentication for security

**Architecture**: Clean Architecture with .NET 8.0  
**Database**: SQL Server 2022+  
**Authentication**: JWT Bearer tokens from SecurityService

---

## Prerequisites

### Required Software

- **.NET 8.0 SDK** or later
- **SQL Server 2022** or later (or Azure SQL Database)
- **IIS 10** (for IIS deployment)
- **Docker** (for Docker deployment)
- **Azure CLI** (for Azure deployment)

### Required Services

- **SecurityService**: Must be deployed and running for JWT token generation
- **SQL Server**: Database server must be accessible

### Network Requirements

- **Port 5000**: HTTP (development)
- **Port 5001**: HTTPS (development)
- **Port 80/443**: Production (IIS/Azure)
- **SQL Server Port**: 1433 (default)

---

## Configuration

### 1. Production Configuration File

Create or update `appsettings.Production.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_PRODUCTION_SERVER;Database=DataLoaderDb;User Id=YOUR_USER;Password=YOUR_PASSWORD;TrustServerCertificate=True;Encrypt=True;"
  },
  "Jwt": {
    "Key": "YOUR_PRODUCTION_JWT_KEY_MINIMUM_32_CHARACTERS_REQUIRED_FOR_SECURITY",
    "Issuer": "SecurityService",
    "Audience": "DataLoaderService"
  }
}
```

### 2. Configuration Values

**Connection String**:
- Replace `YOUR_PRODUCTION_SERVER` with your SQL Server hostname
- Replace `YOUR_USER` with SQL Server username
- Replace `YOUR_PASSWORD` with SQL Server password
- Database name: `DataLoaderDb`

**JWT Configuration**:
- Replace `YOUR_PRODUCTION_JWT_KEY_MINIMUM_32_CHARACTERS_REQUIRED_FOR_SECURITY` with a secure key (32+ characters)
- **IMPORTANT**: JWT Key must match SecurityService configuration
- Issuer: `SecurityService` (must match SecurityService)
- Audience: `DataLoaderService`

### 3. Environment Variables (Alternative)

Instead of appsettings.Production.json, you can use environment variables:

```bash
# Connection String
ConnectionStrings__DefaultConnection="Server=...;Database=DataLoaderDb;..."

# JWT Configuration
Jwt__Key="YOUR_PRODUCTION_JWT_KEY_MINIMUM_32_CHARACTERS_REQUIRED_FOR_SECURITY"
Jwt__Issuer="SecurityService"
Jwt__Audience="DataLoaderService"
```

---

## Database Setup

### 1. Create Database

Connect to SQL Server and create the database:

```sql
CREATE DATABASE DataLoaderDb;
GO

USE DataLoaderDb;
GO
```

### 2. Create Database User

Create a dedicated user for the application:

```sql
CREATE LOGIN DataLoaderUser WITH PASSWORD = 'YOUR_SECURE_PASSWORD';
GO

USE DataLoaderDb;
GO

CREATE USER DataLoaderUser FOR LOGIN DataLoaderUser;
GO

ALTER ROLE db_datareader ADD MEMBER DataLoaderUser;
ALTER ROLE db_datawriter ADD MEMBER DataLoaderUser;
GO
```

### 3. Apply Migrations

Run Entity Framework migrations to create tables:

```bash
# Navigate to project directory
cd Applications/AITooling/Services/DataLoaderService

# Apply migrations
dotnet ef database update --connection "Server=YOUR_SERVER;Database=DataLoaderDb;User Id=DataLoaderUser;Password=YOUR_PASSWORD;TrustServerCertificate=True;Encrypt=True;"
```

**Expected Output**:
```
Applying migration '20260127101458_InitialCreate'.
Done.
```

### 4. Verify Database Schema

Verify the DataRecords table was created:

```sql
USE DataLoaderDb;
GO

SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DataRecords';
GO

-- Expected columns: Id, Name, Value, CreatedAt
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DataRecords';
GO
```

---

## Deployment Options

### Option 1: IIS Deployment

#### Step 1: Build for Production

```bash
cd Applications/AITooling/Services/DataLoaderService
dotnet publish -c Release -o ./publish
```

#### Step 2: Configure IIS

1. Open **IIS Manager**
2. Create new **Application Pool**:
   - Name: `DataLoaderService`
   - .NET CLR Version: `No Managed Code`
   - Managed Pipeline Mode: `Integrated`
3. Create new **Website**:
   - Site name: `DataLoaderService`
   - Application pool: `DataLoaderService`
   - Physical path: `C:\inetpub\wwwroot\DataLoaderService`
   - Binding: `http://*:80` or `https://*:443`

#### Step 3: Deploy Files

Copy published files to IIS directory:

```powershell
Copy-Item -Path ./publish/* -Destination C:\inetpub\wwwroot\DataLoaderService -Recurse -Force
```

#### Step 4: Configure Permissions

Grant IIS_IUSRS read/execute permissions:

```powershell
icacls "C:\inetpub\wwwroot\DataLoaderService" /grant "IIS_IUSRS:(OI)(CI)RX" /T
```

#### Step 5: Start Website

In IIS Manager, start the DataLoaderService website.

#### Step 6: Verify Deployment

Navigate to: `http://localhost/api/data` (should return 401 Unauthorized - expected without token)

---

### Option 2: Docker Deployment

#### Step 1: Create Dockerfile

Create `Dockerfile` in project root:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["DataLoaderService.csproj", "./"]
RUN dotnet restore "DataLoaderService.csproj"
COPY . .
RUN dotnet build "DataLoaderService.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DataLoaderService.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DataLoaderService.dll"]
```

#### Step 2: Build Docker Image

```bash
cd Applications/AITooling/Services/DataLoaderService
docker build -t dataloader-service:latest .
```

#### Step 3: Run Docker Container

```bash
docker run -d \
  --name dataloader-service \
  -p 5000:80 \
  -e ConnectionStrings__DefaultConnection="Server=YOUR_SERVER;Database=DataLoaderDb;User Id=YOUR_USER;Password=YOUR_PASSWORD;TrustServerCertificate=True;Encrypt=True;" \
  -e Jwt__Key="YOUR_PRODUCTION_JWT_KEY_MINIMUM_32_CHARACTERS_REQUIRED_FOR_SECURITY" \
  -e Jwt__Issuer="SecurityService" \
  -e Jwt__Audience="DataLoaderService" \
  dataloader-service:latest
```

#### Step 4: Verify Container

```bash
docker ps
docker logs dataloader-service
```

#### Step 5: Test Endpoint

```bash
curl http://localhost:5000/api/data
# Expected: 401 Unauthorized (no token)
```

---

### Option 3: Azure App Service

#### Step 1: Create Azure Resources

```bash
# Login to Azure
az login

# Create resource group
az group create --name DataLoaderService-RG --location eastus

# Create App Service plan
az appservice plan create \
  --name DataLoaderService-Plan \
  --resource-group DataLoaderService-RG \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --name dataloader-service \
  --resource-group DataLoaderService-RG \
  --plan DataLoaderService-Plan \
  --runtime "DOTNETCORE:8.0"
```

#### Step 2: Configure Application Settings

```bash
# Connection string
az webapp config connection-string set \
  --name dataloader-service \
  --resource-group DataLoaderService-RG \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="Server=YOUR_SERVER;Database=DataLoaderDb;User Id=YOUR_USER;Password=YOUR_PASSWORD;TrustServerCertificate=True;Encrypt=True;"

# JWT settings
az webapp config appsettings set \
  --name dataloader-service \
  --resource-group DataLoaderService-RG \
  --settings \
    Jwt__Key="YOUR_PRODUCTION_JWT_KEY_MINIMUM_32_CHARACTERS_REQUIRED_FOR_SECURITY" \
    Jwt__Issuer="SecurityService" \
    Jwt__Audience="DataLoaderService"
```

#### Step 3: Deploy Application

```bash
cd Applications/AITooling/Services/DataLoaderService

# Publish
dotnet publish -c Release -o ./publish

# Create deployment package
cd publish
zip -r ../deploy.zip .
cd ..

# Deploy to Azure
az webapp deployment source config-zip \
  --name dataloader-service \
  --resource-group DataLoaderService-RG \
  --src deploy.zip
```

#### Step 4: Verify Deployment

```bash
# Get app URL
az webapp show --name dataloader-service --resource-group DataLoaderService-RG --query defaultHostName -o tsv

# Test endpoint
curl https://dataloader-service.azurewebsites.net/api/data
# Expected: 401 Unauthorized (no token)
```

---

## Post-Deployment

### 1. Verify Service Health

Test the service is running:

```bash
# Health check (if implemented)
curl http://YOUR_SERVER/health

# Test authentication (should return 401)
curl http://YOUR_SERVER/api/data
```

### 2. Test with Valid Token

Get a JWT token from SecurityService and test:

```bash
# Get token from SecurityService
TOKEN=$(curl -X POST http://SECURITY_SERVICE/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!"}' \
  | jq -r '.token')

# Test DataLoaderService with token
curl http://YOUR_SERVER/api/data \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Test File Upload

```bash
# Upload CSV file
curl -X POST http://YOUR_SERVER/api/data/upload \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@sample-data.csv"

# Expected response:
# {"message":"Loaded 2 records","count":2}
```

### 4. Verify Database

Check data was saved to database:

```sql
USE DataLoaderDb;
GO

SELECT COUNT(*) FROM DataRecords;
GO

SELECT TOP 10 * FROM DataRecords ORDER BY CreatedAt DESC;
GO
```

---

## Monitoring

### 1. Application Logs

**IIS**: Check Event Viewer → Windows Logs → Application

**Docker**: 
```bash
docker logs dataloader-service
```

**Azure**:
```bash
az webapp log tail --name dataloader-service --resource-group DataLoaderService-RG
```

### 2. Database Monitoring

Monitor database performance:

```sql
-- Check table size
SELECT 
    t.NAME AS TableName,
    p.rows AS RowCounts
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.OBJECT_ID
WHERE t.NAME = 'DataRecords'
AND p.index_id < 2;
GO

-- Check recent activity
SELECT TOP 100 * FROM DataRecords ORDER BY CreatedAt DESC;
GO
```

### 3. Performance Metrics

Monitor these metrics:
- **Request Rate**: Requests per second
- **Response Time**: Average response time (should be < 200ms)
- **Error Rate**: Percentage of failed requests (should be < 1%)
- **Database Connections**: Active connections (should be < 100)

---

## Troubleshooting

### Issue: Service Won't Start

**Symptoms**: Service fails to start, returns 500 error

**Solutions**:
1. Check connection string is correct
2. Verify SQL Server is accessible
3. Check JWT key is configured
4. Review application logs for errors

### Issue: 401 Unauthorized

**Symptoms**: All requests return 401 Unauthorized

**Solutions**:
1. Verify JWT token is valid (not expired)
2. Check JWT key matches SecurityService
3. Verify Issuer and Audience match
4. Check Authorization header format: `Bearer <token>`

### Issue: Database Connection Failed

**Symptoms**: 500 error, logs show "Cannot open database"

**Solutions**:
1. Verify SQL Server is running
2. Check connection string is correct
3. Verify firewall allows connection
4. Check database user has permissions
5. Test connection with SQL Server Management Studio

### Issue: CSV Upload Fails

**Symptoms**: 400 Bad Request on file upload

**Solutions**:
1. Verify file is CSV format
2. Check file size is under 10 MB
3. Verify CSV has Name and Value columns
4. Check file is not corrupted
5. Review application logs for specific error

### Issue: Swagger Not Available

**Symptoms**: /swagger returns 404

**Solution**: Swagger is disabled in production. This is expected behavior for security.

---

## Security Checklist

Before deploying to production:

- [ ] JWT key is secure (32+ characters, random)
- [ ] JWT key matches SecurityService
- [ ] Connection string uses encrypted connection
- [ ] Database user has minimal permissions (read/write only)
- [ ] HTTPS is enforced in production
- [ ] Swagger is disabled in production
- [ ] Sensitive data is not logged
- [ ] Application logs are monitored
- [ ] Database backups are configured
- [ ] Firewall rules are configured

---

## Rollback Procedure

If deployment fails:

### IIS
1. Stop website in IIS Manager
2. Restore previous version from backup
3. Start website

### Docker
```bash
# Stop current container
docker stop dataloader-service
docker rm dataloader-service

# Run previous version
docker run -d --name dataloader-service dataloader-service:previous
```

### Azure
```bash
# Swap deployment slots
az webapp deployment slot swap \
  --name dataloader-service \
  --resource-group DataLoaderService-RG \
  --slot staging \
  --target-slot production
```

---

## Support

For issues or questions:
- **Documentation**: See README.md
- **Logs**: Check application logs
- **Database**: Check SQL Server logs
- **Security**: Contact SecurityService team for JWT issues

---

**Last Updated**: January 28, 2026  
**Version**: 1.0  
**Maintained By**: AITooling Team
