import 'dart:convert';
import 'vendor.dart';

enum OrderStatus { pending, confirmed, preparing, ready, delivered, cancelled }

// Payment policy: allow only C2B (collections) and B2C (payouts). Cash is driver-only.
enum PaymentMethod { c2b, b2c, cash }
enum PaymentStatus { pending, paid, refunded, awaitingDriverRemittance, remitted }

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'],
        productName: map['productName'],
        price: (map['price'] as num).toDouble(),
        quantity: map['quantity'],
        imageUrl: map['imageUrl'],
      );
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final String vendorId;
  final BusinessType businessType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 0.0,
    required this.total,
    this.status = OrderStatus.pending,
    required this.vendorId,
    required this.businessType,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethod = PaymentMethod.c2b,
    this.paymentStatus = PaymentStatus.pending,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'deliveryAddress': deliveryAddress,
        'items': items.map((item) => item.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': status.index,
        'vendorId': vendorId,
        'businessType': businessType.index,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'paymentMethod': paymentMethod.index,
        'paymentStatus': paymentStatus.index,
      };

  factory Order.fromMap(Map<String, dynamic> map) => Order(
        id: map['id'],
        customerId: map['customerId'],
        customerName: map['customerName'],
        customerPhone: map['customerPhone'],
        deliveryAddress: map['deliveryAddress'],
        items: List<OrderItem>.from((map['items'] as List).map((x) => OrderItem.fromMap(x))),
        subtotal: (map['subtotal'] as num).toDouble(),
        deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
        total: (map['total'] as num).toDouble(),
        status: OrderStatus.values[map['status'] ?? OrderStatus.pending.index],
        vendorId: map['vendorId'],
        businessType: BusinessType.values[map['businessType'] ?? BusinessType.store.index],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
        paymentMethod: PaymentMethod.values[map['paymentMethod'] ?? PaymentMethod.c2b.index],
        paymentStatus: PaymentStatus.values[map['paymentStatus'] ?? PaymentStatus.pending.index],
      );

  String toJson() => json.encode(toMap());

  factory Order.fromJson(String source) => Order.fromMap(json.decode(source));

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.c2b:
        return 'C2B (Customer to Business)';
      case PaymentMethod.b2c:
        return 'B2C (Business to Customer)';
      case PaymentMethod.cash:
        return 'Cash (Driver)';
    }
  }

  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.awaitingDriverRemittance:
        return 'Awaiting Driver Remittance';
      case PaymentStatus.remitted:
        return 'Remitted';
    }
  }
}
