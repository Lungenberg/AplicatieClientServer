using AplicatieClientServer.Api.Data;
using AplicatieClientServer.Api.Features.Auth;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration
    .GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException(
        "Connection string 'DefaultConnection' is not configured.");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services
    .AddIdentityApiEndpoints<ApplicationUser>(options =>
    {
        options.User.RequireUniqueEmail = true;
        options.Password.RequiredLength = 8;
        options.SignIn.RequireConfirmedEmail = false;
        options.SignIn.RequireConfirmedAccount = false;
    })
    .AddEntityFrameworkStores<AppDbContext>();

builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.Name = "AcsDrive.Auth";
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = builder.Environment.IsDevelopment()
        ? CookieSecurePolicy.SameAsRequest
        : CookieSecurePolicy.Always;

    options.ExpireTimeSpan = TimeSpan.FromHours(8);
    options.SlidingExpiration = true;

    options.Events.OnRedirectToLogin = context =>
    {
        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        return Task.CompletedTask;
    };

    options.Events.OnRedirectToAccessDenied = context =>
    {
        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        return Task.CompletedTask;
    };
});

builder.Services.AddAuthorization();

builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN";
    options.Cookie.Name = "AcsDrive.Csrf";
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.Cookie.SecurePolicy = builder.Environment.IsDevelopment()
        ? CookieSecurePolicy.SameAsRequest
        : CookieSecurePolicy.Always;
});

builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, context, cancellationToken) =>
    {
        document.Info.Title = "ACS Drive API";
        document.Info.Version = "v1";
        document.Info.Description =
            "For cookie authentication, call POST /auth/login with " +
            "useSessionCookies=true, then use /auth/me and POST /auth/logout with {}. " +
            "The browser sends the authentication cookie automatically. " +
            "POST requests require a fresh /auth/csrf token in X-CSRF-TOKEN; " +
            "Swagger UI adds it automatically.";

        return Task.CompletedTask;
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/openapi/v1.json", "ACS Drive API v1");
        options.DocumentTitle = "ACS Drive API";
        options.EnableTryItOutByDefault();
        options.UseRequestInterceptor("""
            function (request) {
                const method = (request.method || "GET").toUpperCase();
                const target = new URL(request.url, window.location.origin);
                if (target.origin === window.location.origin &&
                    target.pathname.startsWith("/auth/") &&
                    !["GET", "HEAD", "OPTIONS"].includes(method)) {
                    return fetch("/auth/csrf", {
                        credentials: "same-origin",
                        cache: "no-store"
                    }).then(response => {
                        if (!response.ok) throw new Error("Could not get CSRF token.");
                        return response.json();
                    }).then(token => {
                        request.headers["X-CSRF-TOKEN"] = token.requestToken;
                        return request;
                    });
                }
                return request;
            }
            """);
    });
}

app.UseAuthentication();
app.UseAuthorization();

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

app.MapAuthEndpoints();

app.Run();
