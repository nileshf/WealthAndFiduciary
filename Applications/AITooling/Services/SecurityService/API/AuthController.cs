using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SecurityService.Application;

namespace SecurityService.API;

/// <summary>
/// Authentication controller for user registration and login
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AuthService _authService;

    /// <summary>
    /// Initializes a new instance of the AuthController
    /// </summary>
    /// <param name="authService">Authentication service</param>
    public AuthController(AuthService authService)
    {
        _authService = authService;
    }

    /// <summary>
    /// Register a new user
    /// </summary>
    /// <param name="request">Registration request containing username, password, and optional role</param>
    /// <returns>User details including ID, username, and role</returns>
    /// <response code="200">Returns the newly created user</response>
    /// <response code="400">If the request is invalid</response>
    [HttpPost("register")]
    [ProducesResponseType(typeof(object), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var user = await _authService.RegisterAsync(request.Username, request.Password, request.Role ?? "User");
        return Ok(new { user.Id, user.Username, user.Role });
    }

    /// <summary>
    /// Login with username and password
    /// </summary>
    /// <param name="request">Login request containing username and password</param>
    /// <returns>JWT token for authentication</returns>
    /// <response code="200">Returns the JWT token</response>
    /// <response code="401">If credentials are invalid</response>
    [HttpPost("login")]
    [ProducesResponseType(typeof(object), 200)]
    [ProducesResponseType(401)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var token = await _authService.LoginAsync(request.Username, request.Password);
        if (token == null)
            return Unauthorized(new { message = "Invalid credentials" });

        return Ok(new { token });
    }
}

/// <summary>
/// Login request model
/// </summary>
/// <param name="Username">Username for authentication</param>
/// <param name="Password">Password for authentication</param>
public record LoginRequest(
    [Required(ErrorMessage = "Username is required")]
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Username must be between 1 and 100 characters")]
    string Username,

    [Required(ErrorMessage = "Password is required")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Password must be at least 6 characters")]
    string Password
);

/// <summary>
/// Registration request model
/// </summary>
/// <param name="Username">Desired username</param>
/// <param name="Password">Password for the account</param>
/// <param name="Role">Optional role (defaults to "User")</param>
public record RegisterRequest(
    [Required(ErrorMessage = "Username is required")]
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Username must be between 1 and 100 characters")]
    string Username,

    [Required(ErrorMessage = "Password is required")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "Password must be at least 6 characters")]
    string Password,

    [StringLength(50, ErrorMessage = "Role cannot exceed 50 characters")]
    string? Role
);
