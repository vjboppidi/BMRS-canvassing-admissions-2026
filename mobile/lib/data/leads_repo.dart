import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'local_db.dart';
import 'models.dart';

class LeadsRepo {
  LeadsRepo(this._db);
  final LocalDb _db;
  static const _uuid = Uuid();

  Future<List<Lead>> list() async {
    final rows = await _db.db.query('leads', orderBy: 'updated_at DESC');
    return rows.map(Lead.fromDbRow).toList();
  }

  Future<Lead?> byId(String id) async {
    final rows =
        await _db.db.query('leads', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Lead.fromDbRow(rows.first);
  }

  Future<Lead> create({
    required String teacherId,
    required String studentName,
    required String studentClass,
    required String parentName,
    required String parentNumber,
    String? currentSchool,
    String? address,
    String? location,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final lead = Lead(
      id: _uuid.v4(),
      teacherId: teacherId,
      studentName: studentName.trim(),
      studentClass: studentClass,
      parentName: parentName.trim(),
      parentNumber: parentNumber.trim(),
      currentSchool: _nn(currentSchool),
      address: _nn(address),
      location: _nn(location),
      notes: _nn(notes),
      createdAt: now,
      updatedAt: now,
    );
    await _db.db.insert('leads', lead.toDbRow());
    return lead;
  }

  Future<void> update(Lead lead) async {
    lead.updatedAt = DateTime.now().toUtc();
    lead.syncStatus = SyncStatus.pending;
    lead.lastSyncError = null;
    await _db.db
        .update('leads', lead.toDbRow(), where: 'id = ?', whereArgs: [lead.id]);
  }

  Future<void> delete(String id) async {
    await _db.db.delete('leads', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Lead>> pending() async {
    final rows = await _db.db.query(
      'leads',
      where: 'sync_status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
    );
    return rows.map(Lead.fromDbRow).toList();
  }

  Future<void> markSynced(String id) async {
    await _db.db.update(
      'leads',
      {'sync_status': 'synced', 'last_sync_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(String id, String error) async {
    await _db.db.update(
      'leads',
      {'sync_status': 'failed', 'last_sync_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Overwrite the local copy with data from the server (when we fetch on login
  /// or refresh). Marks as synced.
  Future<void> upsertFromServer(
      Map<String, dynamic> remote, String teacherId) async {
    final now = DateTime.now().toUtc();
    final row = {
      'id': remote['id'],
      'teacher_id': remote['teacherId'] ?? teacherId,
      'student_name': remote['studentName'],
      'student_class': remote['studentClass'],
      'current_school': remote['currentSchool'],
      'parent_name': remote['parentName'],
      'parent_number': remote['parentNumber'],
      'address': remote['address'],
      'location': remote['location'],
      'status': remote['status'] ?? 'NEW',
      'notes': remote['notes'],
      'created_at': remote['createdAt'] ?? now.toIso8601String(),
      'updated_at': remote['updatedAt'] ?? now.toIso8601String(),
      'sync_status': 'synced',
      'last_sync_error': null,
    };
    await _db.db.insert(
      'leads',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static String? _nn(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }
}
