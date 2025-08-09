import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackEntry {
  final String id;
  final String userId;
  final String type; // bug, suggestion, other
  final String message;
  final int? rating; // 1-5
  final DateTime createdAt;

  FeedbackEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'message': message,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static FeedbackEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return FeedbackEntry(
      id: doc.id,
      userId: d['userId'] as String,
      type: d['type'] as String,
      message: d['message'] as String,
      rating: (d['rating'] as num?)?.toInt(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


