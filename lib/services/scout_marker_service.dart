import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/scout_marker_model.dart';

class ScoutMarkerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'scout_markers';

  // Adicionar novo marcador de olheiro
  static Future<String> addScoutMarker(ScoutMarker marker) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(marker.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar marcador: $e');
    }
  }

  // Buscar marcadores próximos a uma localização
  static Future<List<ScoutMarker>> getNearbyScoutMarkers({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      // Buscar todos os marcadores verificados
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isVerified', isEqualTo: true)
          .get();

      final markers = querySnapshot.docs
          .map((doc) => ScoutMarker.fromFirestore(doc))
          .toList();

      // Filtrar por distância (implementação simples)
      final nearbyMarkers = markers.where((marker) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          marker.latitude,
          marker.longitude,
        );
        return distance <= radiusKm;
      }).toList();

      return nearbyMarkers;
    } catch (e) {
      throw Exception('Erro ao buscar marcadores próximos: $e');
    }
  }

  // Buscar marcadores por tipo
  static Future<List<ScoutMarker>> getScoutMarkersByType(
    ScoutMarkerType type,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .where('isVerified', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ScoutMarker.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar marcadores por tipo: $e');
    }
  }

  // Buscar marcadores de um olheiro específico
  static Future<List<ScoutMarker>> getScoutMarkersByScout(
    String scoutId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('scoutId', isEqualTo: scoutId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ScoutMarker.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar marcadores do olheiro: $e');
    }
  }

  // Atualizar marcador
  static Future<void> updateScoutMarker(
    String markerId,
    ScoutMarker marker,
  ) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(markerId)
          .update(marker.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar marcador: $e');
    }
  }

  // Deletar marcador
  static Future<void> deleteScoutMarker(String markerId) async {
    try {
      await _firestore.collection(_collection).doc(markerId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar marcador: $e');
    }
  }

  // Verificar se usuário é olheiro confiável
  static Future<bool> isTrustedScout(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data['isTrustedScout'] == true;
    } catch (e) {
      // Para demonstração, vamos simular que alguns usuários são olheiros
      return true; // Temporário para demonstração
    }
  }

  // Calcular distância entre duas coordenadas
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Raio da Terra em km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
