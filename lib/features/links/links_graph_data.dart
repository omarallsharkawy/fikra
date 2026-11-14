part of 'links_screen.dart';

/// Turns the notes and links streams into a [GraphLayout], off the UI thread
/// for large projects.
extension _LinksGraphData on _LinksScreenState {
  void _setProject(String? projectId) {
    if (_projectId != projectId) {
      _cancelHold?.call();
      _pointers.clear();
      _travel.stop();
      _searchOpen = false;
      _search.clear();
      _searchIndex = null;
      _pendingJump = null;
      _installedInput = null;
      _chipGroup = null;
      _collapsed = projectId == null ? {} : ref.read(graphCollapsedGroupsProvider).putIfAbsent(projectId, () => {});
      _projectId = projectId;
      _notesSource = null;
      _linksSource = null;
      _groupsSource = null;
      _selection = null;
      _input = null;
      _pending = null;
      _layout = null;
      _edgePaths = null;
      _layoutError = false;
      _selected = null;
      _fittedFor = null;
    }
  }

  // Project only after a stream emission, not on selection/zoom/theme rebuilds.
  // Content-only writes produce the same projection and retain the layout.
  void _updateGraph(List<Note> notes, List<NoteLink> links, List<NoteGroup> groups) {
    final groupIds = groups.map((g) => g.id).toSet();
    _collapsed.removeWhere((id) => !groupIds.contains(id));
    if (!groupIds.contains(_chipGroup)) _chipGroup = null;
    final notesChanged = !identical(notes, _notesSource);
    final groupsChanged = !identical(groups, _groupsSource);
    final linksChanged = !identical(links, _linksSource);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final headerExtent = GraphLayout.headerHeight * math.max(1, MediaQuery.textScalerOf(context).scale(14) / 14);
    final generalLabel = context.l10n.clusterGeneral;
    final scaler = MediaQuery.textScalerOf(context);
    final style = context.text.chip;
    final labelStyle = Object.hash(
      style,
      context.text.section,
      scaler,
      rtl,
      generalLabel,
      DefaultTextStyle.of(context).style,
      MediaQuery.boldTextOf(context),
      Localizations.localeOf(context),
    );

    if (!notesChanged &&
        !linksChanged &&
        !groupsChanged &&
        _input?.rtl == rtl &&
        _input?.generalLabel == generalLabel &&
        _input?.headerExtent == headerExtent &&
        _labelStyle == labelStyle &&
        setEquals(_input?.collapsedGroups, _collapsed)) {
      return;
    }
    _labelStyle = labelStyle;
    _notesSource = notes;
    _linksSource = links;
    _groupsSource = groups;
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
          ? [
              for (final l in links)
                if (!l.dismissed)
                  (
                    id: l.id,
                    sourceId: l.sourceId,
                    targetId: l.targetId,
                    label: l.label,
                    strength: l.strength,
                    isUser: l.origin == LinkOrigin.user,
                  ),
            ]
          : _input!.links,
      groups: [
        for (final g in groups) (id: g.id, parentId: g.parentId, name: g.name, color: g.color, position: g.position),
      ],
      collapsedGroups: Set.of(_collapsed),
      memberships: {
        for (final n in notes)
          if (n.groupId != null) n.id: n.groupId!,
      },
      labelSizes: {
        for (final name in notes.map((n) => n.cluster?.trim().isNotEmpty == true ? n.cluster! : generalLabel).toSet())
          name: _measureGraphText(name, style, 264),
      },
      suggestedSize: _measureGraphText(context.l10n.suggestedTopics, context.text.section, 320),
      headerExtent: headerExtent,
      rtl: rtl,
      generalLabel: generalLabel,
    );
    if (_input?.sameData(input) ?? false) return;
    _input = input;
    if (_searchOpen || notesChanged || linksChanged || groupsChanged) _searchIndex = GraphSearchIndex(input);
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
    _keepReadingStart(_layout, layout);
    _installedInput = _input;
    _layout = layout;
    _edgePaths = GraphEdgePaths(layout, previous: _edgePaths);
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
