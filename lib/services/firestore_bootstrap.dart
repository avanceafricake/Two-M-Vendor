import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vendor.dart';
import 'firestore_paths.dart';

class FirestoreBootstrap {
  FirestoreBootstrap._();

  static Future<void> ensureMinimalCollections({required String uid, required Vendor vendor}) async {
    final db = FirebaseFirestore.instance;

    // 1) Ensure vendor document exists with defaults
    final vRef = db.doc(FirestorePaths.vendorDoc(uid));
    final vShot = await vRef.get();
    if (!vShot.exists) {
      await vRef.set({
        'id': uid,
        'name': vendor.name.isNotEmpty ? vendor.name : 'Vendor',
        'phone': vendor.phone,
        'businessType': vendor.businessType.index,
        'createdAt': DateTime.now().toIso8601String(),
        'isPhoneVerified': false,
        'onboarded': vendor.onboarded,
      }, SetOptions(merge: true));
    } else {
      // Ensure required fields exist
      await vRef.set({
        if (!vShot.data()!.containsKey('isPhoneVerified')) 'isPhoneVerified': false,
        if (!vShot.data()!.containsKey('phone')) 'phone': vendor.phone,
        if (!vShot.data()!.containsKey('onboarded')) 'onboarded': vendor.onboarded,
      }, SetOptions(merge: true));
    }

    // 2) Ensure wallet document exists (wallet/{uid})
    final wRef = db.doc('wallet/$uid');
    final wShot = await wRef.get();
    final authPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    if (!wShot.exists) {
      final nowIso = DateTime.now().toIso8601String();
      await wRef.set({
        'Id': uid,
        'ownerId': uid,
        'Balance': 0.0,
        // Keep lowercase for app compatibility if needed
        'balance': 0.0,
        'AvailableBalance': 0.0,
        'availableBalance': 0.0,
        'withdrawPhone': vendor.phone.isNotEmpty ? vendor.phone : authPhone,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      }, SetOptions(merge: true));
    } else {
      await wRef.set({
        if (!wShot.data()!.containsKey('ownerId')) 'ownerId': uid,
        if (!wShot.data()!.containsKey('Id')) 'Id': uid,
        if (!wShot.data()!.containsKey('Balance')) 'Balance': 0.0,
        if (!wShot.data()!.containsKey('balance')) 'balance': 0.0,
        if (!wShot.data()!.containsKey('AvailableBalance')) 'AvailableBalance': 0.0,
        if (!wShot.data()!.containsKey('availableBalance')) 'availableBalance': 0.0,
        if (!wShot.data()!.containsKey('withdrawPhone')) 'withdrawPhone': vendor.phone.isNotEmpty ? vendor.phone : authPhone,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }

    // 3) Ensure top-level walletTransactions collection exists implicitly (no-op)
    // Firestore creates collections on first write; nothing required here.
  }
}
