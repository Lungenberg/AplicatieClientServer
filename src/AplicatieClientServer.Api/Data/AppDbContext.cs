using AplicatieClientServer.Api.Features.Drive;
using Microsoft.EntityFrameworkCore;
using AplicatieClientServer.Api.Data.Configurations;

namespace AplicatieClientServer.Api.Data;

public sealed class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
        
    }

    public DbSet<DriveItem> DriveItems => Set<DriveItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfiguration(new DriveItemConfiguration());
    }
}