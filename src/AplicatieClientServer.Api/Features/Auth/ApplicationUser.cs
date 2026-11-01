using Microsoft.AspNetCore.Identity;

namespace AplicatieClientServer.Api.Features.Auth;

public sealed class ApplicationUser : IdentityUser<Guid>
{
    public ApplicationUser()
    {
        Id = Guid.NewGuid();
    }
}
