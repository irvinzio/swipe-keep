using Microsoft.AspNetCore.Mvc;
using SwipeClean.Application.Auth;

namespace SwipeClean.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken cancellationToken)
    {
        var baseUrl = $"{Request.Scheme}://{Request.Host}";
        await _authService.RegisterAsync(request, baseUrl, cancellationToken);
        return Accepted(new { message = "Registration successful. Check your email to confirm your account." });
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _authService.LoginAsync(request, cancellationToken));
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh([FromBody] RefreshRequest request, CancellationToken cancellationToken)
    {
        return Ok(await _authService.RefreshAsync(request, cancellationToken));
    }

    [HttpGet("confirm")]
    public async Task<IActionResult> Confirm([FromQuery] string token, CancellationToken cancellationToken)
    {
        await _authService.ConfirmEmailAsync(token, cancellationToken);
        return Ok(new { message = "Email confirmed successfully." });
    }
}
