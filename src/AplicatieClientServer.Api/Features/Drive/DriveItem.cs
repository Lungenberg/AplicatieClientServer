namespace AplicatieClientServer.Api.Features.Drive;

public sealed class DriveItem
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid OwnerId { get; set; }

    public Guid? ParentId { get; set; }

    public required string Name { get; set; }

    public string? StorageKey { get; set; }

    public required DriveItemKind Kind { get; set; }
    
    public long SizeBytes { get; set; }

    public string? ContentType { get; set; }

    public DateTimeOffset CreatedAtUtc { get; set; } = DateTimeOffset.UtcNow;

    public DateTimeOffset UpdatedAtUtc { get; set; } = DateTimeOffset.UtcNow;
}