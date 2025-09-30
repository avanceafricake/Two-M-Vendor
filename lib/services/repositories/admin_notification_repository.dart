import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product.dart';
import '../../models/vendor.dart';
import '../firestore_paths.dart';

/// Writes admin-facing notifications/events to Firestore.
///
/// Recommended to consume these from an admin dashboard or Cloud Function
/// to fan-out FCM, emails, etc.
class AdminNotificationRepository {
  AdminNotificationRepository(this._db);
  final FirebaseFirestore _db;

  Future<void> notifyVendorRegistration({required Vendor vendor}) async {
    await _db.collection(FirestorePaths.adminNotifications).add({
      'type': 'vendor_registered',
      'vendorId': vendor.id,
      'vendorName': vendor.name,
      'businessName': vendor.businessName,
      'businessType': vendor.businessType.index,
      'categoryKey': vendor.categoryKey,
      'status': vendor.status.name, // expected pendingApproval on creation
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> notifyProductCreated({required Product product, required Vendor vendor}) async {
    await _db.collection(FirestorePaths.adminNotifications).add({
      'type': 'product_created',
      'productId': product.id,
      'productName': product.name,
      'vendorId': vendor.id,
      'vendorName': vendor.name,
      'businessName': vendor.businessName,
      'businessType': vendor.businessType.index,
      'category': product.category,
      'isAvailable': product.isAvailable,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
