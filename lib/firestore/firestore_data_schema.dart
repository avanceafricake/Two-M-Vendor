/// Firestore Data Schema for Vendor Admin App
/// 
/// This file defines the complete data structure for the vendor admin application
/// including collections, documents, and their relationships in Firestore.
library;

import '../models/vendor.dart';
import '../models/product.dart';
import '../models/order.dart';

/// Main collections in the Firestore database:
/// 
/// 1. /vendors/{vendorId} - Vendor profile data (private, vendor-owned)
/// 2. /products/{productId} - Product catalog (public read, vendor write)
/// 3. /vendors/{vendorId}/orders/{orderId} - Vendor-scoped orders
/// 4. /orders/{orderId} - Global orders (for cross-vendor queries)
/// 5. /customers/{customerId} - Customer profiles (private, customer-owned)
/// 6. /analytics/{vendorId} - Analytics data (private, vendor-owned)
/// 7. /vendor_directory/{vendorId} - Public vendor directory (public read)

class FirestoreDataSchema {
  /// Vendor Profile Document Structure
  /// Collection: /vendors/{vendorId}
  /// 
  /// Document ID: Firebase Auth UID
  /// Security Rule: Only the authenticated vendor can read/write their own document
  static Map<String, dynamic> vendorDocument(Vendor vendor) => {
    'id': vendor.id, // Firebase Auth UID
    'name': vendor.name, // Vendor personal name
    'email': vendor.email, // Vendor email
    'phone': vendor.phone, // E.164 format phone number
    'businessType': vendor.businessType.index, // 0=store, 1=restaurant, 2=pharmacy
    'businessName': vendor.businessName, // Business display name
    'businessAddress': vendor.businessAddress, // Physical business address
    'businessDescription': vendor.businessDescription, // Business description
    'profileImageUrl': vendor.profileImageUrl, // Personal profile image URL
    'businessImageUrl': vendor.businessImageUrl, // Business logo/image URL
    'locationLat': vendor.locationLat, // Business latitude (optional)
    'locationLng': vendor.locationLng, // Business longitude (optional)
    'isOnline': vendor.isOnline, // Current online status
    'isPhoneVerified': vendor.isPhoneVerified, // Phone verification status
    'createdAt': vendor.createdAt.toIso8601String(), // ISO timestamp
  };

  /// Product Document Structure
  /// Collection: /products/{productId}
  /// 
  /// Document ID: Auto-generated or UUID
  /// Security Rule: Public read, only vendor can write their own products
  static Map<String, dynamic> productDocument(Product product) => {
    'id': product.id, // Product unique ID
    'name': product.name, // Product name
    'description': product.description, // Product description
    'price': product.price, // Product price (double)
    'category': product.category, // Product category
    'vendorId': product.vendorId, // Owner vendor Firebase Auth UID
    'businessType': product.businessType.index, // Associated business type
    'imageUrls': product.imageUrls, // Array of image URLs
    'isAvailable': product.isAvailable, // Availability status
    'stockQuantity': product.stockQuantity, // Current stock count
    'createdAt': product.createdAt.toIso8601String(), // ISO timestamp
  };

  /// Order Document Structure (Vendor-Scoped)
  /// Collection: /vendors/{vendorId}/orders/{orderId}
  /// 
  /// Document ID: Auto-generated or UUID
  /// Security Rule: Only the vendor can read/write their orders
  static Map<String, dynamic> vendorOrderDocument(Order order) => {
    'id': order.id, // Order unique ID
    'customerId': order.customerId, // Customer Firebase Auth UID
    'customerName': order.customerName, // Customer display name
    'customerPhone': order.customerPhone, // Customer phone number
    'deliveryAddress': order.deliveryAddress, // Delivery address
    'items': order.items.map((item) => {
      'productId': item.productId,
      'productName': item.productName,
      'price': item.price,
      'quantity': item.quantity,
      'imageUrl': item.imageUrl,
    }).toList(),
    'subtotal': order.subtotal, // Order subtotal
    'deliveryFee': order.deliveryFee, // Delivery fee
    'total': order.total, // Total amount
    'status': order.status.index, // Order status (0-5)
    'vendorId': order.vendorId, // Vendor Firebase Auth UID
    'businessType': order.businessType.index, // Business type
    'createdAt': order.createdAt.toIso8601String(), // ISO timestamp
    'updatedAt': order.updatedAt?.toIso8601String(), // Last update timestamp
    'paymentMethod': order.paymentMethod.index, // Payment method (0-2)
    'paymentStatus': order.paymentStatus.index, // Payment status (0-4)
  };

