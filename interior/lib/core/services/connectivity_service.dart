import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams whether the device currently has network connectivity.
/// Used to show the offline banner and to gate sync attempts (Sec. 31).
/// This does NOT guarantee Firebase reachability, only device-level
/// connectivity — good enough for a prototype offline indicator.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});

final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStreamProvider);
  return async.maybeWhen(data: (v) => v, orElse: () => true);
});
