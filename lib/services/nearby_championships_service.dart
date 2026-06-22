import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/championship_model.dart';
import '../services/location_service.dart';
import '../config/google_maps_config.dart';

class NearbyChampionshipsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca campeonatos próximos à localização do usuário
  static Future<List<Map<String, dynamic>>> getNearbyChampionships({
    required double userLatitude,
    required double userLongitude,
    double radiusKm = GoogleMapsConfig.defaultSearchRadiusKm,
  }) async {
    try {
      print('DEBUG: Buscando campeonatos próximos...');
      print('DEBUG: Localização do usuário: $userLatitude, $userLongitude');
      print('DEBUG: Raio de busca: ${radiusKm}km');

      // TEMPORÁRIO: Buscar todos os campeonatos para debug
      final QuerySnapshot snapshot = await _firestore
          .collection('championships')
          .get();

      print('DEBUG: Total de campeonatos encontrados: ${snapshot.docs.length}');

      // Debug dos documentos encontrados
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>?;
        print('DEBUG: Documento $i: ${doc.id}');
        print('DEBUG: - Status: ${data?['status']}');
        print('DEBUG: - Title: ${data?['title']}');
        print(
          'DEBUG: - LocationData: ${data?['locationData'] != null ? "Presente" : "Ausente"}',
        );
      }

      List<Map<String, dynamic>> nearbyChampionships = [];

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        try {
          final championship = Championship.fromFirestore(doc);

          print('DEBUG: Processando campeonato: ${championship.title}');
          print(
            'DEBUG: locationData é null: ${championship.locationData == null}',
          );
          if (championship.locationData != null) {
            print('DEBUG: latitude: ${championship.locationData!.latitude}');
            print('DEBUG: longitude: ${championship.locationData!.longitude}');
            print('DEBUG: isValid: ${championship.locationData!.isValid}');
          }

          // Verificar se o campeonato tem localização
          if (championship.locationData != null &&
              championship.locationData!.isValid) {
            final champLat = championship.locationData!.latitude;
            final champLon = championship.locationData!.longitude;

            // Calcular distância
            final distance = LocationService.calculateDistance(
              userLatitude,
              userLongitude,
              champLat,
              champLon,
            );

            print(
              'DEBUG: Campeonato ${championship.title} - Distância: ${distance.toStringAsFixed(2)}km',
            );

            // Mostrar todos os campeonatos, independentemente da distância
            // Obter endereço do campeonato
            String? address = await LocationService.getAddressFromCoordinates(
              champLat,
              champLon,
            );

            nearbyChampionships.add({
              'championship': championship,
              'distance': distance,
              'address': address ?? 'Endereço não disponível',
              'latitude': champLat,
              'longitude': champLon,
            });

            print('DEBUG: Campeonato adicionado: ${championship.title}');
          } else {
            print(
              'DEBUG: Campeonato ${championship.title} sem localização válida',
            );
          }
        } catch (e) {
          print('DEBUG: Erro ao processar campeonato ${doc.id}: $e');
        }
      }

      // Ordenar por distância
      nearbyChampionships.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      print(
        'DEBUG: Campeonatos próximos encontrados: ${nearbyChampionships.length}',
      );
      return nearbyChampionships;
    } catch (e) {
      print('DEBUG: Erro ao buscar campeonatos próximos: $e');
      return [];
    }
  }

  /// Busca campeonatos por cidade
  static Future<List<Map<String, dynamic>>> getChampionshipsByCity(
    String city,
  ) async {
    try {
      print('DEBUG: Buscando campeonatos na cidade: $city');

      // Obter coordenadas da cidade
      final coordinates = await LocationService.getCoordinatesFromAddress(city);
      if (coordinates == null) {
        print('DEBUG: Não foi possível obter coordenadas da cidade');
        return [];
      }

      return await getNearbyChampionships(
        userLatitude: coordinates['latitude']!,
        userLongitude: coordinates['longitude']!,
        radiusKm: GoogleMapsConfig.maxSearchRadiusKm,
      );
    } catch (e) {
      print('DEBUG: Erro ao buscar campeonatos por cidade: $e');
      return [];
    }
  }

  /// Busca campeonatos em um raio específico
  static Future<List<Map<String, dynamic>>> getChampionshipsInRadius({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    return await getNearbyChampionships(
      userLatitude: latitude,
      userLongitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Obtém estatísticas dos campeonatos próximos
  static Future<Map<String, int>> getNearbyChampionshipsStats({
    required double userLatitude,
    required double userLongitude,
    double radiusKm = GoogleMapsConfig.defaultSearchRadiusKm,
  }) async {
    final championships = await getNearbyChampionships(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      radiusKm: radiusKm,
    );

    int total = championships.length;
    int withOpenRegistration = 0;
    int withClosedRegistration = 0;
    int active = 0;

    for (final champ in championships) {
      final championship = champ['championship'] as Championship;
      switch (championship.status) {
        case ChampionshipStatus.registrationOpen:
          withOpenRegistration++;
          break;
        case ChampionshipStatus.registrationClosed:
          withClosedRegistration++;
          break;
        case ChampionshipStatus.ongoing:
          active++;
          break;
        default:
          break;
      }
    }

    return {
      'total': total,
      'openRegistration': withOpenRegistration,
      'closedRegistration': withClosedRegistration,
      'active': active,
    };
  }
}
