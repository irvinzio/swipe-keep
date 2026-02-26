namespace SwipeClean.Application.Abstractions;

public interface ITokenService
{
    (string token, DateTime expiresAt) CreateAccessToken(Guid userId, string email);
    string GenerateRefreshToken();
}