  /// Global Order Document Structure
  /// Collection: /orders/{orderId}
  /// 
  /// Document ID: Same as vendor-scoped order ID
  /// Security Rule: Vendor and customer can read, only vendor can write
  /// Purpose: Enable cross-vendor queries and customer order history
  static Map<String, dynamic> globalOrderDocument(Order order) => 
      vendorOrderDocument(order); // Same structure as vendor-scoped

  /// Customer Profile Document Structure
  /// Collection: /customers/{customerId}
  /// 
  /// Document ID: Firebase Auth UID
  /// Security Rule: Only the authenticated customer can read/write
  static Map<String, dynamic> customerDocument({
    required String id,
    required String name,
    required String email,
    required String phone,
    String? profileImageUrl,
    String? defaultAddress,
    required DateTime createdAt,
  }) => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profileImageUrl': profileImageUrl,
    'defaultAddress': defaultAddress,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Analytics Document Structure
  /// Collection: /analytics/{vendorId}
  /// 
  /// Document ID: Firebase Auth UID (same as vendor)
  /// Security Rule: Only the vendor can read/write their analytics
  static Map<String, dynamic> analyticsDocument({
    required String vendorId,
    required int totalOrders,
    required double totalRevenue,
    required int totalProducts,
    required int activeProducts,
    required Map<String, int> ordersByStatus,
    required Map<String, double> revenueByMonth,
    required DateTime lastUpdated,
  }) => {
    'vendorId': vendorId,
    'totalOrders': totalOrders,
    'totalRevenue': totalRevenue,
    'totalProducts': totalProducts,
    'activeProducts': activeProducts,
    'ordersByStatus': ordersByStatus,
    'revenueByMonth': revenueByMonth,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  /// Vendor Directory Document Structure
  /// Collection: /vendor_directory/{vendorId}
  /// 
  /// Document ID: Firebase Auth UID (same as vendor)
  /// Security Rule: Public read, only vendor can write
  /// Purpose: Public directory for customer discovery
  static Map<String, dynamic> vendorDirectoryDocument(Vendor vendor) => {
    'id': vendor.id,
    'businessName': vendor.businessName,
    'businessType': vendor.businessType.index,
    'businessAddress': vendor.businessAddress,
    'businessImageUrl': vendor.businessImageUrl,
    'locationLat': vendor.locationLat,
    'locationLng': vendor.locationLng,
    'isOnline': vendor.isOnline,
    'createdAt': vendor.createdAt.toIso8601String(),
  };
}

/// Common query patterns and their required indexes:
/// 
/// 1. Get orders by vendor and status:
///    .where('vendorId', isEqualTo: vendorId)
///    .where('status', isEqualTo: status)
///    .orderBy('createdAt', descending: true)
/// 
/// 2. Get products by vendor and category:
///    .where('vendorId', isEqualTo: vendorId)
///    .where('category', isEqualTo: category)
///    .orderBy('createdAt', descending: true)
/// 
/// 3. Get available products by business type:
///    .where('businessType', isEqualTo: businessType)
///    .where('isAvailable', isEqualTo: true)
///    .orderBy('createdAt', descending: true)
/// 
/// 4. Get online vendors by business type:
///    .where('businessType', isEqualTo: businessType)
///    .where('isOnline', isEqualTo: true)
///    .orderBy('createdAt', descending: true)

/// Best Practices for Data Management:
/// 
/// 1. Always use Firebase Auth UID as the document ID for user-owned documents
/// 2. Include createdAt timestamp in all documents for chronological ordering
/// 3. Use updatedAt timestamp for documents that can be modified
/// 4. Store enum values as integers (.index) for consistency and efficiency
/// 5. Use E.164 format for phone numbers (+country_code + national_number)
/// 6. Store image URLs from Firebase Storage, not base64 strings
/// 7. Use double precision for monetary values to avoid floating-point errors
/// 8. Implement proper validation in security rules to prevent invalid data
/// 9. Use transactions for operations that modify multiple documents
/// 10. Implement offline persistence for better user experience