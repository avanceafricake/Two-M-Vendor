import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/vendor.dart';
import '../firestore_paths.dart';

class VendorRepository {
  VendorRepository(this._db);
  final FirebaseFirestore _db;

  Future<Vendor?> getById(String vendorId) async {
    final snap = await _db.doc(FirestorePaths.vendorDoc(vendorId)).get();
    if (!snap.exists) return null;
    return Vendor.fromMap(snap.data()!);
  }

  Future<void> upsert(Vendor vendor) async {
    await _db.doc(FirestorePaths.vendorDoc(vendor.id)).set(vendor.toMap(), SetOptions(merge: true));
  }

  Stream<Vendor?> watch(String vendorId) {
    return _db.doc(FirestorePaths.vendorDoc(vendorId)).snapshots().map((d) {
      if (!d.exists) return null;
      return Vendor.fromMap(d.data()!);
    });
  }

  Future<void> setOnline(String vendorId, bool isOnline) async {
    await _db.doc(FirestorePaths.vendorDoc(vendorId)).update({'isOnline': isOnline});
  }
}
