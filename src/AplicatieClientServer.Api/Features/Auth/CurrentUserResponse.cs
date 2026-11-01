namespace AplicatieClientServer.Api.Features.Auth;

public sealed record CurrentUserResponse(Guid Id, string? Email);
