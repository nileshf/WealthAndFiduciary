# INN8DataSource Integration Patterns

> **Scope**: INN8DataSource service only
> **Level**: Service-level (Level 3)
> **Precedence**: HIGHEST - defines exact integration patterns for this service

## 🎯 Overview

This document defines integration patterns specific to INN8DataSource. These patterns must be followed when implementing INN8 API integration.

## 🏗️ Project Structure

```
INN8DataSource/
├── INN8DataSource.Domain/
│   ├── Entities/
│   │   ├── Client.cs
│   │   ├── Portfolio.cs
│   │   ├── Security.cs
│   │   ├── Transaction.cs
│   │   └── SyncLog.cs
│   └── Enums/
│       ├── SyncStatus.cs
│       └── TransactionType.cs
│
├── INN8DataSource.Application/
│   ├── Commands/
│   │   ├── SyncClientsCommand.cs
│   │   ├── SyncPortfoliosCommand.cs
│   │   └── SyncTransactionsCommand.cs
│   ├── Queries/
│   │   ├── GetClientByIdQuery.cs
│   │   └── GetPortfoliosByClientQuery.cs
│   ├── DTOs/
│   │   ├── ClientDto.cs
│   │   ├── PortfolioDto.cs
│   │   └── SyncResultDto.cs
│   └── Interfaces/
│       ├── IInn8ApiClient.cs
│       ├── IDataTransformer.cs
│       └── ISyncService.cs
│
├── INN8DataSource.Infrastructure/
│   ├── Data/
│   │   ├── DataSourceDbContext.cs
│   │   └── Configurations/
│   ├── Repositories/
│   │   ├── ClientRepository.cs
│   │   └── PortfolioRepository.cs
│   ├── Integration/
│   │   ├── Inn8ApiClient.cs
│   │   ├── Inn8AuthService.cs
│   │   └── DataTransformer.cs
│   └── Services/
│       └── SyncService.cs
│
└── INN8DataSource.Api/
    ├── Controllers/
    │   ├── ClientsController.cs
    │   ├── PortfoliosController.cs
    │   └── SyncController.cs
    └── BackgroundServices/
        └── SyncBackgroundService.cs
```

## 🔐 Authentication Pattern

### OAuth 2.0 Client Credentials Flow

```csharp
public class Inn8AuthService : IInn8AuthService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly IMemoryCache _cache;
    private readonly ILogger<Inn8AuthService> _logger;

    private const string TokenCacheKey = "Inn8AccessToken";

    public async Task<string> GetAccessTokenAsync()
    {
        // Try to get token from cache
        if (_cache.TryGetValue(TokenCacheKey, out string? cachedToken))
        {
            return cachedToken!;
        }

        // Request new token
        var tokenRequest = new Dictionary<string, string>
        {
            { "grant_type", "client_credentials" },
            { "client_id", _configuration["Inn8:ClientId"] },
            { "client_secret", _configuration["Inn8:ClientSecret"] },
            { "scope", "api.read api.write" }
        };

        var response = await _httpClient.PostAsync(
            $"{_configuration["Inn8:BaseUrl"]}/oauth/token",
            new FormUrlEncodedContent(tokenRequest));

        response.EnsureSuccessStatusCode();

        var tokenResponse = await response.Content.ReadFromJsonAsync<TokenResponse>();
        
        if (tokenResponse == null || string.IsNullOrEmpty(tokenResponse.AccessToken))
        {
            throw new InvalidOperationException("Failed to obtain access token");
        }

        // Cache token (refresh 5 minutes before expiration)
        var cacheExpiration = TimeSpan.FromSeconds(tokenResponse.ExpiresIn - 300);
        _cache.Set(TokenCacheKey, tokenResponse.AccessToken, cacheExpiration);

        _logger.LogInformation("Successfully obtained INN8 access token");

        return tokenResponse.AccessToken;
    }
}
```

## 🔄 API Client Pattern

### Resilient HTTP Client with Polly

