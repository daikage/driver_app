import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import 'reverb_service.dart';

/// The raw stream of realtime events coming from the Reverb socket,
/// exposed as a Riverpod provider so widgets can subscribe to it.
final reverbEventsProvider = StreamProvider.autoDispose<ReverbEvent>((ref) {
  return ReverbService.instance.events;
});

/// Keeps the Reverb WebSocket in sync with the driver's auth + ride state and
/// routes incoming events (new ride requests, status updates, chat) into the
/// ride provider. It renders its [child] unchanged, so it adds no layout.
class RealtimeBindings extends ConsumerStatefulWidget {
  const RealtimeBindings({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<RealtimeBindings> createState() => _RealtimeBindingsState();
}

class _RealtimeBindingsState extends ConsumerState<RealtimeBindings> {
  int? _subscribedRideId;
  bool _subscribedDriversChannel = false;

  @override
  Widget build(BuildContext context) {
    // Keep the socket alive while the user is signed in.
    ref.listen<AuthState>(authProvider, (previous, next) {
      final wasLoggedIn = previous?.isLoggedIn ?? false;
      final isLoggedIn = next.isLoggedIn;

      if (isLoggedIn && !wasLoggedIn) {
        _subscribedRideId = null;
        _subscribedDriversChannel = false;
        ref.read(reverbServiceProvider).connect();
        _syncSubscriptions();
      } else if (!isLoggedIn && wasLoggedIn) {
        _subscribedRideId = null;
        _subscribedDriversChannel = false;
        ref.read(reverbServiceProvider).disconnect();
      }
    });

    // Subscribe/unsubscribe as the active ride changes.
    ref.listen<RideState>(rideProvider, (previous, next) {
      _syncSubscriptions();
    });

    // Route realtime events into app state.
    ref.listen(reverbEventsProvider, (previous, AsyncValue<ReverbEvent>? next) {
      final event = next?.value;
      if (event == null) return;
      _handleEvent(event);
    });

    return widget.child;
  }

  /// Ensures the socket is subscribed to exactly the channels the current
  /// state requires. Safe to call repeatedly (idempotent).
  void _syncSubscriptions() {
    final reverb = ref.read(reverbServiceProvider);

    if (!ref.read(authProvider).isLoggedIn) {
      _subscribedRideId = null;
      _subscribedDriversChannel = false;
      return;
    }

    // Public channel that carries brand-new ride requests (broadcast by the
    // RideRequested event) so drivers see requests without waiting for a poll.
    if (!_subscribedDriversChannel) {
      reverb.subscribe('drivers');
      _subscribedDriversChannel = true;
    }

    final rideState = ref.read(rideProvider);
    final rideId = rideState.ride?['id'] as int?;
    final status = rideState.ride?['status'] as String?;
    final isTerminal = status == 'completed' || status == 'cancelled';

    if (rideId != null && !isTerminal) {
      if (_subscribedRideId != rideId) {
        if (_subscribedRideId != null) {
          reverb.unsubscribe('private-ride.$_subscribedRideId');
          reverb.unsubscribe('presence-ride.$_subscribedRideId');
        }
        _subscribedRideId = rideId;
        reverb.subscribePrivate('ride.$rideId');
        reverb.subscribePresence('ride.$rideId');
      }
    } else if (_subscribedRideId != null) {
      reverb.unsubscribe('private-ride.$_subscribedRideId');
      reverb.unsubscribe('presence-ride.$_subscribedRideId');
      _subscribedRideId = null;
    }
  }

  Future<void> _handleEvent(ReverbEvent event) async {
    final rideNotifier = ref.read(rideProvider.notifier);

    switch (event.event) {
      case 'pusher:connection_established':
        // Socket (re)connected – re-establish the channel subscriptions.
        _syncSubscriptions();
        break;

      case 'RideRequested':
        // A new ride is up for grabs – refresh the available list.
        if (ref.read(authProvider).isDriver) {
          rideNotifier.fetchAvailable();
        }
        break;

      case 'RideStatusUpdated':
        final payload = event.data['ride'];
        if (payload is Map) {
          final payloadRide = (payload).cast<String, dynamic>();
          final payloadId = payloadRide['id'];
          final newStatus = payloadRide['status'];
          final currentRide = ref.read(rideProvider).ride;

          if (currentRide != null &&
              payloadId == currentRide['id'] &&
              newStatus is String) {
            rideNotifier.updateRideLocally({
              ...currentRide,
              ...payloadRide,
            });
            if (newStatus == 'completed' || newStatus == 'cancelled') {
              // Keep the local record so the UI shows the final state;
              // the home screen's poll loop clears cancelled rides.
              return;
            }
          }
        }
        // Pull the authoritative ride record (full customer info, times…).
        rideNotifier.fetchActive();
        break;

      case 'MessageSent':
        final message = event.data['message'];
        if (message is Map) {
          rideNotifier.appendMessage((message).cast<String, dynamic>());
        }
        break;
    }
  }
}