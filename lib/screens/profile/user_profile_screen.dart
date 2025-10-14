import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vendor.dart';
import '../../services/local_storage.dart';
import '../../services/firestore_paths.dart';
import 'profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Vendor? _vendor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      Vendor? v;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance.doc(FirestorePaths.vendorDoc(uid)).get();
        if (snap.exists) {
          v = Vendor.fromMap(snap.data()! as Map<String, dynamic>);
          await LocalStorageService.saveVendor(v);
        }
      }
      v ??= await LocalStorageService.getCurrentVendor();
      setState(() {
        _vendor = v;
        _loading = false;
      });
    } catch (_) {
      final cached = await LocalStorageService.getCurrentVendor();
      setState(() {
        _vendor = cached;
        _loading = false;
      });
    }
  }

  void _onEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    // Reload after returning from edit
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final v = _vendor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _onEdit,
          )
        ],
      ),
      body: v == null
          ? const Center(child: Text('No profile found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        backgroundImage: (v.profileImageUrl != null && v.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(v.profileImageUrl!)
                            : null,
                        child: (v.profileImageUrl == null || v.profileImageUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(v.email, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 6),
                                Flexible(child: Text(v.phone, style: Theme.of(context).textTheme.bodyMedium)),
                                const SizedBox(width: 8),
                                if (v.isPhoneVerified)
                                  Chip(
                                    label: const Text('Verified'),
                                    avatar: const Icon(Icons.verified, size: 16, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    labelStyle: const TextStyle(color: Colors.white),
                                    backgroundColor: Colors.green,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Business', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _kv(context, 'Type', v.businessTypeDisplayName),
                          const SizedBox(height: 8),
                          _kv(context, 'Name', v.businessName),
                          const SizedBox(height: 8),
                          _kv(context, 'Address', v.businessAddress),
                          if (v.businessDescription.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _kv(context, 'Description', v.businessDescription),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _kv(BuildContext context, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
