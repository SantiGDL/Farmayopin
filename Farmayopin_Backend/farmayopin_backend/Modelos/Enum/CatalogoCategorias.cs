namespace farmayopin_backend.Modelos;

public static class CatalogoCategorias
{
    public static string Nombre(CategoriaProducto categoria) => categoria switch
    {
        CategoriaProducto.MEDICAMENTOS => "Medicamentos",
        CategoriaProducto.HIGIENE => "Higiene",
        CategoriaProducto.VITAMINAS => "Vitaminas",
        CategoriaProducto.SIN_CATEGORIA => "Sin categoría",
        CategoriaProducto.PRIMEROS_AUXILIOS => "Primeros auxilios",
        _ => categoria.ToString()
    };

    public static string Nombre(string? codigo) =>
        Enum.TryParse<CategoriaProducto>(codigo, out var categoria)
            ? Nombre(categoria) : Nombre(CategoriaProducto.SIN_CATEGORIA);
}
