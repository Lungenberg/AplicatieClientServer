using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AplicatieClientServer.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "drive_items",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    ParentId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    StorageKey = table.Column<string>(type: "text", nullable: true),
                    Kind = table.Column<int>(type: "integer", nullable: false),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    ContentType = table.Column<string>(type: "text", nullable: true),
                    CreatedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_drive_items", x => x.Id);
                    table.UniqueConstraint("AK_drive_items_OwnerId_Id", x => new { x.OwnerId, x.Id });
                    table.CheckConstraint("ck_drive_items_size_nonnegative", "\"SizeBytes\" >= 0");
                    table.CheckConstraint("ck_drive_items_storage_by_kind", " (\"Kind\" = 1\r\n    AND \"StorageKey\" IS NULL\r\n    AND \"SizeBytes\" = 0)\r\nOR\r\n (\"Kind\" = 2\r\n    AND \"StorageKey\" IS NOT NULL\r\n    AND btrim(\"StorageKey\") <> '')");
                    table.ForeignKey(
                        name: "fk_drive_items_parent_same_owner",
                        columns: x => new { x.OwnerId, x.ParentId },
                        principalTable: "drive_items",
                        principalColumns: new[] { "OwnerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_drive_items_OwnerId_ParentId",
                table: "drive_items",
                columns: new[] { "OwnerId", "ParentId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "drive_items");
        }
    }
}
