import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'core/auth_store.dart';
import 'core/connectivity.dart';
import 'core/notifications.dart';
import 'data/leads_repo.dart';
import 'data/local_db.dart';
import 'data/reminders_repo.dart';
import 'sync/sync_engine.dart';

/// Set in `main()` before `runApp()` so providers can be synchronous.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);
final localDbProvider = Provider<LocalDb>(
  (ref) => throw UnimplementedError('Override in main()'),
);
final notificationsProvider = Provider<AppNotifications>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final authStoreProvider = Provider<AuthStore>(
  (ref) => AuthStore(ref.watch(sharedPrefsProvider)),
);
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(authStore: ref.watch(authStoreProvider)),
);
final connectivityProvider =
    Provider<AppConnectivity>((ref) => AppConnectivity());
final leadsRepoProvider = Provider<LeadsRepo>(
  (ref) => LeadsRepo(ref.watch(localDbProvider)),
);
final remindersRepoProvider = Provider<RemindersRepo>(
  (ref) => RemindersRepo(ref.watch(localDbProvider)),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    api: ref.watch(apiClientProvider),
    leads: ref.watch(leadsRepoProvider),
    reminders: ref.watch(remindersRepoProvider),
    connectivity: ref.watch(connectivityProvider),
  );
  ref.onDispose(engine.stop);
  return engine;
});

/// Notifier for the current auth session.
class AuthController extends StateNotifier<AuthSession?> {
  AuthController(this._store) : super(_store.current);
  final AuthStore _store;

  Future<void> set(AuthSession s) async {
    await _store.save(s);
    state = s;
  }

  Future<void> clear() async {
    await _store.clear();
    state = null;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthSession?>(
  (ref) => AuthController(ref.watch(authStoreProvider)),
);
