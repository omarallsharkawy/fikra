# Data Layer

## Overview

The app's offline data layer. Abstract repositories define what the UI can do
with projects, notes, chat and settings, and the `Local*` implementations back
them with the Drift database and the attachment store. `lib/app/providers.dart`
wires these together, and the UI updates through the repositories' Drift
streams.

## Interface

From `ids.dart`:

- `String newId()`: random UUID v4, used for every row and attachment file.

From `repositories.dart`:

- `typedef ProjectSummary = ({Project project, int noteCount})`
- `abstract interface class ProjectsRepository`, implemented by `LocalProjectsRepository(FikraDatabase db)`: `watchProjects`, `create`, `rename`, `delete`, `deleteImpact`, `watchCurrentId`, `setCurrent`.
- `abstract interface class NotesRepository`, implemented by `LocalNotesRepository(FikraDatabase db, {deleteFiles})`: `watchNotes`, `watchNote`, `watchAttachments`, `watchProjectAttachments`, `notesOf`, `notesWithStatus`, `create`, `markProcessing`, `markReady`, `markFailed`, `applyInsights`, `attachmentPaths`, `acceptRewrite`, `rejectRewrite`, `edit`, `restoreOriginal`, `delete`, `watchLinks`.
- `abstract interface class ChatRepository`, implemented by `LocalChatRepository(FikraDatabase db)`: `watch`, `add`, `clear`.

From `settings_repository.dart`:

- `enum AppLanguage { system, ar, en }`: persisted language choice, free of Flutter types.
- `enum AppTheme { system, light, dark }`: free of Flutter types; the app maps it to `ThemeMode`.
- `abstract interface class SettingsRepository`, implemented by `LocalSettingsRepository(FikraDatabase db, AttachmentStore files)`: `watchTheme`, `setTheme`, `watchLanguage`, `setLanguage`, `readVoiceTextChoices`, `setVoiceTextModel`, `setVoiceTextLanguage`, `readAutoTranscribe`, `setAutoTranscribe`, `readTranscriptionNotificationsAsked`, `markTranscriptionNotificationsAsked`, `wipeAllData`. The voice preference methods also form the narrow `VoiceTextSettings` interface.
- `class WipeFilesException implements Exception`: wraps `cause`.

Subdirectories:

- [`./ai/EGM.md`](./ai/EGM.md): the `AiService` seam and its demo implementation.
- [`./demo/EGM.md`](./demo/EGM.md): `seedDemoProject`.
- [`./files/EGM.md`](./files/EGM.md): `AttachmentStore`, which owns attachment files, and `openWithSystem`.
- [`./local/EGM.md`](./local/EGM.md): `FikraDatabase`, tables, enums and migrations.
- [`./processing/EGM.md`](./processing/EGM.md): `NoteProcessor`, the serial AI queue.

## Invariants

Notes:

- `create` trims title and text and starts the note as `processing`, `RewriteStatus.none`, with empty concepts. Saving and AI completion are separate states.
- Every update through `_write` bumps `updatedAt`.
- `originalText` keeps the typed baseline, except recording appends and explicit safe transcript corrections.
- `edit` keeps a title when the replacement is blank. Changed body text retains the existing edit/original behavior and clears a pending proposal; attachment-only edits leave analysis and proposals intact. It never calls AI. A draft with no body text and no files throws `EmptyNoteException`, regardless of title.
- `edit(..., attachments:)` atomically replaces the attachment draft with the text edit, validates existing attachment IDs belong to that note, and deletes removed disk files only after commit. Cleanup catches all errors so a successful transaction never triggers copy rollback; leftovers are swept later. The optional `deleteFiles` callback is a cleanup-failure test seam. Omitting attachments leaves them intact. Source is recomputed from the resulting files within the same transaction, independently of analysis.
- `acceptRewrite` moves `proposedText` to `editedText`, and is a no-op without a proposal. `acceptRewrite` and `edit` throw if the note does not exist.
- `restoreOriginal` clears only `editedText`.

