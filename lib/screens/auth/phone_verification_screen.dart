import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firestore_paths.dart';

/// Non-intrusive bottom sheet for verifying phone number (Kenya, +254).
class PhoneVerificationSheet extends StatefulWidget {
  final String? prefillPhone; // E.164 or local
  const PhoneVerificationSheet({super.key, this.prefillPhone});

  @override
  State<PhoneVerificationSheet> createState() => _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<PhoneVerificationSheet> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final _localPhoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _lastVerificationId;
  bool _sending = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    // Prefill local part from vendor phone or user phone
    final existing = widget.prefillPhone?.trim();
    final userPhone = _auth.currentUser?.phoneNumber;
    final seed = (existing?.isNotEmpty == true) ? existing : userPhone;
    if (seed != null && seed.isNotEmpty) {
      final local = _extractKeLocal(seed);
      _localPhoneCtrl.text = local;
    }
  }

  @override
  void dispose() {
    _localPhoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  // Convert any given phone to a Kenya local part (9 digits) if possible
  String _extractKeLocal(String phone) {
    var p = phone.trim();
    p = p.replaceAll(' ', '');
    p = p.replaceAll('-', '');
    if (p.startsWith('+254')) {
      p = p.substring(4);
    } else if (p.startsWith('254')) {
      p = p.substring(3);
    } else if (p.startsWith('0')) {
      p = p.substring(1);
    }
    p = _digitsOnly(p);
    if (p.length > 9) p = p.substring(p.length - 9);
    return p;
  }

  String _composeE164() {
    final local = _digitsOnly(_localPhoneCtrl.text);
    return '+254$local';
  }

  Future<void> _markVerified(String e164) async {
    final uid = _auth.currentUser!.uid;
    await _db.doc(FirestorePaths.vendorDoc(uid)).set({
      'isPhoneVerified': true,
      'phone': e164,
    }, SetOptions(merge: true));
    // Also keep wallet withdraw phone in sync
    await _db.doc('wallet/$uid').set({'withdrawPhone': e164}, SetOptions(merge: true));
  }

  Future<void> _sendCode() async {
    final local = _digitsOnly(_localPhoneCtrl.text);
    if (local.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid Kenyan number (9 digits)')));
      return;
    }
    final phone = _composeE164();

    // If already linked, just mark verified and close
    final already = _auth.currentUser?.phoneNumber;
    if (already != null && already.isNotEmpty) {
      await _markVerified(already);
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    setState(() => _sending = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          try {
            await _auth.currentUser!.linkWithCredential(credential);
            await _markVerified(phone);
            if (mounted) Navigator.of(context).maybePop();
          } catch (e) {
            // If provider already linked, mark verified
            if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
              await _markVerified(phone);
              if (mounted) Navigator.of(context).maybePop();
            }
          }
        },
        verificationFailed: (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
        },
        codeSent: (verificationId, resendToken) {
          _lastVerificationId = verificationId;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code sent')));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _lastVerificationId = verificationId;
        },
      );
    } catch (e) {
      // Handle edge cases where the phone is already in use
      if (e is FirebaseAuthException && (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked')) {
        await _markVerified(phone);
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _verifying = true);
    final phone = _composeE164();
    try {
      if (_lastVerificationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Send code first')));
        return;
      }
      final credential = PhoneAuthProvider.credential(verificationId: _lastVerificationId!, smsCode: code);
      await _auth.currentUser!.linkWithCredential(credential);
      await _markVerified(phone);
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      // If already linked, trust and mark verified
      if (e is FirebaseAuthException && (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked')) {
        await _markVerified(phone);
        if (mounted) Navigator.of(context).maybePop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with drag handle and close button
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Verify your phone', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                )
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Verify your mobile number to enable secure wallet withdrawals.')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Kenyan flag + +254 prefix + input
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.surface,
                  ),
                  child: Row(
                    children: const [
                      Text('🇰🇪', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Text('+254', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _localPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    decoration: const InputDecoration(
                      counterText: '',
                      labelText: 'Phone (9 digits)',
                      hintText: '7XXXXXXXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendCode,
                icon: const Icon(Icons.sms),
                label: Text(_sending ? 'Sending…' : 'Send Code'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SMS code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _verifying ? null : _verify,
                    child: Text(_verifying ? 'Verifying…' : 'Verify'),
                  ),
                )
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

/// Backward-compat screen wrapper (unused by StartupGate, kept for direct navigation if needed)
class PhoneVerificationScreen extends StatelessWidget {
  const PhoneVerificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: const PhoneVerificationSheet(),
    );
  }
}
