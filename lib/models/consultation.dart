import 'dart:convert';

class ConsultSettings {
  final bool chatEnabled;
  final bool callEnabled;
  final bool videoEnabled;
  final double chatPrice;
  final double callPrice;
  final double videoPrice;

  const ConsultSettings({
    this.chatEnabled = false,
    this.callEnabled = false,
    this.videoEnabled = false,
    this.chatPrice = 0,
    this.callPrice = 0,
    this.videoPrice = 0,
  });

  ConsultSettings copyWith({
    bool? chatEnabled,
    bool? callEnabled,
    bool? videoEnabled,
    double? chatPrice,
    double? callPrice,
    double? videoPrice,
  }) => ConsultSettings(
    chatEnabled: chatEnabled ?? this.chatEnabled,
    callEnabled: callEnabled ?? this.callEnabled,
    videoEnabled: videoEnabled ?? this.videoEnabled,
    chatPrice: chatPrice ?? this.chatPrice,
    callPrice: callPrice ?? this.callPrice,
    videoPrice: videoPrice ?? this.videoPrice,
  );

  Map<String, dynamic> toMap() => {
    'chatEnabled': chatEnabled,
    'callEnabled': callEnabled,
    'videoEnabled': videoEnabled,
    'chatPrice': chatPrice,
    'callPrice': callPrice,
    'videoPrice': videoPrice,
  };

  factory ConsultSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ConsultSettings();
    return ConsultSettings(
      chatEnabled: map['chatEnabled'] ?? false,
      callEnabled: map['callEnabled'] ?? false,
      videoEnabled: map['videoEnabled'] ?? false,
      chatPrice: (map['chatPrice'] as num?)?.toDouble() ?? 0,
      callPrice: (map['callPrice'] as num?)?.toDouble() ?? 0,
      videoPrice: (map['videoPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory ConsultSettings.fromJson(String source) =>
      ConsultSettings.fromMap(json.decode(source));
}

enum ConsultType { chat, call, video }

enum ConsultStatus { requested, accepted, inProgress, completed, cancelled }

class ConsultRequest {
  final String id;
  final String vendorId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final ConsultType type;
  final double price;
  final ConsultStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConsultRequest({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.type,
    required this.price,
    this.status = ConsultStatus.requested,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'vendorId': vendorId,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'type': type.name,
    'price': price,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory ConsultRequest.fromMap(String id, Map<String, dynamic> map) => ConsultRequest(
    id: id,
    vendorId: map['vendorId'],
    customerId: map['customerId'],
    customerName: map['customerName'] ?? 'Customer',
    customerPhone: map['customerPhone'] ?? '',
    type: _typeFrom(map['type']),
    price: (map['price'] as num?)?.toDouble() ?? 0,
    status: _statusFrom(map['status']),
    createdAt: DateTime.parse(map['createdAt']),
    updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
  );

  static ConsultType _typeFrom(String? v) {
    switch (v) {
      case 'chat':
        return ConsultType.chat;
      case 'call':
        return ConsultType.call;
      case 'video':
        return ConsultType.video;
      default:
        return ConsultType.chat;
    }
  }

  static ConsultStatus _statusFrom(String? v) {
    switch (v) {
      case 'requested':
        return ConsultStatus.requested;
      case 'accepted':
        return ConsultStatus.accepted;
      case 'inProgress':
        return ConsultStatus.inProgress;
      case 'completed':
        return ConsultStatus.completed;
      case 'cancelled':
        return ConsultStatus.cancelled;
      default:
        return ConsultStatus.requested;
    }
  }
}
