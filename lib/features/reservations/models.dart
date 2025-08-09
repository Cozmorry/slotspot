import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String userId;
  final String lotId;
  final String lotName;
  final String zoneId;
  final String zoneName;
  final DateTime startAt;
  final DateTime endAt;
  final String status; // active, canceled, completed

  Reservation({
    required this.id,
    required this.userId,
    required this.lotId,
    required this.lotName,
    required this.zoneId,
    required this.zoneName,
    required this.startAt,
    required this.endAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'lotId': lotId,
        'lotName': lotName,
        'zoneId': zoneId,
        'zoneName': zoneName,
        'startAt': Timestamp.fromDate(startAt.toUtc()),
        'endAt': Timestamp.fromDate(endAt.toUtc()),
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static Reservation fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Reservation(
      id: doc.id,
      userId: d['userId'] as String,
      lotId: d['lotId'] as String,
      lotName: d['lotName'] as String,
      zoneId: d['zoneId'] as String,
      zoneName: d['zoneName'] as String,
      startAt: (d['startAt'] as Timestamp).toDate(),
      endAt: (d['endAt'] as Timestamp).toDate(),
      status: d['status'] as String,
    );
  }
}

class LotZoneOption {
  final String lotId;
  final String lotName;
  final String zoneId;
  final String zoneName;
  final int capacity;
  const LotZoneOption(this.lotId, this.lotName, this.zoneId, this.zoneName, this.capacity);
}

const defaultSaritOptions = <LotZoneOption>[
  LotZoneOption('sarit', 'Sarit Mall', 'A', 'Zone A', 120),
  LotZoneOption('sarit', 'Sarit Mall', 'B', 'Zone B', 150),
  LotZoneOption('sarit', 'Sarit Mall', 'C', 'Zone C', 100),
];


