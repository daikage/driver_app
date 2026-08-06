import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_provider.dart';
import 'documents_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapEngine = ref.watch(mapEngineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use MapLibre GL'),
            subtitle: const Text('Toggle between Google Maps and MapLibre'),
            value: mapEngine == MapEngine.maplibre,
            onChanged: (val) {
              ref.read(mapEngineProvider.notifier).toggleEngine();
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.assignment_ind),
            title: const Text('Driver Documents (KYC)'),
            subtitle: const Text('Upload your license and insurance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
