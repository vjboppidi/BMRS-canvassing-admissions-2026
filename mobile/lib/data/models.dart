/// Sync status of a locally-modified record.
enum SyncStatus { synced, pending, failed }

String syncStatusToDb(SyncStatus s) => switch (s) {
      SyncStatus.synced => 'synced',
      SyncStatus.pending => 'pending',
      SyncStatus.failed => 'failed',
    };

SyncStatus syncStatusFromDb(String s) => switch (s) {
      'synced' => SyncStatus.synced,
      'failed' => SyncStatus.failed,
      _ => SyncStatus.pending,
    };

class Lead {
  Lead({
    required this.id,
    required this.teacherId,
    required this.studentName,
    required this.studentClass,
    required this.parentName,
    required this.parentNumber,
    this.currentSchool,
    this.address,
    this.location,
    this.status = 'NEW',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncError,
  });

  final String id;
  final String teacherId;
  String studentName;
  String studentClass;
  String parentName;
  String parentNumber;
  String? currentSchool;
  String? address;
  String? location;
  String status;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;
  SyncStatus syncStatus;
  String? lastSyncError;

  Map<String, dynamic> toDbRow() => {
        'id': id,
        'teacher_id': teacherId,
        'student_name': studentName,
        'student_class': studentClass,
        'current_school': currentSchool,
        'parent_name': parentName,
        'parent_number': parentNumber,
        'address': address,
        'location': location,
        'status': status,
        'notes': notes,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'sync_status': syncStatusToDb(syncStatus),
        'last_sync_error': lastSyncError,
      };

  factory Lead.fromDbRow(Map<String, dynamic> r) => Lead(
        id: r['id'] as String,
        teacherId: r['teacher_id'] as String,
        studentName: r['student_name'] as String,
        studentClass: r['student_class'] as String,
        currentSchool: r['current_school'] as String?,
        parentName: r['parent_name'] as String,
        parentNumber: r['parent_number'] as String,
        address: r['address'] as String?,
        location: r['location'] as String?,
        status: (r['status'] as String?) ?? 'NEW',
        notes: r['notes'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
        syncStatus: syncStatusFromDb(r['sync_status'] as String? ?? 'pending'),
        lastSyncError: r['last_sync_error'] as String?,
      );

  /// Payload shape the backend expects for POST /leads and POST /leads/sync.
  Map<String, dynamic> toSyncPayload() => {
        'id': id,
        'studentName': studentName,
        'studentClass': studentClass,
        'currentSchool': currentSchool,
        'parentName': parentName,
        'parentNumber': parentNumber,
        'address': address,
        'location': location,
        'status': status,
        'notes': notes,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

class Reminder {
  Reminder({
    required this.id,
    required this.leadId,
    required this.teacherId,
    required this.remindAt,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.status = 'PENDING',
    this.syncStatus = SyncStatus.pending,
    this.lastSyncError,
  });

  final String id;
  final String leadId;
  final String teacherId;
  DateTime remindAt;
  String? note;
  String status;
  DateTime createdAt;
  DateTime updatedAt;
  SyncStatus syncStatus;
  String? lastSyncError;

  Map<String, dynamic> toDbRow() => {
        'id': id,
        'lead_id': leadId,
        'teacher_id': teacherId,
        'remind_at': remindAt.toUtc().toIso8601String(),
        'note': note,
        'status': status,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'sync_status': syncStatusToDb(syncStatus),
        'last_sync_error': lastSyncError,
      };

  factory Reminder.fromDbRow(Map<String, dynamic> r) => Reminder(
        id: r['id'] as String,
        leadId: r['lead_id'] as String,
        teacherId: r['teacher_id'] as String,
        remindAt: DateTime.parse(r['remind_at'] as String),
        note: r['note'] as String?,
        status: (r['status'] as String?) ?? 'PENDING',
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
        syncStatus: syncStatusFromDb(r['sync_status'] as String? ?? 'pending'),
        lastSyncError: r['last_sync_error'] as String?,
      );

  Map<String, dynamic> toSyncPayload() => {
        'id': id,
        'leadId': leadId,
        'remindAt': remindAt.toUtc().toIso8601String(),
        'note': note,
        'status': status,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

class Highlight {
  const Highlight({
    required this.id,
    required this.kind,
    required this.title,
    this.body,
    this.mediaUrl,
    this.order = 0,
  });

  final String id;
  final String kind;
  final String title;
  final String? body;
  final String? mediaUrl;
  final int order;

  factory Highlight.fromJson(Map<String, dynamic> j) => Highlight(
        id: j['id'] as String,
        kind: j['kind'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        mediaUrl: j['mediaUrl'] as String?,
        order: (j['order'] as int?) ?? 0,
      );
}
