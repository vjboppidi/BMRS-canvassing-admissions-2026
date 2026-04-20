import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../providers.dart';

class HighlightsScreen extends ConsumerStatefulWidget {
  const HighlightsScreen({super.key});

  @override
  ConsumerState<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends ConsumerState<HighlightsScreen> {
  late Future<List<Highlight>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Highlight>> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp =
          await api.dio.get<Map<String, dynamic>>('/school-highlights');
      final raw = (resp.data?['highlights'] as List?) ?? const [];
      return raw.cast<Map<String, dynamic>>().map(Highlight.fromJson).toList();
    } on DioException {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      child: FutureBuilder<List<Highlight>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Icon(Icons.school, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'No highlights loaded. Pull to refresh when online.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final h = items[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _KindIcon(kind: h.kind),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(h.title,
                                style: Theme.of(context).textTheme.titleMedium),
                          ),
                        ],
                      ),
                      if (h.body != null) ...[
                        const SizedBox(height: 8),
                        Text(h.body!),
                      ],
                      if (h.mediaUrl != null) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          h.mediaUrl!,
                          style: const TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      'achievement' => Icons.emoji_events,
      'photo' => Icons.photo_library,
      'testimonial' => Icons.format_quote,
      'video' => Icons.play_circle_outline,
      _ => Icons.info_outline,
    };
    return Icon(icon, color: Theme.of(context).colorScheme.primary);
  }
}
