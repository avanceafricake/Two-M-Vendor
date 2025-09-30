import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product.dart';
import '../../models/vendor.dart';
import '../firestore_paths.dart';

class ProductRepository {
  ProductRepository(this._db);
  final FirebaseFirestore _db;

  /// Create a new product
  Future<void> create(Product product) async {
    await _db.collection('products').doc(product.id).set(product.toMap());
  }

  /// Get product by ID
  Future<Product?> getById(String productId) async {
    final snap = await _db.collection('products').doc(productId).get();
    if (!snap.exists) return null;
    return Product.fromMap(snap.data()!);
  }

  /// Update existing product
  Future<void> update(Product product) async {
    await _db.collection('products').doc(product.id).update(product.toMap());
  }

  /// Delete product
  Future<void> delete(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// Get all products for a vendor
  Stream<List<Product>> watchByVendor({
    required String vendorId,
    String? category,
    bool? isAvailable,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('vendorId', isEqualTo: vendorId);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (isAvailable != null) {
      query = query.where('isAvailable', isEqualTo: isAvailable);
    }

    // Avoid composite index requirements on vendorId + createdAt by not ordering in Firestore.
    // We sort client-side in the UI.
    return query
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();
    });
  }

  /// Get products by business type (for customer app)
  Stream<List<Product>> watchByBusinessType({
    required BusinessType businessType,
    String? category,
    bool availableOnly = true,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('businessType', isEqualTo: businessType.index);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (availableOnly) {
      query = query.where('isAvailable', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();
    });
  }

  /// Update product availability
  Future<void> updateAvailability(String productId, bool isAvailable) async {
    await _db.collection('products').doc(productId).update({
      'isAvailable': isAvailable,
    });
  }

  /// Update product stock quantity
  Future<void> updateStock(String productId, int stockQuantity) async {
    await _db.collection('products').doc(productId).update({
      'stockQuantity': stockQuantity,
    });
  }

  /// Batch update multiple products (useful for bulk operations)
  Future<void> batchUpdate(List<Product> products) async {
    final batch = _db.batch();
    for (final product in products) {
      final ref = _db.collection('products').doc(product.id);
      batch.set(ref, product.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  /// Get product count for analytics
  Future<int> getProductCount({
    required String vendorId,
    bool? isAvailable,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('products')
        .where('vendorId', isEqualTo: vendorId);

    if (isAvailable != null) {
      query = query.where('isAvailable', isEqualTo: isAvailable);
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// Search products by name (for vendor dashboard)
  Stream<List<Product>> searchByName({
    required String vendorId,
    required String searchTerm,
    int limit = 50,
  }) {
    // Note: For production, consider using Algolia or similar for full-text search
    // This is a basic implementation using Firestore's limited text search
    return _db
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .where('name', isGreaterThanOrEqualTo: searchTerm)
        .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .orderBy('name')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();
    });
  }
}