```csharp
public class Inn8ApiClient : IInn8ApiClient
{
    private readonly HttpClient _httpClient;
    private readonly IInn8AuthService _authService;
    private readonly ILogger<Inn8ApiClient> _logger;
    private readonly IAsyncPolicy<HttpResponseMessage> _retryPolicy;
    private readonly IAsyncPolicy<HttpResponseMessage> _circuitBreakerPolicy;

    public Inn8ApiClient(
        HttpClient httpClient,
        IInn8AuthService authService,
        ILogger<Inn8ApiClient> logger)
    {
        _httpClient = httpClient;
        _authService = authService;
        _logger = logger;

        // Retry policy: 3 retries with exponential backoff
        _retryPolicy = Policy
            .HandleResult<HttpResponseMessage>(r => !r.IsSuccessStatusCode && IsTransientError(r))
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: retryAttempt => 
                    TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)) + 
                    TimeSpan.FromMilliseconds(Random.Shared.Next(0, 1000)),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    _logger.LogWarning(
                        "Retry {RetryCount} after {Delay}ms due to {StatusCode}",
                        retryCount, timespan.TotalMilliseconds, outcome.Result.StatusCode);
                });

        // Circuit breaker: Open after 5 consecutive failures
        _circuitBreakerPolicy = Policy
            .HandleResult<HttpResponseMessage>(r => !r.IsSuccessStatusCode)
            .CircuitBreakerAsync(
                handledEventsAllowedBeforeBreaking: 5,
                durationOfBreak: TimeSpan.FromSeconds(60),
                onBreak: (outcome, duration) =>
                {
                    _logger.LogError("Circuit breaker opened for {Duration}s", duration.TotalSeconds);
                },
                onReset: () =>
                {
                    _logger.LogInformation("Circuit breaker reset");
                });
    }

    public async Task<T?> GetAsync<T>(string endpoint)
    {
        var token = await _authService.GetAccessTokenAsync();
        
        var request = new HttpRequestMessage(HttpMethod.Get, endpoint);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var policy = Policy.WrapAsync(_retryPolicy, _circuitBreakerPolicy);
        
        var response = await policy.ExecuteAsync(() => _httpClient.SendAsync(request));
        
        response.EnsureSuccessStatusCode();
        
        return await response.Content.ReadFromJsonAsync<T>();
    }

    private static bool IsTransientError(HttpResponseMessage response)
    {
        return response.StatusCode == HttpStatusCode.RequestTimeout ||
               response.StatusCode == HttpStatusCode.TooManyRequests ||
               (int)response.StatusCode >= 500;
    }
}
```

## 🔄 Sync Service Pattern

### Background Sync Service

```csharp
public class SyncBackgroundService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<SyncBackgroundService> _logger;
    private readonly TimeSpan _syncInterval = TimeSpan.FromMinutes(15);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Sync background service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var syncService = scope.ServiceProvider.GetRequiredService<ISyncService>();

                // Sync clients
                await syncService.SyncClientsAsync(stoppingToken);

                // Sync portfolios
                await syncService.SyncPortfoliosAsync(stoppingToken);

                // Sync transactions
                await syncService.SyncTransactionsAsync(stoppingToken);

                _logger.LogInformation("Sync completed successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during sync");
            }

            await Task.Delay(_syncInterval, stoppingToken);
        }

        _logger.LogInformation("Sync background service stopped");
    }
}

public class SyncService : ISyncService
{
    private readonly IInn8ApiClient _apiClient;
    private readonly IClientRepository _clientRepository;
    private readonly IDataTransformer _transformer;
    private readonly ISyncLogRepository _syncLogRepository;
    private readonly ILogger<SyncService> _logger;

    public async Task<SyncResult> SyncClientsAsync(CancellationToken cancellationToken)
    {
        var syncLog = new SyncLog
        {
            EntityType = "Client",
            StartTime = DateTime.UtcNow,
            Status = SyncStatus.InProgress
        };

        try
        {
            // Fetch clients from INN8
            var inn8Clients = await _apiClient.GetAsync<List<Inn8ClientDto>>("clients");
            
            if (inn8Clients == null || inn8Clients.Count == 0)
            {
                _logger.LogWarning("No clients returned from INN8 API");
                syncLog.Status = SyncStatus.NoData;
                syncLog.EndTime = DateTime.UtcNow;
                await _syncLogRepository.AddAsync(syncLog);
                return new SyncResult { Status = SyncStatus.NoData };
            }

            var successCount = 0;
            var errorCount = 0;

            foreach (var inn8Client in inn8Clients)
            {
                try
                {
                    // Transform INN8 format to FullView format
                    var client = _transformer.TransformClient(inn8Client);

                    // Upsert client
                    var existing = await _clientRepository.GetByExternalIdAsync(client.ExternalId);
                    
                    if (existing != null)
                    {
                        // Update existing
                        existing.Name = client.Name;
                        existing.Email = client.Email;
                        existing.Phone = client.Phone;
                        existing.Address = client.Address;
                        existing.Status = client.Status;
                        existing.LastSyncDate = DateTime.UtcNow;
                        
                        await _clientRepository.UpdateAsync(existing);
                    }
                    else
                    {
                        // Insert new
                        client.LastSyncDate = DateTime.UtcNow;
                        await _clientRepository.AddAsync(client);
                    }

                    successCount++;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error syncing client {ClientId}", inn8Client.Id);
                    errorCount++;
                }
            }

            syncLog.Status = errorCount == 0 ? SyncStatus.Success : SyncStatus.PartialSuccess;
            syncLog.RecordCount = successCount;
            syncLog.ErrorCount = errorCount;
            syncLog.EndTime = DateTime.UtcNow;
            
            await _syncLogRepository.AddAsync(syncLog);

            _logger.LogInformation(
                "Client sync completed: {SuccessCount} success, {ErrorCount} errors",
                successCount, errorCount);

            return new SyncResult
            {
                Status = syncLog.Status,
                RecordCount = successCount,
                ErrorCount = errorCount
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Fatal error during client sync");
            
            syncLog.Status = SyncStatus.Failed;
            syncLog.ErrorMessage = ex.Message;
            syncLog.EndTime = DateTime.UtcNow;
            
            await _syncLogRepository.AddAsync(syncLog);

            return new SyncResult { Status = SyncStatus.Failed, ErrorMessage = ex.Message };
        }
    }
}
```

