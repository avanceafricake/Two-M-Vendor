import 'package:cloud_firestore/cloud_firestore.dart' as cf;

import '../../models/order.dart' as model;
import '../firestore_paths.dart';

class OrderRepository {
  OrderRepository(this._db);
  final cf.FirebaseFirestore _db;

  // Create order in global orders collection
  Future<void> create(model.Order order) async {
    // Enforce payment policy: only c2b or b2c; cash only allowed if a driver will remit later.
    if (order.paymentMethod == model.PaymentMethod.cash && order.paymentStatus != model.PaymentStatus.awaitingDriverRemittance) {
      throw Exception('Cash payments must be created with Awaiting Driver Remittance status.');
    }
    final ref = _db.collection(FirestorePaths.orders).doc(order.id);
    await ref.set(order.toMap());
  }

  Future<void> updateStatus({
    required String vendorId,
    required String orderId,
    required model.OrderStatus nextStatus,
  }) async {
    final ref = _db.collection(FirestorePaths.orders).doc(orderId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Order not found');
    final current = model.Order.fromMap(snap.data()! as Map<String, dynamic>);

    // Verify the vendor owns this order
    if (current.vendorId != vendorId) {
      throw Exception('Order does not belong to this vendor');
    }

    if (!_isValidTransition(current.status, nextStatus)) {
      throw Exception('Invalid status transition: ${current.status} -> $nextStatus');
    }

    await ref.update({
      'status': nextStatus.index,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<model.Order>> watchByVendor({required String vendorId, model.OrderStatus? status}) {
    cf.Query<Map<String, dynamic>> q = _db.collection(FirestorePaths.orders)
        .where('vendorId', isEqualTo: vendorId);
    if (status != null) q = q.where('status', isEqualTo: status.index);
    return q.orderBy('createdAt', descending: true).snapshots().map((s) {
      return s.docs.map((d) => model.Order.fromMap(d.data())).toList();
    });
  }

  bool _isValidTransition(model.OrderStatus from, model.OrderStatus to) {
    switch (from) {
      case model.OrderStatus.pending:
        return to == model.OrderStatus.confirmed || to == model.OrderStatus.cancelled;
      case model.OrderStatus.confirmed:
        return to == model.OrderStatus.preparing || to == model.OrderStatus.cancelled;
      case model.OrderStatus.preparing:
        return to == model.OrderStatus.ready || to == model.OrderStatus.cancelled;
      case model.OrderStatus.ready:
        return to == model.OrderStatus.delivered || to == model.OrderStatus.cancelled;
      case model.OrderStatus.delivered:
        return false;
      case model.OrderStatus.cancelled:
        return false;
    }
  }
}
