class WalletInfo {
  final double balance;
  final String withdrawPhone;
  WalletInfo({required this.balance, required this.withdrawPhone});

  factory WalletInfo.fromMap(Map<String, dynamic> map) {
    // Support both 'balance' and 'Balance' keys
    final bal = map.containsKey('balance')
        ? (map['balance'] as num?)?.toDouble()
        : (map['Balance'] as num?)?.toDouble();
    return WalletInfo(
      balance: bal ?? 0.0,
      withdrawPhone: map['withdrawPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'balance': balance,
        'withdrawPhone': withdrawPhone,
      };
}

class WalletTxn {
  final String id;
  // Normalized to 'deposit' | 'withdrawal'
  final String type;
  final double amount;
  final String channel; // e.g., C2B, B2C, Manual
  final String status; // pending|success|failed
  final DateTime timestamp;
  final String? description;

  WalletTxn({
    required this.id,
    required this.type,
    required this.amount,
    required this.channel,
    required this.status,
    required this.timestamp,
    this.description,
  });

  static DateTime _parseTimestamp(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    // Firestore Timestamp
    final tsType = v.runtimeType.toString();
    if (tsType == 'Timestamp') {
      try {
        // ignore: avoid_dynamic_calls
        return v.toDate();
      } catch (_) {}
    }
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    if (v is num) {
      // milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory WalletTxn.fromMap(String id, Map<String, dynamic> map) {
    final rawType = (map['type'] as String?)?.toLowerCase() ?? 'deposit';
    // Support external values 'debit'|'credit' by mapping to 'withdrawal'|'deposit'
    final normalized = rawType == 'debit'
        ? 'withdrawal'
        : rawType == 'credit'
            ? 'deposit'
            : rawType;
    return WalletTxn(
      id: id,
      type: normalized,
      amount: (map['amount'] as num).toDouble(),
      channel: (map['channel'] as String?) ?? 'Manual',
      status: (map['status'] as String?) ?? 'success',
      timestamp: _parseTimestamp(map['timestamp']),
      description: map['Description'] as String? ?? map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'amount': amount,
        'channel': channel,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        if (description != null) 'description': description,
      };
}
