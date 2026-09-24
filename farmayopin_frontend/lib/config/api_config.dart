class ApiConfig {
  //Cuando vaya a deployarlo se cambia entre la del emulador o la version web;
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //Para el Emulador Android:
    defaultValue: 'http://10.0.2.2:5206'

    //Para la version Web:
    //defaultValue: 'http://localhost:5206',
  );

  static Uri uri(String ruta) {
    return Uri.parse(baseUrl).resolve(ruta);
  }
}
