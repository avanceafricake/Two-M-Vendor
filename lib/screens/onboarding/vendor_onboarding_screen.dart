import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/vendor.dart';
import '../../services/firestore_paths.dart';
import '../../utils/category_theme.dart';

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? _selectedCategory; // fashion, food, cosmetics, pharmacy
  bool _saving = false;

  final List<_OnboardCard> _cards = [
    _OnboardCard(
      keyName: CategoryTheme.fashion,
      title: 'Fashion Stores • Kisumu',
      subtitle: 'Clothing, shoes & accessories. Create shoppable catalogs with variants.',
      imageUrl: 'https://pixabay.com/get/g70e58ec5fb96ab91ae152e994293d6c887106975c066460e0fb0dfacfb76b8389977d3efa4ffc25bd59ea27065c7db9f3f55bfb0150a839ad945268afe6e3416_1280.jpg',
    ),
    _OnboardCard(
      keyName: CategoryTheme.food,
      title: 'Restaurants • Kisumu',
      subtitle: 'Menu items, add-ons, and order preparation tracking for delivery & pickup.',
      imageUrl: 'https://pixabay.com/get/ge277e6a4a9d4c668a6c7cdd89fd3a0fb2d554c10e48a09e97deb6ce4d168eee8b75576b1d27f866a3552068c5021d10ed6f01c081477b166e16fb98078089220_1280.jpg',
    ),
    _OnboardCard(
      keyName: CategoryTheme.cosmetics,
      title: 'Cosmetics • Kisumu',
      subtitle: 'Beauty and skincare. Showcase bundles and promotions elegantly.',
      imageUrl: 'https://pixabay.com/get/ge50c567b4b3970f9ed0d4692f1d0db0283ac116e13c92189be7fcab38172e5ee7243bbc17a5b740d9e609c12f0dfb1eaae229b9378ae0ccdcac3670edf3f115b_1280.jpg',
    ),
    _OnboardCard(
      keyName: CategoryTheme.grocery,
      title: 'Grocery • Kisumu',
      subtitle: 'Fresh produce and daily essentials with inventory-friendly tools.',
      imageUrl: 'https://pixabay.com/get/g8b13b9b8bf3a2b0a66f9eec6b1a7d7b9b0f9a8f30f1a0f4d2f5c23fb8d2c6e9c0f77a3c1a7193f075206b6260594f6b85a9ad09498e5480b78f0ec209ca4d6c6_1280.jpg',
    ),
    _OnboardCard(
      keyName: CategoryTheme.pharmacy,
      title: 'Pharmacy / Health • Kisumu',
      subtitle: 'Health products and prescriptions with careful order status flow.',
      imageUrl: 'https://pixabay.com/get/g111b773208cc5696ee1d75fb779fe296771bfa77a51a86ce3935285407fa8a257edf6038a6b093b393d5cc2e41c9e956fbb9a8d41c8d549c676e4ac5b1d0530b_1280.jpg',
    ),
  ];

  Future<void> _complete() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a vendor category to continue')),
      );
      return;
    }
    final uid = _auth.currentUser!.uid;
    setState(() => _saving = true);
    try {
      await _db.doc(FirestorePaths.vendorDoc(uid)).set({
        'onboarded': true,
        'categoryKey': _selectedCategory,
      }, SetOptions(merge: true));
      if (mounted) Navigator.of(context).pop(); // Return to gate to continue
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get Started')),
      body: PageView(
        children: _cards.map((c) => _OnboardPage(
          data: c,
          selected: _selectedCategory == c.keyName,
          onSelect: () => setState(() => _selectedCategory = c.keyName),
        )).toList(),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _saving ? null : _complete,
            icon: const Icon(Icons.check_circle),
            label: Text(_saving ? 'Saving…' : 'Use this setup'),
          ),
        ),
      ),
    );
  }
}

class _OnboardCard {
  final String keyName;
  final String title;
  final String subtitle;
  final String imageUrl;
  const _OnboardCard({required this.keyName, required this.title, required this.subtitle, required this.imageUrl});
}

class _OnboardPage extends StatelessWidget {
  final _OnboardCard data;
  final bool selected;
  final VoidCallback onSelect;
  const _OnboardPage({required this.data, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bg = CategoryTheme.bg(data.keyName);
    final ac = CategoryTheme.ac(data.keyName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(data.imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(data.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: ac)),
          const SizedBox(height: 8),
          Text(data.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? ac : Colors.grey.withValues(alpha: 0.3), width: selected ? 2 : 1),
                color: selected ? ac.withValues(alpha: 0.08) : null,
              ),
              child: Row(
                children: [
                  Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: selected ? ac : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Choose ${data.keyName[0].toUpperCase()}${data.keyName.substring(1)} theme')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
