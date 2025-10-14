import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_paths.dart';
import '../../models/vendor.dart';

import 'phone_verification_screen.dart';
import '../home/root_nav_shell.dart';
import '../../services/phone_verification_coordinator.dart';
import '../../services/firestore_bootstrap.dart';
import 'pending_approval_screen.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _bootstrapped = false;

  Future<void> _ensureBootstrap(Vendor vendor) async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirestoreBootstrap.ensureMinimalCollections(uid: uid, vendor: vendor);
  }

  void _maybeShowVerifySheet(Vendor vendor) {
    // Delegate to coordinator to avoid multiple sheets and to schedule reminders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PhoneVerificationCoordinator.instance.maybePrompt(context, vendor);
    });
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.doc(FirestorePaths.vendorDoc(user.uid)).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.data!.exists) {
          // Minimal guard – if vendor doc missing
          return const RootNavShell();
        }
        final vendor = Vendor.fromMap(snapshot.data!.data()! as Map<String, dynamic>);

        // Bootstrap minimal collections once per app run
        _ensureBootstrap(vendor);

        // Onboarding screen removed; category is chosen during registration.

        // 2) Pending approval: allow app to load; Dashboard will overlay a grey 'Waiting approval' screen
        // if (vendor.status != VendorStatus.approved) {
        //   return const PendingApprovalScreen();
        // }

        // 3) Show non-intrusive verify phone sheet if needed (coordinator limits to one and schedules reminders)
        _maybeShowVerifySheet(vendor);

        // 4) Render the main app shell
        return const RootNavShell();
      },
    );
  }
}
