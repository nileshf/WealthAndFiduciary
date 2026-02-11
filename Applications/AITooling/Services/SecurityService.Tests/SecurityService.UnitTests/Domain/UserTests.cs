using FluentAssertions;
using SecurityService.Domain;
using Xunit;

namespace SecurityService.UnitTests.Domain;

public class UserTests
{
    [Fact]
    public void User_Instantiation_ShouldSetDefaultValues()
    {
        // Arrange & Act
        var user = new User();

        // Assert
        user.Id.Should().Be(0);
        user.Username.Should().BeEmpty();
        user.PasswordHash.Should().BeEmpty();
        user.Role.Should().Be("User");
    }

    [Fact]
    public void User_DefaultRole_ShouldBeUser()
    {
        // Arrange & Act
        var user = new User
        {
            Username = "testuser",
            PasswordHash = "hash123"
        };

        // Assert
        user.Role.Should().Be("User");
    }

    [Fact]
    public void User_PropertySetters_ShouldWork()
    {
        // Arrange
        var user = new User();

        // Act
        user.Id = 1;
        user.Username = "john.doe";
        user.PasswordHash = "hashedpassword";
        user.Role = "Admin";

        // Assert
        user.Id.Should().Be(1);
        user.Username.Should().Be("john.doe");
        user.PasswordHash.Should().Be("hashedpassword");
        user.Role.Should().Be("Admin");
    }

    [Theory]
    [InlineData("User")]
    [InlineData("Admin")]
    [InlineData("Manager")]
    public void User_Role_CanBeSetToAnyValue(string role)
    {
        // Arrange & Act
        var user = new User { Role = role };

        // Assert
        user.Role.Should().Be(role);
    }
}
