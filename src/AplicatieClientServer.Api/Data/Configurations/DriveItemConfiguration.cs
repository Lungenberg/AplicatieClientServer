using AplicatieClientServer.Api.Features.Drive;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AplicatieClientServer.Api.Data.Configurations;

public sealed class DriveItemConfiguration : IEntityTypeConfiguration<DriveItem>
{
    public void Configure(EntityTypeBuilder<DriveItem> builder)
    {
        builder.Property(item => item.Kind)
            .HasConversion<int>();

        builder.ToTable("drive_items", table =>
        {
            table.HasCheckConstraint(
                "ck_drive_items_size_nonnegative",
                """
                "SizeBytes" >= 0
                """);

            table.HasCheckConstraint(
                "ck_drive_items_storage_by_kind",
                $"""
                  ("Kind" = {(int)DriveItemKind.Folder}
                     AND "StorageKey" IS NULL
                     AND "SizeBytes" = 0)
                 OR
                  ("Kind" = {(int)DriveItemKind.File}
                     AND "StorageKey" IS NOT NULL
                     AND btrim("StorageKey") <> '')
                 """);
        });

        builder.HasKey(item => item.Id);

        builder.HasOne<DriveItem>() // у элемента может быть 1 родитель
            .WithMany() // у родителя может быть несколько дочерних элементов
            .HasForeignKey(item => new { item.OwnerId, item.ParentId }) // со стороны дочернего элемента используется пара ownerId + parentId
            .HasPrincipalKey(parent => new { parent.OwnerId, parent.Id }) // ищем родителя по паре ownerId + Id
            .OnDelete(DeleteBehavior.Restrict) // удаление дочерних строк при удалении родителя запрещено
            .HasConstraintName("fk_drive_items_parent_same_owner");

        builder.Property(item => item.Name)
            .IsRequired()
            .HasMaxLength(255);
    }
}