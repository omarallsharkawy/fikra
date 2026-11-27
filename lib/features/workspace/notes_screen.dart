import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_search.dart';
import '../../core/widgets/navigation_inset.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../data/product/models.dart';
import '../../l10n/localizations.dart';
import '../account/profile_name_sheet.dart';
import 'idea_card.dart';
import 'product_widgets.dart';

String rdNoteTitle(BuildContext context, String? title, String content) {
  final value = title?.trim();
  if (value != null &&
      value.isNotEmpty &&
      !RegExp('placeholder|no substantive', caseSensitive: false).hasMatch(value)) {
    return value;
  }
  return content.trim().split('\n').firstOrNull?.trim().isNotEmpty == true
      ? content.trim().split('\n').first.trim()
      : context.l10n.rdUntitled;
}

class ProductNotesScreen extends StatefulWidget {
  const ProductNotesScreen({super.key});
  @override
  State<ProductNotesScreen> createState() => _ProductNotesScreenState();
}

class _ProductNotesScreenState extends State<ProductNotesScreen> {
  Timer? _search;
  String? _tag;
  bool _promptScheduled = false, _showPrompt = false;
  void _namePrompt(ProductRuntime r) {
    if (_promptScheduled || !r.profile.needsNamePrompt) return;
    _promptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !r.profile.needsNamePrompt) return;
      setState(() => _showPrompt = true);
      await r.profile.claimNamePrompt();
    });
  }

  @override
  void dispose() {
    _search?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.profile, r.tags],
    builder: (context, r) {
      final w = r.workspace, l = context.l10n;
      _namePrompt(r);
      if (_tag != null && !r.tags.tags.any((t) => t.id == _tag)) _tag = null;
      final greeting = r.profile.name == null ? l.rdNeutralGreeting : l.rdGreet(rdIsolate(r.profile.name!));
      final empty = !w.loading && w.failure == null && w.notes.isEmpty && w.results == null;
      final children = <Widget>[
        if (_showPrompt && r.profile.name == null)
          RdCard(
            ai: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                RdText(l.rdNamePrompt, weight: FontWeight.w600),
                Row(
                  children: [
                    Expanded(
                      child: RdButton(
                        l.rdAddName,
                        onPressed: () async {
                          await editProfileName(context, r.profile);
                          if (mounted && r.profile.name != null) setState(() => _showPrompt = false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => setState(() => _showPrompt = false), child: Text(l.rdLater)),
                  ],
                ),
              ],
            ),
          ),
        if (r.tags.failure != null)
          ProductFailureView(r.tags.failure!, onRetry: () => r.tags.bind(r.session.account?.id)),
        if (r.profile.failure != null)
          ProductFailureView(
            r.profile.failure!,
            onRetry: () => r.profile.bind(r.session.account?.id, r.session.account?.email ?? ''),
          ),
        if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
        if (w.loading)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (empty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.rd.purpleSoft, borderRadius: BorderRadius.circular(18)),
                  child: RdIcon('spark', color: context.rd.purple),
                ),
                const SizedBox(height: 10),
                RdText(l.rdFirst, size: 19, weight: FontWeight.w700, align: TextAlign.center),
                const SizedBox(height: 4),
                RdText(l.rdFl, color: context.rd.muted, align: TextAlign.center),
                const SizedBox(height: 16),
                RdButton(l.rdStart, full: false, onPressed: () => context.go('/add')),
              ],
            ),
          ),
        if (!empty) ...[
          RdSearch(
            key: ValueKey('search-${w.selectedProjectId}'),
            value: w.query,
            label: l.rdSearch,
            onChanged: (v) {
              w.query = v;
              _search?.cancel();
              final project = w.selectedProjectId;
              _search = Timer(
                const Duration(milliseconds: 350),
                () => project == w.selectedProjectId ? w.search(v) : null,
              );
            },
            onSubmitted: (v) {
              _search?.cancel();
              w.search(v);
            },
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              spacing: 8,
              children: [
                RdChip(l.rdAll, selected: _tag == null, onPressed: () => setState(() => _tag = null)),
                for (final t in r.tags.tags)
                  RdChip(t.label, selected: _tag == t.id, onPressed: () => setState(() => _tag = t.id)),
              ],
            ),
          ),
          if (w.searchFailure != null) ProductFailureView(w.searchFailure!, onRetry: () => w.search(w.query)),
          if (w.searching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ..._notes(context, r),
        ],
        if (ProductEnvironment.previewOf(context)) const DevelopmentBanner(),
      ];
      return RdPage(
        title: greeting,
        header: empty ? const SizedBox.shrink() : null,
        body: RefreshIndicator(
          onRefresh: w.retryWorkspace,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + NavigationInset.of(context)),
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: children,
          ),
        ),
      );
    },
  );
  List<Widget> _notes(BuildContext context, ProductRuntime r) {
    final w = r.workspace, l = context.l10n;
    final results = w.results;
    if (results != null) {
      final values = results
          .where((n) => _tag == null || r.tags.assignments[n.noteId]?.contains(_tag) == true)
          .toList();
      return [
        if (values.isEmpty && !w.searching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
            child: RdText(l.rdNone, color: context.rd.muted, align: TextAlign.center),
          ),
        for (final n in values)
          ProductIdeaCard(
            key: ValueKey('product-note-${n.noteId}'),
            title: rdNoteTitle(context, n.title, n.content),
            content: n.content,
            tags: r.tags.forNote(n.noteId),
            onOpen: () => context.push('/note/${n.noteId}'),
          ),
      ];
    }
    final now = DateTime.now();
    bool today(KnowledgeNote n) {
      final d = n.createdAt.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }

    final values = w.notes.where((n) => _tag == null || r.tags.assignments[n.id]?.contains(_tag) == true).toList();
    return [
      if (values.isEmpty && !w.loading)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 8),
          child: RdText(l.rdNone, color: context.rd.muted, align: TextAlign.center),
        ),
      for (final isToday in [true, false]) ...[
        if (values.any((n) => today(n) == isToday)) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(2, isToday || !values.any(today) ? 12 : 2, 2, 8),
            child: RdText(isToday ? l.rdToday : l.rdEarlier, size: 13, color: context.rd.muted),
          ),
          for (final n in values.where((n) => today(n) == isToday))
            ProductIdeaCard(
              key: ValueKey('product-note-${n.id}'),
              title: rdNoteTitle(context, n.title, n.content),
              content: n.content,
              tags: r.tags.forNote(n.id),
              processing: n.processing.pending,
              onOpen: () => context.push('/note/${n.id}'),
            ),
        ],
      ],
    ];
  }
}
