import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../providers.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  late Future<List<Reminder>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(remindersRepoProvider).list();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reminder>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No reminders yet.'));
        }
        final fmt = DateFormat.yMMMEd().add_jm();
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = items[i];
            return ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(fmt.format(r.remindAt.toLocal())),
              subtitle: Text(r.note ?? '(no note)'),
              trailing: Text(
                r.status,
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }
}
