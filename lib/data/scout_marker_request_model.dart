import 'package:cloud_firestore/cloud_firestore.dart';
import 'scout_marker_model.dart';

enum ScoutMarkerRequestStatus {
  pending('Pendente', '⏳'),
  approved('Aprovado', '✅'),
  rejected('Rejeitado', '❌');

  const ScoutMarkerRequestStatus(this.displayName, this.statusIcon);
  final String displayName;
  final String statusIcon;
}

class ScoutMarkerRequest {
  final String id;
  final String scoutId;
  final String scoutName;
  final String scoutEmail;
  final ScoutMarkerType type;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final ScoutMarkerRequestStatus status;
  final String? adminNotes;
  final String? approvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScoutMarkerRequest({
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
    required this.status,
    this.adminNotes,
    this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScoutMarkerRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScoutMarkerRequest(
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
      status: ScoutMarkerRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ScoutMarkerRequestStatus.pending,
      ),
      adminNotes: data['adminNotes'],
      approvedBy: data['approvedBy'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
      'status': status.name,
      'adminNotes': adminNotes,
      'approvedBy': approvedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
