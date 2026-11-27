import '../../core/widgets/smart_text.dart';
import '../../l10n/localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../data/product/models.dart';
import 'notes_screen.dart' show rdNoteTitle;
import 'product_widgets.dart';
import 'note_graph.dart';

export 'note_graph.dart' show ProductNoteGraph;

class ProductGraphScreen extends ConsumerStatefulWidget {
  const ProductGraphScreen({super.key});
  @override
  ConsumerState<ProductGraphScreen> createState() => _ProductGraphScreenState();
}

class _ProductGraphScreenState extends ConsumerState<ProductGraphScreen> {
  ProductRuntime? _runtime;
  String? _project;
  int _revision = -1;
  bool _coach = true;
  @override
  void initState() {
    super.initState();
    _runtime = ref.read(productRuntimeProvider);
    _runtime!.workspace.addListener(_changed);
    _changed();
    unawaited(_loadCoach());
  }

  Future<void> _loadCoach() async {
    final account = _runtime!.workspace.accountId;
    if (account == null) return;
    try {
      final record = await ref.read(productLocalUiProvider).read('account:$account');
      if (mounted && _runtime!.workspace.accountId == account) {
        setState(() => _coach = record['map_coach_seen'] != true);
      }
    } catch (_) {
      /* A presentation preference must not block the graph. */
    }
  }

  Future<void> _dismissCoach() async {
    setState(() => _coach = false);
    final account = _runtime!.workspace.accountId;
    if (account == null) return;
    try {
      await ref.read(productLocalUiProvider).update('account:$account', (r) => r['map_coach_seen'] = true);
    } catch (_) {
      /* Retain this dismissal on the current screen. */
    }
  }

  void _changed() {
    final id = _runtime!.workspace.selectedProjectId;
    if (_project == id && _revision == _runtime!.workspace.knowledgeRevision) return;
    _project = id;
    _revision = _runtime!.workspace.knowledgeRevision;
    scheduleMicrotask(() {
      if (mounted) _runtime!.workspace.loadGraph();
    });
  }

  @override
  void dispose() {
    _runtime?.workspace.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.tags, r.undo],
    builder: (context, r) {
      final w = r.workspace, l = context.l10n;
      final nodes = w.graph.nodes.where((n) => !r.undo.hiddenIds.contains(n.id)).toList();
      final ids = nodes.map((n) => n.id).toSet();
      final graph = KnowledgeGraph(
        nodes: nodes,
        edges: w.graph.edges.where((e) => ids.contains(e.source) && ids.contains(e.target)).toList(),
      );
      return RdPage(
        title: l.rdMap,
        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width - 32) * .48),
          child: RdText(l.rdLinks(nodes.length, graph.edges.length), size: 13, color: context.rd.muted),
        ),
        children: [
          if (_coach)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: context.rd.purpleSoft, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: RdText(l.rdHint, size: 13)),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: context.rd.blue,
                      textStyle: RdTokens.style(context, size: 13),
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _dismissCoach,
                    child: SmartText(l.rdOk),
                  ),
                ],
              ),
            ),
          if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
          if (w.graphFailure != null) ProductFailureView(w.graphFailure!, onRetry: w.loadGraph),
          if (w.graphLoading && nodes.isEmpty)
            const RdCard(
              child: AspectRatio(aspectRatio: 1, child: Center(child: CircularProgressIndicator())),
            )
          else if (nodes.isEmpty && w.graphFailure == null)
            RdCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  spacing: 14,
                  children: [
                    RdIcon('map', size: 36, color: context.rd.muted),
                    RdText(l.productNoCompletedNotesInThisProjectYet, size: 19, align: TextAlign.center),
                    RdButton(l.rdStart, onPressed: () => context.push('/add')),
                    RdButton(l.productReloadMap, primary: false, onPressed: w.graphLoading ? null : w.loadGraph),
                  ],
                ),
              ),
            )
          else if (nodes.isNotEmpty) ...[
            if (w.graphLoading) const LinearProgressIndicator(minHeight: 2),
            ProductNoteGraph(
              key: ValueKey(w.selectedProjectId),
              graph: graph,
              categories: {for (final n in nodes) n.id: r.tags.forNote(n.id)},
              titles: {
                for (final n in nodes)
                  n.id: rdNoteTitle(context, n.title, w.notes.where((v) => v.id == n.id).firstOrNull?.content ?? ''),
              },
            ),
          ],
          if (graph.edges.length < 3 && nodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: RdText(l.rdFl, color: context.rd.muted, align: TextAlign.center),
            ),
        ],
      );
    },
  );
}
