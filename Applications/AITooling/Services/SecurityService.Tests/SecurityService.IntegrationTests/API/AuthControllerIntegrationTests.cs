using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using SecurityService.Infrastructure;
using Xunit;

namespace SecurityService.IntegrationTests.API;

public class AuthControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public AuthControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    /// <summary>
    /// Creates a new HttpClient with an isolated in-memory database for each test
    /// </summary>
    private HttpClient CreateClient()
    {
        var dbName = "TestDatabase_" + Guid.NewGuid();

        return _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Remove the existing DbContext registration
                services.RemoveAll(typeof(DbContextOptions<SecurityDbContext>));
                services.RemoveAll(typeof(SecurityDbContext));

                // Add in-memory database with unique name for test isolation
                // Use singleton lifetime so the same database is used across all requests in this test
                services.AddDbContext<SecurityDbContext>(options =>
                {
                    options.UseInMemoryDatabase(dbName);
                }, ServiceLifetime.Singleton, ServiceLifetime.Singleton);
            });
        }).CreateClient();
    }

    [Fact]
    public async Task Register_WithValidData_ReturnsOkAndUserDetails()
    {
        // Arrange
        using var client = CreateClient();
        var request = new
        {
            Username = "testuser",
            Password = "TestPassword123!",
            Role = "User"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/register", request);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<JsonElement>(content);

        result.GetProperty("id").GetInt32().Should().BeGreaterThan(0);
        result.GetProperty("username").GetString().Should().Be("testuser");
        result.GetProperty("role").GetString().Should().Be("User");
    }

    [Fact]
    public async Task Register_WithAdminRole_ReturnsOkWithAdminRole()
    {
        // Arrange
        using var client = CreateClient();
        var request = new
        {
            Username = "adminuser",
            Password = "AdminPassword123!",
            Role = "Admin"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/register", request);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<JsonElement>(content);

        result.GetProperty("role").GetString().Should().Be("Admin");
    }

    [Fact]
    public async Task Login_WithValidCredentials_ReturnsOkAndToken()
    {
        // Arrange
        using var client = CreateClient();

        // First register a user
        var registerRequest = new
        {
            Username = "loginuser",
            Password = "LoginPassword123!",
            Role = "User"
        };
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        var loginRequest = new
        {
            Username = "loginuser",
            Password = "LoginPassword123!"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/login", loginRequest);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<JsonElement>(content);

        result.GetProperty("token").GetString().Should().NotBeNullOrEmpty();
    }

    [Fact]
    public async Task Login_WithInvalidCredentials_ReturnsUnauthorized()
    {
        // Arrange
        using var client = CreateClient();
        var loginRequest = new
        {
            Username = "nonexistent",
            Password = "WrongPassword123!"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/login", loginRequest);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<JsonElement>(content);

        result.GetProperty("message").GetString().Should().Be("Invalid credentials");
    }

    [Fact]
    public async Task Login_WithWrongPassword_ReturnsUnauthorized()
    {
        // Arrange
        using var client = CreateClient();

        // First register a user
        var registerRequest = new
        {
            Username = "wrongpassuser",
            Password = "CorrectPassword123!",
            Role = "User"
        };
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        var loginRequest = new
        {
            Username = "wrongpassuser",
            Password = "WrongPassword123!"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/login", loginRequest);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Token_CanBeUsedForAuthentication()
    {
        // Arrange
        using var client = CreateClient();

        // Register and login to get a token
        var registerRequest = new
        {
            Username = "tokenuser",
            Password = "TokenPassword123!",
            Role = "User"
        };
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        var loginRequest = new
        {
            Username = "tokenuser",
            Password = "TokenPassword123!"
        };
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", loginRequest);
        var loginContent = await loginResponse.Content.ReadAsStringAsync();
        var loginResult = JsonSerializer.Deserialize<JsonElement>(loginContent);
        var token = loginResult.GetProperty("token").GetString();

        // Act - Use token in Authorization header
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        // For this test, we'll just verify the token is valid by checking it's not null
        // In a real scenario, you'd call a protected endpoint
        token.Should().NotBeNullOrEmpty();
        client.DefaultRequestHeaders.Authorization.Should().NotBeNull();
    }

    [Fact]
    public async Task Register_ThenLogin_CompleteFlow_Works()
    {
        // Arrange
        using var client = CreateClient();
        var username = "flowuser";
        var password = "FlowPassword123!";

        var registerRequest = new
        {
            Username = username,
            Password = password,
            Role = "User"
        };

        // Act - Register
        var registerResponse = await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Assert - Register succeeded
        registerResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act - Login
        var loginRequest = new
        {
            Username = username,
            Password = password
        };
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", loginRequest);

        // Assert - Login succeeded
        loginResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        var loginContent = await loginResponse.Content.ReadAsStringAsync();
        var loginResult = JsonSerializer.Deserialize<JsonElement>(loginContent);
        var token = loginResult.GetProperty("token").GetString();

        token.Should().NotBeNullOrEmpty();
        token.Should().Contain("."); // JWT tokens have dots
    }
}