`applyInsights` (one transaction, and a no-op if the note was deleted):

- A non-blank live title is kept. `extractedText` is never written.
- A proposed rewrite is discarded when the user edited the note since `basis`, or when `editedText` is already set.
- Concepts are capped at 8.
- AI output is untrusted. Links are kept only for targets in the same project, with no self links and no duplicates, and at most 8 per note. Strength is clamped to 0..1 and non-finite values become 0. Labels are cut to 80 grapheme clusters.
- A note owns its outgoing live AI suggestions only: user links, tombstones and incoming links are retained.

Projects and settings:

- `deleteImpact(id)` is read-only and returns `ProjectDeleteImpact` (`({int notes, int files, int links, bool chat})`) from one statement with four aggregates (`chat` is an `EXISTS` over `chat_entries` for the project, so a project with no notes still reports its chat): the project's notes, their `note_attachments` rows, and distinct unordered note pairs among non-dismissed `note_links` rows that the delete cascade removes (`project_id` is the project, or either end is one of its notes). User links and suggestions on the same pair count once; rejected rows are not counted (they are still deleted). An unknown id counts zeros.

- `ProjectsRepository.create` trims the name and makes the new project current.
- Deleting the current project selects the oldest remaining project, or clears the selection if none remain. This happens in the same transaction as the delete.
- The `current_project` settings key is duplicated as `LocalProjectsRepository._currentKey` and `LocalSettingsRepository._currentProjectKey`. The two must stay equal.
- Theme and language each store `system` as an absent row; unknown values read as `system`. Language uses the existing settings table, with no schema change.
- `wipeAllData` deletes rows children first in one transaction and keeps the theme and language. Files are purged only after the rows are gone, so a failure leaves only unreferenced files, and it surfaces as `WipeFilesException`. Retrying is safe.

Files and ordering:

- Rows are deleted before their files, and file cleanup is best effort. Anything missed is removed by `AttachmentStore.sweepOrphans`.
- `attachmentPaths` returns every new-table path across projects. Migration completes before repository queries; a failed opening prevents startup sweeping. Legacy columns are migration-only.
- `watchNotes` is newest first, and `ChatRepository.watch` is oldest first. `watchProjects` is ordered by creation time. `notesOf` has no defined order.

## Side Effects

- Reads and writes the `projects`, `notes`, `note_attachments`, `note_links`, `chat_entries`, `note_groups` and `settings` tables through `FikraDatabase`. Project deletion relies on foreign-key cascades for notes, links and chat.
- `LocalProjectsRepository.delete` and `LocalNotesRepository.delete` remove attachment files through the static `AttachmentStore.deleteQuietly`, after the row delete.
- `LocalSettingsRepository.wipeAllData` deletes all attachment files and temp recordings through `AttachmentStore.purgeAll`.
- Child side effects are listed in each subdirectory's contract.

## Verification

- Run: `flutter analyze && flutter test`

## Attachment drafts and queries

`attachment_draft.dart` defines `AttachmentDraft` (saved ID or new source path), `EmptyNoteException`, and `saveAttachmentDraft`. The helper copies each new source in draft order, calls the atomic repository operation, and deletes only its new destination files if any copy or commit fails. Sources remain available for retry. `create(attachments:)` writes the note and attachments in one transaction and omits legacy fields.

`watchAttachments(noteId)` is an indexed ordered stream. `watchProjectAttachments(projectId)` performs one joined query and groups rows by note ID. Cards share its provider; they never start one query per note. `_filePaths` joins the new table for note/project deletion; wipe relies on cascades and purges after commit.

## Local links, groups and moves (v6)

