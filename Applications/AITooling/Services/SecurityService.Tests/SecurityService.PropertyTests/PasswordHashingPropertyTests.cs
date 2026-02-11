using FsCheck;
using FsCheck.Xunit;
using SecurityService.Application;
using Microsoft.Extensions.Configuration;
using Moq;

namespace SecurityService.PropertyTests;

/// <summary>
/// Property-based tests for password hashing correctness
/// </summary>
public class PasswordHashingPropertyTests
{
    /// <summary>
    /// Property 1.1: Password Hash Uniqueness
    /// Validates: Requirements 3.1
    /// 
    /// For any password, different salts produce different hashes.
    /// BCrypt automatically generates unique salts, so the same password
    /// hashed twice should produce different hashes.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property PasswordHash_WithSamePassword_ProducesDifferentHashes()
    {
        return Prop.ForAll<NonEmptyString>(passwordGen =>
        {
            var password = passwordGen.Get;

            // Hash the same password twice
            var hash1 = BCrypt.Net.BCrypt.HashPassword(password);
            var hash2 = BCrypt.Net.BCrypt.HashPassword(password);

            // Different salts should produce different hashes
            return hash1 != hash2;
        });
    }

    /// <summary>
    /// Property 1.2: Password Verification Correctness (Positive Case)
    /// Validates: Requirements 3.2
    /// 
    /// For any password and its hash, verification should return true.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property PasswordVerification_WithCorrectPassword_ReturnsTrue()
    {
        return Prop.ForAll<NonEmptyString>(passwordGen =>
        {
            var password = passwordGen.Get;
            var hash = BCrypt.Net.BCrypt.HashPassword(password);

            // Verification with correct password should return true
            return BCrypt.Net.BCrypt.Verify(password, hash);
        });
    }

    /// <summary>
    /// Property 1.2: Password Verification Correctness (Negative Case)
    /// Validates: Requirements 3.2
    /// 
    /// For any two different passwords, verification should return false.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property PasswordVerification_WithIncorrectPassword_ReturnsFalse()
    {
        return Prop.ForAll<NonEmptyString, NonEmptyString>((password1Gen, password2Gen) =>
        {
            var password1 = password1Gen.Get;
            var password2 = password2Gen.Get;

            // Only test when passwords are different
            if (password1 == password2)
                return true; // Skip this test case

            var hash = BCrypt.Net.BCrypt.HashPassword(password1);

            // Verification with incorrect password should return false
            return !BCrypt.Net.BCrypt.Verify(password2, hash);
        });
    }

    /// <summary>
    /// Property 3.1: Password Never Stored Plain
    /// Validates: Requirements 3.3
    /// 
    /// For any password, the hash should never equal the plain password.
    /// </summary>
    [Property(MaxTest = 100)]
    public Property PasswordHash_NeverEqualsPlainPassword()
    {
        return Prop.ForAll<NonEmptyString>(passwordGen =>
        {
            var password = passwordGen.Get;
            var hash = BCrypt.Net.BCrypt.HashPassword(password);

            // Hash should never equal the plain password
            return hash != password;
        });
    }
}
