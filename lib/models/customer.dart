import 'dart:convert';

class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final String? defaultAddress;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.defaultAddress,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'profileImageUrl': profileImageUrl,
        'defaultAddress': defaultAddress,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
        profileImageUrl: map['profileImageUrl'],
        defaultAddress: map['defaultAddress'],
        createdAt: DateTime.parse(map['createdAt']),
      );

  String toJson() => json.encode(toMap());

  factory Customer.fromJson(String source) => Customer.fromMap(json.decode(source));

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    String? defaultAddress,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}