import 'package:cloud_firestore/cloud_firestore.dart';

class CrowdReport {
  final String id;
  final String userId;
  final String lotId;
  final String zoneId;
  final int delta; // +1 free, -1 occupied
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  CrowdReport({
    required this.id,
    required this.userId,
    required this.lotId,
    required this.zoneId,
    required this.delta,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'lotId': lotId,
        'zoneId': zoneId,
        'delta': delta,
        'lat': lat,
        'lng': lng,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static CrowdReport fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CrowdReport(
      id: doc.id,
      userId: d['userId'] as String,
      lotId: d['lotId'] as String,
      zoneId: d['zoneId'] as String,
      delta: (d['delta'] as num).toInt(),
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


