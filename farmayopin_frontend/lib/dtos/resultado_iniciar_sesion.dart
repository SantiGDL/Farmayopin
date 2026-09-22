// DTO para la futura consulta de credenciales y rol.
// El servicio interpretará el JSON; este objeto solo transporta el resultado.
class ResultadoIniciarSesion {
  const ResultadoIniciarSesion({
    required this.exito,
    required this.mensaje,
    this.rol,
    this.token,
    this.usuarioId,
  });

  final bool exito;
  final String mensaje;

  // El backend devuelve 'Admin' o 'Cliente'. En caso de error, será null.
  final String? rol;
  final String? token;
  final int? usuarioId;
}
