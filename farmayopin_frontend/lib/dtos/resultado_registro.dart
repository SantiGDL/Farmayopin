// DTO específico del registro: transporta datos del servicio al controlador.
class ResultadoRegistro {
  const ResultadoRegistro(this.exito, this.mensaje);

  final bool exito;
  final String mensaje;
}
