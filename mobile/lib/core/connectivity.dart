import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus` that exposes a boolean stream of
/// "is there probably internet?". The actual reachability is still best-effort;
/// the sync engine also catches network errors from Dio to be safe.
class AppConnectivity {
  AppConnectivity() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_hasAny);

  Future<bool> isOnline() async {
    final res = await _connectivity.checkConnectivity();
    return _hasAny(res);
  }

  bool _hasAny(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);
}
