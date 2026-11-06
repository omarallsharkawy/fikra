# فِكرة (FIKRA)

اكتب. اربط. اسأل. تطبيق نوتس بالذكاء الاصطناعي: بيربط أفكارك ببعض، وبيجاوبك من نوتسك وبيقولك المصدر.

ده تطبيق الأندرويد (Flutter). الباك إند (FastAPI + AI) في ريبو لوحده.

## النسخة الحالية: تجريبية
- كل حاجة offline على الموبايل: داتابيز SQLite (drift)، والملفات في مساحة التطبيق الخاصة.
- الذكاء الاصطناعي تجريبي (`DemoAiService`). الباك إند هيتركّب مكانه على نفس الـinterface (`AiService`, `AttachmentUploader`).
- الباك أب مقفول (`allowBackup=false` + data extraction rules)، عشان البيانات متخرجش من الموبايل.

## التشغيل
```bash
flutter pub get
flutter run                          # demo
flutter build apk --debug
flutter test
```
لو غيّرت `lib/data/local/database.dart`:
```bash
dart run build_runner build -d
```
وضع الربط بالباك إند (لسه مش جاهز): `--dart-define=FIKRA_MODE=connected`.

## الهيكل
- `lib/app/`: الـproviders، الراوتر، الـshell (الـtabs).
- `lib/core/`: الثيم والـtokens، الحركة (springs)، الـwidgets المشتركة.
- `lib/data/`: الداتابيز، الـrepositories، الـAI (demo)، المشروع التجريبي.
- `lib/features/`: الشاشات: إضافة، النوتس، تفاصيل النوت، الروابط، اسأل، المشاريع.

## التصميم
لوحات Figma والـtokens وقواعد الـRTL موجودين في [design/README.md](design/README.md).

## قبل الربط والـrelease
[docs/before-backend-and-release.md](docs/before-backend-and-release.md)
