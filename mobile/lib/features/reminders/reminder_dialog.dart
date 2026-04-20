import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers.dart';

/// Bottom-sheet dialog to create a follow-up reminder for a lead.
Future<void> showReminderDialog(
  BuildContext context,
  WidgetRef ref, {
  required Lead lead,
}) async {
  final noteCtl = TextEditingController();
  DateTime when = DateTime.now().add(const Duration(days: 3));
  when = DateTime(when.year, when.month, when.day, 10);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> pickWhen() async {
              final date = await showDatePicker(
                context: ctx,
                initialDate: when,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date == null) return;
              if (!ctx.mounted) return;
              final time = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.fromDateTime(when),
              );
              if (time == null) return;
              setState(() {
                when = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Follow up with ${lead.parentName}',
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remind me at'),
                  subtitle: Text(when.toLocal().toString()),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: pickWhen,
                ),
                TextField(
                  controller: noteCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final session = ref.read(authControllerProvider)!;
                    final repo = ref.read(remindersRepoProvider);
                    final r = await repo.create(
                      leadId: lead.id,
                      teacherId: session.teacherId,
                      remindAt: when,
                      note: noteCtl.text.trim().isEmpty
                          ? null
                          : noteCtl.text.trim(),
                    );
                    final notif = ref.read(notificationsProvider);
                    await notif.schedule(
                      id: r.id.hashCode,
                      title: 'Follow up: ${lead.studentName}',
                      body: noteCtl.text.trim().isEmpty
                          ? 'Reminder for ${lead.parentName}'
                          : noteCtl.text.trim(),
                      when: when,
                    );
                    // ignore: unawaited_futures
                    ref.read(syncEngineProvider).run();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Schedule reminder'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
