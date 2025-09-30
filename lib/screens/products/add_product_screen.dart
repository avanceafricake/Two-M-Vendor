import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/vendor.dart';
import '../../models/product.dart';
import '../../services/local_storage.dart';
import '../../services/repositories/product_repository.dart';
import '../../services/repositories/admin_notification_repository.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  
  Vendor? _vendor;
  String? _selectedCategory;
  List<String> _categories = [];
  bool _isLoading = false;
  bool _isAvailable = false; // new products start inactive, admin will activate
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Category-specific fields
  final _fashionSizesCtrl = TextEditingController();
  String _groceryUnit = 'kg';
  final _groceryWeightCtrl = TextEditingController();
  final _cosmeticsShadeCtrl = TextEditingController();
  bool _pharmacyRxRequired = false;
  String _pharmacyDosage = 'Tablets';
  final _foodPrepTimeCtrl = TextEditingController();

  // Selected images
  Uint8List? _coverImageBytes;
  String? _coverImageMime;
  final List<Uint8List> _galleryImageBytes = [];
  final List<String?> _galleryImageMimes = [];

  // Sample product images for different business types
  final Map<BusinessType, List<String>> _sampleImages = {
    BusinessType.store: [
      'https://pixabay.com/get/gc43d8b6fd78698f1e243af4cfa6aa0fb465086614c08f375eb5138a7578e9a0f7d7a78158f96ea4d865c409070e4583a55b926990b6e0d46cc7db9aa0b535bdc_1280.jpg',
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
    ],
    BusinessType.restaurant: [
      'https://pixabay.com/get/g3108610cea02ea7e39438d503d00dbe04b74c126441c8fc63efde172877f64dffe9769253998948755c2e12dce865c753f21e953d70cb90302d45482df22728b_1280.jpg',
      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b',
    ],
    BusinessType.pharmacy: [
      'https://pixabay.com/get/g38680d03c1204d047ecaad1bb3ac1ffe88b71e681924b2c1da1d0accafe695bfcd3191b8dcd5ca3c0e792a3fe3739fb609ee710d7c3013a04ac63023e9f6ae3b_1280.jpg',
      'https://images.unsplash.com/photo-1584017911766-d451b3d0e843',
      'https://images.unsplash.com/photo-1587854692152-cbe660dbde88',
    ],
  };


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _loadVendorData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _fashionSizesCtrl.dispose();
    _groceryWeightCtrl.dispose();
    _cosmeticsShadeCtrl.dispose();
    _foodPrepTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    try {
      final vendor = await LocalStorageService.getCurrentVendor();
      if (vendor != null) {
        setState(() {
          _vendor = vendor;
          _categories = Product.getCategoriesForCategoryKey(vendor.categoryKey);
          _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
        });
        _animationController.forward();
      }
    } catch (e) {
      // Handle error silently
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

  String _bytesToDataUrl(Uint8List bytes, String? mime) {
    final b64 = base64Encode(bytes);
    final m = mime ?? 'image/png';
    return 'data:$m;base64,$b64';
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.bytes != null) {
        setState(() {
          _coverImageBytes = file.bytes;
          _coverImageMime = _mimeFromExtension(file.extension);
        });
      }
    }
  }

  Future<void> _pickGalleryImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (file.bytes != null) {
            _galleryImageBytes.add(file.bytes!);
            _galleryImageMimes.add(_mimeFromExtension(file.extension));
          }
        }
      });
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      _galleryImageBytes.removeAt(index);
      _galleryImageMimes.removeAt(index);
    });
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate() || _vendor == null) return;

    setState(() => _isLoading = true);

    try {
      // Build image URLs from selected files (cover + gallery), fallback to a sample image
      final List<String> imageUrls = [];
      if (_coverImageBytes != null) {
        imageUrls.add(_bytesToDataUrl(_coverImageBytes!, _coverImageMime));
      }
      for (int i = 0; i < _galleryImageBytes.length; i++) {
        imageUrls.add(_bytesToDataUrl(_galleryImageBytes[i], _galleryImageMimes[i]));
      }

      if (imageUrls.isEmpty) {
        final images = _sampleImages[_vendor!.businessType] ?? [];
        if (images.isNotEmpty) {
          imageUrls.add(images[DateTime.now().millisecond % images.length]);
        }
      }

      final double price = double.parse(_priceController.text);
      final double? salePrice = _salePriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_salePriceController.text.trim());

      final attributes = <String, dynamic>{};
      final key = _vendor!.categoryKey;
      if (key == 'fashion') {
        attributes['sizes'] = _fashionSizesCtrl.text.trim();
      } else if (key == 'grocery') {
        attributes['unit'] = _groceryUnit;
        attributes['weightPerUnit'] = double.tryParse(_groceryWeightCtrl.text.trim()) ?? 0;
      } else if (key == 'cosmetics') {
        attributes['shade'] = _cosmeticsShadeCtrl.text.trim();
      } else if (key == 'pharmacy') {
        attributes['requiresPrescription'] = _pharmacyRxRequired;
        attributes['dosageForm'] = _pharmacyDosage;
      } else if (key == 'food') {
        attributes['prepTimeMin'] = int.tryParse(_foodPrepTimeCtrl.text.trim()) ?? 0;
      }

      final product = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: _descriptionController.text,
        price: price,
        salePrice: salePrice,
        category: _selectedCategory ?? 'General',
        vendorId: _vendor!.id,
        businessType: _vendor!.businessType,
        imageUrls: imageUrls,
        isAvailable: _isAvailable,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        createdAt: DateTime.now(),
        attributes: attributes.isEmpty ? null : attributes,
      );

      await LocalStorageService.saveProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_vendor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        centerTitle: true,
      ),
      body: ScaleTransition(
        scale: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Type Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getBusinessIcon(_vendor!.businessType),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adding to ${_vendor!.businessTypeDisplayName}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            _vendor!.businessName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Images Section
                _buildSectionTitle('Images', Icons.image_outlined),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Image
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 96,
                                height: 96,
                                color: Colors.grey.withValues(alpha: 0.15),
                                child: _coverImageBytes != null
                                    ? Image.memory(_coverImageBytes!, fit: BoxFit.cover)
                                    : Icon(Icons.photo, color: Colors.grey.withValues(alpha: 0.5)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cover Image',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This image is shown first for the product. Recommended: 800x800px or higher.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _pickCoverImage,
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text('Upload Cover'),
                                      ),
                                      if (_coverImageBytes != null)
                                        TextButton.icon(
                                          onPressed: () => setState(() => _coverImageBytes = null),
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          label: const Text('Remove', style: TextStyle(color: Colors.red)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        // Gallery
                        Text(
                          'Gallery Images',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add multiple images to showcase different angles or details.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...List.generate(_galleryImageBytes.length, (index) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _galleryImageBytes[index],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: InkWell(
                                      onTap: () => _removeGalleryImage(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                            OutlinedButton.icon(
                              onPressed: _pickGalleryImages,
                              icon: const Icon(Icons.collections),
                              label: const Text('Add to Gallery'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Basic Information
                _buildSectionTitle('Basic Information', Icons.info_outline),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name',
                            prefixIcon: const Icon(Icons.shopping_bag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            prefixIcon: const Icon(Icons.description_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter product description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Category-specific Details
                _buildSectionTitle('Category Details', Icons.tune),
                const SizedBox(height: 16),
                _buildCategoryDetailsCard(),

                const SizedBox(height: 24),

                // Pricing & Stock
                _buildSectionTitle('Pricing & Stock', Icons.monetization_on_outlined),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price (KES)',
                            prefixIcon: const Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter price';
                            }
                            final price = double.tryParse(value!);
                            if (price == null || price <= 0) {
                              return 'Please enter valid price';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _salePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Sale Price (optional, KES)',
                            prefixIcon: const Icon(Icons.local_offer_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText: 'If set, customers will see this discounted price',
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return null;
                            final sp = double.tryParse(text);
                            if (sp == null || sp <= 0) return 'Enter a valid sale price';
                            final p = double.tryParse(_priceController.text.trim());
                            if (p != null && sp > p) return 'Sale price must be <= Price';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Stock Quantity',
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText: 'Leave empty or 0 for unlimited stock',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Available for sale'),
                          subtitle: Text(_isAvailable ? 'Customers can order this product' : 'Product is currently unavailable'),
                          value: _isAvailable,
                          onChanged: (value) => setState(() => _isAvailable = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Add Product Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addProduct,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add),
                              const SizedBox(width: 8),
                              const Text('Add Product'),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Product Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Use clear, descriptive names\n• Write detailed descriptions\n• Set competitive prices\n• Keep stock levels updated',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBusinessIcon(BusinessType type) {
    switch (type) {
      case BusinessType.store:
        return Icons.store;
      case BusinessType.restaurant:
        return Icons.restaurant;
      case BusinessType.pharmacy:
        return Icons.local_pharmacy;
    }
  }

  Widget _buildCategoryDetailsCard() {
    final key = _vendor?.categoryKey;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (key == 'fashion') ...[
              TextFormField(
                controller: _fashionSizesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Available Sizes (e.g., S, M, L, XL)',
                  prefixIcon: Icon(Icons.checklist_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Comma-separated list of sizes',
                ),
              ),
            ] else if (key == 'grocery') ...[
              DropdownButtonFormField<String>(
                initialValue: _groceryUnit,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'piece', child: Text('piece')),
                  DropdownMenuItem(value: 'bundle', child: Text('bundle')),
                ],
                onChanged: (v) => setState(() => _groceryUnit = v ?? 'kg'),
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  prefixIcon: Icon(Icons.scale),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _groceryWeightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight per unit',
                  prefixIcon: Icon(Icons.balance_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (key == 'cosmetics') ...[
              TextFormField(
                controller: _cosmeticsShadeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Shade/Color',
                  prefixIcon: Icon(Icons.palette_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (key == 'pharmacy') ...[
              SwitchListTile(
                value: _pharmacyRxRequired,
                onChanged: (v) => setState(() => _pharmacyRxRequired = v),
                title: const Text('Requires prescription'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _pharmacyDosage,
                items: const [
                  DropdownMenuItem(value: 'Tablets', child: Text('Tablets')),
                  DropdownMenuItem(value: 'Capsules', child: Text('Capsules')),
                  DropdownMenuItem(value: 'Syrup', child: Text('Syrup')),
                  DropdownMenuItem(value: 'Cream', child: Text('Cream/Ointment')),
                ],
                onChanged: (v) => setState(() => _pharmacyDosage = v ?? 'Tablets'),
                decoration: const InputDecoration(
                  labelText: 'Dosage form',
                  prefixIcon: Icon(Icons.medication_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (key == 'food') ...[
              TextFormField(
                controller: _foodPrepTimeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preparation time (min)',
                  prefixIcon: Icon(Icons.timer_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              Text('No extra fields for this category', style: Theme.of(context).textTheme.bodySmall),
            ]
          ],
        ),
      ),
    );
  }
}