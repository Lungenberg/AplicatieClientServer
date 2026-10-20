using AplicatieClientServer.Api.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration
    .GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException(
        "Connection string 'DefaultConnection' is not configured.");

builder.Services.AddDbContext<AppDbContext>(options => 
    options.UseNpgsql(connectionString));

var app = builder.Build();

app.MapGet("/health", () => TypedResults.Ok(new
{
    status = "ok",
    service = "AplicatieClientServer.Api",
    version = "0.1.0"
}));

app.MapGet("/health/db", async Task<IResult> (
    AppDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var canConnect = await dbContext.Database
        .CanConnectAsync(cancellationToken);

    if (!canConnect)
    {
        return TypedResults.Problem(
            title: "Database connection failed.",
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }

    return TypedResults.Ok(new
    {
        status = "ok",
        database = "reachable"
    });
});

app.Run();
