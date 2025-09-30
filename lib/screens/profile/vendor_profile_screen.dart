import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vendor.dart';
import '../../services/local_storage.dart';
import '../../services/firestore_paths.dart';
import 'vendor_profile_edit_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
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
          v = Vendor.fromMap(snap.data()!);
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

  Future<void> _goToEdit() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VendorProfileEditScreen()));
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
        title: const Text('Vendor Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _goToEdit,
          )
        ],
      ),
      body: v == null
          ? const Center(child: Text('No vendor profile found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 96,
                          height: 96,
                          color: Colors.grey.withValues(alpha: 0.15),
                          child: (v.businessImageUrl != null && v.businessImageUrl!.isNotEmpty)
                              ? Image.network(v.businessImageUrl!, fit: BoxFit.cover)
                              : Icon(Icons.store, color: Colors.grey.withValues(alpha: 0.6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.businessName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.category_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(v.businessTypeDisplayName),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16),
                                const SizedBox(width: 6),
                                Expanded(child: Text(v.businessAddress)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (v.businessDescription.isNotEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(v.businessDescription),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (v.locationLat != null && v.locationLng != null)
                            Text('Lat: ${v.locationLat?.toStringAsFixed(6)}, Lng: ${v.locationLng?.toStringAsFixed(6)}')
                          else
                            Text('Not set', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _goToEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Business Profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
