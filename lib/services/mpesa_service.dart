import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:two_m_vendors/services/env_config.dart';

/// M-Pesa service wrapper.
/// In this project we route sensitive calls through Firebase Cloud Functions
/// to keep secrets server-side. The client invokes callable functions.
class MpesaService {
  MpesaService._();
  static final MpesaService instance = MpesaService._();

  bool _initialized = false;
  String? _vendorId;

  bool get isInitialized => _initialized;
  String? get vendorId => _vendorId;

  /// Set vendor context without requiring any Firestore config.
  /// Cloud Functions will read secure config from server-side env.
  void setVendorContext(String vendorId) {
    _vendorId = vendorId;
    _initialized = true;
    if (kDebugMode) debugPrint('MpesaService: vendor context set for $vendorId');
  }

  /// Legacy initializer that checked Firestore for credentials. Left in place for
  /// backward-compat setups, but not required for the Cloud Functions approach.
  Future<bool> initFromFirestore(String vendorId) async {
    try {
      final doc = await FirebaseFirestore.instance.doc('mpesa_config/$vendorId').get();
      if (!doc.exists) {
        if (kDebugMode) debugPrint('Mpesa config missing for vendor: $vendorId (non-blocking)');
        // Still set vendor context so Cloud Functions can run with server-side config
        setVendorContext(vendorId);
        return true;
      }
      final data = (doc.data() ?? {}) as Map<String, dynamic>;
      final consumerKey = (data['consumerKey'] ?? '').toString().trim();
      final consumerSecret = (data['consumerSecret'] ?? '').toString().trim();
      final securityCredential = (data['securityCredential'] ?? '').toString().trim();
      if (consumerKey.isEmpty || consumerSecret.isEmpty || securityCredential.isEmpty) {
        if (kDebugMode) debugPrint('Mpesa config incomplete for vendor: $vendorId (non-blocking)');
        setVendorContext(vendorId);
        return true;
      }

      // If a package-backed client was used, it would be initialized here.
      setVendorContext(vendorId);
      if (kDebugMode) debugPrint('Mpesa initialized for vendor $vendorId');
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Mpesa init error: $e');
        debugPrint('$st');
      }
      // Do not block; set vendor context so callable functions can still be used.
      setVendorContext(vendorId);
      return true;
    }
  }

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  /// Initiate a C2B payment (top-up). Implement when needed.
  Future<Map<String, dynamic>> initiateC2B({
    required String amount,
    required String msisdn,
    required String shortcode,
    required String billRefNumber,
    String? commandId,
  }) async {
    _assertInitialized();
    final callable = _functions.httpsCallable('mpesaC2B');
    final result = await callable.call({
      'vendorId': _vendorId,
      'amount': amount,
      'msisdn': msisdn,
      'shortcode': shortcode,
      'billRefNumber': billRefNumber,
      if (commandId != null) 'commandId': commandId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Initiate a B2C transaction (withdrawal/disbursement).
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

    // If an HTTPS Function URL is provided, call it directly (works when you can only deploy
    // HTTP functions from the Google Cloud Console and not Firebase callable functions).
    if (EnvConfig.mpesaB2CInvokeUrl.isNotEmpty) {
      final resp = await http.post(
        Uri.parse(EnvConfig.mpesaB2CInvokeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vendorId': _vendorId,
          'amount': amount,
          'msisdn': msisdn,
          'remarks': remarks,
          if (commandId != null) 'commandId': commandId,
          if (occassion != null) 'occassion': occassion,
        }),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw StateError('mpesaB2C HTTP error ${resp.statusCode}: ${resp.body}');
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data;
    }

    // Default path: Firebase Callable Function
    final callable = _functions.httpsCallable('mpesaB2C');
    final result = await callable.call({
      'vendorId': _vendorId,
      'amount': amount,
      'msisdn': msisdn,
      'remarks': remarks,
      if (commandId != null) 'commandId': commandId,
      if (occassion != null) 'occassion': occassion,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// STK Push (Lipa Na M-Pesa)
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
    final callable = _functions.httpsCallable('mpesaStkPush');
    final result = await callable.call({
      'vendorId': _vendorId,
      'amount': amount,
      'phoneNumber': phoneNumber,
      'accountReference': accountReference,
      'transactionDesc': transactionDesc,
      // Server holds businessShortCode, passKey, callback URL securely
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  void _assertInitialized() {
    if (!_initialized || _vendorId == null) {
      throw StateError('MpesaService not initialized. Vendor context missing.');
    }
  }
}
