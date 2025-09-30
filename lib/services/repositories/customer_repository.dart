import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/customer.dart';

class CustomerRepository {
  CustomerRepository(this._db);
  final FirebaseFirestore _db;

  /// Create or update customer profile
  Future<void> upsert(Customer customer) async {
    await _db.collection('customers').doc(customer.id).set(
      customer.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Get customer by ID
  Future<Customer?> getById(String customerId) async {
    final snap = await _db.collection('customers').doc(customerId).get();
    if (!snap.exists) return null;
    return Customer.fromMap(snap.data()!);
  }

  /// Watch customer profile for real-time updates
  Stream<Customer?> watch(String customerId) {
    return _db.collection('customers').doc(customerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Customer.fromMap(doc.data()!);
    });
  }

  /// Update customer's default address
  Future<void> updateDefaultAddress(String customerId, String address) async {
    await _db.collection('customers').doc(customerId).update({
      'defaultAddress': address,
    });
  }

  /// Update customer's profile image
  Future<void> updateProfileImage(String customerId, String imageUrl) async {
    await _db.collection('customers').doc(customerId).update({
      'profileImageUrl': imageUrl,
    });
  }

  /// Delete customer profile (GDPR compliance)
  Future<void> delete(String customerId) async {
    await _db.collection('customers').doc(customerId).delete();
  }

  /// Search customers by name (for admin purposes)
  Future<List<Customer>> searchByName({
    required String searchTerm,
    int limit = 50,
  }) async {
    final snapshot = await _db
        .collection('customers')
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .orderBy('name')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Customer.fromMap(doc.data()))
        .toList();
  }

  /// Get customers count (for analytics)
  Future<int> getCustomerCount() async {
    final snapshot = await _db.collection('customers').count().get();
    return snapshot.count ?? 0;
  }
}