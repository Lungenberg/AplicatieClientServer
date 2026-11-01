using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace AplicatieClientServer.Api.Features.Auth;

public static class AuthEndpoints
{
    public static IEndpointRouteBuilder MapAuthEndpoints(
        this IEndpointRouteBuilder endpoints)
    {
        var auth = endpoints.MapGroup("/auth").WithTags("Auth");

        auth.MapIdentityApi<ApplicationUser>();

        var session = auth.MapGroup("")
            .RequireAuthorization(new AuthorizeAttribute
            {
                AuthenticationSchemes = IdentityConstants.ApplicationScheme
            });

        session.MapGet("/me", GetCurrentUserAsync);
        session.MapPost("/logout", LogoutAsync);

        return endpoints;
    }

    private static async Task<Results<Ok<CurrentUserResponse>, UnauthorizedHttpResult>>
        GetCurrentUserAsync(
            ClaimsPrincipal principal,
            UserManager<ApplicationUser> userManager)
    {
        var user = await userManager.GetUserAsync(principal);

        if (user is null)
        {
            return TypedResults.Unauthorized();
        }

        return TypedResults.Ok(new CurrentUserResponse(user.Id, user.Email));
    }

    private static async Task<Results<NoContent, ValidationProblem>>
        LogoutAsync(
            [FromBody] JsonElement request,
            SignInManager<ApplicationUser> signInManager)
    {
        if (request.ValueKind != JsonValueKind.Object ||
            request.EnumerateObject().Any())
        {
            return TypedResults.ValidationProblem(
                new Dictionary<string, string[]>
                {
                    ["body"] = ["Send an empty JSON object."]
                });
        }

        await signInManager.SignOutAsync();

        return TypedResults.NoContent();
    }
}
