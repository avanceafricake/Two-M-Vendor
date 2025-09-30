import 'package:flutter/material.dart';
import '../../models/vendor.dart';
import '../../models/order.dart';
import '../../services/service_locator.dart';
import '../orders/orders_screen.dart';
import '../products/add_product_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/category_theme.dart';
import '../pharmacy/consultation_settings_sheet.dart';
import '../pharmacy/consultation_inbox_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // No local cache reads here; we show live Firestore streams.
    _isLoading = false;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  Color _accentForCategory(String? key) => CategoryTheme.ac(key ?? '');

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.2,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrder(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getBusinessIcon(order.businessType),
              color: _getStatusColor(order.status),
              size: 22,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                order.customerName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${order.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.statusDisplayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Update Status',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<OrderStatus>(
                        value: order.status,
                        isExpanded: true,
                        items: OrderStatus.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name[0].toUpperCase() +
                                      s.name.substring(1)),
                                ))
                            .toList(),
                        onChanged: (_) {
                          // For now, status updates are handled in Orders screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const OrdersScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final locator = ServiceLocator();
    final vendorStream = locator.watchCurrentVendor();
    final ordersStream = locator.watchVendorOrders().map((e) => e.cast<Order>());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/Two_M_App_-_no_slogan.png',
              height: 28,
              fit: BoxFit.contain,
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Online/Offline toggle for accepting orders
          StreamBuilder<dynamic>(
            stream: vendorStream,
            builder: (context, snap) {
              final Vendor? v = snap.data as Vendor?;
              final bool online = v?.isOnline ?? false;
              final bool pending = v?.status == VendorStatus.pendingApproval;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: (v == null || pending)
                      ? null
                      : () async {
                          final locator = ServiceLocator();
                          await locator.vendorRepository
                              .setOnline(locator.currentUserId, !online);
                        },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: online
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: online
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          online ? Icons.toggle_on : Icons.toggle_off,
                          color: online ? Colors.green : Colors.grey,
                          size: 26,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          online ? 'Active' : 'Inactive',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          StreamBuilder<List<Order>>(
            stream: ordersStream,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? const <Order>[];
              final pending =
                  orders.where((o) => o.status == OrderStatus.pending).length;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersScreen(
                            initialStatus: OrderStatus.pending),
                      ),
                    ),
                  ),
                  if (pending > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          pending.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            // Streams auto-refresh; no manual reload required
          },
          child: StreamBuilder<dynamic>(
            stream: vendorStream,
            builder: (context, vendorSnap) {
              final Vendor? vendor = vendorSnap.data as Vendor?;
              final bool isPending =
                  vendor?.status == VendorStatus.pendingApproval;

              return StreamBuilder<List<Order>>(
                stream: ordersStream,
                builder: (context, orderSnap) {
                  final orders = (orderSnap.data ?? const <Order>[])
                      .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  final totalRevenue = orders
                      .where((o) => o.status == OrderStatus.delivered &&
                          (o.paymentStatus == PaymentStatus.paid ||
                              o.paymentStatus == PaymentStatus.remitted))
                      .fold<double>(0.0, (sum, o) => sum + o.total);
                  final totalOrders = orders.length;
                  final pendingOrders =
                      orders.where((o) => o.status == OrderStatus.pending).length;
                  final avgOrderValue =
                      totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

                  // Base dashboard content
                  final Widget content = SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _accentForCategory(vendor?.categoryKey),
                                _accentForCategory(vendor?.categoryKey)
                                    .withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, ${vendor?.name ?? 'Vendor'}!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                vendor?.businessName ?? 'Your Business',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vendor?.businessTypeDisplayName ?? 'Business',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Statistics',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 156,
                          ),
                          children: [
                            _buildStatCard(
                              'Total Revenue',
                              'KES ${totalRevenue.toStringAsFixed(2)}',
                              Icons.monetization_on,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Total Orders',
                              totalOrders.toString(),
                              Icons.shopping_bag,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Pending Orders',
                              pendingOrders.toString(),
                              Icons.pending_actions,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Avg Order Value',
                              'KES ${avgOrderValue.toStringAsFixed(2)}',
                              Icons.trending_up,
                              Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Quick Actions',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 96),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildQuickAction(
                                  'View Orders',
                                  Icons.list_alt,
                                  Colors.blue,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const OrdersScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickAction(
                                  'Add Product',
                                  Icons.add_business,
                                  Colors.green,
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AddProductScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (vendor?.categoryKey == 'pharmacy')
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.2)),
                              color: Colors.blue.withValues(alpha: 0.04),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pharmacist Consultation',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildQuickAction(
                                        'Inbox',
                                        Icons.inbox_outlined,
                                        Colors.blue,
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const ConsultationInboxScreen()),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickAction(
                                        'Settings',
                                        Icons.tune,
                                        Colors.purple,
                                        () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(16)),
                                            ),
                                            builder: (_) => const SafeArea(
                                                child: ConsultationSettingsSheet()),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildQuickAction(
                                        'How it works',
                                        Icons.help_outline,
                                        Colors.teal,
                                        () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                  'Pharmacist Consultation'),
                                              content: const Text(
                                                  'Customers can start a Chat, Call, or Video call with you from the Pharmacy tab. You can adjust availability and rates in Settings and manage requests in Inbox.'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Close'))
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Orders',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const OrdersScreen()),
                              ),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (orders.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 48,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No orders yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color:
                                            Colors.grey.withValues(alpha: 0.7),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your recent orders will appear here',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            Colors.grey.withValues(alpha: 0.6),
                                      ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...orders.take(3).map(_buildRecentOrder),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );

                  if (!isPending) return content;

                  const List<double> greyscaleMatrix = <double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 1, 0,
                  ];

                  return Stack(
                    children: [
                      // Desaturate content
                      ColorFiltered(
                        colorFilter: const ColorFilter.matrix(greyscaleMatrix),
                        child: content,
                      ),
                      // Grey overlay + message
                      Positioned.fill(
                        child: Container(
                          color: Colors.grey.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Waiting for admin approval',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'We\'ll notify you once your account is approved',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
