import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:two_m_vendors/services/mpesa_service.dart';
import '../../models/wallet.dart';
import '../firestore_paths.dart';

class WalletRepository {
  WalletRepository(this._db);
  final FirebaseFirestore _db;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  // Ensure MSISDN is in 2547XXXXXXXX format for Safaricom APIs
  String _formatKenyanMsisdn(String input) {
    var p = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('0')) p = '254${p.substring(1)}';
    if (p.startsWith('7') && p.length == 9) p = '254$p';
    if (!p.startsWith('254')) return p; // if already in correct format or non-KE, return as-is
    return p;
  }

  // Updated to match your Firestore:
  // - wallet/{ownerId} document with fields: Balance (number), ownerId, updatedAt (ISO), [optional withdrawPhone]
  // - walletTransactions collection: amount, Description, timestamp, type ('debit'|'credit'), userId

  DocumentReference<Map<String, dynamic>> _walletDocTop(String ownerId) => _db.doc('wallet/$ownerId');

  // Legacy path kept for backward compatibility: vendors/{vendorId}/wallet/meta
  DocumentReference<Map<String, dynamic>> _walletDocLegacy(String vendorId) =>
      _db.doc('${FirestorePaths.vendorDoc(vendorId)}/wallet/meta');

  CollectionReference<Map<String, dynamic>> _transactionsColTop() => _db.collection('walletTransactions');

  Stream<WalletInfo> watchWallet(String ownerId) {
    // Prefer the new top-level wallet collection, fall back to legacy vendor path if empty.
    return _walletDocTop(ownerId).snapshots().asyncMap((d) async {
      final data = d.data();
      if (data != null && data.isNotEmpty) {
        return WalletInfo.fromMap(data);
      }

      final legacyShot = await _walletDocLegacy(ownerId).get();
      final legacyData = legacyShot.data();
      if (legacyData != null && legacyData.isNotEmpty) {
        return WalletInfo.fromMap(legacyData);
      }

      return WalletInfo(balance: 0.0, withdrawPhone: '');
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
    // Read the withdraw phone first (outside the transaction)
    final walletSnapshot = await _walletDocTop(ownerId).get();
    final withdrawPhone = (walletSnapshot.data()?['withdrawPhone'] ?? '').toString();
    // Pre-create a transaction doc so we can pass its ID to the B2C request as Occassion
    final txnRef = _transactionsColTop().doc();

    await _db.runTransaction((tx) async {
      final wref = _walletDocTop(ownerId);
      final wshot = await tx.get(wref);
      final data = wshot.data() ?? {};
      // Support mixed schemas and string values
      final current = _toDouble(data['availableBalance']) ??
          _toDouble(data['AvailableBalance']) ??
          _toDouble(data['balance']) ??
          _toDouble(data['Balance']) ??
          0.0;
      if (amount <= 0 || amount > current) {
        throw Exception('Insufficient balance');
      }
      // Record transaction as debit for withdrawal
      tx.set(txnRef, {
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
          'AvailableBalance': current - amount,
          'availableBalance': current - amount,
          'ownerId': ownerId,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    });

    // Trigger B2C payout via Cloud Function (non-blocking for the UI)
    try {
      if (withdrawPhone.isEmpty) {
        throw Exception('Withdraw phone not set');
      }
      final msisdn = _formatKenyanMsisdn(withdrawPhone);
      await MpesaService.instance.initiateB2C(
        amount: amount.toString(),
        msisdn: msisdn,
        shortcode: '',
        initiatorName: '',
        remarks: 'Wallet withdrawal for $ownerId',
        commandId: 'BusinessPayment',
        occassion: txnRef.id,
      );
    } catch (e) {
      // Swallow errors here so wallet deduction is not blocked; status will be updated via callbacks if implemented.
      // Consider logging to a collection, e.g., payoutErrors.
    }
  }
}
