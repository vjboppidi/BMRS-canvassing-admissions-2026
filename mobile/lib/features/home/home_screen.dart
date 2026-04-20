import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../sync/sync_engine.dart';
import '../highlights/highlights_screen.dart';
import '../leads/lead_form_screen.dart';
import '../leads/leads_list_screen.dart';
import '../reminders/reminders_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Kick off the sync engine once we have a session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncEngineProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider);
    const pages = [
      LeadsListScreen(),
      RemindersScreen(),
      HighlightsScreen(),
    ];
    const titles = ['My leads', 'Reminders', 'School Highlights'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          _SyncStatusIcon(),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              ref.read(syncEngineProvider).stop();
              await ref.read(authControllerProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (session != null)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Signed in as ${session.name} (${session.role.toLowerCase()})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(child: pages[_index]),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const LeadFormScreen()),
                );
                setState(() {}); // refresh list on return
              },
              icon: const Icon(Icons.person_add),
              label: const Text('New lead'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.people_alt_outlined), label: 'Leads'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined), label: 'Reminders'),
          NavigationDestination(
              icon: Icon(Icons.school_outlined), label: 'Highlights'),
        ],
      ),
    );
  }
}

class _SyncStatusIcon extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(syncEngineProvider);
    return StreamBuilder<SyncOutcome>(
      stream: engine.onSync,
      builder: (ctx, snap) {
        IconData icon = Icons.cloud_outlined;
        Color color = Colors.grey;
        String tooltip = 'Tap to sync';
        final o = snap.data;
        if (o != null) {
          if (o.isOffline) {
            icon = Icons.cloud_off;
            color = Colors.orange;
            tooltip = 'Offline — queued locally';
          } else if (o.isCompleted) {
            icon = (o.leadsFailed + o.remindersFailed) > 0
                ? Icons.cloud_sync
                : Icons.cloud_done;
            color = (o.leadsFailed + o.remindersFailed) > 0
                ? Colors.redAccent
                : Colors.green;
            tooltip = 'Leads ${o.leadsSynced} ok / ${o.leadsFailed} failed';
          }
        }
        return IconButton(
          icon: Icon(icon, color: color),
          tooltip: tooltip,
          onPressed: () => engine.run(),
        );
      },
    );
  }
}
