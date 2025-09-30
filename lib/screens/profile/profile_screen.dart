import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import '../../models/vendor.dart';
import '../../services/local_storage.dart';
import '../../services/repositories/vendor_repository.dart';
import '../../services/firestore_paths.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Vendor? _vendor;
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Phone handling
  String _countryISO = 'KE';
  String _dialCode = '+254';
  String _nationalNumber = '';

  bool _isLoading = false;
  bool _isPhoneVerified = false;

  double? _uploadProgress;

  Uint8List? _profileBytes;
  String? _profileMime;
  // Phone OTP state
  String? _verificationId;
  ConfirmationResult? _webConfirmation;
  RecaptchaVerifier? _recaptchaVerifier;
  bool _otpRequested = false;

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _db;
  late final FirebaseStorage _storage;
  late final VendorRepository _vendorRepo;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _db = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _vendorRepo = VendorRepository(_db);
    // Initial country from device locale if available
    final lc = WidgetsBinding.instance.platformDispatcher.locale;
    if ((lc.countryCode ?? '').isNotEmpty) {
      _countryISO = lc.countryCode!;
    }
    // KE default
    if (_countryISO.toUpperCase() == 'KE') {
      _dialCode = '+254';
    }
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser?.uid;
      Vendor? v;
      if (uid != null) {
        final snap = await _db.doc(FirestorePaths.vendorDoc(uid)).get();
        if (snap.exists) {
          v = Vendor.fromMap(snap.data()!);
          await LocalStorageService.saveVendor(v);
        }
      }
      v ??= await LocalStorageService.getCurrentVendor();
      // Prefill
      _vendor = v;
      _nameController.text = v?.name ?? '';
      _isPhoneVerified = v?.isPhoneVerified ?? false;
      final saved = v?.phone ?? '';
      // Basic parsing: if +254..., set KE and strip 254
      if (saved.startsWith('+254')) {
        _countryISO = 'KE';
        _dialCode = '+254';
        _nationalNumber = saved.replaceFirst('+254', '');
      } else if (saved.startsWith('+')) {
        // Fallback: keep full string but try to split on first space or assume user will re-enter
        // We'll show the full number as national part so they can edit.
        _nationalNumber = saved.replaceFirst('+', '');
      } else {
        _nationalNumber = saved;
      }
      // Sanitize for current country (strip trunk 0 for KE)
      _nationalNumber = _sanitizeNational(_nationalNumber);
      _phoneController.text = _nationalNumber;
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<String?> _uploadProfileImageIfNeeded(String vendorId) async {
    if (_profileBytes == null) return null;
    final String ext = (_profileMime == 'image/jpeg')
        ? 'jpg'
        : (_profileMime == 'image/gif')
            ? 'gif'
            : (_profileMime == 'image/webp')
                ? 'webp'
                : 'png';
    final path = 'users/$vendorId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref(path);
    StreamSubscription<TaskSnapshot>? sub;
    try {
      // Debug: log path and uid for rules diagnosis
      final uid = _auth.currentUser?.uid;
      // ignore: avoid_print
      print('[Storage] Upload profile -> path=$path uid=$uid vendorId=$vendorId');

      UploadTask task;
      // Use putData on all platforms to avoid potential web hangs with data URLs
      final mime = _profileMime ?? 'image/png';
      task = ref.putData(
        _profileBytes!,
        SettableMetadata(contentType: mime),
      );

      // Progress updates with detailed logging
      sub = task.snapshotEvents.listen((snap) {
        if (!mounted) return;
        final total = snap.totalBytes == 0 ? 1 : snap.totalBytes;
        final prog = snap.bytesTransferred / total;
        // ignore: avoid_print
        print('[Storage] profile state=${snap.state} transferred=${snap.bytesTransferred} total=${snap.totalBytes}');
        setState(() => _uploadProgress = prog);
      }, onError: (err) {
        // ignore: avoid_print
        print('[Storage] profile snapshot error: $err');
      });

      // Wait for completion with generous timeout for web
      await task.whenComplete(() {}).timeout(const Duration(minutes: 2), onTimeout: () {
        // ignore: avoid_print
        print('[Storage] Upload profile TIMEOUT after 120s for path=$path');
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
      print('[Storage] Upload profile SUCCESS -> $url');
      return url;
    } catch (e) {
      // ignore: avoid_print
      print('[Storage] Upload profile FAILED: $e');
      rethrow;
    } finally {
      await sub?.cancel();
      if (mounted) setState(() => _uploadProgress = null);
    }
  }


  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.bytes != null) {
        setState(() {
          _profileBytes = file.bytes;
          _profileMime = _mimeFromExtension(file.extension);
        });
      }
    }
  }

  String get _e164 {
      final dial = _dialCode.isNotEmpty ? _dialCode : '';
      // Ensure we drop any trunk leading zeros before saving, e.g., 0729 -> 729
      final digitsOnly = _nationalNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final noTrunkZero = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
      return '$dial$noTrunkZero';
    }

  String _sanitizeNational(String input) {
    String n = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (_countryISO.toUpperCase() == 'KE') {
      // Remove trunk leading zeros and limit to 9 digits
      n = n.replaceFirst(RegExp(r'^0+'), '');
      if (n.length > 9) n = n.substring(0, 9);
    }
    return n;
  }

  List<TextInputFormatter> _phoneInputFormatters() {
    final isKE = _countryISO.toUpperCase() == 'KE';
    final max = isKE ? 9 : 15;
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(max),
    ];
  }

  Future<void> _onPhoneVerifiedPersist() async {
    final v = _vendor!;
    final updated = Vendor(
      id: v.id,
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : v.name,
      email: v.email,
      phone: _e164,
      businessType: v.businessType,
      businessName: v.businessName,
      businessAddress: v.businessAddress,
      businessDescription: v.businessDescription,
      profileImageUrl: v.profileImageUrl,
      businessImageUrl: v.businessImageUrl,
      locationLat: v.locationLat,
      locationLng: v.locationLng,
      isOnline: v.isOnline,
      isPhoneVerified: true,
      createdAt: v.createdAt,
    );
    await _vendorRepo.upsert(updated);
    await LocalStorageService.saveVendor(updated);
    setState(() {
      _vendor = updated;
      _isPhoneVerified = true;
    });
  }

  Future<void> _sendOtp() async {
    if (_vendor == null) return;
    if (_e164.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid phone number')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'not-authenticated',
            message: 'You need to be logged in to verify your phone');
      }
      if (kIsWeb) {
        _recaptchaVerifier ??= RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha-container',
          size: RecaptchaVerifierSize.compact,
          theme: RecaptchaVerifierTheme.light,
        );
        _webConfirmation =
            await user.linkWithPhoneNumber(_e164, _recaptchaVerifier);
        _otpRequested = true;
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('OTP sent to $_e164')));
        }
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: _e164,
          verificationCompleted: (PhoneAuthCredential credential) async {
            try {
              // Try linking first; if already linked, update
              try {
                await user.linkWithCredential(credential);
              } on FirebaseAuthException catch (e) {
                if (e.code == 'provider-already-linked' ||
                    e.code == 'credential-already-in-use') {
                  await user.updatePhoneNumber(credential);
                } else {
                  rethrow;
                }
              }
              await _onPhoneVerifiedPersist();
            } catch (e) {
              // Ignore auto-complete failures; user can manually enter code
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Verification failed: ${e.message}'),
                backgroundColor: Colors.red));
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            _otpRequested = true;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('OTP sent to $_e164')));
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send OTP: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_vendor == null) return;
    final code = _otpController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter the SMS code')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'not-authenticated',
            message: 'You need to be logged in to verify your phone');
      }
      if (kIsWeb) {
        if (_webConfirmation == null) {
          throw FirebaseAuthException(
              code: 'no-verification', message: 'Please request OTP first');
        }
        await _webConfirmation!.confirm(code);
      } else {
        if (_verificationId == null) {
          throw FirebaseAuthException(
              code: 'no-verification', message: 'Please request OTP first');
        }
        final credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!, smsCode: code);
        try {
          await user.linkWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'provider-already-linked' ||
              e.code == 'credential-already-in-use') {
            await user.updatePhoneNumber(credential);
          } else {
            rethrow;
          }
        }
      }
      await _onPhoneVerifiedPersist();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Phone verified')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_vendor == null) return;
    setState(() => _isLoading = true);
    try {
      // ignore: avoid_print
      print('[Profile] Save started');
      final v = _vendor!;
      final uid = v.id;
      String? newPhotoUrl;
      try {
        newPhotoUrl = await _uploadProfileImageIfNeeded(uid);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Photo upload failed: $e'),
                backgroundColor: Colors.orange),
          );
        }
      }

      final updated = Vendor(
        id: uid,
        name: _nameController.text.trim().isEmpty
            ? v.name
            : _nameController.text.trim(),
        email: v.email,
        phone: _e164,
        businessType: v.businessType,
        businessName: v.businessName,
        businessAddress: v.businessAddress,
        businessDescription: v.businessDescription,
        profileImageUrl: newPhotoUrl ?? v.profileImageUrl,
        businessImageUrl: v.businessImageUrl,
        locationLat: v.locationLat,
        locationLng: v.locationLng,
        isOnline: v.isOnline,
        isPhoneVerified: _isPhoneVerified,
        createdAt: v.createdAt,
      );

      bool saved = false;
      try {
        await _vendorRepo
            .upsert(updated)
            .timeout(const Duration(seconds: 20), onTimeout: () {
          // ignore: avoid_print
          print('[Profile] Firestore upsert TIMEOUT');
          throw TimeoutException('Save timed out');
        });
        await LocalStorageService.saveVendor(updated);
        saved = true;
      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Save failed: ${e.message}'),
              backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Save failed: $e'),
              backgroundColor: Colors.red));
        }
      }

      if (saved && mounted) {
        setState(() {
          _vendor = updated;
          if (newPhotoUrl != null) {
            _profileBytes = null;
            _profileMime = null;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Profile saved')));
        }
      }
    } finally {
      // ignore: avoid_print
      print('[Profile] Save finished');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vendor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  backgroundImage: _profileBytes != null
                      ? MemoryImage(_profileBytes!)
                      : (_vendor!.profileImageUrl != null &&
                              _vendor!.profileImageUrl!.isNotEmpty)
                          ? NetworkImage(_vendor!.profileImageUrl!)
                              as ImageProvider
                          : null,
                  child: (_vendor!.profileImageUrl == null &&
                          _profileBytes == null)
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickProfileImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Photo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            IntlPhoneField(
              initialCountryCode: _countryISO,
              showCountryFlag: false,
              flagsButtonPadding: const EdgeInsets.only(left: 12),
              // Hide length counter to avoid confusion (library may set 10 for KE, while we use 9)
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              controller: _phoneController,
              inputFormatters: _phoneInputFormatters(),
              // Disable package length check and manage validation/length ourselves
              disableLengthCheck: true,
              onCountryChanged: (country) {
                setState(() {
                  _countryISO = country.code;
                  _dialCode = '+${country.dialCode}';
                  _nationalNumber = _sanitizeNational(_phoneController.text);
                  _phoneController
                    ..text = _nationalNumber
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: _nationalNumber.length),
                    );
                });
              },
              onChanged: (phone) {
                final sanitized = _sanitizeNational(phone.number);
                if (sanitized != phone.number) {
                  _phoneController
                    ..text = sanitized
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: sanitized.length),
                    );
                }
                setState(() {
                  _dialCode = phone.countryCode;
                  _nationalNumber = sanitized;
                });
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: (_uploadProgress != null)
                    ? Text('Uploading ${(100 * (_uploadProgress ?? 0)).toStringAsFixed(0)}%...')
                    : (_isLoading
                        ? const Text('Saving...')
                        : const Text('Save Changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
