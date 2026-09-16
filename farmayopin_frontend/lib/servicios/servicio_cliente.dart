// Aquí se conectarán los endpoints del cliente cuando existan esas funciones.
// Por ahora devolvemos avisos explícitos, sin inventar productos ni compras.
class ServicioCliente {
  const ServicioCliente();

  String verProductos() {
    return 'El catálogo de productos todavía no está disponible.';
  }

  String verCarrito() {
    return 'El carrito todavía no está disponible.';
  }

  String verHistorico() {
    return 'El histórico de compras todavía no está disponible.';
  }
}
