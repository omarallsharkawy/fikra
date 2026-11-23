# Demo Project Seed

## Overview

Creates the ready-made sample project behind the welcome screen's demo action
(`lib/features/projects/welcome_screen.dart`), so a new install has notes,
concepts and links to show.

## Interface

From `demo_seed.dart`:

- `Future<Project> seedDemoProject(ProjectsRepository projects, NotesRepository notes, {Locale locale = const Locale('ar'), DateTime Function()? clock})`: creates the project, its 7 sample notes and their AI results, and returns the project.

Depends on [`../EGM.md`](../EGM.md) for the repositories, and on
[`../ai/EGM.md`](../ai/EGM.md) for `DemoAiService`.

## Invariants

- Analysis always uses a local `DemoAiService(latency: Duration.zero, locale: locale)`, regardless of the app's configured `AiService`. It also bypasses `NoteProcessor` and its queue.
- Samples are all `NoteSource.text`. Their `createdAt` starts two days before `(clock ?? DateTime.now)()` and advances 7 hours per sample, so the list shows day groups.
- Notes are analyzed in sample order, each against the project's notes at that moment, so a note can only link to samples created before it.
- `applyInsights` is called without `basis`, so the comparison against an earlier snapshot does not apply.

## Side Effects

- Inserts one project, which `ProjectsRepository.create` also makes the current project.
- Inserts 7 notes, and writes their insights and links through `NotesRepository`.
- The sequence is not wrapped in a transaction. A failure partway leaves the project and the notes seeded so far.

## Language and deterministic time

- The locale is captured by the caller at creation. Project name and all seven title/body pairs use generated `lookupAppLocalizations(locale)`; the same locale is passed to sample analysis.
- The optional clock pins note timestamps in screenshots. Existing seeded content is never rewritten on a language change.

## Verification

- Run: `flutter analyze && flutter test`
