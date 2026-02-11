using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.Extensions.Configuration;
using Moq;
using SecurityService.Application;
using SecurityService.Domain;
using Xunit;

namespace SecurityService.UnitTests.Application;

public class AuthServiceTests
{
    private readonly Mock<IUserRepository> _userRepositoryMock;
    private readonly Mock<IConfiguration> _configurationMock;
    private readonly AuthService _authService;

    public AuthServiceTests()
    {
        _userRepositoryMock = new Mock<IUserRepository>();
        _configurationMock = new Mock<IConfiguration>();

        // Setup JWT configuration
        _configurationMock.Setup(x => x["Jwt:Key"]).Returns("YourSuperSecretKeyThatIsAtLeast32CharactersLong!");
        _configurationMock.Setup(x => x["Jwt:Issuer"]).Returns("SecurityService");
        _configurationMock.Setup(x => x["Jwt:Audience"]).Returns("MicroservicesApp");

        _authService = new AuthService(_userRepositoryMock.Object, _configurationMock.Object);
    }

    [Fact]
    public async Task RegisterAsync_ShouldCreateUserWithHashedPassword()
    {
        // Arrange
        var username = "testuser";
        var password = "TestPassword123!";
        var role = "User";

        _userRepositoryMock
            .Setup(x => x.CreateAsync(It.IsAny<User>()))
            .ReturnsAsync((User u) => u);

        // Act
        var result = await _authService.RegisterAsync(username, password, role);

        // Assert
        result.Should().NotBeNull();
        result.Username.Should().Be(username);
        result.Role.Should().Be(role);
        result.PasswordHash.Should().NotBeEmpty();
        result.PasswordHash.Should().NotBe(password); // Password should be hashed
        BCrypt.Net.BCrypt.Verify(password, result.PasswordHash).Should().BeTrue();
    }

    [Fact]
    public async Task RegisterAsync_WithoutRole_ShouldDefaultToUser()
    {
        // Arrange
        var username = "testuser";
        var password = "TestPassword123!";

        _userRepositoryMock
            .Setup(x => x.CreateAsync(It.IsAny<User>()))
            .ReturnsAsync((User u) => u);

        // Act
        var result = await _authService.RegisterAsync(username, password);

        // Assert
        result.Role.Should().Be("User");
    }

    [Fact]
    public async Task LoginAsync_WithValidCredentials_ShouldReturnToken()
    {
        // Arrange
        var username = "testuser";
        var password = "TestPassword123!";
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

        var user = new User
        {
            Id = 1,
            Username = username,
            PasswordHash = passwordHash,
            Role = "User"
        };

        _userRepositoryMock
            .Setup(x => x.GetByUsernameAsync(username))
            .ReturnsAsync(user);

        // Act
        var token = await _authService.LoginAsync(username, password);

        // Assert
        token.Should().NotBeNullOrEmpty();
    }

    [Fact]
    public async Task LoginAsync_WithInvalidUsername_ShouldReturnNull()
    {
        // Arrange
        var username = "nonexistent";
        var password = "TestPassword123!";

        _userRepositoryMock
            .Setup(x => x.GetByUsernameAsync(username))
            .ReturnsAsync((User?)null);

        // Act
        var token = await _authService.LoginAsync(username, password);

        // Assert
        token.Should().BeNull();
    }

    [Fact]
    public async Task LoginAsync_WithInvalidPassword_ShouldReturnNull()
    {
        // Arrange
        var username = "testuser";
        var correctPassword = "CorrectPassword123!";
        var wrongPassword = "WrongPassword123!";
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(correctPassword);

        var user = new User
        {
            Id = 1,
            Username = username,
            PasswordHash = passwordHash,
            Role = "User"
        };

        _userRepositoryMock
            .Setup(x => x.GetByUsernameAsync(username))
            .ReturnsAsync(user);

        // Act
        var token = await _authService.LoginAsync(username, wrongPassword);

        // Assert
        token.Should().BeNull();
    }

    [Fact]
    public async Task GenerateToken_ShouldCreateValidJWT()
    {
        // Arrange
        var username = "testuser";
        var password = "TestPassword123!";
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

        var user = new User
        {
            Id = 1,
            Username = username,
            PasswordHash = passwordHash,
            Role = "Admin"
        };

        _userRepositoryMock
            .Setup(x => x.GetByUsernameAsync(username))
            .ReturnsAsync(user);

        // Act
        var token = await _authService.LoginAsync(username, password);

        // Assert
        token.Should().NotBeNullOrEmpty();

        // Decode token to verify claims
        var handler = new JwtSecurityTokenHandler();
        var jwtToken = handler.ReadJwtToken(token);

        jwtToken.Claims.Should().Contain(c => c.Type == ClaimTypes.Name && c.Value == username);
        jwtToken.Claims.Should().Contain(c => c.Type == ClaimTypes.Role && c.Value == "Admin");
    }

    [Fact]
    public async Task GenerateToken_ShouldHaveTwoHourExpiration()
    {
        // Arrange
        var username = "testuser";
        var password = "TestPassword123!";
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

        var user = new User
        {
            Id = 1,
            Username = username,
            PasswordHash = passwordHash,
            Role = "User"
        };

        _userRepositoryMock
            .Setup(x => x.GetByUsernameAsync(username))
            .ReturnsAsync(user);

        // Act
        var token = await _authService.LoginAsync(username, password);

        // Assert
        var handler = new JwtSecurityTokenHandler();
        var jwtToken = handler.ReadJwtToken(token);

        var expirationTime = jwtToken.ValidTo;
        var expectedExpiration = DateTime.UtcNow.AddHours(2);

        // Allow 1 minute tolerance for test execution time
        expirationTime.Should().BeCloseTo(expectedExpiration, TimeSpan.FromMinutes(1));
    }

    [Fact]
    public async Task GenerateToken_ShouldContainUsernameAndRoleClaims()
    {
        // Arrange
        var username = "testuser";
        var password = "TestPassword123!";
        var role = "Manager";
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);

        var user = new User
        {
            Id = 1,
            Username = username,
            PasswordHash = passwordHash,
            Role = role
        };

        _userRepositoryMock
            .Setup(x => x.GetByUsernameAsync(username))
            .ReturnsAsync(user);

        // Act
        var token = await _authService.LoginAsync(username, password);

        // Assert
        var handler = new JwtSecurityTokenHandler();
        var jwtToken = handler.ReadJwtToken(token);

        var claims = jwtToken.Claims.ToList();
        claims.Should().Contain(c => c.Type == ClaimTypes.Name && c.Value == username);
        claims.Should().Contain(c => c.Type == ClaimTypes.Role && c.Value == role);
    }
}
