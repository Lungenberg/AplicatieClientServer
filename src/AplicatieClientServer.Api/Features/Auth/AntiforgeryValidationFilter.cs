using Microsoft.AspNetCore.Antiforgery;

namespace AplicatieClientServer.Api.Features.Auth;

public sealed class AntiforgeryValidationFilter(IAntiforgery antiforgery)
    : IEndpointFilter
{
    public async ValueTask<object?> InvokeAsync(
        EndpointFilterInvocationContext context,
        EndpointFilterDelegate next)
    {
        var httpContext = context.HttpContext;
        httpContext.Response.Headers.CacheControl = "no-cache, no-store";
        httpContext.Response.Headers.Pragma = "no-cache";

        if (!HttpMethods.IsGet(httpContext.Request.Method) &&
            !HttpMethods.IsHead(httpContext.Request.Method) &&
            !HttpMethods.IsOptions(httpContext.Request.Method))
        {
            try
            {
                await antiforgery.ValidateRequestAsync(httpContext);
            }
            catch (AntiforgeryValidationException)
            {
                return TypedResults.Problem(
                    title: "CSRF validation failed.",
                    detail: "Get a fresh token from /auth/csrf and send it in X-CSRF-TOKEN.",
                    statusCode: StatusCodes.Status400BadRequest,
                    extensions: new Dictionary<string, object?>
                    {
                        ["code"] = "csrf_validation_failed"
                    });
            }
        }

        return await next(context);
    }
}
