import 'dart:math';

import '../models/vendor.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';

/// Sample data generator for testing and development
/// 
/// This class provides methods to generate realistic sample data
/// for vendors, products, orders, and customers.
class SampleDataGenerator {
  static final Random _random = Random();

  /// Generate sample vendors for each business type
  static List<Vendor> generateSampleVendors({int count = 10}) {
    final vendors = <Vendor>[];
    final businessTypes = BusinessType.values;
    
    final sampleBusinesses = {
      BusinessType.store: [
        {'name': 'TechMart Electronics', 'description': 'Latest gadgets and electronics'},
        {'name': 'FashionHub Boutique', 'description': 'Trendy clothing and accessories'},
        {'name': 'HomeDecor Plus', 'description': 'Beautiful home decoration items'},
        {'name': 'SportZone', 'description': 'Sports equipment and activewear'},
      ],
      BusinessType.restaurant: [
        {'name': 'Savory Bites', 'description': 'Delicious local and international cuisine'},
        {'name': 'Pizza Corner', 'description': 'Fresh wood-fired pizzas'},
        {'name': 'Healthy Greens', 'description': 'Fresh salads and healthy meals'},
        {'name': 'Coffee Culture', 'description': 'Premium coffee and pastries'},
      ],
      BusinessType.pharmacy: [
        {'name': 'WellCare Pharmacy', 'description': 'Your health is our priority'},
        {'name': 'MedPlus Chemist', 'description': 'Quality medicines and healthcare'},
        {'name': 'Family Health Store', 'description': 'Complete family healthcare solutions'},
      ],
    };

    for (int i = 0; i < count; i++) {
      final businessType = businessTypes[i % businessTypes.length];
      final businesses = sampleBusinesses[businessType]!;
      final business = businesses[_random.nextInt(businesses.length)];
      
      vendors.add(Vendor(
        id: 'vendor_$i',
        name: _generatePersonName(),
        email: 'vendor$i@example.com',
        phone: '+254${_random.nextInt(900000000) + 100000000}',
        businessType: businessType,
        businessName: business['name']!,
        businessAddress: _generateAddress(),
        businessDescription: business['description']!,
        profileImageUrl: 'https://picsum.photos/200/200?random=$i',
        businessImageUrl: 'https://picsum.photos/400/300?random=${i + 100}',
        locationLat: -1.2921 + (_random.nextDouble() - 0.5) * 0.1,
        locationLng: 36.8219 + (_random.nextDouble() - 0.5) * 0.1,
        isOnline: _random.nextBool(),
        isPhoneVerified: _random.nextBool(),
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      ));
    }
    
    return vendors;
  }

  /// Generate sample products for a vendor
  static List<Product> generateSampleProducts({
    required String vendorId,
    required BusinessType businessType,
    int count = 20,
  }) {
    final products = <Product>[];
    final categories = Product.getCategoriesForBusinessType(businessType);
    
    final sampleProducts = {
      BusinessType.store: [
        {'name': 'Wireless Headphones', 'price': 2999.0, 'category': 'Electronics'},
        {'name': 'Smartphone Case', 'price': 899.0, 'category': 'Electronics'},
        {'name': 'Cotton T-Shirt', 'price': 1299.0, 'category': 'Clothing'},
        {'name': 'Denim Jeans', 'price': 2499.0, 'category': 'Clothing'},
        {'name': 'Table Lamp', 'price': 1899.0, 'category': 'Home & Garden'},
        {'name': 'Wall Clock', 'price': 1599.0, 'category': 'Home & Garden'},
        {'name': 'Basketball', 'price': 1999.0, 'category': 'Sports'},
        {'name': 'Running Shoes', 'price': 4999.0, 'category': 'Sports'},
      ],
      BusinessType.restaurant: [
        {'name': 'Chicken Burger', 'price': 799.0, 'category': 'Main Course'},
        {'name': 'Beef Steak', 'price': 1299.0, 'category': 'Main Course'},
        {'name': 'Caesar Salad', 'price': 599.0, 'category': 'Salads'},
        {'name': 'Greek Salad', 'price': 649.0, 'category': 'Salads'},
        {'name': 'Chocolate Cake', 'price': 499.0, 'category': 'Desserts'},
        {'name': 'Ice Cream', 'price': 299.0, 'category': 'Desserts'},
        {'name': 'Fresh Orange Juice', 'price': 199.0, 'category': 'Beverages'},
        {'name': 'Coffee', 'price': 149.0, 'category': 'Beverages'},
      ],
      BusinessType.pharmacy: [
        {'name': 'Paracetamol 500mg', 'price': 199.0, 'category': 'Over-the-Counter'},
        {'name': 'Cough Syrup', 'price': 349.0, 'category': 'Over-the-Counter'},
        {'name': 'Vitamin C Tablets', 'price': 599.0, 'category': 'Vitamins'},
        {'name': 'Multivitamins', 'price': 899.0, 'category': 'Vitamins'},
        {'name': 'Hand Sanitizer', 'price': 299.0, 'category': 'Personal Care'},
        {'name': 'Face Mask', 'price': 49.0, 'category': 'Personal Care'},
        {'name': 'Baby Diapers', 'price': 1299.0, 'category': 'Baby Care'},
        {'name': 'First Aid Kit', 'price': 799.0, 'category': 'First Aid'},
      ],
    };

    final productList = sampleProducts[businessType]!;
    
    for (int i = 0; i < count; i++) {
      final productData = productList[i % productList.length];
      final category = categories.contains(productData['category']) 
          ? productData['category'] as String
          : categories[_random.nextInt(categories.length)];
      
      products.add(Product(
        id: '${vendorId}_product_$i',
        name: '${productData['name']} ${i ~/ productList.length > 0 ? '(${i ~/ productList.length + 1})' : ''}',
        description: _generateProductDescription(productData['name'] as String),
        price: (productData['price'] as double) * (0.8 + _random.nextDouble() * 0.4),
        category: category,
        vendorId: vendorId,
        businessType: businessType,
        imageUrls: [
          'https://picsum.photos/300/300?random=${i + 200}',
          if (_random.nextBool()) 'https://picsum.photos/300/300?random=${i + 300}',
        ],
        isAvailable: _random.nextDouble() > 0.2, // 80% available
        stockQuantity: _random.nextInt(100),
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
      ));
    }
    
    return products;
  }

