part of 'links_screen.dart';

/// Turns the notes and links streams into a [GraphLayout], off the UI thread
/// for large projects.
extension _LinksGraphData on _LinksScreenState {
  void _setProject(String? projectId) {
    if (_projectId != projectId) {
      _projectId = projectId;
      _notesSource = null;
      _linksSource = null;
      _input = null;
      _pending = null;
      _layout = null;
      _layoutError = false;
      _selected = null;
      _fittedFor = null;
    }
  }

  // Project only after a stream emission, not on selection/zoom/theme rebuilds.
  // Content-only writes produce the same projection and retain the layout.
  void _updateGraph(List<Note> notes, List<NoteLink> links) {
    final notesChanged = !identical(notes, _notesSource);
    final linksChanged = !identical(links, _linksSource);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final generalLabel = context.l10n.clusterGeneral;
    if (!notesChanged && !linksChanged && _input?.rtl == rtl && _input?.generalLabel == generalLabel) return;
    _notesSource = notes;
    _linksSource = links;
    final input = GraphInput(
      notesChanged
          ? [
              for (final n in notes)
                (
                  id: n.id,
                  title: n.title,
                  cluster: n.cluster,
                  createdAt: n.createdAt.microsecondsSinceEpoch,
                  status: n.status.index,
                ),
            ]
          : _input!.notes,
      linksChanged
          ? [for (final l in links) (sourceId: l.sourceId, targetId: l.targetId, label: l.label, strength: l.strength)]
          : _input!.links,
      rtl: rtl,
      generalLabel: generalLabel,
    );
    if (_input?.sameData(input) ?? false) return;
    _input = input;
    _layoutError = false;
    if (input.notes.length > 300 || (input.notes.length > GraphLayout.smallProjectLimit && input.links.length > 600)) {
      // An empty layout is not a useful placeholder for the first large graph.
      if ((_layout?.readyCount ?? 0) < 2) _layout = null;
      // One worker at a time; replace queued work with the latest emission.
      _pending = input;
      if (!_workerRunning) unawaited(_computePending());
    } else {
      _pending = null;
      _acceptLayout(GraphLayout.fromInput(input));
    }
  }

  void _acceptLayout(GraphLayout layout) {
    _layout = layout;
    if (!layout.nodes.containsKey(_selected)) _selected = null;
  }

  Future<void> _computePending() async {
    _workerRunning = true;
    try {
      while (_pending != null) {
        final input = _pending!;
        _pending = null;
        try {
          final layout = await compute(GraphLayout.fromInput, input, debugLabel: 'links-layout');
          if (!mounted) return;
          // Never install an obsolete layout, including after a project switch.
          if (identical(input, _input)) _setState(() => _acceptLayout(layout));
        } catch (_) {
          if (!mounted) return;
          if (identical(input, _input)) _setState(() => _layoutError = true);
        }
      }
    } finally {
      _workerRunning = false;
    }
  }
}
