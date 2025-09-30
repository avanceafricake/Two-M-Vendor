import 'package:flutter/material.dart';
import '../../models/vendor.dart';
import '../../services/local_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Vendor? _vendor;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await LocalStorageService.getCurrentVendor();
    setState(() {
      _vendor = v;
      _isOnline = v?.isOnline ?? true;
    });
  }

  Future<void> _save() async {
    final v = _vendor!;
    final updated = Vendor(
      id: v.id,
      name: v.name,
      email: v.email,
      phone: v.phone,
      businessType: v.businessType,
      businessName: v.businessName,
      businessAddress: v.businessAddress,
      businessDescription: v.businessDescription,
      profileImageUrl: v.profileImageUrl,
      businessImageUrl: v.businessImageUrl,
      locationLat: v.locationLat,
      locationLng: v.locationLng,
      isOnline: _isOnline,
      isPhoneVerified: v.isPhoneVerified,
      createdAt: v.createdAt,
    );
    await LocalStorageService.saveVendor(updated);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vendor == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Be online (Accept orders)'),
            subtitle: const Text('Toggle your availability'),
            value: _isOnline,
            onChanged: (v) => setState(() => _isOnline = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Changes'),
            ),
          )
        ],
      ),
    );
  }
}
