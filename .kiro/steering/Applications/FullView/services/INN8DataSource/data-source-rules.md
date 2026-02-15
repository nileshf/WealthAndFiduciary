# INN8DataSource Business Rules

> **Scope**: INN8DataSource service only
> **Level**: Service-level (Level 3)
> **Precedence**: HIGHEST - overrides application and business unit when conflicts exist

## 🎯 Overview

INN8DataSource is the data integration and synchronization service for the FullView application. This service handles all data exchange with INN8 systems, ensuring data consistency and compliance.

## 🔄 Data Synchronization Rules

### Sync Frequency
- **Real-Time Sync**: Critical financial transactions (immediate)
- **Batch Sync**: Non-critical data (every 15 minutes)
- **Full Sync**: Complete data refresh (daily at 2 AM UTC)
- **On-Demand Sync**: Manual sync triggered by user or system event

### Sync Direction
- **Bidirectional**: Client data, portfolio holdings
- **Inbound Only**: Market data, pricing information
- **Outbound Only**: Audit logs, compliance reports

### Sync Validation
- **Data Integrity**: Checksum validation for all synced data
- **Schema Validation**: Validate against INN8 API schema
- **Business Rules**: Apply FullView business rules before sync
- **Conflict Resolution**: Last-write-wins with audit trail

## 📊 Data Source Schema

- **Schema Name**: `DataSource`
- **Rationale**: Clear separation from other services, easy to identify data integration tables

## 🔐 INN8 API Integration

### Authentication
- **Method**: OAuth 2.0 Client Credentials
- **Token Lifetime**: 1 hour
- **Token Refresh**: Automatic refresh 5 minutes before expiration
- **API Key**: Stored in Azure Key Vault
- **Client Secret**: Rotated every 90 days

### API Endpoints
- **Base URL**: `https://api.inn8.com/v2/`
- **Environments**:
  - Production: `https://api.inn8.com/v2/`
  - Staging: `https://staging-api.inn8.com/v2/`
  - Development: `https://dev-api.inn8.com/v2/`

### Rate Limiting
- **Requests per minute**: 100
- **Requests per hour**: 5000
- **Burst limit**: 200 requests in 10 seconds
- **Retry Strategy**: Exponential backoff with jitter

### Error Handling
- **Transient Errors**: Retry up to 3 times with exponential backoff
- **Permanent Errors**: Log and alert, do not retry
- **Timeout**: 30 seconds per request
- **Circuit Breaker**: Open after 5 consecutive failures, half-open after 60 seconds

## 📋 Data Entities

### Client Data
- **Source**: INN8 Client API
- **Sync Frequency**: Real-time for updates, batch for new clients
- **Fields**: ClientId, Name, Email, Phone, Address, Status
- **Validation**: Email format, phone format, required fields
- **Tenant Isolation**: All clients scoped to tenant

### Portfolio Holdings
- **Source**: INN8 Portfolio API
- **Sync Frequency**: Real-time for trades, batch for positions
- **Fields**: PortfolioId, ClientId, SecurityId, Quantity, CostBasis, MarketValue
- **Validation**: Quantity > 0, valid security, valid client
- **Tenant Isolation**: All portfolios scoped to tenant

### Market Data
- **Source**: INN8 Market Data API
- **Sync Frequency**: Real-time during market hours, batch after hours
- **Fields**: SecurityId, Symbol, Price, Volume, Timestamp
- **Validation**: Price > 0, valid symbol, timestamp within 5 minutes
- **Caching**: Cache for 1 minute during market hours

### Transactions
- **Source**: INN8 Transaction API
- **Sync Frequency**: Real-time
- **Fields**: TransactionId, PortfolioId, SecurityId, Type, Quantity, Price, Timestamp
- **Validation**: Valid transaction type, quantity != 0, price > 0
- **Audit**: All transactions logged immutably

## 🔒 Data Security

### Data Encryption
- **In Transit**: TLS 1.2+ for all API calls
- **At Rest**: AES-256 encryption for sensitive data
- **PII Fields**: Client name, email, phone, address
- **Financial Data**: Portfolio holdings, transactions

### Data Masking
- **Development**: All PII masked with fake data
- **Staging**: PII masked for non-production users
- **Production**: Full data access with audit logging

### Data Retention
- **Client Data**: 7 years after account closure
- **Portfolio Data**: 7 years after portfolio closure
- **Market Data**: 1 year (historical data archived)
- **Transactions**: 7 years (immutable)
- **Sync Logs**: 90 days

## 🔄 Sync Process

### Sync Workflow
1. **Authenticate**: Get OAuth token from INN8
2. **Fetch Data**: Call INN8 API endpoint
3. **Validate**: Validate data against schema and business rules
4. **Transform**: Transform INN8 format to FullView format
5. **Upsert**: Insert or update data in FullView database
6. **Log**: Log sync result (success/failure, record count, duration)
7. **Notify**: Notify on failure or significant changes

### Conflict Resolution
- **Strategy**: Last-write-wins with audit trail
- **Conflict Detection**: Compare timestamps and checksums
- **Conflict Logging**: Log all conflicts for review
- **Manual Resolution**: Support for manual conflict resolution

### Sync Monitoring
- **Metrics**: Sync duration, record count, error rate
- **Alerts**: Alert on sync failure, high error rate, long duration
- **Dashboard**: Real-time sync status dashboard
- **Reports**: Daily sync summary report

## 🧪 Testing Requirements

### Integration Testing
- **Mock INN8 API**: Use WireMock or similar for testing
- **Test Data**: Realistic test data matching INN8 schema
- **Error Scenarios**: Test all error scenarios (timeout, rate limit, invalid data)
- **Performance**: Test sync performance with large datasets

### Property-Based Testing
- **Data Integrity**: Verify synced data matches source data
- **Idempotency**: Verify sync can be run multiple times safely
- **Tenant Isolation**: Verify cross-tenant data leakage is impossible
- **Conflict Resolution**: Verify conflicts are resolved correctly

## 📊 Monitoring and Alerting

### Metrics to Track
- **Sync Success Rate**: Percentage of successful syncs
- **Sync Duration**: Average and P95 sync duration
- **Record Count**: Number of records synced per run
- **Error Rate**: Percentage of failed API calls
- **API Latency**: Average and P95 API response time

### Alerts
- **Sync Failure**: Alert immediately on sync failure
- **High Error Rate**: Alert if error rate > 5%
- **Long Duration**: Alert if sync takes > 10 minutes
- **Rate Limit**: Alert if approaching rate limit
- **Data Discrepancy**: Alert on significant data differences

## 📚 References

- **Integration Patterns**: `./integration-patterns.md`
- **Application Architecture**: `../../app-architecture.md`
- **Business Unit Architecture**: `../../../../org-architecture.md`
- **Business Unit Security**: `../../../../org-architecture.md` (Security Baseline section)

---

**Note**: These rules are specific to INN8DataSource and override application and business unit standards when conflicts exist.

**Last Updated**: January 2025
**Maintained By**: INN8DataSource Team
