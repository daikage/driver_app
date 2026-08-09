import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dynamic_map_view.dart';
import 'settings_screen.dart';
import 'earnings_screen.dart';
import 'chat_screen.dart';
import 'history_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  double _lat = 6.5244;
  double _lng = 3.3792;
  Timer? _timer;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _determinePosition();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    _animController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
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
    final rideState = ref.read(rideProvider);
    final status = rideState.ride?['status'] as String?;
    const activeStatuses = ['accepted', 'arrived', 'started'];

    if (status != null && activeStatuses.contains(status)) {
      final ride = rideState.ride;
      if (ride != null) {
        await notifier.updateLocation(ride['id'] as int, _lat, _lng);
      }
      await notifier.fetchActive();
    } else if (status == null) {
      await notifier.fetchActive();
      await notifier.fetchAvailable(serviceType: rideState.serviceTypeFilter);
    }
  }

  Future<void> _toggleOnline() async {
    try {
      await ref.read(authProvider.notifier).toggleAvailability();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ref.read(authProvider).error ?? 'Could not toggle status.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _transition(String status) async {
    final ride = ref.read(rideProvider).ride;
    if (ride == null) return;
    try {
      await ref
          .read(rideProvider.notifier)
          .updateStatus(ride['id'] as int, status);
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
          SnackBar(
            content: Text(
                ref.read(rideProvider).error ?? 'Could not accept ride.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
  }

  Future<void> _sendSos(int rideId) async {
    try {
      await ref.read(rideProvider.notifier).sendSos(rideId, _lat, _lng);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('SOS Alert sent! Help is on the way.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showRatingDialog(int rideId) {
    int stars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Rate Customer',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was the rider?'),
              const SizedBox(height: 16),
              StatefulBuilder(builder: (context, setDialogState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.accent,
                        size: 36,
                      ),
                      onPressed: () {
                        setDialogState(() => stars = index + 1);
                      },
                    );
                  }),
                );
              }),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Leave a comment (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(rideProvider.notifier).clear();
              },
              child:
                  Text('Skip', style: TextStyle(color: Colors.grey.shade500)),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref.read(rideProvider.notifier).rateRide(
                        rideId,
                        stars,
                        commentController.text.trim(),
                      );
                  if (mounted) Navigator.pop(ctx);
                  ref.read(rideProvider.notifier).clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Thanks for rating!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryMid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RideState>(rideProvider, (previous, next) {
      final prevStatus = previous?.ride?['status'];
      final nextStatus = next.ride?['status'];
      if (prevStatus != 'completed' && nextStatus == 'completed') {
        final rideId = next.ride!['id'];
        _showRatingDialog(rideId);
      }
    });

    final auth = ref.watch(authProvider);
    final rideState = ref.watch(rideProvider);
    final isOnline = auth.user?['is_online'] == true;
    final ride = rideState.ride;
    final status = ride?['status'] as String?;
    final available = rideState.availableRides;
    final filterType = rideState.serviceTypeFilter;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────
          DynamicMapView(latitude: _lat, longitude: _lng),

          // ── Top gradient overlay ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Top bar: Online toggle + actions ───────────────────────
          Positioned(
            top: 52,
            left: 16,
            right: 16,
            child: FadeTransition(
              opacity: _animController,
              child: Row(
                children: [
                  // Online/Offline toggle pill
                  GestureDetector(
                    onTap: _toggleOnline,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient:
                            isOnline ? AppGradients.online : null,
                        color: isOnline ? null : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isOnline
                            ? AppShadows.glow(AppColors.online)
                            : AppShadows.soft,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.white
                                  : AppColors.offline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isOnline
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  _buildTopButton(
                    icon: Icons.history_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildTopButton(
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EarningsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildTopButton(
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildTopButton(
                    icon: Icons.logout_rounded,
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),

          // ── Offline overlay ────────────────────────────────────────
          if (!isOnline)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.offline.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.power_settings_new_rounded,
                            size: 36,
                            color: AppColors.offline,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'You\'re Offline',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Go online to start receiving\nride requests',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppGradients.online,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppShadows.glow(AppColors.online),
                          ),
                          child: ElevatedButton(
                            onPressed: _toggleOnline,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Go Online',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── FABs: Chat & SOS (when ride active) ───────────────────
          if (isOnline && ride != null)
            Positioned(
              top: 110,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'chat_driver',
                    elevation: 4,
                    backgroundColor: AppColors.primaryMid,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChatScreen()),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'sos_driver',
                    elevation: 4,
                    backgroundColor: AppColors.error,
                    onPressed: () => _sendSos(ride['id'] as int),
                    child: const Icon(Icons.emergency_rounded,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

          // ── Service type filter chips (when online, no active ride)
          if (isOnline && ride == null)
            Positioned(
              top: 108,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(null, filterType, 'All'),
                    _buildFilterChip('single', filterType, null),
                    _buildFilterChip('interstate', filterType, null),
                    _buildFilterChip('haulage', filterType, null),
                    _buildFilterChip('dispatch', filterType, null),
                  ],
                ),
              ),
            ),

          // ── Available rides panel ─────────────────────────────────
          if (isOnline && ride == null && available.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassmorphicContainer(
                width: MediaQuery.of(context).size.width,
                height: 400,
                borderRadius: 28,
                blur: 20,
                alignment: Alignment.bottomCenter,
                border: 1,
                linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
                    stops: const [0.1, 1],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      '${available.length} ride request${available.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...available.take(3).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final r = entry.value;
                      final rideServiceType =
                          (r['service_type'] as String?) ?? 'single';
                      final stColor = serviceTypeColor(rideServiceType);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: stColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Service type badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.serviceType(
                                        rideServiceType),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        serviceTypeIcon(rideServiceType),
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        serviceTypeLabel(rideServiceType),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '₦${r['estimated_fare']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: stColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 8, color: AppColors.success),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${r['pickup_address']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 3),
                              child: Container(
                                width: 2,
                                height: 12,
                                color: Colors.grey.shade300,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 8, color: AppColors.error),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${r['dropoff_address']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppGradients.serviceType(
                                      rideServiceType),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _acceptRide(r['id'] as int),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Accept Ride',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().scale(delay: (index * 100).ms, curve: Curves.easeOutBack);
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),

          // ── Active ride panel ─────────────────────────────────────
          if (isOnline && ride != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GlassmorphicContainer(
                width: MediaQuery.of(context).size.width,
                height: 350,
                borderRadius: 28,
                blur: 20,
                alignment: Alignment.bottomCenter,
                border: 1,
                linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
                    stops: const [0.1, 1],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Status header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppGradients.serviceType(
                                ride['service_type'] ?? 'single'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            serviceTypeIcon(
                                ride['service_type'] ?? 'single'),
                            color: Colors.white,
                            size: 22,
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
                                    status?.toUpperCase() ?? '...',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      boxShadow: AppShadows.glow(
                                          AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${ride['pickup_address']} → ${ride['dropoff_address']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Step indicator ─────────────────────────────────
                    _buildStepIndicator(status ?? 'accepted'),
                    const SizedBox(height: 16),
                    // ── Action buttons ─────────────────────────────────
                    Row(
                      children: [
                        if (status == 'accepted')
                          _buildActionButton(
                              'Arrived', 'arrived', AppColors.info),
                        if (status == 'accepted' || status == 'arrived')
                          _buildActionButton(
                              'Start Ride', 'started', AppColors.success),
                        if (status == 'started')
                          _buildActionButton('Complete', 'completed',
                              AppColors.success),
                        if (status == 'accepted' ||
                            status == 'arrived' ||
                            status == 'started')
                          _buildActionButton(
                              'Cancel', 'cancelled', AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: 1.0, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(String currentStatus) {
    final steps = ['accepted', 'arrived', 'started', 'completed'];
    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length, (i) {
        final isCompleted = i <= currentIndex;
        final isLast = i == steps.length - 1;
        final labels = ['Accepted', 'Arrived', 'Started', 'Done'];

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCompleted ? FontWeight.w600 : FontWeight.w400,
                      color: isCompleted
                          ? AppColors.textPrimary
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isCompleted
                        ? AppColors.success
                        : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(String label, String status, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _transition(status),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String? type, String? currentFilter, String? customLabel) {
    final isSelected = type == currentFilter;
    final label = customLabel ?? serviceTypeLabel(type ?? 'single');
    final color = type != null ? serviceTypeColor(type) : AppColors.electricBlue;

    return GestureDetector(
      onTap: () {
        ref.read(rideProvider.notifier).setServiceTypeFilter(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.serviceType(type ?? 'single') : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? AppShadows.glow(color) : AppShadows.soft,
        ),
        child: Row(
          children: [
            if (type != null) ...[
              Icon(
                serviceTypeIcon(type),
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.soft,
        ),
        child: Icon(icon, size: 20, color: Colors.grey.shade700),
      ),
    );
  }
}
