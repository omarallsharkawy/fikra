# تقرير الاختلاف بين الدوكس والكود (EGM drift report)

راجعت كل دوكس المشروع على الكود الحالي في `dev` (كوميت `7e27539`)، و`docs/backend-api.md` اللي لسه ما اتعملوش commit. التقرير بيعرض الاختلافات بس.

## README.md

- بيقول إن ربط الباك إند في `docs/backend-integration.md` بس، ومفيش لينك لـ`docs/backend-api.md`.
- قسم التيستات بيذكر `repositories_test` و`app_flow_test` والـscreenshots بس. مش مذكور `migration_test` و`settings_test` و`graph_layout_test` و`motion_test` و`demo_ai_test` و`integration_test/stress_test.dart`.
- "لو غيّرت `database.dart`" بيقول `build_runner` بس. تغيير الجداول محتاج كمان `drift_dev schema dump` و`schema generate`، وإلا `test/migration_test.dart` مش هيغطي النسخة الجديدة. الخطوتين مكتوبين في `docs/before-backend-and-release.md` بس.
- بيقول إن التيستات بتعمل override لـ`aiServiceProvider`. `test/` و`integration_test/` مفيهمش ده، والـoverrides الفعلية `databaseProvider` و`attachmentStoreProvider`.

## design/README.md

- بيقول "The app is dark-only" والـtokens "plain static classes (no `ThemeExtension`)". الكود فيه فاتح وغامق، و`FikraPalette extends ThemeExtension` في `lib/core/theme/tokens.dart:7`.
- جدول الـtokens بيذكر `FikraColors`. الكلاس ده مش موجود في `lib/`، والموجود `FikraPalette` بيتقري بـ`context.colors`.
- "Tab branch change: enter tokens". الـscale 0.96 اتشال من التابات، والموجود دلوقتي غطا `TabVeil` بيختفي بالتدريج (`lib/app/shell.dart`).
- القاعدة 7 بتقول sheets فوق scrim ‏60%. ده الغامق بس، والفاتح 20% (`tokens.dart:92` و`:151`).
- القاعدة 6 بتقول شارة `بيانات تجريبية` في "اسأل" وفي أي مكان نتيجة AI فيه تجريبية. "اسأل" والإعدادات والترحيب والاقتراح بيستخدموا نصوص تانية، وتاب الروابط والمفاهيم على الكروت مفيهمش شارة خالص.
- Board 4 فيه sign in وsign up، ومالهمش شاشات في الكود. و`BannerKind.offline` معرّف في `fikra_widgets.dart` ومفيش شاشة بتستخدمه.

## docs/backend-integration.md

- خطوات التوصيل ناقصة: `lib/main.dart:12` بيرمي `UnsupportedError` لو `FIKRA_MODE=connected`. لو عملت الخطوات زي ما هي، التطبيق هيقع أول ما يفتح.
- "مش المفروض نلمس أي شاشة" مش دقيقة مع الـAPI الجديد:
  - `AiService` فيه `analyze` و`ask` بس. التعديل والمسح في `NotesRepository` و`ProjectsRepository` مالهمش أي طريق للسيرفر.
  - `uploaderProvider` بيتنادى من `add_screen.dart:234` للـPDF بس. التسجيل الصوتي مش بيعدّي عليه.
  - `AttachmentUploader` بيرجّع progress بس، ومفيش عمود في جدول `Notes` لـfile id أو job id أو attempt id.
- `AiService.analyze` بياخد كل نوتس المشروع، و`backend-api.md` مش بيبعتها.
- قسم "أمثلة نتفق عليها" بقى متغطي في `backend-api.md`. وكلمة `attachmentId` هناك اسمها `file_id` هنا.
- مش مذكور إن التطبيق بياخد أول 8 روابط بس، وبيقص الـ`label` عند 80 حرف (`repositories.dart`، `applyInsights`).

## docs/before-backend-and-release.md

- "احنا على `schemaVersion = 2`". الكود 3 (`database.dart`).
- "INTERNET موجودة في manifest الـdebug بس". موجودة كمان في الـprofile. الـmain لسه من غيرها.
- بند R8/obfuscation: `--obfuscate --split-debug-info` موجودين بالفعل في أمر الـbuild في `README.md`. مفيش إعداد ليهم في `build.gradle.kts`، فالـbuild لو اتعمل من غيرهم هيطلع من غير obfuscation.
- "القوايم الطويلة: دلوقتي `ListView` عادي". ليستة النوتس بقت `ListView.builder`. الشات لسه `ListView` عادي (`ask_screen.dart:153` و`:175`).
- بند الجراف: `GraphLayout.compute` اتعمل بالفعل (`graph_layout.dart:108`). اللي فاضل منه تيست الـRTL.
- بند "Edge ownership" سايب السؤال مفتوح. `backend-api.md` حسمه: الروابط directed وخارجة من النوت.
- بند "Upload contract" بيوصف job بيرجّع `attachmentId`. `backend-api.md` بيوصف `POST /v1/files` بـ`id` من الموبايل.

