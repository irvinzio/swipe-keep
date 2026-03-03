using Microsoft.EntityFrameworkCore;
using SwipeClean.Application.Abstractions;
using SwipeClean.Domain.Entities;

namespace SwipeClean.Application.Auth;

public interface IAuthService
{
    Task RegisterAsync(RegisterRequest request, string confirmationBaseUrl, CancellationToken cancellationToken);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken);
    Task<AuthResponse> RefreshAsync(RefreshRequest request, CancellationToken cancellationToken);
    Task ConfirmEmailAsync(string token, CancellationToken cancellationToken);
}

public class AuthService : IAuthService
{
    private readonly IAppDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly IEmailSender _emailSender;

    public AuthService(IAppDbContext dbContext, IPasswordHasher passwordHasher, ITokenService tokenService, IEmailSender emailSender)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _emailSender = emailSender;
    }

    public async Task RegisterAsync(RegisterRequest request, string confirmationBaseUrl, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (await _dbContext.Users.AnyAsync(u => u.Email == email, cancellationToken))
        {
            throw new InvalidOperationException("Email is already registered.");
        }

        var confirmationToken = Guid.NewGuid().ToString("N");
        var user = new User
        {
            Email = email,
            PasswordHash = _passwordHasher.Hash(request.Password),
            EmailConfirmed = false,
            EmailConfirmationToken = confirmationToken
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var confirmationLink = $"{confirmationBaseUrl.TrimEnd('/')}/api/auth/confirm?token={Uri.EscapeDataString(confirmationToken)}";
        await _emailSender.SendEmailConfirmationAsync(user.Email, confirmationLink, cancellationToken);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _dbContext.Users.Include(u => u.RefreshTokens).SingleOrDefaultAsync(u => u.Email == email, cancellationToken)
            ?? throw new UnauthorizedAccessException("Invalid credentials.");

        if (!_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        if (!user.EmailConfirmed)
        {
            throw new UnauthorizedAccessException("Email must be confirmed before login.");
        }

        var tokens = await IssueTokensAsync(user, cancellationToken);
        return tokens;
    }

    public async Task<AuthResponse> RefreshAsync(RefreshRequest request, CancellationToken cancellationToken)
    {
        var refreshToken = await _dbContext.RefreshTokens
            .Include(rt => rt.User)
            .SingleOrDefaultAsync(rt => rt.Token == request.RefreshToken, cancellationToken)
            ?? throw new UnauthorizedAccessException("Invalid refresh token.");

        if (refreshToken.IsRevoked || refreshToken.ExpiresAt <= DateTime.UtcNow || refreshToken.User is null)
        {
            throw new UnauthorizedAccessException("Invalid refresh token.");
        }

        refreshToken.IsRevoked = true;
        var tokens = await IssueTokensAsync(refreshToken.User, cancellationToken);
        return tokens;
    }

    public async Task ConfirmEmailAsync(string token, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users.SingleOrDefaultAsync(u => u.EmailConfirmationToken == token, cancellationToken)
            ?? throw new KeyNotFoundException("Invalid email confirmation token.");

        user.EmailConfirmed = true;
        user.EmailConfirmationToken = string.Empty;
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<AuthResponse> IssueTokensAsync(User user, CancellationToken cancellationToken)
    {
        var (accessToken, accessExpiry) = _tokenService.CreateAccessToken(user.Id, user.Email);
        var refreshTokenValue = _tokenService.GenerateRefreshToken();
        var refreshExpiry = DateTime.UtcNow.AddDays(7);

        var refreshToken = new RefreshToken
        {
            UserId = user.Id,
            Token = refreshTokenValue,
            ExpiresAt = refreshExpiry,
            IsRevoked = false
        };

        _dbContext.RefreshTokens.Add(refreshToken);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new AuthResponse(accessToken, accessExpiry, refreshTokenValue, refreshExpiry);
    }
}