  /// Generate sample customers
  static List<Customer> generateSampleCustomers({int count = 50}) {
    final customers = <Customer>[];
    
    for (int i = 0; i < count; i++) {
      customers.add(Customer(
        id: 'customer_$i',
        name: _generatePersonName(),
        email: 'customer$i@example.com',
        phone: '+254${_random.nextInt(900000000) + 100000000}',
        profileImageUrl: 'https://picsum.photos/150/150?random=${i + 400}',
        defaultAddress: _generateAddress(),
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(180))),
      ));
    }
    
    return customers;
  }

  /// Generate sample orders for a vendor
  static List<Order> generateSampleOrders({
    required String vendorId,
    required BusinessType businessType,
    required List<Product> products,
    required List<Customer> customers,
    int count = 100,
  }) {
    final orders = <Order>[];
    
    for (int i = 0; i < count; i++) {
      final customer = customers[_random.nextInt(customers.length)];
      final orderProducts = _selectRandomProducts(products, maxItems: 5);
      final items = orderProducts.map((product) => OrderItem(
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: _random.nextInt(3) + 1,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
      )).toList();
      
      final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
      final deliveryFee = _random.nextDouble() * 200 + 50;
      final total = subtotal + deliveryFee;
      
      final createdAt = DateTime.now().subtract(Duration(
        days: _random.nextInt(30),
        hours: _random.nextInt(24),
        minutes: _random.nextInt(60),
      ));
      
      orders.add(Order(
        id: '${vendorId}_order_$i',
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        deliveryAddress: customer.defaultAddress ?? _generateAddress(),
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        status: _generateOrderStatus(),
        vendorId: vendorId,
        businessType: businessType,
        createdAt: createdAt,
        updatedAt: _shouldHaveUpdate() ? createdAt.add(Duration(minutes: _random.nextInt(120))) : null,
        paymentMethod: PaymentMethod.values[_random.nextInt(PaymentMethod.values.length)],
        paymentStatus: _generatePaymentStatus(),
      ));
    }
    
    return orders;
  }

  // Helper methods
  static String _generatePersonName() {
    final firstNames = ['John', 'Jane', 'David', 'Sarah', 'Michael', 'Emily', 'James', 'Jessica', 'Robert', 'Ashley'];
    final lastNames = ['Smith', 'Johnson', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas'];
    return '${firstNames[_random.nextInt(firstNames.length)]} ${lastNames[_random.nextInt(lastNames.length)]}';
  }

  static String _generateAddress() {
    final streets = ['Main St', 'Oak Ave', 'Elm St', 'Park Rd', 'Church St', 'School Rd', 'High St', 'King St'];
    final areas = ['Westlands', 'Karen', 'Lavington', 'Kilimani', 'Parklands', 'Kileleshwa', 'Runda', 'Muthaiga'];
    return '${_random.nextInt(999) + 1} ${streets[_random.nextInt(streets.length)]}, ${areas[_random.nextInt(areas.length)]}, Nairobi';
  }

  static String _generateProductDescription(String productName) {
    final descriptions = [
      'High quality $productName with excellent features.',
      'Premium $productName perfect for daily use.',
      'Durable and reliable $productName at great value.',
      'Modern $productName with latest technology.',
      'Best-selling $productName loved by customers.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  static List<Product> _selectRandomProducts(List<Product> products, {int maxItems = 3}) {
    final shuffled = List<Product>.from(products)..shuffle(_random);
    final itemCount = _random.nextInt(maxItems) + 1;
    return shuffled.take(itemCount).toList();
  }

  static OrderStatus _generateOrderStatus() {
    final weights = {
      OrderStatus.pending: 10,
      OrderStatus.confirmed: 15,
      OrderStatus.preparing: 20,
      OrderStatus.ready: 15,
      OrderStatus.delivered: 30,
      OrderStatus.cancelled: 10,
    };
    
    final totalWeight = weights.values.reduce((a, b) => a + b);
    final randomValue = _random.nextInt(totalWeight);
    
    int currentWeight = 0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (randomValue < currentWeight) {
        return entry.key;
      }
    }
    
    return OrderStatus.delivered;
  }

  static PaymentStatus _generatePaymentStatus() {
    final weights = {
      PaymentStatus.pending: 15,
      PaymentStatus.paid: 60,
      PaymentStatus.refunded: 5,
      PaymentStatus.awaitingDriverRemittance: 10,
      PaymentStatus.remitted: 10,
    };
    
    final totalWeight = weights.values.reduce((a, b) => a + b);
    final randomValue = _random.nextInt(totalWeight);
    
    int currentWeight = 0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (randomValue < currentWeight) {
        return entry.key;
      }
    }
    
    return PaymentStatus.paid;
  }

  static bool _shouldHaveUpdate() => _random.nextDouble() < 0.7; // 70% chance
}