## docs/scalability.md

- حد "20 مجموعة و12 نوت" بيتطبق بس لو المشروع فيه أكتر من 60 نوت (`smallProjectLimit`). كمان فيه حد 240 نوت و1000 رابط، ومش مذكورين.
- مش مذكور إن الجراف بيرسم النوتس اللي حالتها `ready` بس، فالنوت اللي بتتحلل أو فشلت مش بتظهر فيه.
- أمر `flutter drive --profile` مش مذكور جنبه إن النسخة بتتسطب كـ`com.fikra.app.stress`. ده اللي بيحمي التطبيق الحقيقي من المسح.

## docs/backend-api.md

- الـAPI كله لسه مش متنفذ في التطبيق، وده مكتوب في أول الدوك. الاختلافات التانية:
- القصة 1 مش مذكور فيها زرار "جرّب مشروع تجريبي" في `welcome_screen.dart`. مش واضح النوتس دي هتتبعت للسيرفر ولا لأ.
- "مفيش شاشة تسجيل دخول" صح في الكود، بس بيخالف `FIKRA_Project_Documentation.pdf` (الخطوة 1 Registration) وBoard 4 في Figma (sign in وsign up).
- الـ`links` فيها `label` و`strength` بس، والـPDF طالب نوع العلاقة والدليل وتاريخ الإنشاء.
- الدوك بيوعد بحاجات مش مبنية في التطبيق: طابور للتعديلات والمسح، وتخزين الـ`Idempotency-Key`.

## FIKRA_Project_Documentation.pdf

- **خطوة التسجيل (Step 1) وAccount settings:** مفيش حسابات في التطبيق.
- **المشاريع:** الـPDF مش بيذكرها، وبيقول الشات على "entire knowledge base". الكود كل حاجة فيه جوه مشروع واحد، و"اسأل" بيجاوب من المشروع المفتوح بس.
- **الجراف:** الـPDF بيقول العقد concepts وtopics. في الكود العقد نوتس (`links_screen.dart:19`).
- **أدوات الجراف:** فلترة بالموضوع والبحث في العقد مش موجودين في `links_screen.dart`.
- **العلاقات:** مطلوب نوع وثقة وشرح وتاريخ ودليل. `NoteLinks` فيها `label` و`strength` بس، ومفيش تاريخ أو نوع أو دليل.
- **مراجعة الروابط (Step 6):** الـPDF بيقول المستخدم يراجع الروابط أو يقبلها تلقائي حسب إعداداته. الكود بيحفظها على طول، ومفيش إعداد.
- **Entities وKeywords وMain topic:** مفيش ليهم مكان. الموجود `concepts` و`cluster` واحد.
- **Clusters:** الـPDF عايزها متغيرة وهرمية. في الكود كل نوت ليها اسم cluster واحد بيتحدد وقت تحليلها.
- **Home Dashboard (8.2) وشاشة Search (8.8):** مش موجودين. التابات: إضافة، نوتس، روابط، اسأل.
- **Cluster Explorer (8.6):** الموجود sheet فيها ليستة نوتس المجموعة بس (`_showCluster`)، من غير ملخص أو مجموعات مرتبطة.
- **Notes Workspace (8.3):** فيه بحث بالنص، ومفيش فلاتر أو ترتيب بالموضوع.
- **البحث (6.9):** بالنص بس. الدلالي مرتبط بالباك إند.
- **الإجابات (6.7):** الـPDF عايز تفرقة بين اللي في النوتس والاستنتاج والمعرفة العامة. `ChatAnswer` فيه `found` بس.
- **Settings (8.9):** الموجود المظهر ومسح البيانات. مفيش تفضيلات AI أو جراف أو تصدير بيانات.
- **Voice وPDF:** الـPDF حاططهم "Future"، والكود عملهم بالفعل.
- **AI Knowledge Discovery (6.8):** مش موجودة، والـPDF نفسه بيأجلها.
