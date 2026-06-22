import 'app_env.dart';

class GoogleMapsConfig {
  static String get apiKey => AppEnv.googleMapsApiKey;

  // Configurações padrão do mapa
  static const double defaultLatitude = -23.5505; // São Paulo
  static const double defaultLongitude = -46.6333;
  static const double defaultZoom = 12.0;

  // Configurações de busca por proximidade
  static const double maxSearchRadiusKm = 50.0; // 50km de raio máximo
  static const double defaultSearchRadiusKm = 10.0; // 10km de raio padrão

  // Configurações de marcadores
  static const double markerSize = 40.0;
  static const double clusterSize = 50.0;

  // URLs da API
  static const String geocodingBaseUrl =
      'https://maps.googleapis.com/maps/api/geocoding/json';
  static const String placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
  static const String directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
}
