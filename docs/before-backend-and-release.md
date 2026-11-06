# قبل ربط الباك إند والـrelease

دي النقط اللي طلعت من مراجعة الكود (Codex gpt-6.1-sol، high) ومش هتتعمل في النسخة التجريبية. النقط اللي تخص النسخة التجريبية نفسها اتصلّحت في الكود.

## لازم قبل أي release برّه الموبايلات بتاعتنا
- **Signing**: الـrelease حاليًا متوقّع بمفتاح الـdebug (`android/app/build.gradle.kts`). لازم upload key حقيقي، والـbuild يفشل لو المفتاح مش موجود. الأحسن كمان applicationId منفصل للنسخة التجريبية (مثلًا `com.fikra.app.demo`)، عشان لما نغيّر الشهادة منضطرّش نمسح التطبيق وتضيع النوتس.
- **INTERNET permission**: موجودة في manifest الـdebug بس. لازم تتضاف في الـmain manifest (أو flavor الـconnected) قبل ما التطبيق يكلّم الباك إند، ونراجع الـmerged release manifest.
- **R8/obfuscation**: نفعّل `--obfuscate --split-debug-info` في الـrelease build.

## لما نربط باك إند علاء
- **Upload contract**: `AttachmentUploader` حاليًا بيرجّع progress بس. المطلوب:
  - نحفظ النوت والملف محليًا الأول.
  - بعدها upload job بيفضل شغال حتى لو التطبيق اتقفل، ويرجّع `attachmentId` يتحفظ في النوت.
  - idempotency بالـnote id + revision.
- **DTOs**: `AiService` بياخد صفوف الداتابيز كاملة، وفيها مسارات ملفات محلية والنص المقترح. محتاجين request DTOs فيها بس اللي الباك إند محتاجه.
- **Timeouts وidempotency**: في timeout دلوقتي 90 ثانية، والـjobs ماشية واحدة ورا التانية. ناقص:
  - attempt id يتحفظ في الداتابيز.
  - idempotency من ناحية السيرفر.
  - retry/backoff.
- **Auth**: الـtokens تتخزن في `flutter_secure_storage` (Android Keystore)، مش في جدول Settings. HTTPS بس، من غير cleartext.
- **Edge ownership**: كل نوت بقت تملك الروابط اللي خارجة منها بس. نتفق مع علاء: الروابط هتيجي من السيرفر directed ولا undirected؟

## الداتابيز
- **Migrations**: `schemaVersion = 1` ومفيش `onUpgrade`. قبل أول تغيير في الـschema:
  - نعمل export لـschema v1 (`drift_dev schema dump`).
  - نكتب migrations خطوة بخطوة.
  - نختبر على داتابيز v1 حقيقية فيها نوتس وملفات وروابط وشات.

## تحسينات صغيرة مؤجلة
- الـfile picker بيعمل نسخة في الكاش قبل ما نعرف حجم الملف. لو احتجنا حد صارم للحجم، محتاجين import محدود من الـURI.
- مسح الشات وقت ما في إجابة جاية: الزرار بيختفي وقت الانتظار. لما الشات يبقى من السيرفر، نضيف conversation generation id.
