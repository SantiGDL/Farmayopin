class ApiConfig {
  //Cuando vaya a deployarlo se cambia la baseUrl por la del servidor o la ip publica de la pc que toque
  static const String baseUrl = 'http://localhost:5206';

  static Uri uri(String ruta) {
    return Uri.parse(baseUrl).resolve(ruta);
  }
}