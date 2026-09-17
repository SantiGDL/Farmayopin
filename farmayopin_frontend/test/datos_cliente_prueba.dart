import 'package:farmayopin_frontend/dtos/carrito_cliente.dart';
import 'package:farmayopin_frontend/dtos/producto_listado.dart';
import 'package:farmayopin_frontend/dtos/compra_confirmada.dart';
import 'package:farmayopin_frontend/servicios/servicio_admin.dart';
import 'package:farmayopin_frontend/servicios/servicio_cliente.dart';

const ProductoListado medicamentoPrueba = ProductoListado(
  'Paracetamol 500 mg',
  'Analgésico y antipirético',
  2450,
  320,
  'Medicamentos',
  id: 1,
  codigo: 'P1',
  unidad: 'TABLETA',
);
const ProductoListado vitaminaPrueba = ProductoListado(
  'Vitamina C 500 mg',
  'Refuerza el sistema',
  100.5,
  0,
  'Vitaminas',
  id: 2,
  codigo: 'P2',
);
const List<ProductoListado> productosPrueba = [
  medicamentoPrueba,
  vitaminaPrueba,
];
const CarritoCliente carritoPrueba = CarritoCliente(
  7,
  [
    LineaCarritoCliente(1, medicamentoPrueba, 2, 4900),
    LineaCarritoCliente(2, vitaminaPrueba, 3, 301.5),
  ],
  5,
  5201.5,
  700,
  5901.5,
);
const CarritoCliente carritoVacio = CarritoCliente(null, [], 0, 0, 0, 0);

class ServicioClientePrueba extends ServicioCliente {
  const ServicioClientePrueba({
    this.productos = productosPrueba,
    this.carrito = carritoPrueba,
  });

  final List<ProductoListado> productos;
  final CarritoCliente carrito;

  @override
  Future<List<ProductoListado>> listarProductos() async {
    return productos;
  }

  @override
  Future<CarritoCliente> verCarrito() async {
    return carrito;
  }
}

class ServicioAdminPrueba extends ServicioAdmin {
  const ServicioAdminPrueba();

  @override
  Future<List<ProductoListado>> listarProductos() async {
    return productosPrueba;
  }
}

// Doble mutable para comprobar qué solicita la interfaz en el flujo completo.
// Las reglas de negocio se verifican por separado en las pruebas del backend.
class ServicioFlujoPrueba extends ServicioCliente {
  CarritoCliente carrito = carritoVacio;
  int agregados = 0;
  int ultimaCantidad = 0;
  int confirmaciones = 0;
  Future<CompraConfirmada>? confirmacionDemorada;

  @override
  Future<List<ProductoListado>> listarProductos() async => productosPrueba;

  @override
  Future<CarritoCliente> verCarrito() async => carrito;

  void establecerCantidad(int cantidad) {
    if (cantidad == 0) {
      carrito = carritoVacio;
    } else {
      final double subtotal = medicamentoPrueba.precio * cantidad;
      carrito = CarritoCliente(
        7,
        [LineaCarritoCliente(1, medicamentoPrueba, cantidad, subtotal)],
        cantidad,
        subtotal,
        700,
        subtotal + 700,
      );
    }
  }

  @override
  Future<CarritoCliente> agregarProducto(int productoId, int cantidad) async {
    agregados++;
    ultimaCantidad = cantidad;
    establecerCantidad(carrito.cantidadProductos + cantidad);
    return carrito;
  }

  @override
  Future<CarritoCliente> cambiarCantidad(int lineaId, int cantidad) async {
    establecerCantidad(cantidad);
    return carrito;
  }

  @override
  Future<CarritoCliente> eliminarLinea(int lineaId) async {
    establecerCantidad(0);
    return carrito;
  }

  @override
  Future<CompraConfirmada> confirmarCompra() async {
    confirmaciones++;
    final CompraConfirmada compra;
    if (confirmacionDemorada != null) {
      compra = await confirmacionDemorada!;
    } else {
      compra = CompraConfirmada(1, carrito.subtotal, 700, carrito.total!);
    }
    establecerCantidad(0);
    return compra;
  }
}
