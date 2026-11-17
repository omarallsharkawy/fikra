part of 'links_screen.dart';

extension _LinksSurface on _LinksScreenState {
  Widget _navigationHeader(List<NoteGroup> groups) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Keep the normal header's measured height, including its wrapped form.
      Stack(
        children: [
          Visibility(
            visible: _selection == null,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: ProjectHeader(
              title: context.l10n.linksTitle,
              // Pushed at /links/graph: the default maybePop runs this page's
              // PopScope, so Back closes search/selection before leaving.
              leading: (ModalRoute.of(context)?.canPop ?? false) ? const BackButton() : null,
              trailing: HeaderActionButton(
                key: _selection == null ? const ValueKey('graph-search-open') : null,
                icon: Icons.search_rounded,
                label: context.l10n.headerSearch,
                semanticLabel: context.l10n.graphSearchHint,
                onTap: () => _setState(() {
                  _searchOpen = true;
                  _cancelHold?.call();
                }),
              ),
            ),
          ),
          if (_selection != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: SelectionHeader(count: _selection!.length, onClose: _endSelection),
              ),
            ),
        ],
      ),
      if (groups.isNotEmpty && !_searchOpen)
        GroupFilterRow(
          groups: groups,
          selectedId: _chipGroup,
          navigation: true,
          enabled: _selection == null && _navigationReady,
          onOptions: (g) => _groupOptions(g.id),
          onSelect: (id) {
            if (id == null || !_navigationReady) return;
            _chipGroup = id;
            _pickSearch(GraphSearchResult(GraphSearchKind.group, id, ''));
          },
        ),
    ],
  );

  Widget _surface(
    GraphLayout layout,
    List<Note> notes,
    List<NoteLink> links,
    GraphNote? selected,
    Map<String, String> reasons,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Viewport tools live above the graph, never on top of it.
      Padding(
        padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.linksSummary(
                  Fmt.notes(context.l10n, notes.length),
                  Fmt.links(context.l10n, layout.linkCount),
                ),
                style: context.text.meta.copyWith(fontSize: 12, color: context.colors.textSecondary),
                softWrap: true,
              ),
            ),
            FikraIconButton(icon: Icons.add_rounded, label: context.l10n.zoomIn, size: 40, onTap: () => _zoom(1.25)),
            FikraIconButton(icon: Icons.remove_rounded, label: context.l10n.zoomOut, size: 40, onTap: () => _zoom(0.8)),
            FikraIconButton(
              icon: Icons.center_focus_strong_outlined,
              label: context.l10n.resetView,
              size: 40,
              onTap: () {
                _travel.stop();
                _tc.value = _home();
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: Stack(
          children: [
            Positioned.fill(child: _graphCanvas(layout, layout.width, layout.height)),
            if (_selection == null && !_searchOpen)
              // Same box as the canvas viewport, measured in this layout pass:
              // the map is right on the first frame and after a height change.
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      PositionedDirectional(
                        bottom: links.isEmpty ? 88 : 12,
                        end: 12,
                        child: GraphMinimap(
                          layout: layout,
                          controller: _tc,
                          viewportSize: box.biggest,
                          // A focused preview can grow with system text; hide the map
                          // while it owns this corner's vertical space.
                          obscured: selected != null,
                          onMove: _centreViewportImmediately,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (links.isEmpty && selected == null && _selection == null)
              Positioned(
                left: FikraSpace.screen,
                right: FikraSpace.screen,
                bottom: 16,
                child: StatusBanner(kind: BannerKind.info, message: context.l10n.noLinksYet),
              ),
            if (_selection == null)
              Positioned(
                left: FikraSpace.screen,
                right: FikraSpace.screen,
                bottom: 12,
                child: FikraSwitcher(
                  animateSize: !FikraMotion.reduced(context),
                  alignment: Alignment.bottomCenter,
                  child: selected == null
                      ? const SizedBox.shrink(key: ValueKey('no-preview'))
                      : KeyedSubtree(
                          key: ValueKey(selected.id),
                          child: _NodePreview(
                            note: selected,
                            reasons: reasons.values.toList(),
                            onOpen: () => _openNote(selected.id),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
