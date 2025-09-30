import 'dart:convert';
import 'vendor.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? salePrice; // Optional discounted price
  final String category;
  final String vendorId;
  final BusinessType businessType;
  final List<String> imageUrls;
  final bool isAvailable;
  final int stockQuantity;
  final DateTime createdAt;
  final Map<String, dynamic>? attributes; // category-specific attributes (sizes, unit, etc.)

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.category,
    required this.vendorId,
    required this.businessType,
    required this.imageUrls,
    this.isAvailable = true,
    this.stockQuantity = 0,
    required this.createdAt,
    this.attributes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'salePrice': salePrice,
        'category': category,
        'vendorId': vendorId,
        'businessType': businessType.index,
        'imageUrls': imageUrls,
        'isAvailable': isAvailable,
        'stockQuantity': stockQuantity,
        'createdAt': createdAt.toIso8601String(),
        'attributes': attributes,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'],
        name: map['name'],
        description: map['description'],
        price: (map['price'] as num).toDouble(),
        salePrice: map['salePrice'] != null ? (map['salePrice'] as num).toDouble() : null,
        category: map['category'],
        vendorId: map['vendorId'],
        businessType: BusinessType.values[map['businessType']],
        imageUrls: List<String>.from(map['imageUrls']),
        isAvailable: map['isAvailable'] ?? true,
        stockQuantity: map['stockQuantity'] ?? 0,
        createdAt: DateTime.parse(map['createdAt']),
        attributes: map['attributes'] as Map<String, dynamic>?,
      );

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) => Product.fromMap(json.decode(source));

  static List<String> getCategoriesForBusinessType(BusinessType type) {
    switch (type) {
      case BusinessType.store:
        return ['Electronics', 'Clothing', 'Home & Garden', 'Sports', 'Books', 'Toys'];
      case BusinessType.restaurant:
        return ['Appetizers', 'Main Course', 'Desserts', 'Beverages', 'Salads', 'Soups'];
      case BusinessType.pharmacy:
        return ['Prescription', 'Over-the-Counter', 'Vitamins', 'Personal Care', 'Baby Care', 'First Aid'];
    }
  }

  static List<String> getCategoriesForCategoryKey(String? key) {
    switch (key) {
      // Fashion storefronts
      case 'fashion':
        return [
          'Men - Shirts',
          'Men - Trousers',
          'Men - Shoes',
          'Women - Dresses',
          'Women - Tops',
          'Women - Shoes',
          'Unisex - Accessories',
          'Bags & Backpacks',
          'Watches & Jewelry',
          'Kids - Clothing',
        ];
      // Cosmetics & beauty
      case 'cosmetics':
        return [
          'Skincare - Cleansers',
          'Skincare - Moisturizers',
          'Skincare - Serums & Treatments',
          'Sunscreen',
          'Makeup - Face',
          'Makeup - Eyes',
          'Makeup - Lips',
          'Haircare - Shampoo',
          'Haircare - Conditioner',
          'Haircare - Treatments',
          'Fragrance',
          'Tools & Brushes',
        ];
      // Grocery & everyday items
      case 'grocery':
        return [
          'Fruits & Vegetables',
          'Dairy & Eggs',
          'Bakery',
          'Meat & Fish',
          'Pantry & Dry Goods',
          'Snacks',
          'Beverages',
          'Household',
          'Personal Care',
          'Baby Care',
        ];
      // Prepared food & restaurants
      case 'food':
        return [
          'Breakfast',
          'Burgers',
          'Pizza',
          'Chicken & Grill',
          'Rice & Bowls',
          'Sides',
          'Desserts',
          'Beverages',
        ];
      // Pharmacy with OTC-first granularity
      case 'pharmacy':
        return [
          'Supplements & Vitamins',
          'Pain Relief',
          'Cough, Cold & Flu',
          'Allergy',
          'Digestive Health',
          'Skin & Topicals',
          'First Aid',
          'Diabetes Care',
          'Hypertension & Heart',
          'Sexual Wellness',
          'Eye & Ear Care',
          'Oral Care',
          'Baby & Mother Care',
          'Medical Devices',
          'Antibiotics',
          'Prescription Medicines',
        ];
      default:
        return ['General'];
    }
  }
}