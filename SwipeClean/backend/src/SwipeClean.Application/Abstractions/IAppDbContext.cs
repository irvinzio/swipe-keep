using Microsoft.EntityFrameworkCore;
using SwipeClean.Domain.Entities;

namespace SwipeClean.Application.Abstractions;

public interface IAppDbContext
{
    DbSet<User> Users { get; }
    DbSet<RefreshToken> RefreshTokens { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
