import 'package:bmrs_admissions/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncStatus serialization', () {
    test('round-trips all values', () {
      for (final s in SyncStatus.values) {
        expect(syncStatusFromDb(syncStatusToDb(s)), s);
      }
    });

    test('unknown db value defaults to pending', () {
      expect(syncStatusFromDb('gibberish'), SyncStatus.pending);
    });
  });

  group('Lead row round-trip', () {
    test('preserves all fields', () {
      final now = DateTime.utc(2025, 4, 1, 12);
      final l = Lead(
        id: '11111111-1111-1111-1111-111111111111',
        teacherId: '22222222-2222-2222-2222-222222222222',
        studentName: 'Arjun',
        studentClass: 'Class 6',
        parentName: 'Rajesh',
        parentNumber: '+919000000000',
        currentSchool: 'Sunrise',
        address: 'MG Road',
        location: 'Bengaluru',
        notes: 'Interested',
        createdAt: now,
        updatedAt: now,
      );
      final back = Lead.fromDbRow(l.toDbRow());
      expect(back.id, l.id);
      expect(back.studentName, 'Arjun');
      expect(back.syncStatus, SyncStatus.pending);
      expect(back.updatedAt.toUtc(), now);
    });
  });
}