`links_repository.dart` exposes `LinksRepository` / `LocalLinksRepository`: `watchLinks`, `linkNotes`, `updateLabel`, `removeLink`, `acceptSuggestion`, `dismissSuggestion`, `acceptPair`, `dismissPair`. Pair matching uses both directions. Batch linking converts a suggestion or tombstone, leaves an existing user link alone and removes redundant AI/dismissed rows. User labels are trimmed/capped at 80 grapheme clusters (`package:characters`, a direct dependency since links phase 2), so the cap matches the reason field and its counter and never splits an emoji; absent labels persist as `''` in the existing NOT NULL column. `link_label.dart` shares `capLinkLabel` between user and AI operations. User links have strength 1 and creation time. AI labels require acceptance before editing. Removing a user link leaves an AI tombstone; dismiss covers both-direction AI rows. Accept acts only on non-dismissed AI suggestions; stale accepts of dismissed, removed or already accepted rows do nothing. Missing accept/dismiss IDs are no-ops. `updateLabel` is a no-op for a missing row or one that is no longer a user link because it was removed (a dismissed tombstone); it still throws `StateError` for a live AI suggestion. `acceptPair(a, b)`/`dismissPair(a, b)` resolve the unordered pair inside one transaction, so they survive a re-analysis that replaced the suggestion's id; the UI uses them. `acceptPair` acts only when the pair has a live, undismissed AI row and no user or dismissed row, so a stale accept never revives a rejected or removed pair. `dismissPair` leaves a pair with a user link alone, dismisses every AI row of the pair, and when the suggestion vanished meanwhile inserts a tombstone (AI, dismissed, label `''`, strength 0) if both notes exist in the same project. Both repository watch APIs exclude dismissed rows.

`applyInsights` replaces only outgoing, non-dismissed AI rows. A retained user, dismissed or reverse AI row blocks that pair before the eight-link cap. New suggestions have creation times. `linksOnly` updates only concepts, cluster and links, preserving updatedAt, title, original/edited/proposed text, rewrite and processing status. When the analysis basis belongs to a previous project, concepts, cluster and link replacement are skipped; normal jobs still finish title, rewrite and status, while linksOnly makes no writes.

`NotesRepository.moveImpact` returns `({int userLinks, int suggestions})` for distinct unordered non-dismissed crossing pairs. Reverse/duplicate rows count once; a pair with both origins counts once as a user link. `moveNotes` validates the destination, skips missing/already-destination notes, clears groupId and returns moved IDs atomically. Internal links (including tombstones) follow the moved set; crossing rows are deleted. Attachment rows and paths never change.

`groups_repository.dart` exposes `GroupsRepository` / `LocalGroupsRepository`: `watchGroups`, `create`, `rename`, `setColor`, `setParent`, `delete`, `assignNotes`. Positions increase within a project. Names must be nonblank after trim; colors are null or 0–3. Parents must exist, be top level and in the same project; self-parenting and parenting a group with children are forbidden. Violations throw `GroupRuleException` carrying `GroupRuleReason` (`emptyName`, `invalidColor`, `missingProject`, `missingGroup`, `invalidParent`, `selfParent`, `hasChildren`). Assignment replaces one group, skips cross-project/missing notes and permits null to clear. Foreign keys clear deleted groups from notes, raise children to top level and cascade groups on project deletion. Wipe explicitly clears note_groups before projects.

## Undoing "link together" (links phase 5a review)

`LinksRepository.linkNotesForUndo(sourceId, targetIds)` is `linkNotes` with no label that also returns a `LinkChange` per link it made: the row id, the project and every row the pair had before (none, suggestions, a rejection). `undoLinks(changes)` puts each pair back in one transaction: it deletes the pair's rows and re-inserts the earlier ones. A pair whose link is gone, no longer a live user link (removed by hand), moved to another project, or whose notes were deleted or moved, is skipped. Covered by `test/links_groups_moves_test.dart` (`undoLinks` group).

