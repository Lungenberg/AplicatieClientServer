using AplicatieClientServer.Api.Features.Drive;
using Microsoft.EntityFrameworkCore;

namespace AplicatieClientServer.Api.Data;

public sealed class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
        
    }

    public DbSet<DriveItem> DriveItems => Set<DriveItem>();
}