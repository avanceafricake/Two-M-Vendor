import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vendor.dart';
import 'firestore_paths.dart';
import 'local_storage.dart';
import 'repositories/admin_notification_repository.dart';
import 'mpesa_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    await LocalStorageService.clearVendor();
    await _auth.signOut();
  }

  Future<void> signInWithEmailPassword({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    // Load vendor profile into local storage for current app screens
    final uid = cred.user!.uid;
    final vendorSnap = await _db.doc(FirestorePaths.vendorDoc(uid)).get();
    if (vendorSnap.exists) {
      final data = vendorSnap.data()! as Map<String, dynamic>;
      final vendor = Vendor.fromMap(data);
      await LocalStorageService.saveVendor(vendor);
      // Set M-Pesa vendor context (non-blocking)
      MpesaService.instance.setVendorContext(vendor.id);
    } else {
      // If vendor doc missing, create a minimal one based on auth email
      final vendor = Vendor(
        id: uid,
        name: cred.user!.displayName ?? 'Vendor',
        email: cred.user!.email ?? email,
        phone: '',
        businessType: BusinessType.store,
        businessName: 'Business',
        businessAddress: '',
        businessDescription: '',
        createdAt: DateTime.now(),
        // Leave status default (approved) to avoid blocking legacy users
      );
      await _db.doc(FirestorePaths.vendorDoc(uid)).set(vendor.toMap());
      await LocalStorageService.saveVendor(vendor);
      MpesaService.instance.setVendorContext(vendor.id);
    }
  }

  Future<void> registerVendorWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    required BusinessType businessType,
    required String businessName,
    required String businessAddress,
    required String businessDescription,
    String? categoryKey,
    bool onboarded = true,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);

    final vendor = Vendor(
      id: cred.user!.uid,
      name: name,
      email: email,
      phone: phone,
      businessType: businessType,
      businessName: businessName,
      businessAddress: businessAddress,
      businessDescription: businessDescription,
      createdAt: DateTime.now(),
      categoryKey: categoryKey,
      onboarded: onboarded,
      status: VendorStatus.pendingApproval,
    );

    await _db.doc(FirestorePaths.vendorDoc(vendor.id)).set(vendor.toMap());
    await LocalStorageService.saveVendor(vendor);

    // Create a zero-balance wallet for the new vendor (top-level wallet/{uid}) to match your schema
    final wRef = _db.doc('wallet/${vendor.id}');
    final nowIso = DateTime.now().toIso8601String();
    await wRef.set({
      'Id': vendor.id,
      'ownerId': vendor.id,
      'Balance': 0.0,
      // Keep lowercase mirror fields for app compatibility if needed
      'balance': 0.0,
      'AvailableBalance': 0.0,
      'availableBalance': 0.0,
      'withdrawPhone': phone,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    }, SetOptions(merge: true));

    // Set M-Pesa vendor context (Cloud Functions hold secrets)
    MpesaService.instance.setVendorContext(vendor.id);

    // Publish admin notification for new vendor registration
    final adminNotifier = AdminNotificationRepository(_db);
    await adminNotifier.notifyVendorRegistration(vendor: vendor);
  }
}
