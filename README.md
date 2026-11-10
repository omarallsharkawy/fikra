# فِكرة (FIKRA)

اكتب. اربط. اسأل. تطبيق نوتس بالذكاء الاصطناعي: بيربط أفكارك ببعض، وبيجاوبك من نوتسك وبيقولك المصدر.

ده تطبيق الأندرويد (Flutter). الباك إند (FastAPI + AI) في ريبو لوحده.

## النسخة الحالية: تجريبية
- كل حاجة offline على الموبايل: داتابيز SQLite (drift)، والملفات في مساحة التطبيق الخاصة.
- الذكاء الاصطناعي تجريبي (`DemoAiService`). الباك إند هيتركّب مكانه: [docs/backend-api.md](docs/backend-api.md) و[docs/backend-integration.md](docs/backend-integration.md).
- الصوت والـPDF والصور بيفضلوا على الموبايل، ومش بيتحللوا. النص المكتوب بس هو اللي بيتحلل. الـPDF والصور بيتفتحوا في تطبيق خارجي.
- الباك أب مقفول (`allowBackup=false` + data extraction rules)، عشان البيانات متخرجش من الموبايل.
- فاتح وغامق: الألوان في `FikraPalette` (`lib/core/theme/tokens.dart`) وبتتقري بـ`context.colors` و`context.text`، مفيش ألوان ثابتة في الشاشات. الاختيار من شاشة الإعدادات (الترس في الهيدر) وبيتحفظ في جدول Settings.

## المتطلبات (المجرّبة)
- Flutter 3.47.5 (stable)، Dart 3.13.
- Android SDK فيه **platform 37** (`compileSdk = 37`، عشان `permission_handler` 13 محتاجه). الـtargetSdk هو الافتراضي بتاع Flutter.
- Java 17.

## التشغيل
```bash
flutter pub get
flutter run                     # demo
flutter analyze                 # لازم يطلع "No issues found!"
flutter test                    # كل التيستات
```
APK للتجربة (ملف لكل معالج، حوالي 20 ميجا لكل واحد):
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
    repositories.dart        كل القراءة والكتابة في الداتابيز
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
