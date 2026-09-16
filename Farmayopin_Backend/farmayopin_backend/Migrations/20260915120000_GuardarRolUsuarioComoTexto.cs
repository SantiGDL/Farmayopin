using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace farmayopin_backend.Migrations
{
    public partial class GuardarRolUsuarioComoTexto : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "Rol",
                table: "Usuarios",
                type: "varchar(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int")
                .Annotation("MySql:CharSet", "utf8mb4");

            // Al cambiar el tipo, MariaDB conserva los números como texto.
            migrationBuilder.Sql("""
                UPDATE `Usuarios`
                SET `Rol` = CASE `Rol`
                    WHEN '0' THEN 'CLIENTE'
                    WHEN '1' THEN 'ADMIN'
                    ELSE `Rol`
                END;
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Convertir los nombres antes de recuperar la columna numérica.
            migrationBuilder.Sql("""
                UPDATE `Usuarios`
                SET `Rol` = CASE `Rol`
                    WHEN 'CLIENTE' THEN '0'
                    WHEN 'ADMIN' THEN '1'
                    ELSE `Rol`
                END;
                """);

            migrationBuilder.AlterColumn<int>(
                name: "Rol",
                table: "Usuarios",
                type: "int",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "varchar(20)",
                oldMaxLength: 20)
                .OldAnnotation("MySql:CharSet", "utf8mb4");
        }
    }
}
