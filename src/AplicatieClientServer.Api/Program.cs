var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapGet("/health", () => TypedResults.Ok(new
{
    status = "ok",
    service = "AplicatieClientServer.Api",
    version = "0.1.0"
}));

app.Run();
