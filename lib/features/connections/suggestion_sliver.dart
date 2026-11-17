import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'link_pair_busy.dart';
import 'links_index.dart';
import 'suggestion_card.dart';

/// Retain removed snapshots just long enough for only that row to fade/collapse.
/// List children stay lazy; unrelated cards have no animation controller. A
/// pair whose accept/reject already succeeded starts leaving at once, before
/// the re-derived list arrives.
class SuggestionSliver extends ConsumerStatefulWidget {
  const SuggestionSliver({super.key, required this.entries, this.empty, this.here});
  final List<SuggestionEntry> entries;
  final Widget? empty;

  /// See [SuggestionCard.here].
  final String? here;

  @override
  ConsumerState<SuggestionSliver> createState() => _SuggestionSliverState();
}

class _SuggestionSliverState extends ConsumerState<SuggestionSliver> {
  var _rows = <SuggestionEntry>[];
  final _leaving = <String>{};
  final _timers = <String, Timer>{};
  List<SuggestionEntry>? _entries;
  Map<String, bool>? _locks;
  String _key(SuggestionEntry e) => pairKey(e.a.id, e.b.id);

  void _sync(List<SuggestionEntry> entries, Map<String, bool> locks) {
    final next = {
      for (final e in entries)
        if (locks['${e.a.projectId}:${_key(e)}'] != true) _key(e): e,
    };
    if (_entries == null) {
      _rows = next.values.toList();
      return;
    }
    for (final e in _rows) {
      final key = _key(e);
      if (!next.containsKey(key) && _leaving.add(key)) {
        final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220);
        _timers[key] = Timer(duration, () {
          _timers.remove(key);
          if (!mounted || !_leaving.remove(key)) return;
          setState(() => _rows.removeWhere((e) => _key(e) == key));
        });
      }
    }
    for (final key in next.keys) {
      if (_leaving.remove(key)) _timers.remove(key)?.cancel();
    }
    // A leaving row stays after its nearest surviving predecessor, so a second
    // removal mid-collapse never moves an earlier one to the top.
    final after = <String?, List<SuggestionEntry>>{};
    String? anchor;
    for (final e in _rows) {
      final key = _key(e);
      if (next.containsKey(key)) {
        anchor = key;
      } else if (_leaving.contains(key)) {
        (after[anchor] ??= []).add(e);
      }
    }
    _rows = [
      ...?after[null],
      for (final e in next.values) ...[e, ...?after[_key(e)]],
    ];
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
    final locks = ref.watch(linkPairBusyProvider);
    if (!identical(widget.entries, _entries) || !identical(locks, _locks)) {
      _sync(widget.entries, locks);
      _entries = widget.entries;
      _locks = locks;
    }
    if (_rows.isEmpty && widget.empty != null) return SliverToBoxAdapter(child: widget.empty);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final indices = {for (final (i, e) in _rows.indexed) _key(e): i};
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final e = _rows[i], key = _key(e);
          return _CollapsingSuggestion(
            key: ValueKey(key),
            leaving: _leaving.contains(key),
            reduced: reduced,
            child: SuggestionCard(entry: e, here: widget.here),
          );
        },
        childCount: _rows.length,
        findChildIndexCallback: (key) => key is ValueKey<String> ? indices[key.value] : null,
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
