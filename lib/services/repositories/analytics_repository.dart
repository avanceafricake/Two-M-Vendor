import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../models/order.dart';

class AnalyticsData {
  final int totalOrders;
  final double totalRevenue;
  final int totalProducts;
  final int activeProducts;
  final Map<OrderStatus, int> ordersByStatus;
  final Map<String, double> revenueByMonth;
  final DateTime lastUpdated;

  AnalyticsData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalProducts,
    required this.activeProducts,
    required this.ordersByStatus,
    required this.revenueByMonth,
    required this.lastUpdated,
  });

  factory AnalyticsData.fromMap(Map<String, dynamic> map) {
    final ordersByStatusMap = <OrderStatus, int>{};
    (map['ordersByStatus'] as Map<String, dynamic>).forEach((key, value) {
      final status = OrderStatus.values[int.parse(key)];
      ordersByStatusMap[status] = value as int;
    });

    return AnalyticsData(
      totalOrders: map['totalOrders'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
      totalProducts: map['totalProducts'] ?? 0,
      activeProducts: map['activeProducts'] ?? 0,
      ordersByStatus: ordersByStatusMap,
      revenueByMonth: Map<String, double>.from(map['revenueByMonth'] ?? {}),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() => {
    'totalOrders': totalOrders,
    'totalRevenue': totalRevenue,
    'totalProducts': totalProducts,
    'activeProducts': activeProducts,
    'ordersByStatus': ordersByStatus.map((key, value) => 
        MapEntry(key.index.toString(), value)),
    'revenueByMonth': revenueByMonth,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

class AnalyticsRepository {
  AnalyticsRepository(this._db);
  final FirebaseFirestore _db;

  /// Get analytics data for a vendor
  Future<AnalyticsData?> getAnalytics(String vendorId) async {
    final doc = await _db.collection('analytics').doc(vendorId).get();
    if (!doc.exists) return null;
    return AnalyticsData.fromMap(doc.data()!);
  }

  /// Watch analytics data for real-time updates
  Stream<AnalyticsData?> watchAnalytics(String vendorId) {
    return _db.collection('analytics').doc(vendorId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AnalyticsData.fromMap(doc.data()!);
    });
  }

  /// Calculate and update analytics for a vendor
  Future<void> updateAnalytics(String vendorId) async {
    final now = DateTime.now();
    
    // Get orders data
    final ordersSnapshot = await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('orders')
        .get();

    // Get products data
    final productsSnapshot = await _db
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .get();

    // Calculate metrics
    int totalOrders = ordersSnapshot.docs.length;
    double totalRevenue = 0.0;
    final ordersByStatus = <OrderStatus, int>{};
    final revenueByMonth = <String, double>{};

    // Initialize order status counts
    for (final status in OrderStatus.values) {
      ordersByStatus[status] = 0;
    }

    // Process orders
    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final order = Order.fromMap(data);
      
      // Count by status
      ordersByStatus[order.status] = (ordersByStatus[order.status] ?? 0) + 1;
      
      // Add to revenue if delivered
      if (order.status == OrderStatus.delivered) {
        totalRevenue += order.total;
        
        // Group revenue by month
        final monthKey = '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}';
        revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0.0) + order.total;
      }
    }

    // Calculate product metrics
    int totalProducts = productsSnapshot.docs.length;
    int activeProducts = 0;
    
    for (final doc in productsSnapshot.docs) {
      final data = doc.data();
      if (data['isAvailable'] == true) {
        activeProducts++;
      }
    }

    // Create analytics data
    final analyticsData = AnalyticsData(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      totalProducts: totalProducts,
      activeProducts: activeProducts,
      ordersByStatus: ordersByStatus,
      revenueByMonth: revenueByMonth,
      lastUpdated: now,
    );

    // Save to Firestore
    await _db.collection('analytics').doc(vendorId).set(
      analyticsData.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Get revenue for a specific time period
  Future<double> getRevenueForPeriod({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.delivered.index)
        .where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();

    double totalRevenue = 0.0;
    for (final doc in snapshot.docs) {
      final order = Order.fromMap(doc.data());
      totalRevenue += order.total;
    }

    return totalRevenue;
  }

  /// Get order count for a specific status
  Future<int> getOrderCountByStatus({
    required String vendorId,
    required OrderStatus status,
  }) async {
    final snapshot = await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('orders')
        .where('status', isEqualTo: status.index)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get top-selling products for a vendor
  Future<List<Map<String, dynamic>>> getTopProducts({
    required String vendorId,
    int limit = 10,
  }) async {
    // This would require aggregating order items across all orders
    // For now, return products ordered by creation date
    // In production, consider using Cloud Functions for complex aggregations
    final snapshot = await _db
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Schedule analytics update (call this after order status changes)
  Future<void> scheduleAnalyticsUpdate(String vendorId) async {
    // In production, this could trigger a Cloud Function
    // For now, update immediately
    await updateAnalytics(vendorId);
  }
}