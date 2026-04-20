import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers.dart';
import 'lead_form_screen.dart';

class LeadsListScreen extends ConsumerStatefulWidget {
  const LeadsListScreen({super.key});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen> {
  late Future<List<Lead>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = ref.read(leadsRepoProvider).list();
    });
  }

  Future<void> _retrySync() async {
    await ref.read(syncEngineProvider).run();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _retrySync();
      },
      child: FutureBuilder<List<Lead>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final leads = snap.data ?? const [];
          if (leads.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                    child: Text('No leads yet. Tap + to capture your first.')),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: leads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _LeadTile(
              lead: leads[i],
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LeadFormScreen(existing: leads[i]),
                  ),
                );
                _refresh();
              },
              onRetry: _retrySync,
            ),
          );
        },
      ),
    );
  }
}

class _LeadTile extends StatelessWidget {
  const _LeadTile(
      {required this.lead, required this.onTap, required this.onRetry});

  final Lead lead;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text('${lead.studentName} — ${lead.studentClass}'),
      subtitle: Text(
          '${lead.parentName} • ${lead.parentNumber}\n${lead.location ?? ''}'
              .trim()),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SyncBadge(status: lead.syncStatus),
          if (lead.syncStatus == SyncStatus.failed)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (status) {
      case SyncStatus.synced:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Synced';
        break;
      case SyncStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        label = 'Pending';
        break;
      case SyncStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        label = 'Failed';
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
