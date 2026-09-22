import 'package:flutter/material.dart';

class BuscadorProductos extends StatelessWidget {
  const BuscadorProductos({super.key, required this.alCambiar});

  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        onChanged: alCambiar,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search, size: 28, color: Colors.black),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 32,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
