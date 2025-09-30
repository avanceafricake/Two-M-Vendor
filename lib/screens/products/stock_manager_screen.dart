import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/vendor.dart';
import '../../services/local_storage.dart';
import '../../services/service_locator.dart';
import 'add_product_screen.dart';

class StockManagerScreen extends StatefulWidget {
  const StockManagerScreen({super.key});

  @override
  State<StockManagerScreen> createState() => _StockManagerScreenState();
}

class _StockManagerScreenState extends State<StockManagerScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  Vendor? _vendor;
  bool _loading = true;
  String _query = '';
  Stream<List<Product>>? _productStream;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Prefer Firestore live data when authenticated
    try {
      final locator = ServiceLocator();
      if (locator.isAuthenticated) {
        _productStream = locator.watchVendorProducts().map((list) => list.cast<Product>());
      }
    } catch (_) {}

    final vendor = await LocalStorageService.getCurrentVendor();
    List<Product> products;
    if (_productStream == null) {
      // Fallback to local
      products = vendor == null
          ? await LocalStorageService.getProducts()
          : await LocalStorageService.getProductsByVendor(vendor.id);
    } else {
      products = [];
    }
    setState(() {
      _vendor = vendor;
      _products = products..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      if (_query.isEmpty) {
        _filtered = _products;
      } else {
        final q = _query.toLowerCase();
        _filtered = _products
            .where((p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  Future<void> _toggleAvailability(Product p, bool value) async {
    try {
      await ServiceLocator().productRepository.updateAvailability(p.id, value);
    } catch (_) {
      // Fallback to local cache if offline
      final updated = Product(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        category: p.category,
        vendorId: p.vendorId,
        businessType: p.businessType,
        imageUrls: p.imageUrls,
        isAvailable: value,
        stockQuantity: p.stockQuantity,
        createdAt: p.createdAt,
      );
      await LocalStorageService.saveProduct(updated);
      await _load();
    }
  }

  Future<void> _changeStock(Product p, int delta) async {
    final newQty = (p.stockQuantity + delta).clamp(0, 1000000);
    try {
      await ServiceLocator().productRepository.updateStock(p.id, newQty);
    } catch (_) {
      final updated = Product(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.price,
        category: p.category,
        vendorId: p.vendorId,
        businessType: p.businessType,
        imageUrls: p.imageUrls,
        isAvailable: p.isAvailable,
        stockQuantity: newQty,
        createdAt: p.createdAt,
      );
      await LocalStorageService.saveProduct(updated);
      await _load();
    }
  }

  Widget _buildProductTile(Product p) {
    final image = p.imageUrls.isNotEmpty ? p.imageUrls.first : null;

    Widget priceChip(BuildContext context) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'KES ${p.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    Widget stockChip() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Stock: ${p.stockQuantity}',
            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600),
          ),
        );

    Widget actionsRow() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Decrease',
              onPressed: () => _changeStock(p, -1),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
            ),
            IconButton(
              tooltip: 'Increase',
              onPressed: () => _changeStock(p, 1),
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image != null && !image.startsWith('data:')
                  ? Image.network(
                      image,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Switch(
                        value: p.isAvailable,
                        onChanged: (v) => _toggleAvailability(p, v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;
                      if (isNarrow) {
                        // Stack chips and actions vertically to prevent overflow on narrow screens
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                priceChip(context),
                                stockChip(),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: actionsRow(),
                            ),
                          ],
                        );
                      }
                      // Wide layout: chips and actions in one row with spacer
                      return Row(
                        children: [
                          Flexible(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                priceChip(context),
                                stockChip(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          actionsRow(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image, color: Colors.grey.withValues(alpha: 0.6)),
    );
  }

  Widget _buildListViewFor(List<Product> items) {
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? items
        : items.where((p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q)).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          onChanged: (v) {
            setState(() => _query = v);
          },
          decoration: const InputDecoration(
            labelText: 'Search products',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.6)),
                const SizedBox(height: 8),
                const Text('No products found'),
                const SizedBox(height: 4),
                const Text('Use the + button to add your first product', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ...filtered.map(_buildProductTile),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Manager'),
        actions: [
          IconButton(
            tooltip: 'Add Product',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _productStream != null
            ? StreamBuilder<List<Product>>(
                stream: _productStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Can\'t load products: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final live = (snapshot.data ?? [])..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  return _buildListViewFor(live);
                },
              )
            : _buildListViewFor(_filtered),
      ),
    );
  }
}
