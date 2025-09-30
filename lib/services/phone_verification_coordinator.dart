import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vendor.dart';
import 'firestore_paths.dart';
import '../screens/auth/phone_verification_screen.dart';

/// Ensures only one Verify Phone bottom sheet is visible and schedules reminders.
class PhoneVerificationCoordinator {
  PhoneVerificationCoordinator._();
  static final PhoneVerificationCoordinator instance = PhoneVerificationCoordinator._();

  bool _isOpen = false;
  DateTime? _nextReminderAt;
  int _reminderStage = 0; // 0 = immediate, 1 = +10 min, 2 = +24h, 3+ = every 3 days

  bool get isOpen => _isOpen;

  /// Decide next reminder time based on the stage.
  DateTime _computeNextReminderFrom(DateTime base) {
    switch (_reminderStage) {
      case 0:
        _reminderStage = 1;
        return base.add(const Duration(minutes: 10));
      case 1:
        _reminderStage = 2;
        return base.add(const Duration(hours: 24));
      default:
        _reminderStage += 1;
        return base.add(const Duration(days: 3));
    }
  }

  /// Show the verify sheet once if vendor is not verified.
  /// Will not show if another sheet is already open.
  Future<void> maybePrompt(BuildContext context, Vendor vendor) async {
    if (_isOpen) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final vDoc = await FirebaseFirestore.instance.doc(FirestorePaths.vendorDoc(user.uid)).get();
    final data = vDoc.data() ?? {};
    final isVerified = (data['isPhoneVerified'] == true) || (user.phoneNumber != null && user.phoneNumber!.isNotEmpty);

    if (isVerified) return;

    final now = DateTime.now();
    if (_nextReminderAt != null && now.isBefore(_nextReminderAt!)) {
      return; // not time yet
    }

    _isOpen = true;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: PhoneVerificationSheet(prefillPhone: vendor.phone),
        ),
      );
    } catch (_) {
      // ignore
    } finally {
      _isOpen = false;
      _nextReminderAt = _computeNextReminderFrom(DateTime.now());
    }
  }
}
