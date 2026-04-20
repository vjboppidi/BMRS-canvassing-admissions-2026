import 'package:uuid/uuid.dart';
import 'local_db.dart';
import 'models.dart';

class RemindersRepo {
  RemindersRepo(this._db);
  final LocalDb _db;
  static const _uuid = Uuid();

  Future<List<Reminder>> list() async {
    final rows = await _db.db.query('reminders', orderBy: 'remind_at ASC');
    return rows.map(Reminder.fromDbRow).toList();
  }

  Future<List<Reminder>> forLead(String leadId) async {
    final rows = await _db.db.query(
      'reminders',
      where: 'lead_id = ?',
      whereArgs: [leadId],
      orderBy: 'remind_at ASC',
    );
    return rows.map(Reminder.fromDbRow).toList();
  }

  Future<Reminder> create({
    required String leadId,
    required String teacherId,
    required DateTime remindAt,
    String? note,
  }) async {
    final now = DateTime.now().toUtc();
    final r = Reminder(
      id: _uuid.v4(),
      leadId: leadId,
      teacherId: teacherId,
      remindAt: remindAt.toUtc(),
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('reminders', r.toDbRow());
    return r;
  }

  Future<void> update(Reminder r) async {
    r.updatedAt = DateTime.now().toUtc();
    r.syncStatus = SyncStatus.pending;
    r.lastSyncError = null;
    await _db.db
        .update('reminders', r.toDbRow(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> delete(String id) async {
    await _db.db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Reminder>> pending() async {
    final rows = await _db.db.query(
      'reminders',
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
    );
    return rows.map(Reminder.fromDbRow).toList();
  }

  Future<void> markSynced(String id) async {
    await _db.db.update(
      'reminders',
      {'sync_status': 'synced', 'last_sync_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(String id, String error) async {
    await _db.db.update(
      'reminders',
      {'sync_status': 'failed', 'last_sync_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
