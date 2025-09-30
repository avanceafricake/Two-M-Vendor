import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/vendor.dart';
import '../../services/local_storage.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_drawer.dart';

class OrdersScreen extends StatefulWidget {
  final OrderStatus? initialStatus;
  const OrdersScreen({super.key, this.initialStatus});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  OrderStatus? _selectedStatus;
  late AnimationController _animationController;
  Stream<List<Order>>? _ordersStream;

  int _countForStatus(OrderStatus status) =>
      _orders.where((o) => o.status == status).length;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final locator = ServiceLocator();
      if (locator.isAuthenticated) {
        _ordersStream = locator.watchVendorOrders().map((e) => e.cast<Order>());
      }
      if (widget.initialStatus != null) {
        _filterOrders(widget.initialStatus);
      }
      setState(() => _isLoading = false);
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterOrders(OrderStatus? status) {
    setState(() {
      _selectedStatus = status;
      if (status == null) {
        _filteredOrders = _orders;
      } else {
        _filteredOrders =
            _orders.where((order) => order.status == status).toList();
      }
    });
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      await ServiceLocator().orderRepository.updateStatus(
        vendorId: order.vendorId,
        orderId: order.id,
        nextStatus: newStatus,
      );
    } catch (e) {
      // fallback to local cache
      final updatedOrder = Order(
        id: order.id,
        customerId: order.customerId,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        deliveryAddress: order.deliveryAddress,
        items: order.items,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        total: order.total,
        status: newStatus,
        vendorId: order.vendorId,
        businessType: order.businessType,
        createdAt: order.createdAt,
        updatedAt: DateTime.now(),
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
      );
      await LocalStorageService.saveOrder(updatedOrder);
      await _loadOrders();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
    }
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

  Widget _buildChoiceChip(String label, OrderStatus? status) {
    final bool isSelected =
        status == null ? _selectedStatus == null : _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _filterOrders(status),
      backgroundColor: Colors.grey.withValues(alpha: 0.1),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getBusinessIcon(order.businessType),
                    color: _getStatusColor(order.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.statusDisplayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _getStatusColor(order.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.customerName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        order.customerName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(order.createdAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Items (${order.itemsCount}):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      if (item.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item.imageUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 32,
                              height: 32,
                              color: Colors.grey.withValues(alpha: 0.2),
                              child: Icon(Icons.image, size: 16),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.shopping_bag, size: 16),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            Text(
                              '${item.quantity} x KES ${item.price.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'KES ${item.total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: KES ${order.total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Payment: ${order.paymentMethodDisplayName} • ${order.paymentStatusDisplayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    Text(
                      _formatDateTime(order.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                if (order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled)
                  PopupMenuButton<OrderStatus>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (status) => _updateOrderStatus(order, status),
                    itemBuilder: (context) => [
                      if (order.status == OrderStatus.pending) ...[
                        PopupMenuItem(
                          value: OrderStatus.confirmed,
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              const Text('Confirm'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: OrderStatus.ready,
                          child: Row(
                            children: [
                              Icon(Icons.done_all,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              const Text('Mark Ready for Pickup'),
                            ],
                          ),
                        ),
                      ],
                      if (order.status == OrderStatus.confirmed)
                        PopupMenuItem(
                          value: OrderStatus.preparing,
                          child: Row(
                            children: [
                              Icon(Icons.kitchen,
                                  color: Colors.purple, size: 20),
                              const SizedBox(width: 8),
                              const Text('Start Preparing'),
                            ],
                          ),
                        ),
                      if (order.status == OrderStatus.preparing)
                        PopupMenuItem(
                          value: OrderStatus.ready,
                          child: Row(
                            children: [
                              Icon(Icons.done_all,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              const Text('Mark Ready'),
                            ],
                          ),
                        ),
                      if (order.status == OrderStatus.ready)
                        PopupMenuItem(
                          value: OrderStatus.delivered,
                          child: Row(
                            children: [
                              Icon(Icons.delivery_dining,
                                  color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              const Text('Mark Delivered'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: OrderStatus.cancelled,
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text('Cancel'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [const SizedBox(width: 8), const Text('Orders')],
        ),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _animationController,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip('All (${_orders.length})', null),
                      _buildChoiceChip(
                          'Pending (${_countForStatus(OrderStatus.pending)})',
                          OrderStatus.pending),
                      _buildChoiceChip(
                          'Confirmed (${_countForStatus(OrderStatus.confirmed)})',
                          OrderStatus.confirmed),
                      _buildChoiceChip(
                          'Preparing (${_countForStatus(OrderStatus.preparing)})',
                          OrderStatus.preparing),
                      _buildChoiceChip(
                          'Ready (${_countForStatus(OrderStatus.ready)})',
                          OrderStatus.ready),
                      _buildChoiceChip(
                          'Delivered (${_countForStatus(OrderStatus.delivered)})',
                          OrderStatus.delivered),
                      _buildChoiceChip(
                          'Cancelled (${_countForStatus(OrderStatus.cancelled)})',
                          OrderStatus.cancelled),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadOrders,
                child: _ordersStream != null
                    ? StreamBuilder<List<Order>>(
                        stream: _ordersStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    'Can\'t load orders: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                )
                              ],
                            );
                          }

                          final list = snapshot.data ?? [];
                          _orders = list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                          if (_selectedStatus != null) {
                            _filteredOrders = _orders.where((o) => o.status == _selectedStatus).toList();
                          } else {
                            _filteredOrders = _orders;
                          }
                          if (_filteredOrders.isEmpty) {
                            return ListView(
                              padding: const EdgeInsets.all(32),
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 64,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No orders found',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.grey.withValues(alpha: 0.7),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedStatus != null
                                      ? 'No orders with ${_selectedStatus!.name} status'
                                      : 'Your orders will appear here',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.withValues(alpha: 0.6),
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) => _buildOrderCard(_filteredOrders[index]),
                          );
                        },
                      )
                    : (_filteredOrders.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(32),
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No orders found',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.grey.withValues(alpha: 0.7),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedStatus != null
                                    ? 'No orders with ${_selectedStatus!.name} status'
                                    : 'Your orders will appear here',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.withValues(alpha: 0.6),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) => _buildOrderCard(_filteredOrders[index]),
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
