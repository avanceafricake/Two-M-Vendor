import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A thin wrapper for M-Pesa Daraja. In production, wire this to flutter_mpesa_package.
/// For now, we expose the same API surface without importing the package to
/// keep builds green until credentials are provided and the package resolves.
class MpesaService {
  MpesaService._();
  static final MpesaService instance = MpesaService._();

  bool _initialized = false;
  String? _vendorId;

  bool get isInitialized => _initialized;
  String? get vendorId => _vendorId;

  /// Initialize using credentials fetched from Firestore.
  /// Expects doc at mpesa_config/{vendorId} with fields: consumerKey, consumerSecret, securityCredential.
  Future<bool> initFromFirestore(String vendorId) async {
    try {
      final doc = await FirebaseFirestore.instance.doc('mpesa_config/$vendorId').get();
      if (!doc.exists) {
        if (kDebugMode) debugPrint('Mpesa config missing for vendor: $vendorId');
        _initialized = false;
        return false;
      }
      final data = (doc.data() ?? {});
      final consumerKey = (data['consumerKey'] ?? '').toString().trim();
      final consumerSecret = (data['consumerSecret'] ?? '').toString().trim();
      final securityCredential = (data['securityCredential'] ?? '').toString().trim();
      if (consumerKey.isEmpty || consumerSecret.isEmpty || securityCredential.isEmpty) {
        if (kDebugMode) debugPrint('Mpesa config incomplete for vendor: $vendorId');
        _initialized = false;
        return false;
      }

      // In the package-backed implementation you'd call FlutterMpesa.initFlutterMpesa here.
      _initialized = true;
      _vendorId = vendorId;
      if (kDebugMode) debugPrint('Mpesa initialized (stub) for vendor $vendorId');
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Mpesa init error: $e');
        debugPrint('$st');
      }
      _initialized = false;
      return false;
    }
  }

  /// Initiate a C2B payment (top-up). Currently stubbed until runtime package is enabled.
  Future<Map<String, dynamic>> initiateC2B({
    required String amount,
    required String msisdn,
    required String shortcode,
    required String billRefNumber,
    String? commandId,
  }) async {
    _assertInitialized();
    throw UnimplementedError('C2B not wired: add flutter_mpesa_package usage in MpesaService.');
  }

  /// Initiate a B2C transaction (withdrawal). Currently stubbed.
  Future<Map<String, dynamic>> initiateB2C({
    required String amount,
    required String msisdn,
    required String shortcode,
    required String initiatorName,
    required String remarks,
    String? commandId,
    String? occassion,
  }) async {
    _assertInitialized();
    throw UnimplementedError('B2C not wired: add flutter_mpesa_package usage in MpesaService.');
  }

  /// STK Push (Lipa Na M-Pesa). Currently stubbed.
  Future<Map<String, dynamic>> initiateStkPush({
    required String amount,
    required String phoneNumber,
    required String businessShortCode,
    required String passKey,
    required String callbackUrl,
    required String accountReference,
    required String transactionDesc,
  }) async {
    _assertInitialized();
    throw UnimplementedError('STK Push not wired: add flutter_mpesa_package usage in MpesaService.');
  }

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError('MpesaService not initialized. Call initFromFirestore(vendorId) first.');
    }
  }
}
