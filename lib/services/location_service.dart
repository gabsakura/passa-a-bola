import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/google_maps_config.dart';

class LocationService {
  /// Verifica e solicita permissões de localização
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  /// Verifica se as permissões de localização estão concedidas
  static Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status == PermissionStatus.granted;
  }

  /// Obtém a localização atual do usuário
  static Future<Position?> getCurrentLocation() async {
    try {
      // Verificar se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }

      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }

      // Obter localização atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  /// Converte coordenadas em endereço
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Construir endereço de forma mais robusta
        List<String> parts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
      return null;
    } catch (e) {
      print('Erro ao obter endereço: $e');
      return null;
    }
  }

  /// Converte endereço em coordenadas com múltiplas tentativas
  static Future<Map<String, double>?> getCoordinatesFromAddress(
    String address,
  ) async {
    try {
      // Limpar e normalizar o endereço
      String cleanAddress = _cleanAddress(address);

      // Primeiro, tentar com a API de geocoding padrão
      Map<String, double>? result = await _tryGeocodingAPI(cleanAddress);
      if (result != null) return result;

      // Se não funcionou, tentar com Google Places API
      result = await _tryGooglePlacesAPI(cleanAddress);
      if (result != null) return result;

      // Como último recurso, tentar com endereços conhecidos de São Paulo
      result = await _tryKnownAddresses(cleanAddress);
      if (result != null) return result;

      return null;
    } catch (e) {
      print('Erro geral ao obter coordenadas: $e');
      return null;
    }
  }

  /// Tenta usar a API de geocoding padrão
  static Future<Map<String, double>?> _tryGeocodingAPI(String address) async {
    try {
      // Tentar diferentes variações do endereço
      List<String> addressVariations = _generateAddressVariations(address);

      for (String variation in addressVariations) {
        try {
          print('Tentando geocoding: $variation');
          List<Location> locations = await locationFromAddress(
            variation,
            localeIdentifier: 'pt_BR',
          );

          if (locations.isNotEmpty) {
            Location location = locations.first;
            print('Endereço encontrado via geocoding: $variation');
            return {
              'latitude': location.latitude,
              'longitude': location.longitude,
            };
          }
        } catch (e) {
          print('Erro no geocoding $variation: $e');
          continue;
        }
      }
      return null;
    } catch (e) {
      print('Erro no geocoding: $e');
      return null;
    }
  }

  /// Tenta usar Google Places API como alternativa
  static Future<Map<String, double>?> _tryGooglePlacesAPI(
    String address,
  ) async {
    try {
      // Usar a chave da API do Google Maps
      String apiKey = GoogleMapsConfig.apiKey;
      if (apiKey.isEmpty) {
        print('Chave da API do Google Maps não configurada');
        return null;
      }

      String encodedAddress = Uri.encodeComponent(address);
      String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&region=br';

      print('Tentando Google Places API: $url');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];

          print(
            'Endereço encontrado via Google Places: ${result['formatted_address']}',
          );
          return {
            'latitude': location['lat'].toDouble(),
            'longitude': location['lng'].toDouble(),
          };
        } else {
          print('Google Places API retornou: ${data['status']}');
        }
      } else {
        print('Erro HTTP: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Erro na Google Places API: $e');
      return null;
    }
  }

  /// Tenta mapear para endereços conhecidos de São Paulo
  static Future<Map<String, double>?> _tryKnownAddresses(String address) async {
    // Mapear endereços comuns para coordenadas conhecidas
    Map<String, Map<String, double>> knownAddresses = {
      'centro': {'latitude': -23.5505, 'longitude': -46.6333},
      'vila olimpia': {'latitude': -23.5585, 'longitude': -46.6253},
      'pinheiros': {'latitude': -23.5687, 'longitude': -46.6934},
      'ibirapuera': {'latitude': -23.5555, 'longitude': -46.6153},
      'paulista': {'latitude': -23.5613, 'longitude': -46.6565},
      'morumbi': {'latitude': -23.5455, 'longitude': -46.6353},
      'sé': {'latitude': -23.5489, 'longitude': -46.6388},
      'liberdade': {'latitude': -23.5565, 'longitude': -46.6333},
      'vila madalena': {'latitude': -23.5462, 'longitude': -46.6919},
      'itaim bibi': {'latitude': -23.5687, 'longitude': -46.6934},
    };

    String lowerAddress = address.toLowerCase();

    for (String key in knownAddresses.keys) {
      if (lowerAddress.contains(key)) {
        print('Endereço mapeado para localização conhecida: $key');
        return knownAddresses[key];
      }
    }

    return null;
  }

  /// Limpa e normaliza o endereço
  static String _cleanAddress(String address) {
    return address
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Múltiplos espaços em um
        .replaceAll(RegExp(r'[^\w\s,.-]'), '') // Remove caracteres especiais
        .trim();
  }

  /// Gera variações do endereço para tentar diferentes formatos
  static List<String> _generateAddressVariations(String address) {
    List<String> variations = [address];

    // Adicionar "Brasil" se não estiver presente
    if (!address.toLowerCase().contains('brasil') &&
        !address.toLowerCase().contains('brazil')) {
      variations.add('$address, Brasil');
    }

    // Adicionar "SP" se não estiver presente
    if (!address.toLowerCase().contains('sp') &&
        !address.toLowerCase().contains('são paulo') &&
        !address.toLowerCase().contains('sao paulo')) {
      variations.add('$address, SP');
      variations.add('$address, São Paulo, SP');
    }

    // Se contém apenas o nome da rua, tentar adicionar bairro comum
    if (address.split(',').length == 1) {
      variations.add('$address, Centro, São Paulo, SP');
      variations.add('$address, Vila Olímpia, São Paulo, SP');
      variations.add('$address, Pinheiros, São Paulo, SP');
    }

    return variations;
  }

  /// Calcula a distância entre duas coordenadas em quilômetros
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Verifica se uma localização está dentro do raio de busca
  static bool isWithinRadius(
    double userLat,
    double userLon,
    double targetLat,
    double targetLon,
    double radiusKm,
  ) {
    double distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radiusKm;
  }

  /// Obtém a localização padrão (São Paulo) se não conseguir obter a atual
  static Map<String, double> getDefaultLocation() {
    return {
      'latitude': GoogleMapsConfig.defaultLatitude,
      'longitude': GoogleMapsConfig.defaultLongitude,
    };
  }

  /// Função de teste para debugar problemas de localização
  static Future<void> testLocationSearch(String address) async {
    print('=== TESTE DE BUSCA DE LOCALIZAÇÃO ===');
    print('Endereço original: $address');

    String cleanAddress = _cleanAddress(address);
    print('Endereço limpo: $cleanAddress');

    List<String> variations = _generateAddressVariations(cleanAddress);
    print('Variações geradas: $variations');

    // Testar cada variação
    for (int i = 0; i < variations.length; i++) {
      String variation = variations[i];
      print('\n--- Tentativa ${i + 1}: $variation ---');

      try {
        List<Location> locations = await locationFromAddress(
          variation,
          localeIdentifier: 'pt_BR',
        );

        if (locations.isNotEmpty) {
          Location location = locations.first;
          print(
            '✅ SUCESSO! Coordenadas: ${location.latitude}, ${location.longitude}',
          );
          return;
        } else {
          print('❌ Nenhuma localização encontrada');
        }
      } catch (e) {
        print('❌ Erro: $e');
      }
    }

    // Testar Google Places API
    print('\n--- Testando Google Places API ---');
    Map<String, double>? result = await _tryGooglePlacesAPI(cleanAddress);
    if (result != null) {
      print(
        '✅ Google Places API funcionou! Coordenadas: ${result['latitude']}, ${result['longitude']}',
      );
    } else {
      print('❌ Google Places API falhou');
    }

    // Testar endereços conhecidos
    print('\n--- Testando endereços conhecidos ---');
    result = await _tryKnownAddresses(cleanAddress);
    if (result != null) {
      print(
        '✅ Endereço conhecido encontrado! Coordenadas: ${result['latitude']}, ${result['longitude']}',
      );
    } else {
      print('❌ Nenhum endereço conhecido encontrado');
    }

    print('\n=== FIM DO TESTE ===');
  }
}
