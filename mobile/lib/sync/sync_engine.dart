import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/config.dart';
import '../core/connectivity.dart';
import '../data/leads_repo.dart';
import '../data/reminders_repo.dart';

/// Background loop that drains pending writes (leads + reminders) to the
/// backend. Runs periodically and is also kicked off when the connectivity
/// status flips back to online.
class SyncEngine {
  SyncEngine({
    required this.api,
    required this.leads,
    required this.reminders,
    required this.connectivity,
  });

  final ApiClient api;
  final LeadsRepo leads;
  final RemindersRepo reminders;
  final AppConnectivity connectivity;

  Timer? _timer;
  StreamSubscription<bool>? _connSub;
  bool _running = false;
  final _controller = StreamController<SyncOutcome>.broadcast();
  Stream<SyncOutcome> get onSync => _controller.stream;

  void start() {
    _timer ??= Timer.periodic(AppConfig.syncInterval, (_) => run());
    _connSub ??= connectivity.onStatusChanged.listen((online) {
      if (online) run();
    });
    // Fire an initial sweep.
    run();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _connSub?.cancel();
    _connSub = null;
  }

  Future<SyncOutcome> run() async {
    if (_running) return const SyncOutcome.skipped();
    _running = true;
    try {
      final online = await connectivity.isOnline();
      if (!online) {
        const outcome = SyncOutcome.offline();
        _controller.add(outcome);
        return outcome;
      }

      final pendingLeads = await leads.pending();
      final pendingReminders = await reminders.pending();

      int leadsOk = 0, leadsFail = 0;
      if (pendingLeads.isNotEmpty) {
        try {
          final resp = await api.dio.post<Map<String, dynamic>>(
            '/leads/sync',
            data: {
              'leads': pendingLeads.map((l) => l.toSyncPayload()).toList()
            },
          );
          final results = (resp.data?['results'] as List?) ?? const [];
          final byId = {
            for (final r in results.cast<Map<String, dynamic>>())
              r['id'] as String: r,
          };
          for (final l in pendingLeads) {
            if (byId.containsKey(l.id)) {
              await leads.markSynced(l.id);
              leadsOk++;
            } else {
              await leads.markFailed(l.id, 'not confirmed by server');
              leadsFail++;
            }
          }
        } on DioException catch (e) {
          for (final l in pendingLeads) {
            await leads.markFailed(l.id, _readableError(e));
            leadsFail++;
          }
        }
      }

      int remOk = 0, remFail = 0;
      for (final r in pendingReminders) {
        try {
          await api.dio.post<Map<String, dynamic>>('/reminders',
              data: r.toSyncPayload());
          await reminders.markSynced(r.id);
          remOk++;
        } on DioException catch (e) {
          await reminders.markFailed(r.id, _readableError(e));
          remFail++;
        }
      }

      final outcome = SyncOutcome.completed(
        leadsSynced: leadsOk,
        leadsFailed: leadsFail,
        remindersSynced: remOk,
        remindersFailed: remFail,
      );
      _controller.add(outcome);
      return outcome;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Sync crashed: $e\n$st');
      }
      final outcome = SyncOutcome.crashed(e.toString());
      _controller.add(outcome);
      return outcome;
    } finally {
      _running = false;
    }
  }

  String _readableError(DioException e) {
    final status = e.response?.statusCode;
    if (status != null) return 'HTTP $status';
    return e.type.name;
  }
}

class SyncOutcome {
  const SyncOutcome._({
    required _Kind kind,
    this.leadsSynced = 0,
    this.leadsFailed = 0,
    this.remindersSynced = 0,
    this.remindersFailed = 0,
    this.error,
  }) : _kind = kind;

  const SyncOutcome.skipped() : this._(kind: _Kind.skipped);
  const SyncOutcome.offline() : this._(kind: _Kind.offline);
  const SyncOutcome.completed({
    required int leadsSynced,
    required int leadsFailed,
    required int remindersSynced,
    required int remindersFailed,
  }) : this._(
          kind: _Kind.completed,
          leadsSynced: leadsSynced,
          leadsFailed: leadsFailed,
          remindersSynced: remindersSynced,
          remindersFailed: remindersFailed,
        );
  const SyncOutcome.crashed(String err)
      : this._(kind: _Kind.crashed, error: err);

  final _Kind _kind;
  final int leadsSynced;
  final int leadsFailed;
  final int remindersSynced;
  final int remindersFailed;
  final String? error;

  bool get isOffline => _kind == _Kind.offline;
  bool get isCompleted => _kind == _Kind.completed;
}

enum _Kind { skipped, offline, completed, crashed }
