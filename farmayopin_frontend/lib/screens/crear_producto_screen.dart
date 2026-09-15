import 'package:flutter/material.dart';

// Esta pantalla es una guía VISUAL: todavía no envía datos al backend.
// Pensá en los widgets como etiquetas HTML que se anidan:
// Column = elementos en vertical; Row = elementos en horizontal.
class CrearProductoScreen extends StatelessWidget {
  const CrearProductoScreen({super.key});

  // Como una variable de CSS: reutilizamos el mismo color.
  static const verde = Color(0xFF00AAA5);

  @override
  Widget build(BuildContext context) {
    // Scaffold es la estructura de la pantalla; body es su contenido.
    return Scaffold(
      body: SafeArea(
        // Permite desplazar el formulario si la pantalla es pequeña
        // o si el teclado tapa los campos.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            // Equivale a un max-width de CSS. En celular ocupa lo disponible.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  encabezado(context),
                  const SizedBox(height: 24), // Espacio entre bloques.
                  tarjetaPresentacion(),
                  const SizedBox(height: 24),

                  // 1. Campo que ocupa todo el ancho.
                  campoTexto(
                    etiqueta: 'Nombre del producto',
                    ayuda: 'Ingresá el nombre del producto',
                    icono: Icons.sell_outlined,
                  ),
                  const SizedBox(height: 16),

                  // 2. Dos campos en una fila.
                  // Expanded reparte el ancho disponible en partes iguales.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: campoTexto(
                          etiqueta: 'Precio',
                          ayuda: '0,00',
                          icono: Icons.attach_money,
                          teclado: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: campoTexto(
                          etiqueta: 'Stock',
                          ayuda: '0',
                          icono: Icons.inventory_2_outlined,
                          teclado: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Un select, como en HTML. Categorías de ejemplo.
                  const Text('Categoría'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: decoracionCampo(
                      'Seleccioná una categoría',
                      Icons.category_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'medicamentos',
                        child: Text('Medicamentos'),
                      ),
                      DropdownMenuItem(
                        value: 'higiene',
                        child: Text('Higiene personal'),
                      ),
                      DropdownMenuItem(
                        value: 'cuidado',
                        child: Text('Cuidado personal'),
                      ),
                    ],
                    // El widget muestra la selección por sí mismo.
                    // Más adelante guardaremos aquí el ID para enviarlo a C#.
                    onChanged: (valor) {},
                  ),
                  const SizedBox(height: 16),

                  // 4. Varias líneas: similar a un textarea.
                  campoTexto(
                    etiqueta: 'Descripción',
                    ayuda: 'Ingresá una descripción del producto…',
                    icono: Icons.description_outlined,
                    lineas: 3,
                    teclado: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  const Text('Foto del producto'),
                  const SizedBox(height: 6),
                  zonaFoto(context),
                  const SizedBox(height: 20),

                  // onPressed equivale a la función de un onclick.
                  FilledButton.icon(
                    onPressed: () => mostrarAviso(
                      context,
                      'Esta es una maqueta: falta conectar el guardado a la API.',
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar producto'),
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => mostrarAviso(
                      context,
                      'Cancelar volverá al menú cuando agreguemos esa pantalla.',
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Estas funciones devuelven piezas de interfaz para que build se lea
  // de arriba abajo. No hace falta crear un archivo por cada pieza.
  Widget encabezado(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/farmayopin_logo.png', width: 100),
            const Text(
              'Administrador',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => mostrarAviso(
            context,
            'Falta conectar el cierre de sesión.',
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Cerrar sesión'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: const Color(0xFFF2F2F2),
          ),
        ),
      ],
    );
  }

  Widget tarjetaPresentacion() {
    // Container combina fondo, bordes y espacio: parecido a un div con CSS.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4BC3B5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Agregá nuevos artículos al inventario de la farmacia.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.medication, size: 90, color: Color(0xFF9AE5D4)),
        ],
      ),
    );
  }

  // Un solo molde para los campos. Los parámetros entre { } se pasan
  // por nombre: campoTexto(etiqueta: 'Stock', ayuda: '0', ...).
  // required significa obligatorio; "lineas = 1" es un valor por defecto.
  Widget campoTexto({
    required String etiqueta,
    required String ayuda,
    required IconData icono,
    int lineas = 1,
    TextInputType teclado = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta),
        const SizedBox(height: 6),
        TextFormField(
          maxLines: lineas,
          keyboardType: teclado,
          style: const TextStyle(fontSize: 14),
          decoration: decoracionCampo(ayuda, icono),
        ),
      ],
    );
  }

  // Estilo compartido de los inputs; los bordes se heredan de main.dart.
  InputDecoration decoracionCampo(String ayuda, IconData icono) {
    return InputDecoration(
      hintText: ayuda,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      prefixIcon: Icon(icono, size: 20, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget zonaFoto(BuildContext context) {
    return OutlinedButton(
      onPressed: () => mostrarAviso(
        context,
        'Falta implementar la selección de una foto.',
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        backgroundColor: const Color(0xFFF5FAF9),
        side: const BorderSide(color: Color(0xFF9ADBD4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Column(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 36),
          SizedBox(height: 8),
          Text('Subí una foto del producto'),
          SizedBox(height: 4),
          Text('JPG o PNG · Máximo 5 MB', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // SnackBar es un mensaje breve al pie de la pantalla.
  void mostrarAviso(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}
