import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../services/auth_service.dart';
import '../models/vendor.dart';
import '../screens/auth/login_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/profile/vendor_profile_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Vendor? _vendor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vendor = await LocalStorageService.getCurrentVendor();
    if (mounted) setState(() => _vendor = vendor);
  }

  Widget _avatar() {
    if (_vendor?.profileImageUrl != null &&
        _vendor!.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
          radius: 28, backgroundImage: NetworkImage(_vendor!.profileImageUrl!));
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
    );
  }

  void _navigate(Widget page) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/Two_M_App_-_no_slogan.png',
                            height: 28,
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.store_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _avatar(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _vendor?.name ?? 'Vendor',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _vendor?.businessName ?? 'Business',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
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
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => _navigate(const UserProfileScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Vendor Profile'),
              onTap: () => _navigate(const VendorProfileScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Orders'),
              onTap: () => _navigate(const OrdersScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Wallet (Lipa na M-Pesa)'),
              onTap: () => _navigate(const WalletScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => _navigate(const SettingsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Support'),
              onTap: () => _navigate(const SupportScreen()),
            ),
            const Spacer(),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
