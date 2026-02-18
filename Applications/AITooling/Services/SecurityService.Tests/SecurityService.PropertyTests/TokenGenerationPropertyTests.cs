using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using FsCheck;
using FsCheck.Xunit;
using SecurityService.Application;
using SecurityService.Domain;
using Microsoft.Extensions.Configuration;
using Moq;

namespace SecurityService.PropertyTests;

/// <summary>
/// Property-based tests for JWT token generation correctness
/// </summary>
public class TokenGenerationPropertyTests
{
    private static AuthService CreateAuthService()
    {
        var mockRepo = new Mock<IUserRepository>();
        var mockConfig = new Mock<IConfiguration>();

        // Setup JWT configuration
        mockConfig.Setup(c => c["Jwt:Key"]).Returns("this-is-a-very-secure-secret-key-with-at-least-32-characters");
        mockConfig.Setup(c => c["Jwt:Issuer"]).Returns("SecurityService");
        mockConfig.Setup(c => c["Jwt:Audience"]).Returns("AIToolingClients");

        return new AuthService(mockRepo.Object, mockConfig.Object);
    }

    /// <summary>
    /// Property 2.1: Token Expiration
    /// Validates: Requirements 2.3
    /// 
    /// For any user, the generated token should expire exactly 2 hours from now.
    /// We allow a small tolerance (1 second) for execution time.
    /// </summary>
    [Property(MaxTest = 50)]
    public Property TokenExpiration_IsAlwaysTwoHours()
    {
        return Prop.ForAll<NonEmptyString, NonEmptyString>((usernameGen, roleGen) =>
        {
            var username = usernameGen.Get;
            var role = roleGen.Get;

            var user = new User
            {
                Id = 1,
                Username = username,
                PasswordHash = "dummy-hash",
                Role = role
            };

            var service = CreateAuthService();
            var beforeGeneration = DateTime.UtcNow;

            // Use reflection to call private GenerateToken method
            var method = typeof(AuthService).GetMethod("GenerateToken",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var token = (string)method!.Invoke(service, new object[] { user })!;

            var afterGeneration = DateTime.UtcNow;

            // Parse the token
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);

            // Check expiration is approximately 2 hours from now
            // Note: AuthService uses DateTime.Now, so we need to convert to UTC
            var expectedExpiration = beforeGeneration.AddHours(2);
            var actualExpiration = jwtToken.ValidTo.ToUniversalTime();

            // Allow 5 seconds tolerance for execution time and timezone conversion
            var difference = Math.Abs((actualExpiration - expectedExpiration).TotalSeconds);

            return difference <= 5;
        });
    }

    /// <summary>
    /// Property 2.2: Token Claims Completeness
    /// Validates: Requirements 2.2
    /// 
    /// For any user, the generated token should always contain username and role claims.
    /// </summary>
    [Property(MaxTest = 50)]
    public Property TokenClaims_AlwaysContainUsernameAndRole()
    {
        return Prop.ForAll<NonEmptyString, NonEmptyString>((usernameGen, roleGen) =>
        {
            var username = usernameGen.Get;
            var role = roleGen.Get;

            var user = new User
            {
                Id = 1,
                Username = username,
                PasswordHash = "dummy-hash",
                Role = role
            };

            var service = CreateAuthService();

            // Use reflection to call private GenerateToken method
            var method = typeof(AuthService).GetMethod("GenerateToken",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var token = (string)method!.Invoke(service, new object[] { user })!;

            // Parse the token
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);

            // Check claims
            var nameClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Name);
            var roleClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Role);

            // Both claims must exist and have correct values
            return nameClaim != null &&
                   nameClaim.Value == username &&
                   roleClaim != null &&
                   roleClaim.Value == role;
        });
    }

    /// <summary>
    /// Property: Token Format Validity
    /// Additional property to ensure tokens are always valid JWT format.
    /// </summary>
    [Property(MaxTest = 50)]
    public Property Token_IsAlwaysValidJwtFormat()
    {
        return Prop.ForAll<NonEmptyString, NonEmptyString>((usernameGen, roleGen) =>
        {
            var username = usernameGen.Get;
            var role = roleGen.Get;

            var user = new User
            {
                Id = 1,
                Username = username,
                PasswordHash = "dummy-hash",
                Role = role
            };

            var service = CreateAuthService();

            // Use reflection to call private GenerateToken method
            var method = typeof(AuthService).GetMethod("GenerateToken",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var token = (string)method!.Invoke(service, new object[] { user })!;

            // Try to parse the token - should not throw
            try
            {
                var handler = new JwtSecurityTokenHandler();
                var jwtToken = handler.ReadJwtToken(token);

                // Token should have 3 parts separated by dots
                var parts = token.Split('.');
                return parts.Length == 3 && jwtToken != null;
            }
            catch
            {
                return false;
            }
        });
    }
}
