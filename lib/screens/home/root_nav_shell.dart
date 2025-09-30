import 'package:flutter/material.dart';
import '../home/dashboard_screen.dart';
import '../wallet/wallet_screen.dart';
import '../orders/orders_screen.dart';
import '../products/stock_manager_screen.dart';
import '../products/add_product_screen.dart';

class RootNavShell extends StatefulWidget {
  const RootNavShell({super.key});

  @override
  State<RootNavShell> createState() => _RootNavShellState();
}

class _RootNavShellState extends State<RootNavShell> {
  int _currentIndex = 0;
  bool _isFabHovered = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      DashboardScreen(),
      WalletScreen(),
      OrdersScreen(),
      StockManagerScreen(),
    ];
  }

  void _onAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
        ],
      ),
      floatingActionButton: MouseRegion(
        onEnter: (_) => setState(() => _isFabHovered = true),
        onExit: (_) => setState(() => _isFabHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: _isFabHovered
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _isFabHovered && MediaQuery.of(context).size.width > 520
                ? FloatingActionButton.extended(
                    key: const ValueKey('fab-extended'),
                    onPressed: _onAddProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  )
                : FloatingActionButton(
                    key: const ValueKey('fab-regular'),
                    onPressed: _onAddProduct,
                    tooltip: 'Add Product',
                    child: const Icon(Icons.add),
                  ),
          ),
        ),
      ),
    );
  }
}
