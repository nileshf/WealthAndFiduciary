using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using DataLoaderService.Infrastructure;
using DataLoaderService.IntegrationTests.Fixtures;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.IdentityModel.Tokens;

namespace DataLoaderService.IntegrationTests.API;

public class DataControllerTests : IClassFixture<DataLoaderWebApplicationFactory>
{
    private readonly DataLoaderWebApplicationFactory _factory;
    private const string JwtKey = "ThisIsASecretKeyForTestingPurposesOnly123456";
    private const string JwtIssuer = "DataLoaderService";
    private const string JwtAudience = "DataLoaderService";

    public DataControllerTests(DataLoaderWebApplicationFactory factory)
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
                services.RemoveAll(typeof(DbContextOptions<DataDbContext>));
                services.RemoveAll(typeof(DataDbContext));

                // Add in-memory database with unique name for test isolation
                // Use singleton lifetime so the same database is used across all requests in this test
                services.AddDbContext<DataDbContext>(options =>
                {
                    options.UseInMemoryDatabase(dbName);
                }, ServiceLifetime.Singleton, ServiceLifetime.Singleton);
            });
        }).CreateClient();
    }

    [Fact]
    public async Task UploadFile_WithValidFileAndToken_Returns200AndCount()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var csvContent = "Name,Value\nProduct1,Value1\nProduct2,Value2";
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes(csvContent));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        content.Add(fileContent, "file", "test.csv");

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("\"count\":2");
        responseContent.Should().Contain("Loaded 2 records");
    }

    [Fact]
    public async Task UploadFile_WithoutToken_Returns401()
    {
        // Arrange
        using var client = CreateClient();
        var csvContent = "Name,Value\nProduct1,Value1";
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes(csvContent));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        content.Add(fileContent, "file", "test.csv");

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task UploadFile_WithEmptyFile_Returns400()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Array.Empty<byte>());
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        content.Add(fileContent, "file", "empty.csv");

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("No file uploaded");
    }

    [Fact]
    public async Task UploadFile_WithNoFile_Returns400()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var content = new MultipartFormDataContent();

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task GetAll_WithValidToken_Returns200AndData()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Upload some data first
        var csvContent = "Name,Value\nTest1,Value1";
        var uploadContent = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes(csvContent));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        uploadContent.Add(fileContent, "file", "test.csv");
        await client.PostAsync("/api/data/upload", uploadContent);

        // Act
        var response = await client.GetAsync("/api/data");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("Test1");
        responseContent.Should().Contain("Value1");
    }

    [Fact]
    public async Task GetAll_WithoutToken_Returns401()
    {
        // Arrange
        using var client = CreateClient();

        // Act
        var response = await client.GetAsync("/api/data");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task EndToEnd_UploadAndRetrieve_DataMatches()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var csvContent = "Name,Value\nEndToEnd1,ETE_Value1\nEndToEnd2,ETE_Value2";
        var uploadContent = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes(csvContent));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        uploadContent.Add(fileContent, "file", "endtoend.csv");

        // Act - Upload
        var uploadResponse = await client.PostAsync("/api/data/upload", uploadContent);
        uploadResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act - Retrieve
        var getResponse = await client.GetAsync("/api/data");
        getResponse.StatusCode.Should().Be(HttpStatusCode.OK);

        // Assert
        var responseContent = await getResponse.Content.ReadAsStringAsync();
        responseContent.Should().Contain("EndToEnd1");
        responseContent.Should().Contain("ETE_Value1");
        responseContent.Should().Contain("EndToEnd2");
        responseContent.Should().Contain("ETE_Value2");
    }

    [Fact]
    public async Task UploadFile_WithFileTooLarge_Returns400()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Create a file larger than 10 MB
        var largeContent = new byte[11 * 1024 * 1024]; // 11 MB
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(largeContent);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        content.Add(fileContent, "file", "large.csv");

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("File size exceeds maximum limit");
    }

    [Fact]
    public async Task UploadFile_WithNonCsvExtension_Returns400()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes("some content"));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/plain");
        content.Add(fileContent, "file", "test.txt");

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("Only CSV files are supported");
    }

    [Fact]
    public async Task UploadFile_WithInvalidCsvFormat_Returns400()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // CSV with wrong columns
        var csvContent = "WrongColumn1,WrongColumn2\nValue1,Value2";
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes(csvContent));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        content.Add(fileContent, "file", "invalid.csv");

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("Invalid CSV format");
    }

    [Fact]
    public async Task UploadFile_WithMalformedCsv_Returns400()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Malformed CSV (unclosed quote)
        var csvContent = "Name,Value\n\"Unclosed,Value1";
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes(csvContent));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        content.Add(fileContent, "file", "malformed.csv");

        // Act
        var response = await client.PostAsync("/api/data/upload", content);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("Invalid CSV format");
    }

    [Fact]
    public async Task GetById_WithValidId_Returns200AndData()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Upload some data first
        var csvContent = "Name,Value\nTestProduct,TestValue";
        var uploadContent = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(Encoding.UTF8.GetBytes(csvContent));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/csv");
        uploadContent.Add(fileContent, "file", "test.csv");
        await client.PostAsync("/api/data/upload", uploadContent);

        // Act - Get by ID 1 (first record)
        var response = await client.GetAsync("/api/data/1");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        var responseContent = await response.Content.ReadAsStringAsync();
        responseContent.Should().Contain("TestProduct");
    }

    [Fact]
    public async Task GetById_WithInvalidId_Returns404()
    {
        // Arrange
        using var client = CreateClient();
        var token = GenerateJwtToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Act - Try to get non-existent record
        var response = await client.GetAsync("/api/data/999");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    private string GenerateJwtToken()
    {
        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(JwtKey));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, "test-user-id"),
            new Claim(ClaimTypes.Email, "test@example.com")
        };

        var token = new JwtSecurityToken(
            issuer: JwtIssuer,
            audience: JwtAudience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
