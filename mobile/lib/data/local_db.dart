import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed local store. The mobile app is offline-first: every lead and
/// reminder is written here first and the sync engine later pushes them to the
/// backend.
class LocalDb {
  LocalDb._(this.db);

  final Database db;

  static Future<LocalDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'bmrs_admissions.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE leads(
            id TEXT PRIMARY KEY,
            teacher_id TEXT NOT NULL,
            student_name TEXT NOT NULL,
            student_class TEXT NOT NULL,
            current_school TEXT,
            parent_name TEXT NOT NULL,
            parent_number TEXT NOT NULL,
            address TEXT,
            location TEXT,
            status TEXT NOT NULL DEFAULT 'NEW',
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            last_sync_error TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_leads_sync ON leads(sync_status)');
        await db.execute('CREATE INDEX idx_leads_updated ON leads(updated_at)');

        await db.execute('''
          CREATE TABLE reminders(
            id TEXT PRIMARY KEY,
            lead_id TEXT NOT NULL,
            teacher_id TEXT NOT NULL,
            remind_at TEXT NOT NULL,
            note TEXT,
            status TEXT NOT NULL DEFAULT 'PENDING',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            last_sync_error TEXT
          )
        ''');
        await db
            .execute('CREATE INDEX idx_reminders_lead ON reminders(lead_id)');
        await db.execute(
            'CREATE INDEX idx_reminders_sync ON reminders(sync_status)');
      },
    );
    return LocalDb._(db);
  }

  Future<void> close() async => db.close();
}
