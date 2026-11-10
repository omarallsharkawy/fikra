# Shared

## Overview

Display helpers for notes that are used by more than one feature.

## Interface

- `note_presentation.dart`
  - `IconData sourceIcon(NoteSource s)`: icon for one note source. Currently called only inside this file.
  - `List<IconData> sourceIcons(Note n)`: every source of a note.
  - `String noteTitle(BuildContext context, Note n)`: the note's title, or a fallback label when the title is blank.
- `open_attachment.dart`
  - `Future<void> openAttachment(BuildContext context, WidgetRef ref, String path)`: opens a file in another app, and shows a toast if it returns false or throws. Used for photos and the PDF viewer’s explicit open-elsewhere action.

## Invariants

- `sourceIcons` always returns at least one icon, in the order PDF, voice, photos. `sourceIcon(n.source)` is used only when the note has no attachment.
- `noteTitle` checks the trimmed title for blankness but returns the untrimmed title.
- `links_screen.dart` in [links](../links/EGM.md) has a private `_graphTitle` with the same fallback text, because `GraphNote` is not a `Note`. Change both together.

## Side Effects

- `openAttachment` starts another app through `fileOpenerProvider`. Everything else here is pure.

## Localization

`noteTitle(BuildContext context, Note n)` resolves only the blank-title fallback using `context.l10n`. `openAttachment` uses the localized open-file failure; stored file names and titles are returned unchanged.

## Verification

- Run: `flutter analyze && flutter test`
