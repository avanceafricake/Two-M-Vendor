class WalletInfo {
  final double balance;
  final String withdrawPhone;
  WalletInfo({required this.balance, required this.withdrawPhone});

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory WalletInfo.fromMap(Map<String, dynamic> map) {
    // Prefer availableBalance, then fall back to balance / Balance
    final bal = _parseDouble(map['availableBalance'] ?? map['AvailableBalance']) ??
        _parseDouble(map['balance']) ??
        _parseDouble(map['Balance']);
    return WalletInfo(
      balance: bal ?? 0.0,
      withdrawPhone: (map['withdrawPhone'] ?? '').toString(),
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

  static double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0.0;
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
      amount: _parseAmount(map['amount']),
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
