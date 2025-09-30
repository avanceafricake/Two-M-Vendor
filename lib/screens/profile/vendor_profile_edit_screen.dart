import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/vendor.dart';
import '../../services/local_storage.dart';
import '../../services/repositories/vendor_repository.dart';

class VendorProfileEditScreen extends StatefulWidget {
  const VendorProfileEditScreen({super.key});

  @override
  State<VendorProfileEditScreen> createState() => _VendorProfileEditScreenState();
}

class _VendorProfileEditScreenState extends State<VendorProfileEditScreen> {
  Vendor? _vendor;
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  double? _lat;
  double? _lng;

  Uint8List? _bizBytes;
  String? _bizMime;
  bool _isLoading = false;
  double? _uploadProgress;

  late final VendorRepository _vendorRepo;
  late final FirebaseStorage _storage;

  @override
  void initState() {
    super.initState();
    _vendorRepo = VendorRepository(FirebaseFirestore.instance);
    _storage = FirebaseStorage.instance;
    _load();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final v = await LocalStorageService.getCurrentVendor();
    setState(() {
      _vendor = v;
      _businessNameController.text = v?.businessName ?? '';
      _businessAddressController.text = v?.businessAddress ?? '';
      _businessDescriptionController.text = v?.businessDescription ?? '';
      _lat = v?.locationLat;
      _lng = v?.locationLng;
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

  Future<String?> _uploadBusinessImageIfNeeded(String vendorId) async {
    if (_bizBytes == null) return null;
    final String ext = (_bizMime == 'image/jpeg')
        ? 'jpg'
        : (_bizMime == 'image/gif')
            ? 'gif'
            : (_bizMime == 'image/webp')
                ? 'webp'
                : 'png';
    final path = 'users/$vendorId/business_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref(path);
    StreamSubscription<TaskSnapshot>? sub;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // ignore: avoid_print
      print('[Storage] Upload business -> path=$path uid=$uid vendorId=$vendorId');

      UploadTask task;
      // Use putData on all platforms to avoid potential web hangs with data URLs
      final mime = _bizMime ?? 'image/png';
      task = ref.putData(
        _bizBytes!,
        SettableMetadata(contentType: mime),
      );

      // Progress updates
      sub = task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        final total = snap.totalBytes == 0 ? 1 : snap.totalBytes;
        final prog = snap.bytesTransferred / total;
        // ignore: avoid_print
        print('[Storage] business state=${snap.state} transferred=${snap.bytesTransferred} total=${snap.totalBytes}');
        setState(() => _uploadProgress = prog);
      }, onError: (err) {
        // ignore: avoid_print
        print('[Storage] business snapshot error: $err');
      });

      // Wait for completion with generous timeout for web
      await task.whenComplete(() {}).timeout(const Duration(minutes: 2), onTimeout: () {
        // ignore: avoid_print
        print('[Storage] Upload business TIMEOUT after 120s for path=$path');
        throw TimeoutException('Upload timed out');
      });

      final url = await ref
          .getDownloadURL()
          .timeout(const Duration(seconds: 60), onTimeout: () {
        // ignore: avoid_print
        print('[Storage] getDownloadURL TIMEOUT for path=$path');
        throw TimeoutException('getDownloadURL timed out');
      });

      // ignore: avoid_print
      print('[Storage] Upload business SUCCESS -> $url');
      return url;
    } catch (e) {
      // ignore: avoid_print
      print('[Storage] Upload business FAILED: $e');
      rethrow;
    } finally {
      await sub?.cancel();
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_vendor == null) return;
    setState(() => _isLoading = true);
    try {
      // ignore: avoid_print
      print('[VendorProfile] Save started');
      final v = _vendor!;
      String? newBizPhotoUrl;
      try {
        newBizPhotoUrl = await _uploadBusinessImageIfNeeded(v.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Business image upload failed: $e'), backgroundColor: Colors.orange),
          );
        }
      }

      final updated = Vendor(
        id: v.id,
        name: v.name,
        email: v.email,
        phone: v.phone,
        businessType: v.businessType,
        businessName: _businessNameController.text.trim().isNotEmpty ? _businessNameController.text.trim() : v.businessName,
        businessAddress: _businessAddressController.text.trim().isNotEmpty ? _businessAddressController.text.trim() : v.businessAddress,
        businessDescription: _businessDescriptionController.text.trim().isNotEmpty ? _businessDescriptionController.text.trim() : v.businessDescription,
        profileImageUrl: v.profileImageUrl,
        businessImageUrl: newBizPhotoUrl ?? v.businessImageUrl,
        locationLat: _lat ?? v.locationLat,
        locationLng: _lng ?? v.locationLng,
        isOnline: v.isOnline,
        isPhoneVerified: v.isPhoneVerified,
        createdAt: v.createdAt,
      );

      bool saved = false;
      try {
        await _vendorRepo
            .upsert(updated)
            .timeout(const Duration(seconds: 20), onTimeout: () {
          // ignore: avoid_print
          print('[VendorProfile] Firestore upsert TIMEOUT');
          throw TimeoutException('Save timed out');
        });
        await LocalStorageService.saveVendor(updated);
        saved = true;
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Save failed: ${e.message}'), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Save failed: $e'), backgroundColor: Colors.red));
        }
      }

      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor profile saved')));
        Navigator.of(context).pop(true);
      }
    } finally {
      // ignore: avoid_print
      print('[VendorProfile] Save finished');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vendor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hasBizImage = (_vendor!.businessImageUrl != null && _vendor!.businessImageUrl!.isNotEmpty) || _bizBytes != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Vendor Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 96,
                    height: 96,
                    color: Colors.grey.withValues(alpha: 0.15),
                    child: hasBizImage
                        ? (_bizBytes != null
                            ? Image.memory(_bizBytes!, fit: BoxFit.cover)
                            : Image.network(_vendor!.businessImageUrl!, fit: BoxFit.cover))
                        : Icon(Icons.store, color: Colors.grey.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickBusinessImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Business Image'),
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _businessAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _businessDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Business Description',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _lat?.toStringAsFixed(6) ?? ''),
                    readOnly: false,
                    decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    onChanged: (v) => _lat = double.tryParse(v) ?? _lat,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _lng?.toStringAsFixed(6) ?? ''),
                    readOnly: false,
                    decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    onChanged: (v) => _lng = double.tryParse(v) ?? _lng,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                ),
                const SizedBox(width: 12),
                if (_lat != null && _lng != null)
                  Text('(${_lat?.toStringAsFixed(5)}, ${_lng?.toStringAsFixed(5)})', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: (_uploadProgress != null)
                    ? Text('Uploading ${(100 * (_uploadProgress ?? 0)).toStringAsFixed(0)}%...')
                    : (_isLoading ? const Text('Saving...') : const Text('Save Changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
