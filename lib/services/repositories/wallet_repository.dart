import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/wallet.dart';
import '../firestore_paths.dart';

class WalletRepository {
  WalletRepository(this._db);
  final FirebaseFirestore _db;

  // Updated to match your Firestore:
  // - wallet/{ownerId} document with fields: Balance (number), ownerId, updatedAt (ISO), [optional withdrawPhone]
  // - walletTransactions collection: amount, Description, timestamp, type ('debit'|'credit'), userId

  DocumentReference<Map<String, dynamic>> _walletDocTop(String ownerId) =>
      _db.doc('wallet/$ownerId');

  // Legacy path kept for backward compatibility: vendors/{vendorId}/wallet/meta
  DocumentReference<Map<String, dynamic>> _walletDocLegacy(String vendorId) =>
      _db.doc('${FirestorePaths.vendorDoc(vendorId)}/wallet/meta');

  CollectionReference<Map<String, dynamic>> _transactionsColTop() =>
      _db.collection('walletTransactions');

  Stream<WalletInfo> watchWallet(String ownerId) {
    // Prefer the new top-level wallet collection.
    return _walletDocTop(ownerId).snapshots().map((d) {
      final data = d.data();
      if (data == null || data.isEmpty) return WalletInfo(balance: 0.0, withdrawPhone: '');
      return WalletInfo.fromMap(data);
    });
  }

  Stream<List<WalletTxn>> watchTransactions(String ownerId, {int limit = 20}) {
    // Sort client-side to reduce index requirements
    return _transactionsColTop()
        .where('ownerId', isEqualTo: ownerId)
        .limit(limit)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => WalletTxn.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> setWithdrawPhone(String ownerId, String phone) async {
    await _walletDocTop(ownerId).set({'withdrawPhone': phone}, SetOptions(merge: true));
  }

  Future<void> requestWithdrawal(String ownerId, double amount, {String channel = 'B2C'}) async {
    await _db.runTransaction((tx) async {
      final wref = _walletDocTop(ownerId);
      final wshot = await tx.get(wref);
      final data = wshot.data() ?? {};
      // Support both 'balance' and 'Balance'
      final current = (data['balance'] as num?)?.toDouble() ?? (data['Balance'] as num?)?.toDouble() ?? 0.0;
      if (amount <= 0 || amount > current) {
        throw Exception('Insufficient balance');
      }
      // Record transaction as debit for withdrawal
      tx.set(_transactionsColTop().doc(), {
        'ownerId': ownerId,
        'type': 'debit',
        'amount': amount,
        'channel': channel,
        'status': 'pending',
        'Description': 'Withdrawal to M-Pesa',
        'timestamp': DateTime.now().toIso8601String(),
      });
      // Update wallet Balance (capital B to match your schema), also mirror lowercase for safety
      tx.set(
        wref,
        {
          'Balance': current - amount,
          'balance': current - amount,
          'ownerId': ownerId,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
