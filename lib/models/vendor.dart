import 'dart:convert';

enum BusinessType { store, restaurant, pharmacy }

enum VendorStatus { pendingApproval, approved, suspended, rejected }

class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final BusinessType businessType;
  final String businessName;
  final String businessAddress;
  final String businessDescription;
  final String? profileImageUrl;
  final String? businessImageUrl;
  final double? locationLat;
  final double? locationLng;
  final bool isOnline;
  final bool isPhoneVerified;
  final DateTime createdAt;
  // Onboarding + category theming
  final bool onboarded;
  final String? categoryKey; // fashion, food, cosmetics, pharmacy, grocery
  // Approval status
  final VendorStatus status;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessType,
    required this.businessName,
    required this.businessAddress,
    required this.businessDescription,
    this.profileImageUrl,
    this.businessImageUrl,
    this.locationLat,
    this.locationLng,
    this.isOnline = true,
    this.isPhoneVerified = false,
    required this.createdAt,
    this.onboarded = false,
    this.categoryKey,
    this.status = VendorStatus.approved,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'businessType': businessType.index,
        'businessName': businessName,
        'businessAddress': businessAddress,
        'businessDescription': businessDescription,
        'profileImageUrl': profileImageUrl,
        'businessImageUrl': businessImageUrl,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'isOnline': isOnline,
        'isPhoneVerified': isPhoneVerified,
        'createdAt': createdAt.toIso8601String(),
        'onboarded': onboarded,
        'categoryKey': categoryKey,
        'status': status.name,
      };

  static VendorStatus _statusFromMap(dynamic value) {
    if (value is String) {
      return VendorStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => VendorStatus.approved,
      );
    }
    if (value is int) {
      if (value >= 0 && value < VendorStatus.values.length) {
        return VendorStatus.values[value];
      }
    }
    return VendorStatus.approved;
  }

  factory Vendor.fromMap(Map<String, dynamic> map) => Vendor(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
        businessType: BusinessType.values[map['businessType']],
        businessName: map['businessName'],
        businessAddress: map['businessAddress'],
        businessDescription: map['businessDescription'],
        profileImageUrl: map['profileImageUrl'],
        businessImageUrl: map['businessImageUrl'],
        locationLat: (map['locationLat'] as num?)?.toDouble(),
        locationLng: (map['locationLng'] as num?)?.toDouble(),
        isOnline: map['isOnline'] ?? true,
        isPhoneVerified: map['isPhoneVerified'] ?? false,
        createdAt: DateTime.parse(map['createdAt']),
        onboarded: map['onboarded'] ?? false,
        categoryKey: map['categoryKey'],
        status: _statusFromMap(map['status']),
      );

  String toJson() => json.encode(toMap());

  factory Vendor.fromJson(String source) => Vendor.fromMap(json.decode(source));

  String get businessTypeDisplayName {
    switch (businessType) {
      case BusinessType.store:
        return 'Store';
      case BusinessType.restaurant:
        return 'Restaurant';
      case BusinessType.pharmacy:
        return 'Pharmacy';
    }
  }
}
