import 'package:farmayopin_frontend/dtos/carrito_cliente.dart';
import 'package:farmayopin_frontend/dtos/producto_listado.dart';
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
