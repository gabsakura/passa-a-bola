import '../services/location_service.dart';
import '../services/nearby_championships_service.dart';

class SaoPauloLocationsService {
  // Endereços famosos de São Paulo para testes
  static const Map<String, Map<String, double>> famousLocations = {
    'Avenida Paulista, 1000 - Bela Vista': {
      'latitude': -23.5613,
      'longitude': -46.6565,
    },
    'Parque Ibirapuera - Vila Mariana': {
      'latitude': -23.5874,
      'longitude': -46.6576,
    },
    'Estádio do Morumbi - Morumbi': {
      'latitude': -23.5994,
      'longitude': -46.7208,
    },
    'Shopping Iguatemi - Vila Olímpia': {
      'latitude': -23.5925,
      'longitude': -46.6876,
    },
    'Praça da Sé - Centro': {'latitude': -23.5505, 'longitude': -46.6333},
    'Vila Madalena - Pinheiros': {'latitude': -23.5489, 'longitude': -46.6938},
    'Liberdade - Centro': {'latitude': -23.5569, 'longitude': -46.6339},
    'Avenida Faria Lima - Itaim Bibi': {
      'latitude': -23.5679,
      'longitude': -46.6925,
    },
    'Parque Villa-Lobos - Alto de Pinheiros': {
      'latitude': -23.5456,
      'longitude': -46.7308,
    },
    'Mercado Municipal - Centro': {'latitude': -23.5456, 'longitude': -46.6308},
  };

  /// Busca campeonatos próximos a um endereço específico de São Paulo
  static Future<List<Map<String, dynamic>>> searchChampionshipsByAddress({
    required String address,
    double radiusKm = 10.0,
  }) async {
    try {
      print('DEBUG: Buscando campeonatos próximos ao endereço: $address');

      // Primeiro, tentar obter coordenadas do endereço
      Map<String, double>? coordinates;

      // Verificar se é um endereço famoso conhecido
      if (famousLocations.containsKey(address)) {
        coordinates = famousLocations[address]!;
        print('DEBUG: Usando coordenadas de endereço famoso: $coordinates');
      } else {
        // Tentar geocodificar o endereço
        coordinates = await LocationService.getCoordinatesFromAddress(address);
        if (coordinates == null) {
          print('DEBUG: Não foi possível obter coordenadas do endereço');
          return [];
        }
        print('DEBUG: Coordenadas obtidas via geocodificação: $coordinates');
      }

      // Verificar se as coordenadas estão em São Paulo (aproximadamente)
      if (!_isInSaoPaulo(coordinates['latitude']!, coordinates['longitude']!)) {
        print('DEBUG: Endereço não está em São Paulo');
        return [];
      }

      // Buscar campeonatos próximos
      final championships =
          await NearbyChampionshipsService.getNearbyChampionships(
            userLatitude: coordinates['latitude']!,
            userLongitude: coordinates['longitude']!,
            radiusKm: radiusKm,
          );

      print(
        'DEBUG: Encontrados ${championships.length} campeonatos próximos ao endereço',
      );
      return championships;
    } catch (e) {
      print('DEBUG: Erro ao buscar campeonatos por endereço: $e');
      return [];
    }
  }

  /// Verifica se as coordenadas estão dentro da área de São Paulo
  static bool _isInSaoPaulo(double latitude, double longitude) {
    // Limites aproximados de São Paulo
    const double minLat = -24.0;
    const double maxLat = -23.3;
    const double minLng = -47.0;
    const double maxLng = -46.3;

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }

  /// Obtém lista de endereços famosos para teste
  static List<String> getFamousAddresses() {
    return famousLocations.keys.toList();
  }

  /// Busca campeonatos em múltiplos endereços famosos
  static Future<Map<String, List<Map<String, dynamic>>>>
  searchMultipleAddresses({double radiusKm = 10.0}) async {
    Map<String, List<Map<String, dynamic>>> results = {};

    for (String address in famousLocations.keys) {
      print('DEBUG: Testando endereço: $address');
      final championships = await searchChampionshipsByAddress(
        address: address,
        radiusKm: radiusKm,
      );

      if (championships.isNotEmpty) {
        results[address] = championships;
        print(
          'DEBUG: Encontrados ${championships.length} campeonatos em $address',
        );
      }
    }

    return results;
  }

  /// Obtém estatísticas de campeonatos por região de São Paulo
  static Future<Map<String, dynamic>> getRegionalStats({
    double radiusKm = 15.0,
  }) async {
    final results = await searchMultipleAddresses(radiusKm: radiusKm);

    int totalChampionships = 0;
    int regionsWithChampionships = 0;
    Map<String, int> regionCounts = {};

    for (String region in results.keys) {
      int count = results[region]!.length;
      regionCounts[region] = count;
      totalChampionships += count;
      if (count > 0) regionsWithChampionships++;
    }

    return {
      'totalChampionships': totalChampionships,
      'regionsWithChampionships': regionsWithChampionships,
      'totalRegions': famousLocations.length,
      'regionCounts': regionCounts,
      'averagePerRegion': totalChampionships / famousLocations.length,
    };
  }
}