`acceptPairForUndo(a, b)` / `dismissPairForUndo(a, b)` run `acceptPair` / `dismissPair` in one transaction and return a `PairChange` (project, both note ids, the pair's rows right before and right after), or null when the rows did not change (no live suggestion, already yours or rejected, self or cross-project pair). `undoPairChange(change)` restores the pair in one transaction only when its rows are still exactly `after` (by id and every column) and both notes still exist in `change.projectId`: it deletes the pair's rows and re-inserts `before`, so the suggestion returns with its id, reason, strength and state, and the accepted row or the rejection tombstone is gone. A pair removed, relinked, re-labelled or re-analysed meanwhile, or whose notes were deleted or moved, is left alone and the call returns false. Covered by the `pair accept/reject Undo` group in `test/links_groups_moves_test.dart`.

## Voice preferences (phase 1)

The existing key/value settings table also stores voice_text_model (modelName) and voice_text_language (ar/en/auto). Reads return a nullable pair so the feature can choose an installed-model fallback; writes use insertOnConflictUpdate. Speech language is independent of app language, and invalid values are rejected. Wipe retains both keys alongside theme/language; only current_project is removed. Phase 2 adds schema v7 and optional saved-recording transcription; phase 3 adds user-consented external engines. Tests cover reopening, overwrites, validation and wipe retention in test/settings_test.dart; feature tests use a matching in-memory VoiceTextSettings fake.

## Saved recording transcription (phase 2)

VoiceTextSettings also exposes readAutoTranscribe/setAutoTranscribe, using voice_text_auto_transcribe (`true`/`false`, absent/unknown = false). Wipe preserves this preference along with model/language/theme. transcription_notifications_asked (`true` once the app asked for notification permission for transcription; absent = not asked) is also kept by wipe, like the system permission itself. AttachmentDraft.transcribe is a new-file save intent; transcriptionDraft snapshots auto-or-explicit selection for voice drafts only, never existing IDs or non-voice files. saveAttachmentDraft preserves the intent through copying. _replaceAttachments persists queued atomically with new rows and preserves all transcription metadata for existing IDs during edits.

TranscriptionQueue in processing owns attachment state and atomically appends transcript text, as text the user wrote, to freshly read Notes.originalText and, when the note has an edit, to Notes.editedText, so displayText holds it once and restoreOriginal keeps it. extractedText is untouched. transcriptNoteText remembers what is already represented in the note body across multiple different redos; deleting an attachment does not erase text the user may have edited. Notes.status becomes processing in the same success transaction so the normal AI pass also survives a killed wake-up.

A nullable transcriptionOrder allocated transactionally preserves FIFO on launch recovery. transcriptionAttempts (NOT NULL, default 0) counts runs started since the last manual request; replacing attachments on edit preserves it. save wake-ups take only new copied/requested paths; ordinary enqueue ignores done attachments unless redo is explicit.

## External transcription services (phase 3)

transcription/ owns TranscriptionServices/LocalTranscriptionServices, typed non-secret config, ServiceKeyStore/SecureServiceKeys, request builders, the fakeable HttpClient transport and RemoteTranscriptionEngine. See transcription/EGM.md for API docs, limits, timeout and consent contracts. No new database schema is required. LocalSettingsRepository accepts an optional TranscriptionServices boundary and wipes service keys/config/selection before deleting ordinary data. Theme, language, model and auto preferences retain their existing wipe behavior. Credential failure prevents a successful wipe and leaves the service manifest discoverable for retry. Notes and attachment repositories never receive keys or provider request bodies.

## Voice 2a drafts and correction writes

AttachmentDraft.policy is the effective per-recording choice; nullable is only an unresolved new-draft default. transcriptionDraft resolves new defaults from auto while preserving explicit off. transcribe is a save request only for new voice files, never for saved rows or other file kinds. policyChanged distinguishes an explicit saved-row choice from a stale snapshot; withPolicy sets it. Attachment replacement re-reads live rows and carries policy, correction, correctedAt, revision and all earlier transcription metadata. Untouched stale drafts cannot overwrite newer policy/corrections. Explicit off changes cancel queued/running status without deleting a completed transcript. No old attachment is auto-enqueued by Edit.

The approved exception to the originalText baseline is recording transcript append and an explicit transcript correction's safe paragraph update; ordinary note edits still use editedText. TranscriptCorrections lives in processing and drives normal analysis after a safe note change.
