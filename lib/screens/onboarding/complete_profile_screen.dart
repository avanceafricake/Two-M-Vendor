import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/vendor.dart';
import '../home/dashboard_screen.dart';
import '../../services/local_storage.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  Vendor? _vendor;
  Uint8List? _profileBytes;
  String? _profileMime;
  Uint8List? _bizBytes;
  String? _bizMime;
  double? _lat;
  double? _lng;
  bool _isPhoneVerified = false;
  bool _loading = false;
  String? _otpSent;
  final _otpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final v = await LocalStorageService.getCurrentVendor();
    setState(() {
      _vendor = v;
      _lat = v?.locationLat;
      _lng = v?.locationLng;
      _isPhoneVerified = v?.isPhoneVerified ?? false;
    });
  }

  String _mimeFromExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  String _bytesToDataUrl(Uint8List bytes, String? mime) {
    final b64 = base64Encode(bytes);
    final m = mime ?? 'image/png';
    return 'data:$m;base64,$b64';
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.single;
      if (f.bytes != null) {
        setState(() {
          _profileBytes = f.bytes;
          _profileMime = _mimeFromExtension(f.extension);
        });
      }
    }
  }

  Future<void> _pickBusinessImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.single;
      if (f.bytes != null) {
        setState(() {
          _bizBytes = f.bytes;
          _bizMime = _mimeFromExtension(f.extension);
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _otpSent = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP sent to ${_vendor?.phone}: $_otpSent')));
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim() == _otpSent) {
      setState(() => _isPhoneVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone verified')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP'), backgroundColor: Colors.red));
    }
  }

  Future<void> _finish() async {
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
      profileImageUrl: _profileBytes != null ? _bytesToDataUrl(_profileBytes!, _profileMime) : v.profileImageUrl,
      businessImageUrl: _bizBytes != null ? _bytesToDataUrl(_bizBytes!, _bizMime) : v.businessImageUrl,
      locationLat: _lat ?? v.locationLat,
      locationLng: _lng ?? v.locationLng,
      isOnline: v.isOnline,
      isPhoneVerified: _isPhoneVerified,
      createdAt: v.createdAt,
    );
    await LocalStorageService.saveVendor(updated);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vendor == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.checklist, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Add your images, confirm your location, and verify your phone to start receiving orders.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Profile Photo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  backgroundImage: _profileBytes != null ? MemoryImage(_profileBytes!) : null,
                  child: _profileBytes == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(onPressed: _pickProfileImage, icon: const Icon(Icons.upload_file), label: const Text('Upload'))
              ],
            ),
            const SizedBox(height: 16),
            Text('Business Image', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey.withValues(alpha: 0.2),
                    child: _bizBytes != null ? Image.memory(_bizBytes!, fit: BoxFit.cover) : const Icon(Icons.store),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(onPressed: _pickBusinessImage, icon: const Icon(Icons.upload_file), label: const Text('Upload'))
              ],
            ),
            const SizedBox(height: 16),
            Text('Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _lat?.toStringAsFixed(6) ?? ''),
                    decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    onChanged: (v) => _lat = double.tryParse(v) ?? _lat,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _lng?.toStringAsFixed(6) ?? ''),
                    decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    onChanged: (v) => _lng = double.tryParse(v) ?? _lng,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use GPS'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text('Phone Verification', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _sendOtp,
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('Send OTP'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Enter OTP', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _isPhoneVerified ? null : _verifyOtp, child: const Text('Verify'))
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _finish,
                icon: const Icon(Icons.check_circle),
                label: const Text('Finish Setup'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
