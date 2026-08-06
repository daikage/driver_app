import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dynamic_map_view.dart';
import 'settings_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final double _lat = 6.5244;
  final double _lng = 3.3792;
  bool isOnline = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pairride Driver'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Row(
            children: [
              Text(isOnline ? 'Online' : 'Offline', style: const TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: isOnline,
                onChanged: (val) {
                  setState(() {
                    isOnline = val;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          DynamicMapView(
            latitude: _lat,
            longitude: _lng,
          ),
          if (!isOnline)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'You are offline.\nGo online to receive ride requests.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
