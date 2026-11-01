using AplicatieClientServer.Api.Data.Configurations;
using AplicatieClientServer.Api.Features.Auth;
using AplicatieClientServer.Api.Features.Drive;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace AplicatieClientServer.Api.Data;

public sealed class AppDbContext
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<DriveItem> DriveItems => Set<DriveItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfiguration(new DriveItemConfiguration());
    }
}
