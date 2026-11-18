import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/stagger.dart';
import 'link_pair_busy.dart';
import 'links_index.dart';
import 'links_library_provider.dart';
import 'suggestion_card.dart';

/// Retain removed snapshots just long enough for only that row to fade/collapse.
/// List children stay lazy; unrelated cards have no animation controller. A
/// pair whose accept/reject already succeeded starts leaving at once, before
/// the re-derived list arrives.
class SuggestionSliver extends ConsumerStatefulWidget {
  const SuggestionSliver({super.key, required this.entries, this.empty, this.here, this.stagger});
  final List<SuggestionEntry> entries;
  final Widget? empty;

  /// See [SuggestionCard.here].
  final String? here;
  final StaggerController? stagger;

  @override
  ConsumerState<SuggestionSliver> createState() => _SuggestionSliverState();
}

class _SuggestionSliverState extends ConsumerState<SuggestionSliver> {
  var _rows = <String>[];
  final _available = <String, SuggestionEntry>{};
  final _busyPairs = <String, String>{};
  final _snapshots = <String, SuggestionEntry>{};
  final _leaving = <String>{};
  final _timers = <String, Timer>{};
  final _children = <String, Widget>{};
  Map<String, int> _indices = const {};
  List<SuggestionEntry>? _entries;
  bool? _reduced;
  String _key(SuggestionEntry e) => pairKey(e.a.id, e.b.id);

  void _index() => _indices = {for (final (i, key) in _rows.indexed) key: i};

  void _leave(String key) {
    if (!_snapshots.containsKey(key) || !_leaving.add(key)) return;
    _children.remove(key);
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220);
    _timers[key] = Timer(duration, () {
      _timers.remove(key);
      if (!mounted || !_leaving.remove(key)) return;
      setState(() {
        _rows.remove(key);
        _snapshots.remove(key);
        _children.remove(key);
        _index();
      });
    });
  }

  void _sync(Map<String, bool> locks) {
    _available.clear();
    _busyPairs.clear();
    for (final e in widget.entries) {
      final key = _key(e);
      _available[key] = e;
      _busyPairs['${e.a.projectId}:$key'] = key;
    }
    final next = {
      for (final e in _available.entries)
        if (locks['${e.value.a.projectId}:${e.key}'] != true) e.key: e.value,
    };
    for (final key in _rows) {
      if (!next.containsKey(key)) _leave(key);
    }
    for (final e in next.entries) {
      if (_leaving.remove(e.key)) {
        _timers.remove(e.key)?.cancel();
        _children.remove(e.key);
      }
      if (_snapshots[e.key] != e.value) _children.remove(e.key);
      _snapshots[e.key] = e.value;
    }
    // Retain each leaving row after its nearest surviving predecessor.
    final after = <String?, List<String>>{};
    String? anchor;
    for (final key in _rows) {
      if (next.containsKey(key)) {
        anchor = key;
      } else if (_leaving.contains(key)) {
        (after[anchor] ??= []).add(key);
      }
    }
    _rows = [
      ...?after[null],
      for (final key in next.keys) ...[key, ...?after[key]],
    ];
    _index();
  }

  void _locksChanged(Map<String, bool>? previous, Map<String, bool> next) {
    var changed = false;
    for (final e in next.entries) {
      if (!e.value || previous?[e.key] == true) continue;
      // Jobs are few; the cached pair map avoids a scan of every suggestion.
      final key = _busyPairs[e.key];
      if (key == null) continue;
      _leave(key);
      changed = true;
    }
    // A fresh snapshot can release the lock before the parent passes its new
    // entries. Only restore a still-live pair; stale props must not restart a
    // completed removal's 220 ms timer.
    final restore =
        previous?.entries.any((e) {
          final pair = _busyPairs[e.key];
          if (!e.value || next[e.key] == true || pair == null) return false;
          final project = _available[pair]!.a.projectId;
          final index = ref.read(linksLibraryProvider(project)).value;
          return index == null || index.suggestionPairs.contains(pair);
        }) ??
        false;
    if (restore) {
      _sync(next);
      changed = true;
    }
    if (changed) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SuggestionSliver old) {
    super.didUpdateWidget(old);
    if (old.here != widget.here || old.stagger != widget.stagger) _children.clear();
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Claim/failure changes only rebuild the affected card's selected busy bit.
    ref.listen(linkPairBusyProvider, _locksChanged);
    if (!identical(widget.entries, _entries)) {
      _sync(ref.read(linkPairBusyProvider));
      _entries = widget.entries;
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced != reduced) {
      _reduced = reduced;
      _children.clear();
    }
    if (_rows.isEmpty && widget.empty != null) return SliverToBoxAdapter(child: widget.empty);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final key = _rows[i];
          return _children.putIfAbsent(key, () {
            final card = SuggestionCard(entry: _snapshots[key]!, here: widget.here);
            return _CollapsingSuggestion(
              key: ValueKey(key),
              leaving: _leaving.contains(key),
              reduced: reduced,
              child: widget.stagger == null ? card : StaggeredEntry(stagger: widget.stagger!, itemId: key, child: card),
            );
          });
        },
        childCount: _rows.length,
        findChildIndexCallback: (key) => key is ValueKey<String> ? _indices[key.value] : null,
      ),
    );
  }
}

class _CollapsingSuggestion extends StatefulWidget {
  const _CollapsingSuggestion({super.key, required this.leaving, required this.reduced, required this.child});
  final bool leaving, reduced;
  final Widget child;

  @override
  State<_CollapsingSuggestion> createState() => _CollapsingSuggestionState();
}

class _CollapsingSuggestionState extends State<_CollapsingSuggestion> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1, duration: const Duration(milliseconds: 220));
  late final _curve = CurvedAnimation(parent: _controller, curve: Curves.linear);

  @override
  void initState() {
    super.initState();
    if (widget.leaving) _controller.value = 0;
  }

  @override
  void didUpdateWidget(covariant _CollapsingSuggestion old) {
    super.didUpdateWidget(old);
    if (widget.reduced) {
      _controller.value = widget.leaving ? 0 : 1;
    } else if (widget.leaving) {
      _controller.animateTo(0, curve: Curves.decelerate);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: widget.leaving,
    child: SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _curve, child: widget.child),
    ),
  );
}
