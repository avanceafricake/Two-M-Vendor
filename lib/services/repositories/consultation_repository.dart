import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/consultation.dart';
import '../firestore_paths.dart';

class ConsultationRepository {
  ConsultationRepository(this._db);
  final FirebaseFirestore _db;

  // Settings are stored inside the vendor doc as a nested map to reduce reads.
  Stream<ConsultSettings> watchSettings(String vendorId) {
    return _db.doc(FirestorePaths.vendorDoc(vendorId)).snapshots().map((d) {
      final data = d.data();
      return ConsultSettings.fromMap(data?['consultationSettings'] as Map<String, dynamic>?);
    });
  }

  Future<void> saveSettings(String vendorId, ConsultSettings settings) async {
    await _db.doc(FirestorePaths.vendorDoc(vendorId)).set({
      'consultationSettings': settings.toMap(),
    }, SetOptions(merge: true));
  }

  // Incoming requests from customer app. Top-level collection for cross-app querying.
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection(FirestorePaths.consultationRequests);

  Stream<List<ConsultRequest>> watchRequests(String vendorId) {
    return _requests.where('vendorId', isEqualTo: vendorId).snapshots().map((s) {
      final list = s.docs.map((d) => ConsultRequest.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateRequestStatus(String requestId, ConsultStatus status) async {
    await _requests.doc(requestId).set({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
