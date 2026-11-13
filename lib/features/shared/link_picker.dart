import 'dart:math' as math;

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import 'note_links.dart';
import 'note_presentation.dart';

part 'link_picker_layout.dart';
part 'link_picker_row.dart';

/// Smallest list height before the picker form scrolls as a whole.
const _minListHeight = 120.0;

/// Opens the multi-select sheet that links [source] to other notes of its own
/// project, then shows how many were linked. Completes when the sheet closes.
Future<void> showLinkPicker(BuildContext context, {required Note source}) async {
  final l10n = context.l10n;
  final linked = await showFikraSheet<int>(
    context,
    title: l10n.linkToNote,
    tall: true,
    builder: (_) => LinkPickerSheet(source: source),
  );
  if (linked != null && context.mounted) showToast(context, l10n.notesLinked(linked));
}

/// The picker's content: search, newest-first lazy list with checkmarks, an
/// optional reason and one confirm button. Pops with the number of new links.
/// Notes you already linked can't be picked; a suggestion can, and becomes yours.
class LinkPickerSheet extends ConsumerStatefulWidget {
  const LinkPickerSheet({super.key, required this.source});
  final Note source;

  /// How many times a picker rebuilt its candidates and link states from the
  /// streams. A keystroke only filters, so tests check this stays put.
  @visibleForTesting
  static int derivations = 0;

  @override
  ConsumerState<LinkPickerSheet> createState() => _LinkPickerSheetState();
}

class _LinkPickerSheetState extends ConsumerState<LinkPickerSheet> {
  final _search = TextEditingController();
  final _reason = TextEditingController();
  final _picked = <String>{};
  String _query = '';
  bool _busy = false;
  bool _failed = false;

  // Lower-cased title and text per note, rebuilt only when either changes.
  final _haystacks = <String, (String, String, String)>{};

  // Derived from the two streams; rebuilt only when either emits.
  List<Note>? _notes;
  List<NoteLink>? _links;
  List<Note> _candidates = const [];
  Map<String, Note> _byId = const {};
  Map<String, LinkOrigin> _origins = const {};

  // The filtered list, rebuilt when the query or the candidates change.
  String? _shownQuery;
  List<Note>? _shownFrom;
  List<Note> _shown = const [];

  void _derive(List<Note> notes, List<NoteLink> links) {
    if (identical(notes, _notes) && identical(links, _links)) return;
    LinkPickerSheet.derivations++;
    _notes = notes;
    _links = links;
    _candidates = [
      for (final n in notes)
        if (n.id != widget.source.id) n,
    ];
    _byId = {for (final n in _candidates) n.id: n};
    _origins = {for (final e in linksOfNote(widget.source.id, links, _byId)) e.other.id: e.link.origin};
    if (_haystacks.length > _candidates.length * 2) _haystacks.removeWhere((id, _) => !_byId.containsKey(id));
  }

  List<Note> _filter(String query) {
    if (query == _shownQuery && identical(_candidates, _shownFrom)) return _shown;
    _shownQuery = query;
    _shownFrom = _candidates;
    return _shown = query.isEmpty
        ? _candidates
        : [
            for (final n in _candidates)
              if (_haystack(n).contains(query)) n,
          ];
  }

  @override
  void dispose() {
    _search.dispose();
    _reason.dispose();
    super.dispose();
  }

  String _haystack(Note n) {
    final cached = _haystacks[n.id];
    if (cached != null && cached.$1 == n.title && cached.$2 == n.displayText) return cached.$3;
    final h = '${n.title}\n${n.displayText}'.toLowerCase();
    _haystacks[n.id] = (n.title, n.displayText, h);
    return h;
  }

  void _toggle(String id) {
    if (_busy) return;
    setState(() => _picked.contains(id) ? _picked.remove(id) : _picked.add(id));
  }

  Future<void> _confirm(List<String> ids) async {
    if (_busy || ids.isEmpty) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final route = ModalRoute.of(context);
    try {
      final linked = await ref.read(linksRepoProvider).linkNotes(widget.source.id, ids, label: _reason.text);
      // Dismissed while saving: the sheet is already closing, and popping now
      // would close the page under it. The links are saved either way.
      if (mounted && (route?.isCurrent ?? false)) Navigator.pop(context, linked.length);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.source.projectId;
    final notesAsync = ref.watch(notesOfProjectProvider(projectId));
    final linksAsync = ref.watch(linksOfProjectProvider(projectId));
    final failed = (notesAsync.hasError && !notesAsync.hasValue) || (linksAsync.hasError && !linksAsync.hasValue);
    final ready = notesAsync.hasValue && linksAsync.hasValue;

    _derive(notesAsync.value ?? const <Note>[], linksAsync.value ?? const <NoteLink>[]);
    final candidates = _candidates;
    final byId = _byId;
    final origins = _origins;
    final shown = _filter(_query.trim().toLowerCase());
    // A pick that vanished or became your link meanwhile no longer counts.
    final ids = [
      for (final id in _picked)
        if (byId.containsKey(id) && origins[id] != LinkOrigin.user) id,
    ];

    final Widget list;
    if (failed) {
      list = _PickerMessage(text: context.l10n.noteLinksLoadFailed);
    } else if (!ready) {
      list = const SizedBox.shrink();
    } else if (candidates.isEmpty) {
      list = _PickerMessage(icon: Icons.notes_rounded, text: context.l10n.linkPickerEmpty);
    } else if (shown.isEmpty) {
      list = _PickerMessage(
        icon: Icons.search_off_rounded,
        title: context.l10n.noResultsTitle,
        text: context.l10n.noResultsBody(_query.trim()),
      );
    } else {
      list = ListView.builder(
        key: const ValueKey('link-picker-list'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: shown.length,
        itemBuilder: (context, i) {
          final n = shown[i];
          return _PickRow(
            key: ValueKey('link-pick-${n.id}'),
            note: n,
            origin: origins[n.id],
            picked: _picked.contains(n.id),
            onTap: _busy || origins[n.id] == LinkOrigin.user ? null : () => _toggle(n.id),
          );
        },
      );
    }

    final top = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FikraField(
          key: const ValueKey('link-search'),
          controller: _search,
          hint: context.l10n.searchNotesHint,
          icon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
      ],
    );
    final bottom = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        LinkReasonField(controller: _reason),
        if (_failed) ...[
          const SizedBox(height: 8),
          StatusBanner(kind: BannerKind.error, message: context.l10n.linkFailed),
        ],
        const SizedBox(height: 12),
        FikraButton(
          key: const ValueKey('link-confirm'),
          label: context.l10n.linkSelected(ids.length),
          icon: Icons.link_rounded,
          loading: _busy,
          onPressed: ids.isEmpty ? null : () => _confirm(ids),
        ),
      ],
    );
    // The list takes the room the controls leave. When that is less than a
    // usable list (short screen, keyboard, large text, error banner), the
    // whole form scrolls instead of overflowing.
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        key: const ValueKey('link-picker-form'),
        child: _PickerLayout(height: box.maxHeight, minListHeight: _minListHeight, children: [top, list, bottom]),
      ),
    );
  }
}
