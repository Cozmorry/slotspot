import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(FirebaseFirestore.instance);
});

class FeedbackRepository {
  FeedbackRepository(this.db);
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('feedback');

  Future<void> submit(FeedbackEntry entry) async {
    final doc = _col.doc();
    await doc.set(entry.toMap());
  }
}


