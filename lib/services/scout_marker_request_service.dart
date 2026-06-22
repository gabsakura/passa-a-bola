import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/scout_marker_request_model.dart';
import '../data/scout_marker_model.dart';
import 'scout_marker_service.dart';

class ScoutMarkerRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'scout_marker_requests';

  // Criar uma nova solicitação de marcador
  static Future<String> createRequest(ScoutMarkerRequest request) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao criar solicitação: $e');
    }
  }

  // Criar solicitação com dados do usuário autenticado
  static Future<String> createRequestWithUserData({
    required ScoutMarkerType type,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar dados do usuário
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      String scoutName = 'Usuário';
      String scoutEmail = user.email ?? '';

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        scoutName = userData['name'] ?? user.displayName ?? 'Usuário';
        scoutEmail = userData['email'] ?? user.email ?? '';
      }

      final request = ScoutMarkerRequest(
        id: '', // Será gerado pelo Firestore
        scoutId: user.uid,
        scoutName: scoutName,
        scoutEmail: scoutEmail,
        type: type,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        address: address,
        status: ScoutMarkerRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createRequest(request);
    } catch (e) {
      throw Exception('Erro ao criar solicitação: $e');
    }
  }

  // Obter solicitações de um olheiro específico
  static Future<List<ScoutMarkerRequest>> getRequestsByScout(
    String scoutId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('scoutId', isEqualTo: scoutId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ScoutMarkerRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar solicitações: $e');
    }
  }

  // Obter todas as solicitações pendentes (para admins)
  static Future<List<ScoutMarkerRequest>> getPendingRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ScoutMarkerRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar solicitações pendentes: $e');
    }
  }

  // Aprovar uma solicitação
  static Future<void> approveRequest(
    String requestId,
    String adminId,
    String? adminNotes,
  ) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'approved',
        'approvedBy': adminId,
        'adminNotes': adminNotes,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erro ao aprovar solicitação: $e');
    }
  }

  // Rejeitar uma solicitação
  static Future<void> rejectRequest(
    String requestId,
    String adminId,
    String? adminNotes,
  ) async {
    try {
      await _firestore.collection(_collection).doc(requestId).update({
        'status': 'rejected',
        'approvedBy': adminId,
        'adminNotes': adminNotes,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erro ao rejeitar solicitação: $e');
    }
  }

  // Converter solicitação aprovada em marcador
  static Future<void> convertToMarker(ScoutMarkerRequest request) async {
    try {
      final marker = ScoutMarker(
        id: '',
        scoutId: request.scoutId,
        scoutName: request.scoutName,
        scoutEmail: request.scoutEmail,
        type: request.type,
        title: request.title,
        description: request.description,
        latitude: request.latitude,
        longitude: request.longitude,
        address: request.address,
        createdAt: request.createdAt,
        updatedAt: DateTime.now(),
        isVerified: true,
      );

      await ScoutMarkerService.addScoutMarker(marker);
    } catch (e) {
      throw Exception('Erro ao converter em marcador: $e');
    }
  }

  // Deletar solicitação
  static Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection(_collection).doc(requestId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar solicitação: $e');
    }
  }
}
