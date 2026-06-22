import 'package:cloud_firestore/cloud_firestore.dart';

enum ScoutMarkerType {
  friendlyMatch, // Jogo amistoso feminino
  footballSchool, // Escolhinha de futebol
  externalChampionship, // Campeonato não organizado pelo Passa a Bola
}

class ScoutMarker {
  final String id;
  final String scoutId; // ID do olheiro que marcou
  final String scoutName;
  final String scoutEmail;
  final ScoutMarkerType type;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified; // Se foi verificado pela equipe
  final Map<String, dynamic>? additionalInfo;

  ScoutMarker({
    required this.id,
    required this.scoutId,
    required this.scoutName,
    required this.scoutEmail,
    required this.type,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.additionalInfo,
  });

  factory ScoutMarker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScoutMarker(
      id: doc.id,
      scoutId: data['scoutId'] ?? '',
      scoutName: data['scoutName'] ?? '',
      scoutEmail: data['scoutEmail'] ?? '',
      type: ScoutMarkerType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ScoutMarkerType.friendlyMatch,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      address: data['address'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      additionalInfo: data['additionalInfo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'scoutId': scoutId,
      'scoutName': scoutName,
      'scoutEmail': scoutEmail,
      'type': type.name,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'additionalInfo': additionalInfo,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case ScoutMarkerType.friendlyMatch:
        return 'Jogo Amistoso Feminino';
      case ScoutMarkerType.footballSchool:
        return 'Escolhinha de Futebol';
      case ScoutMarkerType.externalChampionship:
        return 'Campeonato Externo';
    }
  }

  String get typeIcon {
    switch (type) {
      case ScoutMarkerType.friendlyMatch:
        return '⚽';
      case ScoutMarkerType.footballSchool:
        return '🏫';
      case ScoutMarkerType.externalChampionship:
        return '🏆';
    }
  }
}
