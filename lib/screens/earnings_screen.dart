import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earning_provider.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(earningProvider.notifier).fetchWalletAndEarnings());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(earningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Earnings'),
      ),
      body: state.loading && state.wallet == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.wallet == null
              ? Center(child: Text(state.error!))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Column(
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₦${state.wallet?['balance'] ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Earnings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: state.earnings.isEmpty
                          ? const Center(child: Text('No earnings yet.'))
                          : ListView.builder(
                              itemCount: state.earnings.length,
                              itemBuilder: (ctx, i) {
                                final earning = state.earnings[i];
                                return ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.attach_money, color: Colors.white),
                                  ),
                                  title: Text('Ride #${earning['ride_id']}'),
                                  subtitle: Text('Commission: ₦${earning['commission_deducted']}'),
                                  trailing: Text(
                                    '+ ₦${earning['amount']}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
