import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../models/wallet.dart';
import '../../models/vendor.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _withdrawAmountController = TextEditingController();
  Stream<WalletInfo>? _walletStream;
  Stream<List<WalletTxn>>? _txnsStream;
  Stream<Vendor?>? _vendorStream;
  Vendor? _vendor;

  @override
  void initState() {
    super.initState();
    final locator = ServiceLocator();
    if (locator.isAuthenticated) {
      final uid = locator.currentUserId;
      _walletStream = locator.walletRepository.watchWallet(uid);
      _txnsStream = locator.walletRepository.watchTransactions(uid);
      _vendorStream = locator.watchCurrentVendor().map((e) => e as Vendor?);
    }
  }

  Future<void> _withdraw(double balance) async {
    final amount = double.tryParse(_withdrawAmountController.text) ?? 0;
    if (amount <= 0) return;
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.red),
      );
      return;
    }
    try {
      await ServiceLocator().walletRepository.requestWithdrawal(ServiceLocator().currentUserId, amount);
      _withdrawAmountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal requested')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: StreamBuilder<Vendor?>(
        stream: _vendorStream,
        builder: (context, vSnap) {
          if (vSnap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Can\'t load vendor profile: ${vSnap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          _vendor = vSnap.data;
          // Ensure withdraw phone mirrors vendor phone when available
          if (vSnap.hasData && vSnap.data != null) {
            ServiceLocator().walletRepository.setWithdrawPhone(ServiceLocator().currentUserId, vSnap.data!.phone);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<WalletInfo>(
                  stream: _walletStream,
                  builder: (context, wSnap) {
                    if (wSnap.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Can\'t load wallet: ${wSnap.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final balance = (wSnap.data?.balance ?? 0.0);
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available Balance', style: Theme.of(context).textTheme.bodySmall),
                              Text('KES ${balance.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.policy, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Policy', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Accepted: C2B (Customer to Business) and B2C (Business to Customer). Cash is handled by drivers only.',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Withdraw (B2C)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Withdraw to Phone',
                            prefixIcon: const Icon(Icons.phone),
                            border: const OutlineInputBorder(),
                            hintText: _vendor?.phone ?? '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _withdrawAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Amount (KES)',
                            prefixIcon: Icon(Icons.payments_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<WalletInfo>(
                          stream: _walletStream,
                          builder: (context, wSnap) {
                            final balance = (wSnap.data?.balance ?? 0.0);
                            return SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => _withdraw(balance),
                                icon: const Icon(Icons.send_to_mobile),
                                label: const Text('Withdraw to M-Pesa (B2C)'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                StreamBuilder<List<WalletTxn>>(
                  stream: _txnsStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Can\'t load transactions: ${snap.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final txns = (snap.data ?? [])..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    if (txns.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('No transactions yet', style: Theme.of(context).textTheme.bodyMedium),
                      );
                    }
                    return Column(
                      children: txns
                          .map((t) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (t.type == 'withdrawal' ? Colors.orange : Colors.green).withValues(alpha: 0.15),
                                  child: Icon(t.type == 'withdrawal' ? Icons.call_made : Icons.call_received,
                                      color: t.type == 'withdrawal' ? Colors.orange : Colors.green),
                                ),
                                title: Text('${t.type == 'withdrawal' ? 'Withdrawal' : 'Deposit'} - ${t.channel}'),
                                subtitle: Text('${t.timestamp.toLocal()} • ${t.status}'),
                                trailing: Text('KES ${t.amount.toStringAsFixed(2)}'),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class _Txn {
  final String type;
  final double amount;
  final String channel;
  final String status;
  final String timestamp;

  _Txn(this.type, this.amount, this.channel, this.status, this.timestamp);

  factory _Txn.fromMap(Map<String, dynamic> m) => _Txn(
        m['type'],
        (m['amount'] as num).toDouble(),
        m['channel'],
        m['status'],
        m['timestamp'],
      );
}
