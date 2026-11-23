# فِكرة (FIKRA)

اكتب. اربط. اسأل. تطبيق نوتس بالذكاء الاصطناعي: بيربط أفكارك ببعض، وبيجاوبك من نوتسك وبيقولك المصدر.

ده تطبيق الأندرويد (Flutter). الباك إند (FastAPI + AI) في ريبو لوحده.

## Current development phase

The default `flutter run` opens backend-aligned product journeys using explicit, volatile development fixtures. No backend or third-party provider is contacted. Registration/email/Google/processing/search/chat/transcription previews are not real integration or durable storage. Existing local notes and files are kept separately without migration.

- [Behavior audit](docs/phases/backend-alignment/behavior-audit.md)
- [User-story capability map](docs/features/backend-aligned-journeys/story-capability-map.md)
- [Implementation, fixture limits, connection checklist and walkthrough](docs/features/backend-aligned-journeys/implementation.md)
- [Validation record](docs/phases/backend-alignment/validation-results.md)
- [Reviewed backend handbook](https://github.com/theg4br/fikrah/blob/dev/docs/mobile/README.md)

Use `flutter run --dart-define=FIKRA_MODE=demo` for the preserved local-first app described below. `FIKRA_MODE=connected` remains unavailable. Appearance and language preferences are shared; private fixture and legacy note data are separate.

## Legacy local demo reference

The remaining local storage/attachment/transcription documentation describes explicit legacy demo mode, not the new default product contract.

## النسخة الحالية: تجريبية
- كل حاجة offline على الموبايل: داتابيز SQLite (drift)، والملفات في مساحة التطبيق الخاصة.
- الذكاء الاصطناعي تجريبي (`DemoAiService`). ده المسار المحلي القديم؛ المسار الجديد وواجهات الربط موضحين في دليل التنفيذ أعلاه.
- الصوت والـPDF والصور بيفضلوا على الموبايل، ومش بيتحللوا. النص المكتوب بس هو اللي بيتحلل.
- الباك أب مقفول (`allowBackup=false` + data extraction rules)، عشان البيانات متخرجش من الموبايل.
- فاتح وغامق: الألوان في `FikraPalette` (`lib/core/theme/tokens.dart`) وبتتقري بـ`context.colors` و`context.text`، مفيش ألوان ثابتة في الشاشات. الاختيار من شاشة الإعدادات (الترس في الهيدر) وبيتحفظ في جدول Settings.

## المتطلبات (المجرّبة)
- Flutter 3.47.5 (stable)، Dart 3.13.
- Android SDK فيه **platform 37** (`compileSdk = 37`، عشان `permission_handler` 13 محتاجه). الـtargetSdk هو الافتراضي بتاع Flutter.
- Java 17.

## التشغيل
```bash
flutter pub get
flutter run                     # backend-aligned development fixtures
flutter run --dart-define=FIKRA_MODE=demo  # preserved local-first demo
flutter analyze                 # لازم يطلع "No issues found!"
flutter test                    # كل التيستات
```
APK للتجربة (ملف لكل معالج):
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
```
الناتج في `build/app/outputs/flutter-apk/`. معظم الموبايلات: `app-arm64-v8a-release.apk`.

لو غيّرت `lib/data/local/database.dart`:
```bash
dart run build_runner build -d
```

## الهيكل
```
lib/
  main.dart                  تهيئة + ProviderScope
  app/                       الـwiring: providers, router, shell (التابات), app_config (demo/connected)
  core/                      مشترك ومش مربوط بشاشة: theme/tokens, motion (springs), widgets, format
  data/
    local/database.dart      الجداول (drift) + extensions على Note
    repositories.dart        المشاريع والنوتس والنقل والشات
    links_repository.dart    روابط المستخدم واقتراحات التحليل
    groups_repository.dart   مجموعات النوتس المحلية
    ai/                      AiService (interface) + النسخة التجريبية
    processing/              NoteProcessor: طابور التحليل بعد الحفظ
    files/                   AttachmentStore وفتح الملفات: الصوت والـPDF والصور على الموبايل
    demo/                    المشروع التجريبي
  features/<screen>/         شاشة في كل فولدر؛ features/shared فيه helpers للعرض
```

## النوت بتمشي إزاي
```
Add screen
  → AttachmentStore.persist (لو فيه ملف)
  → NotesRepository.create          الحالة: processing (النوت اتحفظت خلاص)
  → NoteProcessor.process           طابور، واحدة ورا التانية، timeout 90 ثانية
      → AiService.analyze
      → NotesRepository.applyInsights   الحالة: ready، أو failed لو حصل خطأ
  → drift streams → providers → الشاشات بتتحدث لوحدها
```
- النص الأصلي عمره ما بيتمسح. التعديل أو الصياغة المعتمدة بيتحفظوا في `editedText`.
- الشاشات بتقرا بيانات المشروع المختار من `selectedNotesProvider` وأخواتها. شاشة تفاصيل النوت بتقرا بـ`note.projectId` (`notesOfProjectProvider(id)`).

## التيستات
- `test/repositories_test.dart`: الداتابيز والطابور. بيستخدم fake `AiService` اسمه `_ScriptedAi`.
- `test/app_flow_test.dart`: التطبيق كامل على داتابيز in-memory، بـ`fikraTest` و`pumpUntil` و`pumpFuture` من `test/support/app_harness.dart`.
- لقطات شاشة لمراجعة التصميم (مش بتشتغل مع `flutter test` العادي):
  ```bash
  flutter test test/screenshots --run-skipped -t screenshots    # → build/screenshots/{ar,en}/{dark,light}/*.png
  ```
- الـoverrides: `databaseProvider` (داتابيز in-memory) و`attachmentStoreProvider` و`fileOpenerProvider` (fakes).

## التصميم
لوحات Figma والـtokens وقواعد الـRTL في [design/README.md](design/README.md).

## قبل الربط والـrelease
[docs/before-backend-and-release.md](docs/before-backend-and-release.md)

## Languages

The UI supports Arabic (RTL) and English (LTR). Settings → Language offers System, العربية, and English. System uses English for an English device and Arabic for every other device language. The preference persists and applies immediately; saved notes, topics, groups and answers keep their original language.

To add or change copy, edit the same key in `lib/l10n/app_ar.arb` (the template) and `app_en.arb`, using the approved wording in `docs/plans/copy-glossary.md`. Add typed placeholder metadata and ICU plural branches when needed, then run `flutter gen-l10n`. Generated `app_localizations*.dart` files live in `lib/l10n` and are checked in; do not edit them by hand. Widgets read `context.l10n` from `lib/l10n/localizations.dart`; code without a context receives the resolved locale and calls `lookupAppLocalizations(locale)`. Demo topic/group labels use `lib/l10n/demo_vocabulary.json`, following the glossary's separate vocabulary tables.

Run `flutter analyze`, `flutter test`, and the screenshot command above after a copy change. Screenshots cover both languages and themes with fixed sample timestamps.

## Attachments

PDFs open inside FIKRA from the note’s PDF row (`/note/:id/pdf/:attachmentId`). The route resolves the selected attachment from the saved note’s attachment table, never a query parameter. Every part of a note card opens its note. Photos continue to open in another app.

The viewer uses pinned `pdfrx` 2.12.0 (PDFium), continuous vertical scrolling, pinch and double-tap zoom, and the existing localized page indicator. Pages retain their document colors on the themed backdrop; app controls follow Arabic RTL or English LTR. Its open-in-another-app action uses the existing `fileOpenerProvider`, including when loading fails. Missing, unreadable, corrupt and absent PDF attachments show `pdfLoadFailed` with retry. Password-protected PDFs show `pdfPasswordProtected`, retain opening in another app, and omit retry; no password prompt is shown.

Documents stay local: no upload, indexing, or AI analysis. The loader opens the file by path without a full-file Dart byte buffer; PDFium performs native work on a background worker. Progressive page loading and lazy rendering keep work near the viewport, with a 32 MiB rendering-image cache target (not a total-process memory limit). Source inspection confirmed `FPDF_LoadDocument` runs on the library background worker and rendering uses viewport caches. A Linux native smoke check opened a synthetic 200-page, 52,517,035-byte PDF in 26 ms with only one page initially loaded, rendered its first page by 37 ms and its last page by 90 ms while the Dart event loop kept ticking. These are desktop smoke measurements, not Android frame-time or peak-memory guarantees; real-device large-file and gesture checks are still needed.

`pdfDocumentLoaderProvider` is injectable for widget tests. `test/pdf_viewer_test.dart` covers failure and lifetime behavior; app-flow tests cover navigation, external opening and unchanged photo behavior. The screenshot suite writes `20_pdf_failure.png` in both languages and themes. Loaded PDF screenshots are not part of this widget suite because it does not initialize native PDFium; verify native rendering on a phone.

The release split arm64 APK measured 29,140,552 bytes after this feature (baseline 21,601,841; +7,538,711 bytes, +34.9%). The regenerated merged release manifest adds no permissions and keeps minSdk 24 / targetSdk 36.

Each note can contain several PDFs, recordings and photos. Add or remove individual files on the edit screen, then Save changes; leaving without saving preserves the saved files. Files are stored locally in the attachment table (retained in schema v6), and cards show per-kind counts. Only typed text is analyzed.

File-only notes use the first file’s title: PDF name without its extension, “Voice recording”, or the photo title in the current language. Editing cannot save a note without body text or files. Untouched auto-titles follow a removed first file; typed titles are preserved. Add and Edit share microphone ownership, and recording stops current playback first.

Schema v6 adds on-device user links, rejected-pair tombstones, two-level note groups and atomic moves between projects. This phase exposes data APIs only; screens and `AiService` are unchanged.
