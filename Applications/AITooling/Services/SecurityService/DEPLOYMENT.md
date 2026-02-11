# SecurityService Deployment Guide

## Overview

SecurityService is a JWT-based authentication microservice built with ASP.NET Core 8.0. This guide covers deployment to production environments.

## Prerequisites

- .NET 8.0 Runtime
- SQL Server 2019 or later (or Azure SQL Database)
- HTTPS certificate for production

## Configuration

### 1. Database Setup

**Create Database:**
```sql
CREATE DATABASE SecurityDb;
GO

USE SecurityDb;
GO

-- Create application user
CREATE LOGIN SecurityServiceUser WITH PASSWORD = 'YourSecurePassword';
CREATE USER SecurityServiceUser FOR LOGIN SecurityServiceUser;

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER SecurityServiceUser;
ALTER ROLE db_datawriter ADD MEMBER SecurityServiceUser;
ALTER ROLE db_ddladmin ADD MEMBER SecurityServiceUser;
GO
```

**Run Migrations:**
```bash
cd SecurityService
dotnet ef database update --connection "Server=YOUR_SERVER;Database=SecurityDb;User Id=SecurityServiceUser;Password=YourSecurePassword;TrustServerCertificate=False;Encrypt=True;"
```

### 2. Application Configuration

**Update appsettings.Production.json:**

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_PRODUCTION_SERVER;Database=SecurityDb;User Id=SecurityServiceUser;Password=YOUR_SECURE_PASSWORD;TrustServerCertificate=False;Encrypt=True;"
  },
  "Jwt": {
    "Key": "YOUR_SECURE_RANDOM_KEY_AT_LEAST_32_CHARACTERS_LONG",
    "Issuer": "SecurityService",
    "Audience": "MicroservicesApp"
  }
}
```

**Important Security Notes:**
- JWT Key must be at least 32 characters
- Use a cryptographically secure random string for JWT Key
- Store sensitive configuration in Azure Key Vault or similar
- Never commit production secrets to source control

**Generate Secure JWT Key (PowerShell):**
```powershell
$bytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

### 3. Build and Publish

**Build for Production:**
```bash
dotnet publish -c Release -o ./publish
```

**Verify Build:**
```bash
cd publish
dotnet SecurityService.dll
```

## Deployment Options

### Option 1: Windows Server with IIS

1. **Install Prerequisites:**
   - .NET 8.0 Hosting Bundle
   - IIS with ASP.NET Core Module

2. **Create IIS Site:**
   - Create new Application Pool (.NET CLR Version: No Managed Code)
   - Create new Website pointing to publish folder
   - Configure HTTPS binding with certificate

3. **Configure Application Pool:**
   - Identity: ApplicationPoolIdentity or custom service account
   - Enable 32-bit Applications: False
   - Start Mode: AlwaysRunning

4. **Set Environment Variable:**
   ```xml
   <environmentVariables>
     <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
   </environmentVariables>
   ```

### Option 2: Docker Container

**Dockerfile:**
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["SecurityService.csproj", "./"]
RUN dotnet restore
COPY . .
RUN dotnet build -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SecurityService.dll"]
```

**Build and Run:**
```bash
docker build -t securityservice:latest .
docker run -d -p 5000:80 -p 5001:443 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ConnectionStrings__DefaultConnection="YOUR_CONNECTION_STRING" \
  -e Jwt__Key="YOUR_JWT_KEY" \
  securityservice:latest
```

### Option 3: Azure App Service

1. **Create App Service:**
   - Runtime: .NET 8
   - Operating System: Windows or Linux
   - Region: Choose appropriate region

2. **Configure Application Settings:**
   - Add ConnectionStrings:DefaultConnection
   - Add Jwt:Key
   - Add Jwt:Issuer
   - Add Jwt:Audience
   - Set ASPNETCORE_ENVIRONMENT=Production

3. **Deploy:**
   ```bash
   az webapp deployment source config-zip \
     --resource-group YOUR_RESOURCE_GROUP \
     --name YOUR_APP_NAME \
     --src ./publish.zip
   ```

## Post-Deployment Verification

### 1. Health Check

**Test Registration:**
```bash
curl -X POST https://your-domain.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"TestPass123"}'
```

**Expected Response:**
```json
{
  "id": 1,
  "username": "testuser",
  "role": "User"
}
```

**Test Login:**
```bash
curl -X POST https://your-domain.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"TestPass123"}'
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 2. Security Verification

- ✅ Swagger UI is disabled (should return 404)
- ✅ HTTPS is enforced
- ✅ JWT tokens are validated correctly
- ✅ Invalid credentials return 401
- ✅ Database connection is secure (encrypted)

### 3. Monitoring

**Application Insights (Azure):**
- Configure Application Insights connection string
- Monitor request rates, response times, failures
- Set up alerts for high error rates

**Logging:**
- Verify logs are being written
- Check for any startup errors
- Monitor authentication failures

## Troubleshooting

### Issue: Database Connection Fails

**Solution:**
- Verify connection string is correct
- Check firewall rules allow connection
- Verify SQL Server user has correct permissions
- Test connection with SQL Server Management Studio

### Issue: JWT Token Validation Fails

**Solution:**
- Verify Jwt:Key matches between services
- Check Jwt:Issuer and Jwt:Audience are correct
- Ensure token hasn't expired (2 hour lifetime)
- Verify system clocks are synchronized

### Issue: 500 Internal Server Error

**Solution:**
- Check application logs for detailed error
- Verify all configuration values are set
- Check database migrations have been applied
- Verify .NET 8.0 runtime is installed

## Rollback Procedure

1. **Stop Application:**
   - IIS: Stop Application Pool
   - Docker: `docker stop CONTAINER_ID`
   - Azure: Stop App Service

2. **Restore Previous Version:**
   - Deploy previous publish folder
   - Or rollback to previous Docker image
   - Or use Azure deployment slot swap

3. **Verify Rollback:**
   - Test registration and login endpoints
   - Check application logs
   - Monitor for errors

## Security Checklist

- [ ] JWT Key is cryptographically secure (32+ characters)
- [ ] Database connection uses encrypted connection
- [ ] HTTPS is enforced in production
- [ ] Swagger UI is disabled in production
- [ ] Sensitive configuration stored in Key Vault
- [ ] Application runs with least privilege account
- [ ] Database user has minimal required permissions
- [ ] Firewall rules restrict database access
- [ ] Application Insights or logging configured
- [ ] Alerts configured for critical errors

## Maintenance

### Database Backups

**Automated Backups (SQL Server):**
```sql
-- Full backup daily
BACKUP DATABASE SecurityDb 
TO DISK = 'C:\Backups\SecurityDb_Full.bak'
WITH INIT, COMPRESSION;

-- Transaction log backup hourly
BACKUP LOG SecurityDb 
TO DISK = 'C:\Backups\SecurityDb_Log.trn'
WITH COMPRESSION;
```

### Updates

**Apply Updates:**
1. Test in staging environment
2. Schedule maintenance window
3. Backup database
4. Deploy new version
5. Run database migrations
6. Verify functionality
7. Monitor for issues

## Support

For issues or questions:
- Check application logs
- Review this deployment guide
- Contact: WealthAndFiduciary - AITooling Team
