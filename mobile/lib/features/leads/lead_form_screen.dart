import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers.dart';
import '../reminders/reminder_dialog.dart';

class LeadFormScreen extends ConsumerStatefulWidget {
  const LeadFormScreen({super.key, this.existing});

  final Lead? existing;

  @override
  ConsumerState<LeadFormScreen> createState() => _LeadFormScreenState();
}

const _classes = [
  'Nursery',
  'LKG',
  'UKG',
  'Class 1',
  'Class 2',
  'Class 3',
  'Class 4',
  'Class 5',
  'Class 6',
  'Class 7',
  'Class 8',
  'Class 9',
  'Class 10',
  'Class 11',
  'Class 12',
];

class _LeadFormScreenState extends ConsumerState<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentName;
  String _studentClass = _classes.first;
  late final TextEditingController _currentSchool;
  late final TextEditingController _parentName;
  late final TextEditingController _parentNumber;
  late final TextEditingController _address;
  late final TextEditingController _location;
  late final TextEditingController _notes;
  String _status = 'NEW';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _studentName = TextEditingController(text: e?.studentName ?? '');
    _studentClass = e?.studentClass ?? _classes.first;
    _currentSchool = TextEditingController(text: e?.currentSchool ?? '');
    _parentName = TextEditingController(text: e?.parentName ?? '');
    _parentNumber = TextEditingController(text: e?.parentNumber ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _status = e?.status ?? 'NEW';
  }

  @override
  void dispose() {
    _studentName.dispose();
    _currentSchool.dispose();
    _parentName.dispose();
    _parentNumber.dispose();
    _address.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(leadsRepoProvider);
      final session = ref.read(authControllerProvider)!;
      if (widget.existing == null) {
        await repo.create(
          teacherId: session.teacherId,
          studentName: _studentName.text,
          studentClass: _studentClass,
          parentName: _parentName.text,
          parentNumber: _parentNumber.text,
          currentSchool: _currentSchool.text,
          address: _address.text,
          location: _location.text,
          notes: _notes.text,
        );
      } else {
        final l = widget.existing!
          ..studentName = _studentName.text.trim()
          ..studentClass = _studentClass
          ..currentSchool = _currentSchool.text.trim().isEmpty
              ? null
              : _currentSchool.text.trim()
          ..parentName = _parentName.text.trim()
          ..parentNumber = _parentNumber.text.trim()
          ..address = _address.text.trim().isEmpty ? null : _address.text.trim()
          ..location =
              _location.text.trim().isEmpty ? null : _location.text.trim()
          ..notes = _notes.text.trim().isEmpty ? null : _notes.text.trim()
          ..status = _status;
        await repo.update(l);
      }
      // Kick a sync without blocking the UI.
      // ignore: unawaited_futures
      ref.read(syncEngineProvider).run();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addReminder() async {
    final existing = widget.existing;
    if (existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Save the lead first before adding a reminder.')),
      );
      return;
    }
    await showReminderDialog(context, ref, lead: existing);
  }

  Future<void> _delete() async {
    final l = widget.existing;
    if (l == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete lead?'),
        content: Text(
            'This will remove ${l.studentName} locally. Server deletion syncs later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(leadsRepoProvider).delete(l.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit lead' : 'New lead'),
        actions: [
          if (isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _studentName,
              decoration: const InputDecoration(
                labelText: 'Student name *',
                border: OutlineInputBorder(),
              ),
              validator: _req,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _studentClass,
              decoration: const InputDecoration(
                labelText: 'Class *',
                border: OutlineInputBorder(),
              ),
              items: _classes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _studentClass = v ?? _classes.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentSchool,
              decoration: const InputDecoration(
                labelText: 'Current school',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentName,
              decoration: const InputDecoration(
                labelText: 'Parent name *',
                border: OutlineInputBorder(),
              ),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _parentNumber,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Parent phone *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Enter a valid phone'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location / locality',
                border: OutlineInputBorder(),
              ),
            ),
            if (isEdit) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('New')),
                  DropdownMenuItem(
                      value: 'CONTACTED', child: Text('Contacted')),
                  DropdownMenuItem(
                      value: 'INTERESTED', child: Text('Interested')),
                  DropdownMenuItem(value: 'ENROLLED', child: Text('Enrolled')),
                  DropdownMenuItem(value: 'LOST', child: Text('Lost')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'NEW'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Save changes' : 'Save lead'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _addReminder,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Reminder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
}
