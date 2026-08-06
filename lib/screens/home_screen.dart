import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../widgets/dynamic_map_view.dart';
import 'settings_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  double _lat = 6.5244; // Fallback Lagos coords until GPS reports a position
  double _lng = 3.3792;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // Short poll: discover ride requests, sync status, and stream location.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _lat = position.latitude;
            _lng = position.longitude;
          });
        }
      }
    } catch (_) {
      // Keep fallback coordinates if location is unavailable.
    }
  }

  bool get _isOnline {
    final user = ref.read(authProvider).user;
    return user?['is_online'] == true;
  }

  Future<void> _poll() async {
    if (!_isOnline) return;

    final notifier = ref.read(rideProvider.notifier);
    final status = ref.read(rideProvider).ride?['status'] as String?;
    const activeStatuses = ['accepted', 'arrived', 'started'];

    if (status != null && activeStatuses.contains(status)) {
      final ride = ref.read(rideProvider).ride;
      if (ride != null) {
        await notifier.updateLocation(ride['id'] as int, _lat, _lng);
      }
      await notifier.fetchActive();
    } else if (status == null) {
      await notifier.fetchActive();
      await notifier.fetchAvailable();
    }
  }

  Future<void> _toggleOnline() async {
    try {
      await ref.read(authProvider.notifier).toggleAvailability();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ref.read(authProvider).error ?? 'Could not toggle status.')),
        );
      }
    }
  }

  Future<void> _transition(String status) async {
    final ride = ref.read(rideProvider).ride;
    if (ride == null) return;
    try {
      await ref.read(rideProvider.notifier).updateStatus(ride['id'] as int, status);
    } catch (_) {
      // Error is surfaced through rideProvider state.
    }
  }

  Future<void> _acceptRide(int rideId) async {
    try {
      await ref.read(rideProvider.notifier).acceptRide(rideId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(rideProvider).error ?? 'Could not accept ride.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final rideState = ref.watch(rideProvider);
    final isOnline = auth.user?['is_online'] == true;
    final ride = rideState.ride;
    final status = ride?['status'] as String?;
    final available = rideState.availableRides;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pairride Driver'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Row(
            children: [
              Text(isOnline ? 'Online' : 'Offline',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: isOnline,
                onChanged: (_) => _toggleOnline(),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          DynamicMapView(latitude: _lat, longitude: _lng),
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
          if (isOnline && ride == null && available.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${available.length} ride request(s)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final r in available.take(3))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on,
                              color: Colors.green),
                          title: Text(
                              '${r['pickup_address']} → ${r['dropoff_address']}'),
                          subtitle: Text('₦${r['estimated_fare']}'),
                          trailing: ElevatedButton(
                            onPressed: () => _acceptRide(r['id'] as int),
                            child: const Text('Accept'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (isOnline && ride != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ride status: ${status?.toUpperCase() ?? '...'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${ride['pickup_address']} → ${ride['dropoff_address']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (status == 'accepted')
                            _statusButton(context, 'arrived', 'Arrived'),
                          if (status == 'accepted' || status == 'arrived')
                            _statusButton(context, 'started', 'Start'),
                          if (status == 'started')
                            _statusButton(context, 'completed', 'Complete'),
                          if (status == 'accepted' ||
                              status == 'arrived' ||
                              status == 'started')
                            _statusButton(context, 'cancelled', 'Cancel',
                                isDestructive: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusButton(BuildContext context, String status, String label,
      {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => _transition(status),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: Text(label),
      ),
    );
  }
}
