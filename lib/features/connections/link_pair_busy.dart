import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'links_index.dart';
import 'links_library_provider.dart';

/// Locked pairs, shared across lazy recreation and every pushed presentation.
/// The value is true once the write succeeded: lists collapse that row at once
/// instead of waiting for the re-derive. The lock ends with the first snapshot
/// that no longer suggests the pair, or with the first one derived from a newer
/// links emission: if the pair is still a suggestion there, it shows again.
final linkPairBusyProvider = NotifierProvider<LinkPairBusy, Map<String, bool>>(LinkPairBusy.new);

class LinkPairBusy extends Notifier<Map<String, bool>> {
  final _jobs = <String, ({String project, String pair, Object? stale})>{};
  final _subscriptions = <String, ProviderSubscription<AsyncValue<LinksIndex>>>{};

  @override
  Map<String, bool> build() {
    ref.onDispose(() {
      for (final sub in _subscriptions.values) {
        sub.close();
      }
      _subscriptions.clear();
    });
    return const {};
  }

  bool claim(String key, {required String project, required String pair}) {
    if (state.containsKey(key)) return false;
    _jobs[key] = (project: project, pair: pair, stale: null);
    state = {...state, key: false};
    // A container-level listener: this notifier is paused while no card
    // watches it (Links tab hidden, page popped), and a paused `ref.listen`
    // would miss the emission that ends the lock. Closed with the last job.
    _subscriptions.putIfAbsent(
      project,
      () => ref.container.listen(linksLibraryProvider(project), (_, next) => _refresh(project, next)),
    );
    return true;
  }

  void finish(String key, {required bool success}) {
    if (!ref.mounted) return;
    final job = _jobs[key];
    if (job == null) return;
    if (!success) {
      _remove(key);
      return;
    }
    // Snapshots from this links list predate the write and still show the pair.
    _jobs[key] = (
      project: job.project,
      pair: job.pair,
      stale: ref.read(linksLibraryProvider(job.project)).value?.linksSource,
    );
    state = {...state, key: true};
    _refresh(job.project, ref.read(linksLibraryProvider(job.project)));
  }

  void _refresh(String project, AsyncValue<LinksIndex> source) {
    final index = source.value;
    if (index == null || !ref.mounted) return;
    final finished = [
      for (final e in _jobs.entries)
        if (e.value.project == project && state[e.key] == true) e,
    ];
    if (finished.isEmpty) return;
    final live = index.suggestionPairs;
    for (final e in finished) {
      if (!live.contains(e.value.pair) || !identical(index.linksSource, e.value.stale)) _remove(e.key);
    }
  }

  void _remove(String key) {
    final job = _jobs.remove(key);
    state = {...state}..remove(key);
    if (job != null && !_jobs.values.any((j) => j.project == job.project)) _subscriptions.remove(job.project)?.close();
  }
}