## 🔄 Data Transformation Pattern

```csharp
public class DataTransformer : IDataTransformer
{
    public Client TransformClient(Inn8ClientDto inn8Client)
    {
        return new Client
        {
            ExternalId = inn8Client.Id,
            Name = inn8Client.FullName,
            Email = inn8Client.EmailAddress,
            Phone = FormatPhoneNumber(inn8Client.PhoneNumber),
            Address = TransformAddress(inn8Client.Address),
            Status = MapClientStatus(inn8Client.Status),
            TenantId = GetTenantIdFromContext()
        };
    }

    public Portfolio TransformPortfolio(Inn8PortfolioDto inn8Portfolio)
    {
        return new Portfolio
        {
            ExternalId = inn8Portfolio.Id,
            ClientId = GetClientIdByExternalId(inn8Portfolio.ClientId),
            Name = inn8Portfolio.Name,
            AccountNumber = inn8Portfolio.AccountNumber,
            AccountType = MapAccountType(inn8Portfolio.Type),
            Status = MapPortfolioStatus(inn8Portfolio.Status),
            TenantId = GetTenantIdFromContext()
        };
    }

    private string FormatPhoneNumber(string? phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return string.Empty;
        
        // Remove all non-digit characters
        var digits = new string(phone.Where(char.IsDigit).ToArray());
        
        // Format as (XXX) XXX-XXXX
        if (digits.Length == 10)
        {
            return $"({digits.Substring(0, 3)}) {digits.Substring(3, 3)}-{digits.Substring(6)}";
        }
        
        return phone;
    }

    private string TransformAddress(Inn8AddressDto? address)
    {
        if (address == null) return string.Empty;
        
        return $"{address.Street}, {address.City}, {address.State} {address.ZipCode}";
    }

    private ClientStatus MapClientStatus(string inn8Status)
    {
        return inn8Status.ToLower() switch
        {
            "active" => ClientStatus.Active,
            "inactive" => ClientStatus.Inactive,
            "suspended" => ClientStatus.Suspended,
            _ => ClientStatus.Unknown
        };
    }
}
```

## 🧪 Testing Patterns

### Integration Test with WireMock

```csharp
public class Inn8ApiClientTests : IClassFixture<WireMockFixture>
{
    private readonly WireMockFixture _wireMock;
    private readonly Inn8ApiClient _client;

    public Inn8ApiClientTests(WireMockFixture wireMock)
    {
        _wireMock = wireMock;
        
        var httpClient = new HttpClient
        {
            BaseAddress = new Uri(_wireMock.ServerUrl)
        };
        
        _client = new Inn8ApiClient(httpClient, Mock.Of<IInn8AuthService>(), Mock.Of<ILogger<Inn8ApiClient>>());
    }

    [Fact]
    public async Task GetAsync_WithValidResponse_ReturnsData()
    {
        // Arrange
        _wireMock.Server
            .Given(Request.Create().WithPath("/clients").UsingGet())
            .RespondWith(Response.Create()
                .WithStatusCode(200)
                .WithHeader("Content-Type", "application/json")
                .WithBody(JsonSerializer.Serialize(new List<Inn8ClientDto>
                {
                    new() { Id = "123", FullName = "Test Client" }
                })));

        // Act
        var result = await _client.GetAsync<List<Inn8ClientDto>>("clients");

        // Assert
        result.Should().NotBeNull();
        result.Should().HaveCount(1);
        result![0].FullName.Should().Be("Test Client");
    }

    [Fact]
    public async Task GetAsync_WithTransientError_RetriesAndSucceeds()
    {
        // Arrange
        _wireMock.Server
            .Given(Request.Create().WithPath("/clients").UsingGet())
            .InScenario("Retry")
            .WillSetStateTo("Attempt 1")
            .RespondWith(Response.Create().WithStatusCode(500));

        _wireMock.Server
            .Given(Request.Create().WithPath("/clients").UsingGet())
            .InScenario("Retry")
            .WhenStateIs("Attempt 1")
            .WillSetStateTo("Attempt 2")
            .RespondWith(Response.Create().WithStatusCode(200).WithBody("[]"));

        // Act
        var result = await _client.GetAsync<List<Inn8ClientDto>>("clients");

        // Assert
        result.Should().NotBeNull();
    }
}
```

## 📚 References

- **Data Source Rules**: `./data-source-rules.md`
- **Application Architecture**: `../../app-architecture.md`
- **Business Unit Architecture**: `../../../../org-architecture.md`
- **Business Unit Coding Standards**: `../../../../org-coding-standards.md`

---

**Note**: These integration patterns are specific to INN8DataSource and must be followed exactly.

**Last Updated**: January 2025
**Maintained By**: INN8DataSource Team
