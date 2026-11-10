part of 'links_screen.dart';

/// Leaving the graph: open a note, or pick one from a cluster sheet.
extension _LinksNavigation on _LinksScreenState {
  /// Opens a note, handing over the full row when the graph still has it so
  /// the details screen draws it on its first frame.
  void _openNote(String id) {
    Note? full;
    for (final n in _notesSource ?? const <Note>[]) {
      if (n.id == id) {
        full = n;
        break;
      }
    }
    context.push('/note/$id', extra: full);
  }

  Future<void> _showCluster(GraphRow row) => showFikraSheet<void>(
    context,
    title: row.cluster,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.55,
      child: ListView.builder(
        itemExtent: 64,
        itemCount: row.notes.length,
        itemBuilder: (context, index) {
          final note = row.notes[index];
          return ListTile(
            title: Text(
              _graphTitle(context, note),
              style: context.text.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              _openNote(note.id);
            },
          );
        },
      ),
    ),
  );

  Future<void> _showMoreClusters(GraphLayout layout) async {
    final row = await showFikraSheet<GraphRow>(
      context,
      title: context.l10n.moreGroups,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.55,
        child: ListView.builder(
          itemExtent: 72,
          itemCount: layout.hiddenRows.length,
          itemBuilder: (context, index) {
            final row = layout.hiddenRows[index];
            return ListTile(
              title: Text(row.cluster, style: context.text.body, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(Fmt.notes(context.l10n, row.notes.length), style: context.text.meta),
              onTap: () => Navigator.pop(sheetContext, row),
            );
          },
        ),
      ),
    );
    if (mounted && row != null) await _showCluster(row);
  }
}
