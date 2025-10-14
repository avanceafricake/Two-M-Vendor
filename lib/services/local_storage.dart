import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/vendor.dart';
import '../models/product.dart';
import '../models/order.dart';

class LocalStorageService {
  static const String _vendorKey = 'vendor_data';
  static const String _productsKey = 'products_data';
  static const String _ordersKey = 'orders_data';
  static const String _currentVendorKey = 'current_vendor';
  static const String _walletBalanceKey = 'wallet_balance_kes';
  static const String _walletTxnsKey = 'wallet_txns';

  static Map<String, String> _storage = {};  

  // Auth UX preferences
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';


  // Vendor operations
  static Future<void> saveVendor(Vendor vendor) async {
    _storage[_currentVendorKey] = vendor.id;
    _storage[_vendorKey] = vendor.toJson();
  }

  static Future<Vendor?> getCurrentVendor() async {
    final vendorData = _storage[_vendorKey];
    if (vendorData != null) {
      return Vendor.fromJson(vendorData);
    }
    return null;
  }

  static Future<void> clearVendor() async {
    _storage.remove(_currentVendorKey);
    _storage.remove(_vendorKey);
  }

  // Wallet operations (simulated)
  static Future<double> getWalletBalance() async {
    final v = _storage[_walletBalanceKey];
    if (v != null) return double.tryParse(v) ?? 0.0;
    // Seed balance
    _storage[_walletBalanceKey] = '12500.00';
    return 12500.00;
  }

  static Future<void> setWalletBalance(double value) async {
    _storage[_walletBalanceKey] = value.toStringAsFixed(2);
  }

  static Future<List<Map<String, dynamic>>> getWalletTransactions() async {
    final raw = _storage[_walletTxnsKey];
    if (raw == null) return [];
    final List list = json.decode(raw);
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> addWalletTransaction(Map<String, dynamic> txn) async {
    final txns = await getWalletTransactions();
    txns.insert(0, txn);
    _storage[_walletTxnsKey] = json.encode(txns);
  }

  // Products operations
  static Future<void> saveProduct(Product product) async {
    final products = await getProducts();
    products.removeWhere((p) => p.id == product.id);
    products.add(product);
    
    final productsJson = products.map((p) => p.toMap()).toList();
    _storage[_productsKey] = json.encode(productsJson);
  }

  static Future<List<Product>> getProducts() async {
    final productsData = _storage[_productsKey];
    if (productsData != null) {
      final List<dynamic> productsList = json.decode(productsData);
      return productsList.map((p) => Product.fromMap(p)).toList();
    }
    return _getSampleProducts();
  }

  static Future<List<Product>> getProductsByVendor(String vendorId) async {
    final products = await getProducts();
    return products.where((p) => p.vendorId == vendorId).toList();
  }

  // Orders operations
  static Future<void> saveOrder(Order order) async {
    final orders = await getOrders();
    orders.removeWhere((o) => o.id == order.id);
    orders.add(order);
    
    final ordersJson = orders.map((o) => o.toMap()).toList();
    _storage[_ordersKey] = json.encode(ordersJson);
  }

  static Future<List<Order>> getOrders() async {
    final ordersData = _storage[_ordersKey];
    if (ordersData != null) {
      final List<dynamic> ordersList = json.decode(ordersData);
      return ordersList.map((o) => Order.fromMap(o)).toList();
    }
    return _getSampleOrders();
  }

  static Future<List<Order>> getOrdersByVendor(String vendorId) async {
    final orders = await getOrders();
    return orders.where((o) => o.vendorId == vendorId).toList();
  }

  // Authentication check
  static Future<bool> isLoggedIn() async {
    return _storage.containsKey(_currentVendorKey);
  }

  // Sample data generators
  static List<Product> _getSampleProducts() {
    return [
      Product(
        id: '1',
        name: 'Wireless Headphones',
        description: 'High-quality wireless headphones with noise cancellation',
        price: 199.99,
        category: 'Electronics',
        vendorId: 'vendor_1',
        businessType: BusinessType.store,
        imageUrls: ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e'],
        stockQuantity: 25,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Product(
        id: '2',
        name: 'Grilled Chicken Burger',
        description: 'Juicy grilled chicken with fresh lettuce and tomatoes',
        price: 12.99,
        category: 'Main Course',
        vendorId: 'vendor_1',
        businessType: BusinessType.restaurant,
        imageUrls: ['https://images.unsplash.com/photo-1568901346375-23c9450c58cd'],
        stockQuantity: 50,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Product(
        id: '3',
        name: 'Pain Relief Medicine',
        description: 'Effective pain relief medication, 500mg tablets',
        price: 8.99,
        category: 'Over-the-Counter',
        vendorId: 'vendor_1',
        businessType: BusinessType.pharmacy,
        imageUrls: ['https://images.unsplash.com/photo-1584017911766-d451b3d0e843'],
        stockQuantity: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<Order> _getSampleOrders() {
    return [
      Order(
        id: '1',
        customerId: 'customer_1',
        customerName: 'John Doe',
        customerPhone: '+1234567890',
        deliveryAddress: '123 Main St, City, State 12345',
        items: [
          OrderItem(
            productId: '1',
            productName: 'Wireless Headphones',
            price: 199.99,
            quantity: 1,
            imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
          ),
        ],
        subtotal: 199.99,
        deliveryFee: 5.99,
        total: 205.98,
        status: OrderStatus.pending,
        vendorId: 'vendor_1',
        businessType: BusinessType.store,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.c2b,
        paymentStatus: PaymentStatus.pending,
      ),
      Order(
        id: '2',
        customerId: 'customer_2',
        customerName: 'Jane Smith',
        customerPhone: '+1234567891',
        deliveryAddress: '456 Oak Ave, City, State 12345',
        items: [
          OrderItem(
            productId: '2',
            productName: 'Grilled Chicken Burger',
            price: 12.99,
            quantity: 2,
            imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
          ),
        ],
        subtotal: 25.98,
        deliveryFee: 3.99,
        total: 29.97,
        status: OrderStatus.confirmed,
        vendorId: 'vendor_1',
        businessType: BusinessType.restaurant,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        paymentMethod: PaymentMethod.c2b,
        paymentStatus: PaymentStatus.paid,
      ),
      Order(
        id: '3',
        customerId: 'customer_3',
        customerName: 'Mike Johnson',
        customerPhone: '+1234567892',
        deliveryAddress: '789 Pine St, City, State 12345',
        items: [
          OrderItem(
            productId: '3',
            productName: 'Pain Relief Medicine',
            price: 8.99,
            quantity: 1,
            imageUrl: 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843',
          ),
        ],
        subtotal: 8.99,
        deliveryFee: 2.99,
        total: 11.98,
        status: OrderStatus.delivered,
        vendorId: 'vendor_1',
        businessType: BusinessType.pharmacy,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.awaitingDriverRemittance,
      ),
    ];
  }
}