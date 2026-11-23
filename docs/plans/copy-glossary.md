# جدول المصطلحات والكلام — فِكرة

التاريخ: 2026-11-10. الحالة: نهائي. Argon راجع المقترح (`copy-review-argon.md`) ومراجعته اتدمجت هنا، والقرارات كلها اتحسمت (القسم ج). عمود "المقترح" والإنجليزي هما النص النهائي اللي يتنقل لملفات الـARB. مفيش كود اتغير.

الملف ده فيه كل كلمة بتظهر للمستخدم في التطبيق، والكلام المقترح بدلها بالعربي، والإنجليزي. الهدف إن الكلام يبقى زي ما واحد بيكلم صاحبه: مصري، بسيط، ونفس الحاجة ليها نفس الاسم في كل حتة.

قواعد الكتابة اللي اتبعتها:

- عامية مصرية بسيطة، بنفس النبرة في كل الشاشات.
- مفيش كلمات متألفة أو منقولة بالحروف لو فيه كلمة عربي عادية. الكلمات التقنية اللي الناس بتقولها فعلاً بالإنجليزي (PDF، الباك إند، RAG) بتفضل زي ما هي.
- الأزرار أفعال: "احفظ"، "احذف"، "ضيف"، مش "حفظ" و"حذف" و"إضافة". الاستثناءين: "إلغاء"، لأنه متعارف عليه ومفيش فعل أوضح منه، و"إنشاء" (اتحسم، القسم ج). اسم التاب "إضافة" مش زرار، فبيفضل زي ما هو.
- رسالة الغلط بتقول إيه اللي حصل وتعمل إيه: "مقدرناش نحفظ الملاحظة. جرّب تاني."
- مفيش علامات تعجب.
- الإنجليزي بسيط، sentence case، ومش ترجمة حرفية.
- كل الفشل بقى "مقدرناش…" بدل الخليط بين "معرفناش" و"مقدرناش" و"مش قادرين".
- "احذف/اتحذف" للحاجات اللي ليها اسم (ملاحظة، مشروع، تسجيل، ملف). "امسح/اتمسح" للتنضيف الشامل (المحادثة، كل البيانات، البحث).
- الإنجليزي في رسايل الفشل بيبدأ بـ`Couldn't…` من غير `We`، زي "مقدرناش…" بالعربي.

---

## أ) المصطلحات الأساسية

| المصطلح | الحالي | المقترح | English | ليه |
|---|---|---|---|---|
| اسم التطبيق | فِكرة | فِكرة (بدون تغيير) | Fikra | بالإنجليزي اسم علم، من غير ترجمة. |
| الشعار | اكتب. اربط. اسأل. | بدون تغيير | Write. Connect. Ask. | |
| note (مفرد) | نوت | ملاحظة | note | قرار المنسق. "نوت" كلمة منقولة ومش طبيعية في جملة. |
| notes (جمع) | نوتس | ملاحظات | notes | |
| notes + ضمير | نوتسك / نوتسي | ملاحظاتك / ملاحظاتي | your notes | "نوتسك" هي الكلمة اللي عمر اشتكى منها. |
| المثنى | نوتين | ملاحظتين | two notes | |
| تاب الملاحظات | النوتس | الملاحظات | Notes | راجعت العرض: التاب عرضه حوالي 87dp، و"الملاحظات" المفروض تكفي. لازم تتراجع في الـscreenshots بعد التنفيذ. |
| project | مشروع | بدون تغيير | project | |
| concept | مفهوم / المفاهيم | موضوع / المواضيع | topic / Topics | "المفاهيم" كلمة كتب. اللي بيظهر فعلاً حاجات زي "الشبكات" و"RAG"، ودي مواضيع. (اتحسم: المواضيع) |
| cluster (المجموعة في شاشة الروابط) | مجموعة | بدون تغيير | group | بيظهر كعنوان صف في الروابط وفي سطر التاريخ في صفحة الملاحظة. |
| link / related | رابط / الروابط / مرتبطة | رابط / الروابط / ملاحظات مرتبطة | link / Links / Related notes | "رابط" ممكن يتفهم لينك ويب، بس معناه هنا واضح من الشاشة. (اتحسم: الروابط) كل حالات قسم الملاحظات المرتبطة في صفحة الملاحظة بتقول "مرتبطة" (`relatedNotesHeader`، `relatedLoadFailed`، `relatedEmpty`، `analyzingBody`). "قريبة" للشرح العام بس (`welcomeLinks`، `linksEmptyBody`). |
| سبب الربط | مرتبطة بـ{concept} | بدون تغيير | Both mention {concept} | |
| ask | اسأل | بدون تغيير | Ask | |
| answer | الإجابة | بدون تغيير | answer | |
| source | المصدر / المصادر | بدون تغيير | source / Sources | |
| chat | المحادثة | بدون تغيير | chat | |
| attachment | ملف | ملف | file | مش بنقول "مرفق" في أي حتة، و"ملف" أبسط. |
| PDF | PDF / ملف PDF | بدون تغيير | PDF | |
| photos | صور | بدون تغيير | photos | |
| recording | تسجيل صوتي | بدون تغيير | voice recording | |
| زرار التسجيل | تسجيل صوت | سجّل صوت | Record voice | الزرار فعل. |
| analysis | التحليل | التحليل / بنحلل / بتحلل | analysis / analyzing | نفس الكلمة في البادج والزرار ورسالة الفشل والشرح (`addFooter`، `analyzingBody`)، مش "بتقرا"، عشان لما التحليل يفشل يبقى "مقدرناش نحلل" و"حلّلها تاني" بنفس المصطلح. |
| rewrite | اقتراح إعادة صياغة | صياغة مقترحة | Suggested rewrite | أقصر، ونفس المعنى. |
| original text | النص الأصلي / الأصل / التفريغ الأصلي | النص الأصلي / الأصلية | original text / Original | "التفريغ" غلط: التطبيق مش بيفرّغ الصوت لكلام أصلاً. التابين بالمؤنث على اعتبار "النسخة" ("المعدّلة" / "الأصلية")، وأي زرار أو عنوان تاني بيقول "النص الأصلي" كامل (`originalTextLabel`، `keepOriginal`، `restoreOriginal`). |
| edited version | النسخة المحسّنة | المعدّلة | Edited | النسخة دي بتظهر كمان لما المستخدم يعدّل بإيده، فكلمة "المحسّنة" مش دقيقة. |
| demo (نسخة التطبيق) | نسخة تجريبية | بدون تغيير | Demo version | |
| demo (بيانات) | بيانات تجريبية / تجريبي | بدون تغيير | Sample data / Demo | |
| demo project | مشروع تجريبي | مشروع جاهز | sample project | عشان ما يتلخبطش مع "نسخة تجريبية". |
| settings | الإعدادات | بدون تغيير | Settings | |
| file size | بايت / ك.ب / م.ب | بايت / KB / MB | B / KB / MB | محدش بيكتب "ك.ب". KB وMB هي اللي الناس بتقولها وتقراها. |

### "ملاحظة" في كل مكان: بتتقري طبيعي؟

راجعت كل مكان فيه "نوت" أو "نوتس" بعد التبديل:

| المكان | بعد التبديل | الحكم |
|---|---|---|
| تاب، عنوان الشاشة | الملاحظات | طبيعية. |
| البحث | دوّر في الملاحظات | طبيعية. |
| العدد | ملاحظة واحدة، ملاحظتين، 3 ملاحظات، 11 ملاحظة | طبيعية، والجمع مظبوط. |
| فاضي | لسه مفيش ملاحظات / ضيف أول ملاحظة | طبيعية. |
| عنوان شاشة اسأل | ~~اسأل ملاحظاتك~~ | **مش طبيعية.** كأنك بتكلم الملاحظات نفسها. البديل: **اسأل عن ملاحظاتك**. |
| خانة السؤال | اسأل عن أي حاجة في ملاحظاتك | طبيعية. |
| مفيش إجابة | ملقيناش إجابة في ملاحظاتك | طبيعية. |
| شاشة الإضافة، الخانة لما فيه ملف | ~~ضيف ملاحظة على الملف~~ | **بتتلخبط.** "ملاحظة" دلوقتي معناها الـnote كلها، فالجملة بقت معناها "ضيف note على الملف". البديل: **اكتب كام سطر عن الملف عشان فِكرة تربطه (اختياري)** (`bodyHintWithFileLinks`). |
| من غير عنوان | ملاحظة جديدة | طبيعية. |
| الحذف | تحذف الملاحظة دي؟ / الملاحظة اتحذفت | طبيعية. |
| صفحة الملاحظة | ملاحظات مرتبطة | طبيعية. |
| الإعدادات | ملاحظاتك وملفاتك محفوظة على الموبايل ده بس | طبيعية. |
| نص الـdemo | تطبيق ملاحظات بيستخدم الذكاء الاصطناعي… | طبيعية. |

---

## ب) كل النصوص، شاشة شاشة

الأعمدة: المفتاح المقترح لملف الـARB، مكانه في الكود، النص الحالي، المقترح، الإنجليزي. لو المقترح "بدون تغيير" يبقى النص الحالي كويس. المفاتيح المتكررة (زي `retry` و`cancel`) مكتوبة في كل مكان بتظهر فيه، بس هي مفتاح واحد في الـARB.

النصوص اللي فيها قيم متغيرة مكتوب فيها الـplaceholder بين `{}`.

### 1. التطبيق والتابات — `lib/app/`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `appTitle` | lib/app/app.dart:22 | فِكرة | بدون تغيير | Fikra |
| `navAdd` | lib/app/shell.dart:23 | إضافة | بدون تغيير | Add |
| `navNotes` | lib/app/shell.dart:24 | النوتس | الملاحظات | Notes |
| `navLinks` | lib/app/shell.dart:25 | الروابط | بدون تغيير | Links |
| `navAsk` | lib/app/shell.dart:26 | اسأل | بدون تغيير | Ask |
| `storageErrorTitle` | lib/app/storage_error_screen.dart:16 | في مشكلة في التخزين | فيه مشكلة في التخزين | There's a storage problem |
| `storageErrorBody` | lib/app/storage_error_screen.dart:17 | مش قادرين نقرأ بياناتك دلوقتي. اتأكد إن فيه مساحة فاضية وجرّب تاني. | مقدرناش نقرا بياناتك دلوقتي. اتأكد إن فيه مساحة فاضية على الموبايل، وجرّب تاني. | Couldn't read your data right now. Make sure your phone has free space, then try again. |
| `retry` | lib/app/storage_error_screen.dart:19 | جرّب تاني | بدون تغيير | Try again |

ملحوظة: lib/app/app_config.dart:11 كومنت في الكود، مش نص بيظهر.

### 2. الصيغ والأعداد والتواريخ — `lib/core/format.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `today` | lib/core/format.dart:15 | النهارده | بدون تغيير | Today |
| `yesterday` | lib/core/format.dart:16 | امبارح | بدون تغيير | Yesterday |
| `justNow` | lib/core/format.dart:22 | دلوقتي | بدون تغيير | Just now |
| `minutesAgo` | lib/core/format.dart:23 | من {m} دقيقة | جمع (تحت) | جمع (تحت) |
| `hoursAgo` | lib/core/format.dart:25 | من {h} ساعة | جمع (تحت) | جمع (تحت) |
| `notesCount` | lib/core/format.dart:40 | مفيش نوتس / نوت واحدة / نوتين / {n} نوتس / {n} نوت | جمع (تحت) | جمع (تحت) |
| `linksCount` | lib/core/format.dart:43 | مفيش روابط / رابط واحد / رابطين / {n} روابط / {n} رابط | جمع (تحت) | جمع (تحت) |
| `sizeBytes` | lib/core/format.dart:51 | {size} بايت | بدون تغيير | {size} B |
| `sizeKb` | lib/core/format.dart:52 | {size} ك.ب | {size} KB | {size} KB |
| `sizeMb` | lib/core/format.dart:53 | {size} م.ب | {size} MB | {size} MB |
| (صيغة الوقت) | lib/core/format.dart:5 | `h:mm a` بالعربي ← "7:47 م" | بدون تغيير | `h:mm a` ← "7:47 PM" |
| (صيغة اليوم) | lib/core/format.dart:6 | `EEEE d MMMM` ← "الأحد 8 نوفمبر" | بدون تغيير | `EEEE, d MMMM` ← "Sunday, 8 November" |

ملحوظات:

- `Fmt.relative` (السطور 20–27) مش مستخدمة في أي شاشة دلوقتي. لو هتتنقل للـARB لازم الجمع يتصلّح، لأن "من 5 دقيقة" غلط في العربي.
- `Fmt.count` (السطر 31) بيحسب الجمع بإيده: 3–10 جمع، والباقي مفرد. ده بيطلّع "103 نوت" بدل "103 ملاحظات". صيغة ICU تحت بتحل ده لوحدها (قاعدة العربي: `few` = آخر رقمين من 3 لـ10، `many` = من 11 لـ99).
- السطر 30 كومنت، والسطر 57 أرقام عربي للتحويل. مش نصوص بتظهر.

**الجمع بصيغة ICU:**

| المفتاح | zero | one | two | few | many | other |
|---|---|---|---|---|---|---|
| `notesCount` ع | مفيش ملاحظات | ملاحظة واحدة | ملاحظتين | {count} ملاحظات | {count} ملاحظة | {count} ملاحظة |
| `notesCount` En | No notes (`=0`) | 1 note | — | — | — | {count} notes |
| `linksCount` ع | مفيش روابط | رابط واحد | رابطين | {count} روابط | {count} رابط | {count} رابط |
| `linksCount` En | No links (`=0`) | 1 link | — | — | — | {count} links |
| `minutesAgo` ع | دلوقتي | من دقيقة | من دقيقتين | من {count} دقايق | من {count} دقيقة | من {count} دقيقة |
| `minutesAgo` En | Just now (`=0`) | 1 minute ago | — | — | — | {count} minutes ago |
| `hoursAgo` ع | — | من ساعة | من ساعتين | من {count} ساعات | من {count} ساعة | من {count} ساعة |
| `hoursAgo` En | — | 1 hour ago | — | — | — | {count} hours ago |

الإنجليزي فيه `one` و`other` بس. الـzero بالإنجليزي لازم يتكتب `=0` صريح.

### 3. المكونات المشتركة — `lib/core/widgets/`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `badgeSampleData` | lib/core/widgets/fikra_widgets.dart:295 | بيانات تجريبية | بدون تغيير | Sample data |
| `badgeSaved` | lib/core/widgets/fikra_widgets.dart:296 | تم الحفظ | اتحفظت | Saved |
| `badgeAnalyzing` | lib/core/widgets/fikra_widgets.dart:297 | جاري التحليل… | بنحللها… | Analyzing… |
| `badgeFailed` | lib/core/widgets/fikra_widgets.dart:298 | فشل | فيه مشكلة | Failed |
| `delete` | lib/core/widgets/fikra_widgets.dart:569 | حذف | احذف | Delete |
| `cancel` | lib/core/widgets/fikra_widgets.dart:599 | إلغاء | بدون تغيير | Cancel |
| `loadErrorTitle` | lib/core/widgets/fikra_widgets.dart:704 | مش قادرين نحمّل البيانات | مقدرناش نحمّل البيانات | Couldn't load your data |
| `loadErrorBody` | lib/core/widgets/fikra_widgets.dart:705 | حصلت مشكلة وإحنا بنقرا البيانات. جرّب تاني. | مقدرناش نقرا بياناتك دلوقتي. جرّب تاني. | Couldn't read your data right now. Try again. |
| `retry` | lib/core/widgets/fikra_widgets.dart:708 | جرّب تاني | بدون تغيير | Try again |
| `genericError` | lib/core/widgets/fikra_widgets.dart:720 | حصلت مشكلة، جرّب تاني | حصلت مشكلة. جرّب تاني. | Something went wrong. Try again. |
| `voicePlayA11y` | lib/core/widgets/voice_player.dart:75 | تشغيل | شغّل | Play |
| `voicePauseA11y` | lib/core/widgets/voice_player.dart:75 | إيقاف مؤقت | وقّف | Pause |
| `voiceUnavailableA11y` | lib/core/widgets/voice_player.dart:75 | التسجيل مش متاح | بدون تغيير | Recording unavailable |
| `voiceRecording` | lib/core/widgets/voice_player.dart:94 | تسجيل صوتي | بدون تغيير | Voice recording |
| `fileUnavailable` | lib/core/widgets/voice_player.dart:116 | الملف مش متاح | بدون تغيير | File unavailable |
| `deleteRecording` | lib/core/widgets/voice_player.dart:130 | احذف التسجيل | بدون تغيير | Delete recording |

ملحوظة: `badgeSaved` و`badgeAnalyzing` و`badgeFailed` هي القيم الافتراضية. `badgeAnalyzing` بس هو اللي بيظهر بالقيمة دي (note_card.dart:61). الباقيين كل مكان بيبعت النص بتاعه.

### 4. الترحيب — `lib/features/projects/welcome_screen.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `firstProjectTitle` | welcome_screen.dart:21 | أول مشروع | سمّي أول مشروع | Name your first project |
| `create` | welcome_screen.dart:21 | إنشاء | بدون تغيير | Create |
| `createProjectFailed` | welcome_screen.dart:26 | مقدرناش نعمل المشروع، جرّب تاني | مقدرناش نعمل المشروع. جرّب تاني. | Couldn't create the project. Try again. |
| `sampleProjectFailed` | welcome_screen.dart:37 | مقدرناش نجهّز المشروع التجريبي، جرّب تاني | مقدرناش نفتح المشروع الجاهز. جرّب تاني. | Couldn't open the sample project. Try again. |
| `appTitle` | welcome_screen.dart:71 | فِكرة | بدون تغيير | Fikra |
| `tagline` | welcome_screen.dart:77 | اكتب. اربط. اسأل. | بدون تغيير | Write. Connect. Ask. |
| `welcomeCapture` | welcome_screen.dart:82 | اكتب أو سجّل صوت أو ارفع PDF | اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور | Type, record your voice, or add a PDF or photos |
| `welcomeLinks` | welcome_screen.dart:83 | فِكرة بتربط النوتس اللي شبه بعض لوحدها | فِكرة بتربط الملاحظات القريبة من بعض لوحدها | Fikra links related notes for you |
| `welcomeAsk` | welcome_screen.dart:84 | اسأل والإجابة تيجي من نوتسك مع المصدر | اسأل، والإجابة بتيجي من ملاحظاتك ومعاها المصدر | Ask, and get answers from your notes with sources |
| `welcomeDemoBadge` | welcome_screen.dart:88 | نسخة تجريبية: البيانات على الموبايل بس | نسخة تجريبية: كل حاجة بتفضل على موبايلك | Demo version: everything stays on your phone |
| `startNewProject` | welcome_screen.dart:92 | ابدأ مشروع جديد | بدون تغيير | Start a new project |
| `trySampleProject` | welcome_screen.dart:95 | جرّب مشروع تجريبي | جرّب مشروع جاهز | Try a sample project |

ليه شلت "ارفع": الملفات مش بتترفع لأي مكان، بتفضل على الموبايل (والإعدادات بتقول كده). "ارفع" بتدّي إحساس عكس كده.

### 5. المشاريع — `lib/features/projects/project_header.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `projectPillA11y` | project_header.dart:33 | المشروع: {name}. تغيير المشروع | المشروع: {name}. دوس عشان تغيّره | Project: {name}. Tap to change |
| `noProject` | project_header.dart:33 | مفيش | مفيش مشروع | None |
| `settings` | project_header.dart:55 | الإعدادات | بدون تغيير | Settings |
| `projectsTitle` | project_header.dart:68 | المشاريع | بدون تغيير | Projects |
| `newProject` | project_header.dart:92 | مشروع جديد | بدون تغيير | New project |
| `newProject` | project_header.dart:95 | مشروع جديد (عنوان الشيت) | بدون تغيير | New project |
| `create` | project_header.dart:95 | إنشاء | بدون تغيير | Create |
| `projectOptionsA11y` | project_header.dart:164 | خيارات {name} | خيارات «{name}» | Options for {name} |
| `renameProject` | project_header.dart:187 | إعادة تسمية | غيّر الاسم | Rename |
| `renameProject` | project_header.dart:190 | إعادة تسمية (عنوان الشيت) | غيّر الاسم | Rename |
| `save` | project_header.dart:190 | حفظ | احفظ | Save |
| `deleteProject` | project_header.dart:197 | حذف المشروع | احذف المشروع | Delete project |
| `deleteProjectTitle` | project_header.dart:203 | تحذف «{name}»؟ | بدون تغيير | Delete "{name}"? |
| `deleteProjectBody` | project_header.dart:204 | كل النوتس والروابط والمحادثات اللي في المشروع هتتحذف، ومش هينفع ترجّعها. | كل الملاحظات والملفات والمحادثات اللي في المشروع ده هتتحذف، ومش هتعرف ترجّعها. | All notes, files and chats in this project will be deleted. You can't undo this. |
| `projectDeleted` | project_header.dart:208 | المشروع اتحذف | بدون تغيير | Project deleted |
| `projectNameHint` | project_header.dart:239 | اسم المشروع | اسم المشروع، مثلاً: مذاكرة | Project name, e.g. Study |

ليه ضفت "الملفات" في رسالة الحذف: حذف المشروع بيمسح ملفاته من الموبايل كمان (lib/data/repositories.dart:100–117)، والرسالة الحالية مش بتقول كده.

### 6. الإضافة — `lib/features/add/`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `recordStartFailed` | add_screen.dart:145 | التسجيل مش شغال دلوقتي، جرّب تاني | مقدرناش نبدأ التسجيل. جرّب تاني. | Couldn't start recording. Try again. |
| `recordInterrupted` | add_screen.dart:171 | التسجيل اتقطع، جرّب تاني | التسجيل اتقطع. سجّل تاني. | The recording stopped. Record again. |
| `pdfOnly` | add_screen.dart:204 | اختار ملف PDF بس | الملف ده مش PDF. اختار ملف PDF. | That file isn't a PDF. Choose a PDF. |
| `fileOpenFailed` | add_screen.dart:213 | معرفناش نفتح الملف | مقدرناش نفتح الملف. جرّب ملف تاني. | Couldn't open that file. Try another one. |
| `photosOpenFailed` | add_screen.dart:236 | معرفناش نفتح الصور | مقدرناش نفتح الصور. جرّب تاني. | Couldn't open the photos. Try again. |
| `noteSaved` | add_screen.dart:314 | اتحفظت | الملاحظة اتحفظت | Note saved |
| `noteSavedAnalyzing` | add_screen.dart:314 | اتحفظت. فِكرة بتحللها دلوقتي | الملاحظة اتحفظت، وفِكرة بتحللها دلوقتي | Note saved. Fikra is analyzing it now. |
| `noteSaveFailed` | add_screen.dart:318 | معرفناش نحفظ النوت، جرّب تاني | مقدرناش نحفظ الملاحظة. جرّب تاني. | Couldn't save the note. Try again. |
| `voiceRecording` | add_screen.dart:327 | تسجيل صوتي (عنوان ملاحظة صوت بس) | بدون تغيير | Voice recording |
| `photosTitle` | add_screen.dart:327 | صور (عنوان ملاحظة صور بس) | بدون تغيير | Photos |
| `addTitle` | add_screen.dart:381 | إضافة | ملاحظة جديدة | New note |
| `titleOptionalHint` | add_screen.dart:431 | عنوان (اختياري) | بدون تغيير | Title (optional) |
| `bodyHintWithFileLinks` | add_screen.dart:457 | ضيف ملاحظة على الملف (اختياري) | اكتب كام سطر عن الملف عشان فِكرة تربطه (اختياري) | Add a few lines about the file so Fikra can link it (optional) |
| `bodyHint` | add_screen.dart:457 | اكتب فكرتك هنا… | بدون تغيير | Write your idea… |
| `addFooter` | add_screen.dart:482 | النوت بتتحفظ الأول، وبعدين فِكرة بتحلل النص وتربطه. الملفات بتفضل على موبايلك. | الملاحظة بتتحفظ على طول، وبعدين فِكرة بتحلل النص وتربطه بالباقي. الملفات بتفضل على موبايلك. | Your note is saved right away, then Fikra analyzes the text and links it to related notes. Files stay on your phone. |
| `discardRecording` | add_screen.dart:538 | إلغاء التسجيل | الغي التسجيل | Discard recording |
| `stopRecording` | add_screen.dart:545 | إيقاف التسجيل | وقّف التسجيل | Stop recording |
| `recordVoice` | add_screen.dart:558 | تسجيل صوت | سجّل صوت | Record voice |
| `addPdf` | add_screen.dart:565 | إرفاق ملف PDF | ضيف PDF | Add PDF |
| `addPhotos` | add_screen.dart:572 | إضافة صور | ضيف صور | Add photos |
| `save` | add_screen.dart:579 | حفظ | احفظ | Save |
| `removeFile` | add_screen.dart:697 | شيل الملف | بدون تغيير | Remove file |
| `removePhoto` | add_screen.dart:734 | شيل الصورة {n} | بدون تغيير | Remove photo {n} |
| `micNeededTitle` | add_screen.dart:770 | محتاجين إذن المايك | بدون تغيير | Microphone access needed |
| `close` | add_screen.dart:774 | إغلاق | اقفل | Close |
| `micBlockedBody` | add_screen.dart:782 | الإذن مقفول من الإعدادات. افتح إعدادات التطبيق وفعّل المايك. | المايك مقفول لفِكرة. افتح إعدادات التطبيق واسمح بالمايك. | Microphone access is off. Open app settings and allow the microphone. |
| `micAskBody` | add_screen.dart:783 | عشان تسجّل فكرة بصوتك، اسمح لفِكرة تستخدم المايك. | بدون تغيير | To record your voice, let Fikra use the microphone. |
| `openSettings` | add_screen.dart:788 | افتح الإعدادات | بدون تغيير | Open settings |
| `allowMic` | add_screen.dart:788 | اسمح بالمايك | بدون تغيير | Allow microphone |
| `recordingNow` | inline_recorder.dart:39 | بيسجّل | بدون تغيير | Recording |

ملحوظة على `addTitle`: التاب نفسه يفضل "إضافة"، بس عنوان الشاشة "ملاحظة جديدة" بيقول إنت بتعمل إيه. بالإنجليزي "Add" لوحدها كعنوان شاشة شكلها ناقص. (اتحسم)

ملحوظة على `bodyHintWithFileLinks`: اتحسم إن الخانة لما فيه ملف بتستخدم نسخة UX-04 اللي بتقول ليه يكتب. المفتاح القديم `bodyHintWithFile` ("اكتب كام سطر عن الملف (اختياري)") اتشال، ومفيش غير المفتاح ده للخانة دي.

ملحوظة على رسايل الحفظ (`noteSaved`، `noteSavedAnalyzing`، `noteSavedNoText`): التلاتة بيظهروا من نفس المكان بعد الحفظ، فكلهم بيبدأوا بـ"الملاحظة اتحفظت" / `Note saved`. البادج `badgeSaved` ("اتحفظت") حاجة تانية وبيفضل قصير.

ملحوظة على `discardRecording`: الزرار ده بيلغي التسجيل اللي شغال دلوقتي ويرمي الجزء اللي اتسجل. "الغي التسجيل" فعل زي "وقّف التسجيل" اللي جنبه.

### 7. قائمة الملاحظات — `lib/features/notes/`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `notesTitle` | notes_screen.dart:118 | النوتس | الملاحظات | Notes |
| `searchNotesHint` | notes_screen.dart:124 | دوّر في النوتس | دوّر في الملاحظات | Search notes |
| `notesEmptyTitle` | notes_screen.dart:152 | لسه مفيش نوتس | لسه مفيش ملاحظات | No notes yet |
| `notesEmptyBody` | notes_screen.dart:153 | اكتب فكرة أو سجّل صوت أو ارفع PDF، وفِكرة هتنظمها وتربطها لوحدها. | اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور، وفِكرة هترتّبها وتربطها لوحدها. | Type an idea, record your voice, or add a PDF or photos. Fikra sorts and links them for you. |
| `addFirstNote` | notes_screen.dart:155 | ضيف أول نوت | ضيف أول ملاحظة | Add your first note |
| `noResultsTitle` | notes_screen.dart:166 | مفيش نتايج | بدون تغيير | No results |
| `noResultsBody` | notes_screen.dart:167 | مفيش نوت فيها «{query}». جرّب كلمة تانية. | مفيش ملاحظة فيها «{query}». جرّب كلمة تانية. | No notes contain "{query}". Try another word. |
| `noteAnalysisFailed` | note_card.dart:62 | التحليل فشل | مقدرناش نحللها | Couldn't analyze |
| `noteRewriteSuggested` | note_card.dart:68 | في اقتراح صياغة | فيه صياغة مقترحة | Rewrite suggested |
| `noteSavedBadge` | note_card.dart:71 | محفوظة | بدون تغيير | Saved |
| `openFileA11y` | note_card.dart:100 | افتح ملف {name} (أو "PDF") | افتح {name} | Open {name} |
| `untitledNote` | lib/features/shared/note_presentation.dart:21 | نوت جديدة | ملاحظة جديدة | New note |
| `openFileFailed` | lib/features/shared/open_attachment.dart:10 | معرفناش نفتح الملف. اتأكد إن عندك تطبيق بيفتحه. | مقدرناش نفتح الملف. اتأكد إن عندك تطبيق يفتح النوع ده. | Couldn't open the file. Make sure you have an app that can open it. |

ملحوظة: notes_screen.dart:74 كومنت.

### 8. صفحة الملاحظة — `lib/features/note_details/note_details_screen.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `noteOptions` | note_details_screen.dart:41 | خيارات النوت | خيارات الملاحظة | Note options |
| `edit` | note_details_screen.dart:45 | تعديل | عدّل | Edit |
| `restoreOriginal` | note_details_screen.dart:54 | رجّع النص الأصلي | بدون تغيير | Restore original text |
| `originalRestored` | note_details_screen.dart:58 | رجعنا النص الأصلي | رجّعنا النص الأصلي | Original text restored |
| `deleteNote` | note_details_screen.dart:62 | حذف النوت | احذف الملاحظة | Delete note |
| `deleteNoteTitle` | note_details_screen.dart:68 | تحذف النوت دي؟ | تحذف الملاحظة دي؟ | Delete this note? |
| `deleteNoteBody` | note_details_screen.dart:69 | النوت وروابطها هيتحذفوا، ومش هينفع ترجّعها. | الملاحظة وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها. | The note, its files and its links will be deleted. You can't undo this. |
| `noteDeleted` | note_details_screen.dart:74 | النوت اتحذفت | الملاحظة اتحذفت | Note deleted |
| `back` | note_details_screen.dart:99 | رجوع | بدون تغيير | Back |
| `options` | note_details_screen.dart:102 | خيارات | بدون تغيير | Options |
| `noteNotFoundTitle` | note_details_screen.dart:113 | النوت مش موجودة | الملاحظة دي مش موجودة | Note not found |
| `noteNotFoundBody` | note_details_screen.dart:114 | يمكن تكون اتحذفت. | بدون تغيير | It may have been deleted. |
| `analysisFailedBanner` | note_details_screen.dart:165 | التحليل فشل، بس النوت محفوظة زي ما هي. | مقدرناش نحلل الملاحظة، بس هي محفوظة زي ما هي. | Couldn't analyze this note, but it's saved as is. |
| `analyzeAgain` | note_details_screen.dart:168 | جرّب التحليل تاني | حلّلها تاني | Analyze again |
| `viewEdited` | note_details_screen.dart:182 | النسخة المحسّنة | المعدّلة | Edited |
| `viewOriginal` | note_details_screen.dart:182 | الأصل | الأصلية | Original |
| `originalTextLabel` | note_details_screen.dart:186 | النص الأصلي | بدون تغيير | Original text |
| `topicsHeader` | note_details_screen.dart:193 | المفاهيم | المواضيع | Topics |
| `relatedNotesHeader` | note_details_screen.dart:199 | نوتس مرتبطة | ملاحظات مرتبطة | Related notes |
| `analyzingBody` | note_details_screen.dart:226 | فِكرة بتحلل النوت: بتطلّع المفاهيم وبتدوّر على نوتس مرتبطة. النوت نفسها محفوظة. | فِكرة بتحلل الملاحظة دلوقتي عشان تطلّع مواضيعها وتلاقي الملاحظات المرتبطة بيها. الملاحظة نفسها محفوظة. | Fikra is analyzing this note to find its topics and related notes. The note itself is saved. |
| `suggestedRewrite` | note_details_screen.dart:272 | اقتراح إعادة صياغة | صياغة مقترحة | Suggested rewrite |
| `demoBadge` | note_details_screen.dart:273 | تجريبي | بدون تغيير | Demo |
| `useRewrite` | note_details_screen.dart:283 | اعتمد | استخدمها | Use it |
| `keepOriginal` | note_details_screen.dart:292 | خلي الأصل | خلّي النص الأصلي | Keep original text |
| `pdfFile` | note_details_screen.dart:310 | ملف PDF | بدون تغيير | PDF file |
| `openFileA11y` | note_details_screen.dart:320 | افتح ملف {name} | افتح {name} | Open {name} |
| `openPhotoA11y` | note_details_screen.dart:364 | افتح الصورة {n} | بدون تغيير | Open photo {n} |
| `relatedLoadFailed` | note_details_screen.dart:382 | مقدرناش نجيب النوتس المرتبطة دلوقتي. | مقدرناش نجيب الملاحظات المرتبطة دلوقتي. | Couldn't load related notes right now. |
| `relatedEmpty` | note_details_screen.dart:397 | لسه مفيش نوتس شبهها في المشروع ده. | لسه مفيش ملاحظات مرتبطة بيها في المشروع ده. | No related notes in this project yet. |
| `relatedRowA11y` | note_details_screen.dart:405 | {title}، {reason} | بدون تغيير | {title}, {reason} |

ليه "المعدّلة" بدل "النسخة المحسّنة": الزرار ده بيظهر لما `editedText` يبقى مختلف عن الأصل (lib/data/local/database.dart:199). ده بيحصل لو المستخدم قبل الصياغة المقترحة، أو عدّل بإيده (lib/data/repositories.dart:294). في الحالة التانية كلمة "المحسّنة" غلط.

ليه ضفت "ملفاتها" في رسالة الحذف: حذف الملاحظة بيمسح ملفاتها من الموبايل (lib/data/repositories.dart:309).

### 9. تعديل الملاحظة — `lib/features/note_details/edit_note_screen.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `changesSaved` | edit_note_screen.dart:40 | التعديل اتحفظ | بدون تغيير | Changes saved |
| `changesSaveFailed` | edit_note_screen.dart:43 | معرفناش نحفظ التعديل، جرّب تاني | مقدرناش نحفظ التعديل. جرّب تاني. | Couldn't save your changes. Try again. |
| `unsavedTitle` | edit_note_screen.dart:63 | عندك تعديلات مش محفوظة | بدون تغيير | You have unsaved changes |
| `saveChanges` | edit_note_screen.dart:66 | احفظ التعديل | بدون تغيير | Save changes |
| `discardChanges` | edit_note_screen.dart:68 | اخرج من غير حفظ | بدون تغيير | Discard changes |
| `keepEditing` | edit_note_screen.dart:73 | كمّل تعديل | بدون تغيير | Keep editing |
| `noteNotFoundTitle` | edit_note_screen.dart:111 | النوت مش موجودة | الملاحظة دي مش موجودة | Note not found |
| `noteNotFoundBody` | edit_note_screen.dart:112 | يمكن تكون اتحذفت. | بدون تغيير | It may have been deleted. |
| `editNoteTitle` | edit_note_screen.dart:118 | تعديل النوت | تعديل الملاحظة | Edit note |
| `titleHint` | edit_note_screen.dart:120 | العنوان | بدون تغيير | Title |
| `noteTextA11y` | edit_note_screen.dart:126 | نص النوت | نص الملاحظة | Note text |
| `originalKeptHint` | edit_note_screen.dart:140 | النص الأصلي بيفضل محفوظ، وتقدر ترجّعه من خيارات النوت. | النص الأصلي بيفضل محفوظ، وتقدر ترجّعه من خيارات الملاحظة. | Your original text is kept. You can restore it from the note's options. |
| `originalKeptHint` | edit_note_screen.dart:141 | التفريغ الأصلي بيفضل محفوظ، وتقدر ترجّعه من خيارات النوت. | يتشال، ونستخدم نفس جملة السطر 140 | (same) |
| `saveChanges` | edit_note_screen.dart:145 | حفظ التعديل | احفظ التعديل | Save changes |
| `cancel` | edit_note_screen.dart:147 | إلغاء | بدون تغيير | Cancel |

ليه شلت "التفريغ": مفيش تفريغ صوت لكلام في التطبيق. الملاحظة الصوتية ملهاش غير النص اللي المستخدم كتبه بإيده، فالجملة دي بتوعد بحاجة مش موجودة.

### 10. الروابط — `lib/features/links/`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `clusterGeneral` | graph_layout.dart:124 | أفكار عامة | بدون تغيير | General |
| `moreGroups` | links_screen.dart:164 | مجموعات أكتر | باقي المجموعات | More groups |
| `linksTitle` | links_screen.dart:233 | الروابط | بدون تغيير | Links |
| `linksEmptyTitle` | links_screen.dart:265 | الروابط بتظهر هنا | بدون تغيير | Links show up here |
| `linksEmptyBody` | links_screen.dart:266 | ضيف نوتين أو أكتر عن مواضيع قريبة، وفِكرة هتربطهم ببعض. | ضيف ملاحظتين أو أكتر عن مواضيع قريبة، وفِكرة هتربطهم ببعض. | Add two or more notes on related topics, and Fikra will link them. |
| `addNote` | links_screen.dart:268 | ضيف نوت | ضيف ملاحظة | Add a note |
| `linksSummary` | links_screen.dart:285 | {notesCount} · {linksCount} | بدون تغيير (بالجمع الجديد) | {notesCount} · {linksCount} |
| `zoomIn` | links_screen.dart:293 | تكبير | كبّر | Zoom in |
| `zoomOut` | links_screen.dart:299 | تصغير | صغّر | Zoom out |
| `resetView` | links_screen.dart:305 | رجّع العرض | بدون تغيير | Reset view |
| `showGroupA11y` | links_screen.dart:383 | عرض {notesCount} في {cluster} | اعرض {notesCount} في «{cluster}» | Show {notesCount} in {cluster} |
| `moreGroupsCount` | links_screen.dart:392 | مجموعات أكتر ({count}) | باقي المجموعات ({count}) | More groups ({count}) |
| `noLinksYet` | links_screen.dart:412 | لسه مفيش روابط. النوتس اللي فيها مفاهيم مشتركة هتترابط. | لسه مفيش روابط. الملاحظات اللي بتتكلم في نفس المواضيع هتتربط ببعض لوحدها. | No links yet. Notes on the same topics get linked automatically. |
| `untitledNote` | links_screen.dart:449 | نوت جديدة | ملاحظة جديدة | New note |
| `clusterGeneral` | links_screen.dart:498 | أفكار عامة | بدون تغيير | General |
| `nodeMeta` | links_screen.dart:498 | {cluster} · {linksCount} | بدون تغيير | {cluster} · {linksCount} |
| `openNote` | links_screen.dart:523 | فتح النوت | افتح الملاحظة | Open note |

### 11. اسأل — `lib/features/ask/ask_screen.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `askFailed` | ask_screen.dart:58 | معرفناش نجاوب دلوقتي، جرّب تاني | مقدرناش نجاوب دلوقتي. جرّب تاني. | Couldn't answer right now. Try again. |
| `clearChatTitle` | ask_screen.dart:84 | تمسح المحادثة؟ | بدون تغيير | Clear this chat? |
| `clearChatBody` | ask_screen.dart:85 | الأسئلة والإجابات هتتمسح. النوتس نفسها مش هتتأثر. | الأسئلة والإجابات هتتمسح، والملاحظات نفسها مش هيحصلها حاجة. | Questions and answers will be cleared. Your notes stay as they are. |
| `clear` | ask_screen.dart:86 | مسح | امسح | Clear |
| `askSuggestion` | ask_screen.dart:112 | إيه اللي كتبته عن {title}؟ | بدون تغيير | What did I write about {title}? |
| `askTitle` | ask_screen.dart:119 | اسأل | بدون تغيير | Ask |
| `clearChatA11y` | ask_screen.dart:125 | مسح المحادثة | امسح المحادثة | Clear chat |
| `askDemoBadge` | ask_screen.dart:137 | إجابات تجريبية من نوتسك | إجابات تجريبية من ملاحظاتك | Demo answers from your notes |
| `askEmptyTitle` | ask_screen.dart:159 | اسأل نوتسك | اسأل عن ملاحظاتك | Ask about your notes |
| `askEmptyNoNotes` | ask_screen.dart:161 | ضيف نوتس الأول، وبعدها اسأل عنها هنا. الإجابة بتيجي من نوتسك بس، ومعاها المصدر. | ضيف ملاحظات الأول، وبعدين اسأل عنها هنا. الإجابة بتيجي من ملاحظاتك بس، ومعاها المصدر. | Add some notes first, then ask about them here. Answers come only from your notes, with sources. |
| `askEmptyBody` | ask_screen.dart:162 | الإجابة بتيجي من النوتس اللي في المشروع ده بس، ومعاها المصدر. | الإجابة بتيجي من ملاحظات المشروع ده بس، ومعاها المصدر. | Answers come only from this project's notes, with sources. |
| `askHint` | ask_screen.dart:221 | اسأل عن أي حاجة في نوتسك | اسأل عن أي حاجة في ملاحظاتك | Ask anything about your notes |
| `send` | ask_screen.dart:233 | إرسال | ابعت | Send |
| `notFoundInNotes` | ask_screen.dart:297 | ملقيناش إجابة في نوتسك | ملقيناش إجابة في ملاحظاتك | No answer found in your notes |
| `sources` | ask_screen.dart:305 | المصادر | بدون تغيير | Sources |
| `sourceA11y` | ask_screen.dart:332 | مصدر {index}: {title} | بدون تغيير | Source {index}: {title} |
| `sourceDeletedA11y` | ask_screen.dart:332 | مصدر {index}: نوت اتحذفت | مصدر {index}: ملاحظة اتحذفت | Source {index}: deleted note |
| `deletedNote` | ask_screen.dart:352 | نوت اتحذفت | ملاحظة اتحذفت | Deleted note |

### 12. الإعدادات — `lib/features/settings/settings_screen.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `eraseAllTitle` | settings_screen.dart:19 | تمسح كل البيانات؟ | بدون تغيير | Erase all data? |
| `eraseAllBody` | settings_screen.dart:20 | كل المشاريع والنوتس والتسجيلات والملفات والمحادثات هتتمسح من الموبايل، ومش هينفع ترجّعها. | كل المشاريع والملاحظات والتسجيلات والملفات والمحادثات هتتمسح من الموبايل، ومش هتعرف ترجّعها. | All projects, notes, recordings, files and chats will be erased from this phone. You can't undo this. |
| `eraseAllConfirm` | settings_screen.dart:21 | امسح كله | امسح كل حاجة | Erase everything |
| `eraseAllDone` | settings_screen.dart:31 | كل حاجة اتمسحت | بدون تغيير | All data erased |
| `eraseAllPartial` | settings_screen.dart:33 | البيانات اتمسحت، بس شوية ملفات لسه. هتتمسح لوحدها أول ما تفتح التطبيق تاني. | البيانات اتمسحت، بس فيه ملفات لسه. هتتمسح لوحدها أول ما تفتح التطبيق تاني. | Your data was erased, but a few files are left. They'll be removed next time you open the app. |
| `eraseAllFailed` | settings_screen.dart:35 | مقدرناش نمسح البيانات، جرّب تاني | مقدرناش نمسح البيانات. جرّب تاني. | Couldn't erase your data. Try again. |
| `back` | settings_screen.dart:57 | رجوع | بدون تغيير | Back |
| `settingsTitle` | settings_screen.dart:64 | الإعدادات | بدون تغيير | Settings |
| `appearance` | settings_screen.dart:65 | المظهر | بدون تغيير | Appearance |
| `themeSystem` | settings_screen.dart:67 | زي الموبايل | بدون تغيير | System |
| `themeLight` | settings_screen.dart:67 | فاتح | بدون تغيير | Light |
| `themeDark` | settings_screen.dart:67 | غامق | بدون تغيير | Dark |
| `themeHint` | settings_screen.dart:73 | لو اخترت "زي الموبايل"، فِكرة هتمشي على وضع الموبايل الفاتح أو الغامق. | «زي الموبايل» بيخلّي شكل التطبيق فاتح أو غامق على حسب موبايلك. | "System" follows your phone's light or dark mode. |
| `dataSection` | settings_screen.dart:76 | البيانات | بدون تغيير | Data |
| `dataStaysLocal` | settings_screen.dart:85 | نوتسك وملفاتك محفوظة على الموبايل ده بس، ومش بتتنقل لأي مكان. | ملاحظاتك وملفاتك محفوظة على الموبايل ده بس، ومش بتتبعت لأي مكان. | Your notes and files are stored only on this phone and are never sent anywhere. |
| `eraseAll` | settings_screen.dart:92 | مسح كل البيانات | امسح كل البيانات | Erase all data |
| `aboutSection` | settings_screen.dart:97 | عن التطبيق | بدون تغيير | About |
| `appTitle` | settings_screen.dart:107 | فِكرة | بدون تغيير | Fikra |
| `tagline` | settings_screen.dart:108 | اكتب. اربط. اسأل. | بدون تغيير | Write. Connect. Ask. |
| `demoVersion` | settings_screen.dart:112 | نسخة تجريبية | بدون تغيير | Demo version |
| `languageSection` | (جديد) | — | اللغة | Language |
| `languageSystem` | (جديد) | — | زي الموبايل | System |
| `languageArabic` | (جديد) | — | العربية | العربية |
| `languageEnglish` | (جديد) | — | English | English |

اسم كل لغة بيتكتب بلغته هو في الواجهتين ("العربية" و"English")، عشان اللي فتح التطبيق بلغة مش فاهمها يلاقي لغته.

### 13. الـAI التجريبي — `lib/data/ai/demo_ai_service.dart`

النصوص اللي بتظهر للمستخدم:

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `demoLinkReason` | demo_ai_service.dart:109 | مرتبطة بـ{concept} | بدون تغيير | Both mention {concept} |
| `demoAnswerNotFound` | demo_ai_service.dart:142 | مفيش نوت في المشروع ده بتتكلم عن الموضوع. جرّب تسأل بطريقة تانية أو ضيف نوت عنه. | مفيش ملاحظة في المشروع ده بتتكلم عن الموضوع ده. جرّب تسأل بطريقة تانية، أو ضيف ملاحظة عنه. | None of the notes in this project cover that. Try asking another way, or add a note about it. |
| `demoAnswerIntro` | demo_ai_service.dart:147 | من نوتسك في المشروع ده: | من ملاحظاتك في المشروع ده: | From your notes in this project: |
| `demoAnswerFooter` | demo_ai_service.dart:151 | (إجابة تجريبية من نوتسك) | يتشال (اتحسم، شوف UX-14). مفيش مفتاح ARB للسطر ده، والبادج `askDemoBadge` بيكفي. | (removed) |
| `clusterGeneral` | demo_ai_service.dart:172 | أفكار عامة | بدون تغيير | General |
| `untitledNoteFallback` | demo_ai_service.dart:206 | نوت بدون عنوان | ملاحظة من غير عنوان | Untitled note |
| `expandLlm` | demo_ai_service.dart:55 | LLM (نموذج لغوي كبير) | بدون تغيير | LLM (large language model) |
| `expandRag` | demo_ai_service.dart:54 | RAG (Retrieval-Augmented Generation) | بدون تغيير | RAG (Retrieval-Augmented Generation) |

**المواضيع (concepts)**، السطور 17–50. دي القيم اللي بتظهر كـchips:

| المكان | الحالي | المقترح | English |
|---|---|---|---|
| demo_ai_service.dart:17 | RAG | بدون تغيير | RAG |
| demo_ai_service.dart:19 | LLM | بدون تغيير | LLM |
| demo_ai_service.dart:21 | Embeddings | بدون تغيير | Embeddings |
| demo_ai_service.dart:24 | البحث الدلالي | بدون تغيير | Semantic search |
| demo_ai_service.dart:26 | AI Agents | بدون تغيير | AI agents |
| demo_ai_service.dart:27 | الذكاء الاصطناعي | بدون تغيير | AI |
| demo_ai_service.dart:29 | Flutter | بدون تغيير | Flutter |
| demo_ai_service.dart:31 | إدارة الحالة | بدون تغيير | State management |
| demo_ai_service.dart:34 | تصميم الواجهات | بدون تغيير | UI design |
| demo_ai_service.dart:38 | FastAPI | بدون تغيير | FastAPI |
| demo_ai_service.dart:39 | APIs | بدون تغيير | APIs |
| demo_ai_service.dart:40 | قواعد البيانات | بدون تغيير | Databases |
| demo_ai_service.dart:44 | المحاضرات | بدون تغيير | Lectures |
| demo_ai_service.dart:45 | الامتحانات | بدون تغيير | Exams |
| demo_ai_service.dart:46 | المذاكرة | بدون تغيير | Studying |
| demo_ai_service.dart:47 | الشبكات | بدون تغيير | Networking |
| demo_ai_service.dart:48 | صناعة المحتوى | بدون تغيير | Content creation |

**المجموعات (clusters)**، السطور 17–50:

| المكان | الحالي | المقترح | English |
|---|---|---|---|
| demo_ai_service.dart:17 | الذكاء الاصطناعي | بدون تغيير | AI |
| demo_ai_service.dart:29 | تطوير التطبيقات | بدون تغيير | App development |
| demo_ai_service.dart:38 | الباك إند | بدون تغيير | Backend |
| demo_ai_service.dart:44 | المذاكرة | بدون تغيير | Studying |
| demo_ai_service.dart:48 | المحتوى | بدون تغيير | Content |

الحاجات اللي مش بتظهر وما اتحسبتش: مفاتيح البحث في القاموس (الكلمات على الشمال في السطور 17–50، زي `'نموذج لغوي'` و`'محاضرة'`) والـstop words (السطور 59–91). دي بيتدوّر بيها جوه نص المستخدم.

ملحوظة لمرحلة اللغات: القاموس دلوقتي بيعرف "محاضرة" و"امتحان" و"مذاكرة" و"شبكات" و"فيديو" و"تصميم" و"واجهة" و"ذكاء اصطناعي" بالعربي بس. عشان نص الـdemo الإنجليزي يطلّع نفس المواضيع، لازم تتضاف مفاتيح إنجليزي: `lecture`، `exam`، `study`، `network`، `video`، `design`، `interface`، `ai`، و`embeddings` (المفاتيح اللاتيني بتتطابق ككلمة كاملة، فـ`embedding` الموجود مش بيلقط "embeddings" اللي في `sample6Body` الإنجليزي).

**قيد معروف (اتحسم: الاختيار ب من مراجعة Argon):** أسماء المواضيع والمجموعات (زي "الذكاء الاصطناعي" و"المذاكرة" و"أفكار عامة") بتتخزن في الداتابيز كنص، بلغة الواجهة وقت التحليل، ومفيش مفتاح محايد زي `topic_ai`. لو المستخدم غيّر لغة التطبيق بعدين، الملاحظات القديمة هتفضل مواضيعها ومجموعاتها باللغة اللي اتحللت بيها، والجديدة هتتحلل باللغة الجديدة. ده مقبول للنسخة التجريبية، ومفيش مفاتيح ARB للمواضيع أو المجموعات بسببه. الجدولين اللي فوق بيوضحوا القيمة اللي الـdemo AI بيطلّعها في كل لغة.

### 14. المشروع الجاهز — `lib/data/demo/demo_seed.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `sampleProjectName` | demo_seed.dart:7 | مشروع التخرج | بدون تغيير | Graduation project |
| `sample1Title` | demo_seed.dart:11 | فكرة المشروع | بدون تغيير | Project idea |
| `sample1Body` | demo_seed.dart:11 | تطبيق نوتس بيستخدم الذكاء الاصطناعي عشان يربط الأفكار ببعض ويجاوب على أسئلتي من نوتسي بس. | تطبيق ملاحظات بيستخدم الذكاء الاصطناعي عشان يربط الأفكار ببعض ويجاوب على أسئلتي من ملاحظاتي بس. | A notes app that uses AI to connect ideas and answer my questions from my own notes only. |
| `sample2Title` | demo_seed.dart:13 | إزاي RAG بيشتغل | بدون تغيير | How RAG works |
| `sample2Body` | demo_seed.dart:14 | الـrag بيجيب أقرب أجزاء من النوتس بالـembedding وبعدين الـllm بيكتب الإجابة منها مع ذكر المصدر | الـrag بيجيب أقرب أجزاء من الملاحظات بالـembedding وبعدين الـllm بيكتب الإجابة منها مع ذكر المصدر | rag finds the closest chunks of my notes using embeddings, then the llm writes the answer from them and cites the source |
| `sample3Title` | demo_seed.dart:17 | شكل الواجهة | بدون تغيير | The UI |
| `sample3Body` | demo_seed.dart:18 | تصميم الواجهة داكن وبسيط، بالعربي من اليمين للشمال، وفيه أربع تابات: إضافة، النوتس، الروابط، اسأل. | تصميم الواجهة غامق وبسيط، بالعربي من اليمين للشمال، وفيه أربع تابات: إضافة، الملاحظات، الروابط، اسأل. | The UI is dark and simple, right-to-left in Arabic, with four tabs: Add, Notes, Links, Ask. |
| `sample4Title` | demo_seed.dart:20 | إدارة الحالة في Flutter | بدون تغيير | State management in Flutter |
| `sample4Body` | demo_seed.dart:20 | هستخدم riverpod لإدارة الحالة في flutter، وقاعدة بيانات محلية للنسخة التجريبية. | بدون تغيير | I'll use riverpod for state management in flutter, with a local database for the demo. |
| `sample5Title` | demo_seed.dart:21 | الباك إند | بدون تغيير | Backend |
| `sample5Body` | demo_seed.dart:21 | علاء هيعمل الباك إند بـfastapi و postgres مع pgvector، والتطبيق هيكلمه عن طريق api. | بدون تغيير | Alaa is building the backend with fastapi and postgres with pgvector. The app talks to it through an api. |
| `sample6Title` | demo_seed.dart:22 | البحث الدلالي | بدون تغيير | Semantic search |
| `sample6Body` | demo_seed.dart:22 | البحث الدلالي بيدوّر بالمعنى مش بالكلمة، وده معتمد على التضمينات اللي بتتخزن في قاعدة بيانات. | البحث الدلالي بيدوّر بالمعنى مش بالكلمة، وده معتمد على الـembedding اللي بيتخزن في قاعدة بيانات. | Semantic search looks for meaning, not exact words. It relies on embeddings stored in a database. |
| `sample7Title` | demo_seed.dart:23 | محاضرة الشبكات | بدون تغيير | Networks lecture |
| `sample7Body` | demo_seed.dart:23 | محاضرة الشبكات النهارده كانت عن TCP و UDP، لازم أراجعها قبل الامتحان. | بدون تغيير | Today's networks lecture was about TCP and UDP. I need to review it before the exam. |

ملحوظات:

- demo_seed.dart:5 كومنت.
- النص الإنجليزي للعينات متعمّد يكون بحروف صغيرة في `rag` و`llm` و`fastapi`، عشان الـdemo بيوري "الصياغة المقترحة" بتكبّر الحروف وتشرح الاختصارات.
- `sample3Body` (اتحسم: الاختيار أ من مراجعة Argon): بيفضل ملاحظة تاريخية كتبها طالب عن فكرة مشروعه، فـ"غامق" و"بالعربي من اليمين للشمال" بيفضلوا رغم إن التطبيق بقى فيه فاتح وإنجليزي. الحاجة الوحيدة اللي اتغيرت أسماء التابات، بالترتيب الحالي (UX-01 اتحسم إن الترتيب يفضل زي ما هو) وبأسمائها الجديدة.
- `sample6Body`: "الـembedding" بدل "التضمينات"، لأن محدش بيقول "التضمينات". بالمفرد مش "الـembeddings" عشان سببين: نفس الكلمة اللي في `sample2Body` ("بالـembedding")، والقاموس في demo_ai_service.dart (`_containsWord`، حوالي السطر 178) بيطابق المفاتيح اللاتيني ككلمة كاملة، فالمفتاح `embedding` مش بيلقط "embeddings". لو اتكتبت بالجمع، الملاحظة دي هتخسر موضوع Embeddings وربطها بـ`sample2Body`.

### 15. نصوص جديدة (من الخطة ومن docs/plans/ux-proposals.md)

مش موجودة في الكود لسه، ومش داخلة في العدد اللي تحت. `bodyHintWithFileLinks` (UX-04) مش هنا: اتحسم إنه بيحل محل الخانة القديمة، فبقى في القسم 6 مكان `bodyHintWithFile`.

| المفتاح | لفين | المقترح | English |
|---|---|---|---|
| `clearSearch` | زرار ✕ في البحث، وزرار حالة "مفيش نتايج" (UX-05) | امسح البحث | Clear search |
| `noteSavedNoText` | toast بعد حفظ ملف من غير نص (UX-04) | الملاحظة اتحفظت. اكتب عنها كام سطر عشان تتربط بالباقي | Note saved. Add a few lines so it can be linked. |
| `noTextNoLinks` | صفحة الملاحظة لما مفيش نص (UX-04) | الملاحظة دي مفيهاش نص، عشان كده فِكرة مش هتعرف تربطها بحاجة. | This note has no text, so Fikra can't link it. |
| `pdfOpenElsewhere` | عارض الـPDF | افتح في تطبيق تاني | Open in another app |
| `pdfPageOf` | عارض الـPDF | {page} من {total} | {page} of {total} |
| `pdfLoadFailed` | عارض الـPDF | مقدرناش نفتح الملف ده. ممكن يكون بايظ أو اتحذف. | Couldn't open this file. It may be damaged or missing. |
| `languageSection` وأخواتها | الإعدادات | شوف القسم 12 | |

### العدد

252 سطر في جداول القسم (ب): 228 نص في الجداول العادية، و17 موضوع و5 مجموعات من الـdemo AI، وصيغتين للوقت واليوم. ده من غير جدول الجمع (هو تفصيل لأربع سطور موجودة أصلاً)، ومن غير المفاتيح الأربعة الجديدة للغة، ومن غير الـ6 نصوص الجديدة في القسم 15. يعني المجموع 262 سطر نص (252 + 4 + 6). (`bodyHintWithFileLinks` بيتعد مرة واحدة، في القسم 6.) فيه 23 ملف جواهم حروف عربي، و22 منهم فيهم نص بيظهر للمستخدم. الملف الوحيد اللي مفيهوش هو lib/app/app_config.dart، لأن العربي اللي فيه كومنت بس.

### 16. روابط الملاحظة (المرحلة 2 من خطة الروابط) — `lib/features/note_details/` و`lib/features/shared/link_picker.dart`

قسم "ملاحظات مرتبطة" في صفحة الملاحظة بقى قسم "الروابط": المستخدم بيربط بإيده، وبيقبل أو يرفض اقتراحات التحليل. العنوان بقى نفس اسم تاب الروابط (`navLinks`). المفاتيح الأربعة القديمة في القسم 8 (`relatedNotesHeader`، `relatedLoadFailed`، `relatedEmpty`، `relatedRowA11y`) اتشالت من ملفات الـARB، والمفاتيح اللي تحت بتحل محلها. المفاتيح الموجودة اللي القسم ده بيستخدمها زي ما هي: `searchNotesHint`، `noResultsTitle`، `noResultsBody`، `save`، `cancel`.

| المفتاح | لفين | المقترح | English |
|---|---|---|---|
| `noteLinksHeader` | عنوان القسم في صفحة الملاحظة (بدل `relatedNotesHeader`) | الروابط | Links |
| `linkToNote` | الزرار اللي فوق القسم، وعنوان شيت الاختيار | اربط بملاحظة | Link to a note |
| `noteLinksEmpty` | القسم لما يكون فاضي (بدل `relatedEmpty`) | لسه مفيش روابط للملاحظة دي. دوس «اربط بملاحظة» عشان تربطها بملاحظات تانية. | No links yet. Tap "Link to a note" to connect this note to others. |
| `noteLinksLoadFailed` | القسم لما الروابط ماتتحملش (بدل `relatedLoadFailed`) | مقدرناش نجيب الروابط دلوقتي. | Couldn't load links right now. |
| `linkSuggestedTag` | تاج على الرابط اللي التحليل اقترحه، وعلى الملاحظة المقترحة في شيت الاختيار | اقتراح | Suggested |
| `linkRowA11y` | قارئ الشاشة: صف فيه عنوان وتفصيلة (السبب، أو "مربوطة أصلاً"، أو "اقتراح") (بدل `relatedRowA11y`) | {title}، {detail} | {title}, {detail} |
| `suggestedLinkA11y` | قارئ الشاشة: صف الاقتراح في القسم | اقتراح: {title} | Suggested: {title} |
| `acceptLink` | زرار على الاقتراح | اقبل | Accept |
| `acceptLinkA11y` | قارئ الشاشة: زرار القبول | اقبل الربط بـ«{title}» | Accept link to {title} |
| `rejectLink` | زرار على الاقتراح | ارفض | Reject |
| `rejectLinkA11y` | قارئ الشاشة: زرار الرفض | ارفض الربط بـ«{title}» | Reject link to {title} |
| `linkOptionsA11y` | قارئ الشاشة: زرار الخيارات على رابطك | خيارات الرابط مع «{title}» | Link options for {title} |
| `linkOptionsTitle` | عنوان شيت خيارات الرابط | خيارات الرابط | Link options |
| `editLinkReason` | خيار في الشيت، وعنوان شيت تعديل السبب | عدّل السبب | Edit reason |
| `removeLink` | خيار في الشيت | شيل الرابط | Remove link |
| `removeLinkTitle` | رسالة التأكيد | تشيل الرابط ده؟ | Remove this link? |
| `removeLinkBody` | رسالة التأكيد | الملاحظتين هيفضلوا زي ما هم، بس فِكرة مش هتقترح تربطهم ببعض تاني. | Both notes stay as they are, but Fikra won't suggest linking them again. |
| `removeLinkConfirm` | زرار التأكيد | شيل | Remove |
| `linkRemoved` | toast بعد الشيل | الرابط اتشال | Link removed |
| `linkUpdateFailed` | toast لما القبول أو الرفض أو الشيل يفشل، ورسالة في شيت تعديل السبب | مقدرناش نعدّل الرابط. جرّب تاني. | Couldn't update the link. Try again. |
| `linkReasonHint` | خانة السبب في شيت الاختيار وشيت التعديل | السبب (اختياري) | Reason (optional) |
| `alreadyLinked` | جنب الملاحظة اللي مربوطة بإيدك في شيت الاختيار | مربوطة أصلاً | Already linked |
| `linkPickerEmpty` | شيت الاختيار لما مفيش ملاحظات تانية في المشروع | مفيش ملاحظات تانية في المشروع ده تربطها بالملاحظة دي. | There are no other notes in this project to link. |
| `linkFailed` | رسالة في شيت الاختيار لما الربط يفشل | مقدرناش نربط الملاحظات. جرّب تاني. | Couldn't link the notes. Try again. |
| `linkSelected` | زرار التأكيد في شيت الاختيار | جمع (تحت) | جمع (تحت) |
| `notesLinked` | toast بعد الربط | جمع (تحت) | جمع (تحت) |

**الجمع بصيغة ICU:**

| المفتاح | zero | one | two | few | many | other |
|---|---|---|---|---|---|---|
| `linkSelected` ع | اربط | اربط ملاحظة واحدة | اربط ملاحظتين | اربط {count} ملاحظات | اربط {count} ملاحظة | اربط {count} ملاحظة |
| `linkSelected` En | Link (`=0`) | Link 1 note | — | — | — | Link {count} notes |
| `notesLinked` ع | مفيش ملاحظات اتربطت | الملاحظة اتربطت بملاحظة واحدة | الملاحظة اتربطت بملاحظتين | الملاحظة اتربطت بـ{count} ملاحظات | الملاحظة اتربطت بـ{count} ملاحظة | الملاحظة اتربطت بـ{count} ملاحظة |
| `notesLinked` En | No notes were linked (`=0`) | Linked to 1 note | — | — | — | Linked to {count} notes |

ملحوظات:

- "شيل الرابط" مش "احذف الرابط": الرابط مش حاجة ليها اسم زي الملاحظة والملف، والملاحظتين نفسهم مابيتحذفوش. نفس فعل `removeFile` و`removePhoto`.
- "اقتراح" (اسم) بدل "مقترح" أو "مقترحة"، عشان التاج بيتحط على رابط (مذكر) وعلى ملاحظة (مؤنث).
- `linkSelected` بصيغة zero بيظهر بس والزرار مقفول (مفيش حاجة متختارة).
- `notesLinked` بصيغة zero بيظهر بس لو كل الملاحظات اللي اتختارت اتحذفت قبل التأكيد.
- عداد السبب (`12/80`) أرقام بس، من غير نص، وبيتكتب من الشمال لليمين في اللغتين زي حجم الملف.

### 17. النقل بين المشاريع ورسايل المسح (المرحلة 3 من خطة الروابط) — `lib/features/note_details/` و`lib/features/shared/project_picker.dart` و`lib/features/projects/` و`lib/features/ask/`

"انقل لمشروع تاني" بقى في خيارات الملاحظة، ورسالة مسح المشروع بقت بتقول بالأرقام إيه اللي هيتحذف. المفاتيح الموجودة اللي القسم ده بيستخدمها زي ما هي: `notesCount` و`linksCount` (للأرقام جوه الجمل، وبيظهروا بس لو الرقم أكبر من صفر)، `deleteProjectTitle`، `projectDeleted`، `cancel`، `firstProjectTitle` ("سمّي أول مشروع"، موجود أصلاً). `deletedNote` و`sourceDeletedA11y` (القسم 11) اتشالوا من ملفات الـARB، و`sourceMissing` و`sourceMissingA11y` بيحلوا محلهم.

| المفتاح | لفين | المقترح | English |
|---|---|---|---|
| `moveToProject` | خيار في شيت خيارات الملاحظة، وعنوان شيت اختيار المشروع | انقل لمشروع تاني | Move to another project |
| `moveNoOtherProject` | شيت اختيار المشروع لو مفضلش مشروع تاني | مفيش مشروع تاني تنقل له الملاحظة. | There's no other project to move this note to. |
| `moveNoteTitle` | عنوان رسالة التأكيد | تنقل الملاحظة لـ«{project}»؟ | Move this note to "{project}"? |
| `moveNoteBody` | رسالة التأكيد لما روابط هتتشال. `{lost}` = `linksCount` و/أو `suggestionsCount`، متوصّلين بـ`listTwo` | الملاحظة هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا. | The note moves with its files. Its {lost} to notes that stay here will be removed. |
| `moveNoteBodyNoLinks` | رسالة التأكيد لما مفيش حاجة هتتشال | الملاحظة هتتنقل بملفاتها، ومفيش روابط هتتشال. | The note moves with its files. No links will be removed. |
| `moveConfirm` | زرار التأكيد | انقل | Move |
| `noteMoved` | toast بعد النقل | الملاحظة اتنقلت لـ«{project}» | Note moved to "{project}" |
| `moveNoteFailed` | toast لما النقل يفشل | مقدرناش ننقل الملاحظة. جرّب تاني. | Couldn't move the note. Try again. |
| `suggestionsCount` | عدد الاقتراحات جوه `moveNoteBody` | جمع (تحت) | جمع (تحت) |
| `filesCount` | عدد الملفات جوه `deleteProjectBody` | جمع (تحت) | جمع (تحت) |
| `listTwo` | بيوصّل حاجتين في جملة | {first} و{second} | {first} and {second} |
| `listThree` | بيوصّل تلات حاجات في جملة | {first} و{second} و{third} | {first}, {second} and {third} |
| `deleteProjectBody` | رسالة مسح المشروع (اتغيرت، القسم 5). `{items}` = `notesCount` و`filesCount` و`linksCount`، اللي أكبر من صفر بس، متوصّلين بـ`listTwo` أو `listThree` | هيتحذف {items}، والمحادثة كمان. مش هتعرف ترجّعهم. | This deletes {items}, plus the chat. You can't undo this. |
| `deleteProjectEmptyBody` | رسالة مسح مشروع مفيهوش ملاحظات ولا محادثة | المشروع ده فاضي، مفيهوش ملاحظات. | This project is empty. It has no notes. |
| `deleteProjectEmptyChatBody` | رسالة مسح مشروع مفيهوش ملاحظات بس فيه محادثة «اسأل» | المشروع ده مفيهوش ملاحظات، بس المحادثة اللي فيه هتتحذف. مش هتعرف ترجّعها. | This project has no notes, but its chat will be deleted. You can't undo this. |
| `firstProjectNameHint` | خانة الاسم في "سمّي أول مشروع" بس (UX-17) | اسم المشروع، مثلاً: مذاكرة | Project name, e.g. Study |
| `projectNameHint` | خانة الاسم في "مشروع جديد" و"غيّر الاسم" (اتغير، القسم 5) | اسم المشروع | Project name |
| `sourceMissing` | مصدر في إجابة "اسأل" لملاحظة اتنقلت أو اتحذفت (بدل `deletedNote`) | ملاحظة مابقتش في المشروع ده | Note no longer in this project |
| `sourceMissingA11y` | قارئ الشاشة: نفس المصدر (بدل `sourceDeletedA11y`) | مصدر {index}: ملاحظة مابقتش في المشروع ده | Source {index}: note no longer in this project |

**الجمع بصيغة ICU:**

| المفتاح | zero | one | two | few | many | other |
|---|---|---|---|---|---|---|
| `suggestionsCount` ع | مفيش اقتراحات | اقتراح واحد | اقتراحين | {count} اقتراحات | {count} اقتراح | {count} اقتراح |
| `suggestionsCount` En | No suggestions (`=0`) | 1 suggestion | — | — | — | {count} suggestions |
| `filesCount` ع | مفيش ملفات | ملف واحد | ملفين | {count} ملفات | {count} ملف | {count} ملف |
| `filesCount` En | No files (`=0`) | 1 file | — | — | — | {count} files |

أمثلة بعد التركيب:

- النقل: "الملاحظة هتتنقل بملفاتها، وهيتشال رابطين و3 اقتراحات بينها وبين الملاحظات اللي هتفضل هنا." / "The note moves with its files. Its 2 links and 3 suggestions to notes that stay here will be removed."
- المسح: "هيتحذف 3 ملاحظات وملفين و11 رابط، والمحادثة كمان. مش هتعرف ترجّعهم." / "This deletes 3 notes, 2 files and 11 links, plus the chat. You can't undo this."

ملحوظات:

- "رابط" في رسالة النقل معناها روابطك اللي عملتها بإيدك، و"اقتراح" هي اقتراحات التحليل، زي التاج في القسم 16. الرابط بيتعد مرة واحدة لكل ملاحظتين، والاقتراح اللي اترفض مش بيتعد.
- "هيتشال" للروابط (زي `removeLink`)، و"هيتحذف" للملاحظات والملفات (زي `deleteNote`). في رسالة المسح كله بيتحذف مع المشروع، فالفعل واحد.
- الفعل قبل العدد ("هيتشال رابطين"، "هيتحذف 3 ملاحظات") عشان مايحتاجش يتطابق مع المفرد والمتنى والجمع.
- الأعداد اللي بصفر مش بتتكتب في الجملة. لو مفيش روابط هتتشال، الرسالة بتبقى `moveNoteBodyNoLinks`. ولو المشروع مفيهوش ملاحظات، `deleteProjectEmptyBody`، إلا لو فيه محادثة «اسأل» فبتبقى `deleteProjectEmptyChatBody`، عشان المحادثة بتتحذف مع المشروع.
- اسم المشروع جوه `moveNoteTitle` و`noteMoved` و`deleteProjectTitle` بيتحط بين علامتين مخفيتين (FSI وPDI) من الكود، مش في ملفات الـARB، عشان اسم زي «2026 Work» مايتقلبش لـ«Work 2026» جوه جملة عربي. النص نفسه زي ما هو.
- لو الأرقام اتغيرت والرسالة مفتوحة (تحليل زوّد اقتراحات، أو ملاحظة اتضافت)، الرسالة بتظهر تاني بالأرقام الجديدة قبل النقل أو المسح.
- زرار `moveConfirm` أحمر لما روابط هتتشال، وعادي لما مفيش حاجة هتضيع.
- `projectNameHint` في القسم 5 كان بالمثال لكل الخانات. UX-17 بيحصر المثال في أول مشروع بس (`firstProjectNameHint`)، و"مشروع جديد" و"غيّر الاسم" بيرجعوا لـ"اسم المشروع".
- `sourceMissing` بيغطي الملاحظة اللي اتنقلت لمشروع تاني واللي اتحذفت: الاتنين مابقوش في المشروع ده، والصف مابيتفتحش.

### 18. وضع الاختيار والمجموعات (المرحلة 5أ من خطة الروابط) — `lib/features/notes/` و`lib/features/shared/` و`lib/core/widgets/toasts.dart`

ضغطة طويلة على كارت في قائمة الملاحظات بتفتح وضع الاختيار. تحت فيه شريط: «اربطهم ببعض» (من ملاحظتين لحد 6)، «مجموعة»، «انقل»، «احذف». فوق القائمة فلتر بالمجموعات، ومنه خيارات المجموعة. المفاتيح الموجودة اللي القسم ده بيستخدمها زي ما هي: `moveConfirm` (زرار «انقل» في الشريط وفي رسالة النقل)، `delete` (زرار «احذف»)، `moveToProject` (عنوان شيت اختيار المشروع)، `create`، `save`، `cancel`، `notesCount` و`linksCount` و`suggestionsCount` (للأرقام جوه الجمل)، `listTwo`. ولو المتختار ملاحظة واحدة بس، النقل والحذف بيستخدموا نصوص الملاحظة الواحدة زي ما هي: `moveNoteTitle`، `moveNoteBody`، `moveNoteBodyNoLinks`، `noteMoved`، `moveNoteFailed`، `deleteNoteTitle`، `deleteNoteBody`، `noteDeleted`.

| المفتاح | لفين | المقترح | English |
|---|---|---|---|
| `selectedCount` | عنوان وضع الاختيار في قائمة الملاحظات | جمع (تحت) | جمع (تحت) |
| `closeSelection` | قارئ الشاشة: زرار ✕ اللي بيقفل وضع الاختيار | اقفل الاختيار | Close selection |
| `linkTogether` | زرار في شريط الاختيار: بيربط كل ملاحظة متختارة بكل واحدة تانية | اربطهم ببعض | Link together |
| `groupAction` | زرار في شريط الاختيار | مجموعة | Group |
| `linkTogetherLimit` | سطر فوق الشريط لما المتختار أكتر من {max}، والزرار مقفول | تقدر تربط لحد {max} ملاحظات ببعض. لو أكتر، حطهم في مجموعة. | You can link up to {max} notes together. For more, use a group. |
| `linkTogetherNeedsTwo` | قارئ الشاشة: ليه زرار الربط مقفول لما ملاحظة واحدة بس متختارة | اختار ملاحظتين على الأقل عشان تربطهم. | Select at least 2 notes to link them. |
| `linksAdded` | toast بعد «اربطهم ببعض»، ومعاه زرار تراجع | جمع (تحت) | جمع (تحت) |
| `undo` | زرار في الـtoast بعد الربط والتجميع | تراجع | Undo |
| `undoFailed` | toast لما التراجع يفشل | مقدرناش نتراجع عن اللي اتعمل. | Couldn't undo that. |
| `chooseGroup` | عنوان شيت المجموعات | اختار مجموعة | Choose a group |
| `newGroup` | صف في شيت المجموعات، وعنوان شيت المجموعة الجديدة | مجموعة جديدة | New group |
| `removeFromGroup` | صف في شيت المجموعات، بيظهر بس لو ملاحظة متختارة في مجموعة | شيل من المجموعة | Remove from group |
| `noGroupsYet` | شيت المجموعات لما المشروع مفيهوش مجموعات | لسه مفيش مجموعات في المشروع ده. | No groups in this project yet. |
| `subGroupA11y` | قارئ الشاشة: صف مجموعة فرعية في الشيت (الإزاحة مش بتتقري). `{notes}` = `notesCount` | {group}، جوه «{parent}»، {notes} | {group}, inside {parent}, {notes} |
| `notesGrouped` | toast بعد الحط في مجموعة، ومعاه زرار تراجع. `{notes}` = `notesCount` | اتحط {notes} في «{group}» | Added {notes} to "{group}" |
| `groupRemovedFrom` | toast بعد «شيل من المجموعة»، ومعاه زرار تراجع | اتشالت المجموعة من {notes} | Removed the group from {notes} |
| `groupFailed` | toast لما تعديل مجموعة أو الحط فيها يفشل | مقدرناش نعدّل المجموعة. جرّب تاني. | Couldn't update the group. Try again. |
| `groupNameHint` | خانة الاسم في المجموعة الجديدة وفي «غيّر الاسم» | اسم المجموعة | Group name |
| `groupColorLabel` | عنوان اختيار اللون، ومعاه اسم اللون المختار | اللون: {color} | Color: {color} |
| `colorNone` | اختيار اللون | من غير لون | No color |
| `colorBlue` | اختيار اللون | أزرق | Blue |
| `colorGreen` | اختيار اللون | أخضر | Green |
| `colorYellow` | اختيار اللون | أصفر | Yellow |
| `colorGray` | اختيار اللون | رمادي | Gray |
| `groupParentLabel` | عنوان اختيار المجموعة الأم في المجموعة الجديدة | جوه مجموعة (اختياري) | Inside a group (optional) |
| `groupParentNone` | أول اختيار تحت `groupParentLabel` | ولا واحدة | None |
| `moveNotesTitle` | عنوان رسالة نقل أكتر من ملاحظة. `{notes}` = `notesCount` | تنقل {notes} لـ«{project}»؟ | Move {notes} to "{project}"? |
| `moveNotesBody` | رسالة نقل أكتر من ملاحظة لما روابط هتتشال. `{lost}` زي `moveNoteBody` | جمع (تحت) | جمع (تحت) |
| `moveNotesBodyNoLinks` | رسالة نقل أكتر من ملاحظة لما مفيش حاجة هتتشال | جمع (تحت) | جمع (تحت) |
| `notesMoved` | toast بعد نقل أكتر من ملاحظة | اتنقل {notes} لـ«{project}» | Moved {notes} to "{project}" |
| `moveNotesFailed` | toast لما نقل أكتر من ملاحظة يفشل | مقدرناش ننقل الملاحظات. جرّب تاني. | Couldn't move the notes. Try again. |
| `moveNotesNoOtherProject` | شيت اختيار المشروع من وضع الاختيار لو مفيش مشروع تاني | مفيش مشروع تاني تنقل له الملاحظات. | There's no other project to move these notes to. |
| `deleteNotesTitle` | عنوان رسالة حذف أكتر من ملاحظة. `{notes}` = `notesCount` | تحذف {notes}؟ | Delete {notes}? |
| `deleteNotesBody` | رسالة حذف أكتر من ملاحظة | جمع (تحت) | جمع (تحت) |
| `notesDeleted` | toast بعد حذف أكتر من ملاحظة | اتحذف {notes} | Deleted {notes} |
| `deleteNotesFailed` | toast لما حذف أكتر من ملاحظة يفشل (اللي اتحذف بيفضل محذوف) | مقدرناش نحذف كل الملاحظات. جرّب تاني. | Couldn't delete all the notes. Try again. |
| `allGroupsFilter` | أول اختيار في فلتر المجموعات فوق القائمة | الكل | All |
| `groupOptionsA11y` | قارئ الشاشة: زرار خيارات المجموعة المختارة في الفلتر | خيارات المجموعة «{group}» | Options for the group {group} |
| `groupEmptyTitle` | القائمة لما المجموعة المختارة في الفلتر فاضية | المجموعة دي فاضية | This group is empty |
| `groupEmptyBody` | تحت `groupEmptyTitle` | دوس ضغطة طويلة على ملاحظة عشان تختارها، وبعدين «مجموعة». | Long-press a note to select it, then tap Group. |
| `noteGroupA11y` | قارئ الشاشة: تاج المجموعة على كارت الملاحظة | في مجموعة «{group}» | In group {group} |
| `renameGroup` | خيار في شيت خيارات المجموعة، وعنوان شيت الاسم | غيّر الاسم | Rename |
| `changeGroupColor` | خيار في شيت خيارات المجموعة، وعنوان شيت اللون | غيّر اللون | Change color |
| `putInGroup` | خيار في شيت خيارات المجموعة، وعنوان شيت اختيار المجموعة الأم | حطها جوه مجموعة تانية | Put inside another group |
| `takeOutOfGroup` | خيار في شيت خيارات مجموعة فرعية | طلّعها برة «{parent}» | Take out of "{parent}" |
| `deleteGroup` | خيار في شيت خيارات المجموعة | احذف المجموعة | Delete group |
| `deleteGroupTitle` | عنوان رسالة حذف المجموعة | تحذف المجموعة «{group}»؟ | Delete the group "{group}"? |
| `deleteGroupBody` | رسالة حذف المجموعة (التأكيد عادي مش أحمر، لأن مفيش ملاحظة بتضيع) | الملاحظات اللي فيها هتفضل زي ما هي، بس من غير مجموعة. والمجموعات اللي جواها هتطلع برة. | Its notes stay as they are, just without a group. Groups inside it move out. |
| `groupDeleted` | toast بعد حذف المجموعة | المجموعة اتحذفت | Group deleted |
| `noParentGroups` | شيت اختيار المجموعة الأم لو مفيش مجموعة رئيسية تانية | مفيش مجموعة تانية تحطها جواها. | There's no other group to put it in. |
| `groupRuleEmptyName` | رسالة: الاسم فاضي | اكتب اسم للمجموعة. | Write a name for the group. |
| `groupRuleInvalidColor` | رسالة: لون مش من الأربعة | اللون ده مش متاح. | That color isn't available. |
| `groupRuleMissingProject` | رسالة: المشروع اتحذف | المشروع ده مابقاش موجود. | This project no longer exists. |
| `groupRuleMissingGroup` | رسالة: المجموعة اتحذفت | المجموعة دي مابقتش موجودة. | This group no longer exists. |
| `groupRuleInvalidParent` | رسالة: المجموعة الأم مجموعة فرعية أو مش موجودة | تقدر تحط المجموعة جوه مجموعة رئيسية بس، مش جوه مجموعة فرعية. | A group can only go inside a top-level group, not inside a sub-group. |
| `groupRuleSelfParent` | رسالة: المجموعة جوه نفسها | مينفعش تحط المجموعة جوه نفسها. | A group can't go inside itself. |
| `groupRuleHasChildren` | رسالة: مجموعة جواها مجموعات | المجموعة دي جواها مجموعات، فمينفعش تتحط جوه مجموعة تانية. | This group has groups inside it, so it can't go inside another group. |

**الجمع بصيغة ICU:**

| المفتاح | zero | one | two | few | many | other |
|---|---|---|---|---|---|---|
| `selectedCount` ع | مفيش حاجة متختارة | ملاحظة واحدة متختارة | ملاحظتين متختارين | {count} ملاحظات متختارة | {count} ملاحظة متختارة | {count} ملاحظة متختارة |
| `selectedCount` En | Nothing selected (`=0`) | 1 selected | — | — | — | {count} selected |
| `linksAdded` ع | الملاحظات دي مربوطة ببعض أصلاً | اتعمل رابط جديد | اتعمل رابطين جداد | اتعمل {count} روابط جديدة | اتعمل {count} رابط جديد | اتعمل {count} رابط جديد |
| `linksAdded` En | These notes were already linked (`=0`) | Added 1 link | — | — | — | Added {count} links |
| `moveNotesBody` ع | الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا. | الملاحظة هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا. | الملاحظتين هيتنقلوا بملفاتهم، وهيتشال {lost} بينهم وبين الملاحظات اللي هتفضل هنا. | الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا. | الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا. | الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا. |
| `moveNotesBody` En | — | The note moves with its files. Its {lost} to notes that stay here will be removed. | — | — | — | The notes move with their files. Their {lost} to notes that stay here will be removed. |
| `moveNotesBodyNoLinks` ع | الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال. | الملاحظة هتتنقل بملفاتها، ومفيش روابط هتتشال. | الملاحظتين هيتنقلوا بملفاتهم، ومفيش روابط هتتشال. | الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال. | الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال. | الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال. |
| `moveNotesBodyNoLinks` En | — | The note moves with its files. No links will be removed. | — | — | — | The notes move with their files. No links will be removed. |
| `deleteNotesBody` ع | الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها. | الملاحظة وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها. | الملاحظتين وملفاتهم وروابطهم هيتحذفوا، ومش هتعرف ترجّعهم. | الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها. | الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها. | الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها. |
| `deleteNotesBody` En | — | The note, its files and its links will be deleted. You can't undo this. | — | — | — | These notes, their files and their links will be deleted. You can't undo this. |

أمثلة بعد التركيب:

- النقل: "تنقل 3 ملاحظات لـ«شغل»؟" ثم "الملاحظات هتتنقل بملفاتها، وهيتشال رابطين واقتراح واحد بينها وبين الملاحظات اللي هتفضل هنا." / "Move 3 notes to "Work"?" then "The notes move with their files. Their 2 links and 1 suggestion to notes that stay here will be removed."
- الحذف: "تحذف ملاحظتين؟" ثم "الملاحظتين وملفاتهم وروابطهم هيتحذفوا، ومش هتعرف ترجّعهم." / "Delete 2 notes?" then "These notes, their files and their links will be deleted. You can't undo this."
- المجموعة: "اتحط 3 ملاحظات في «مذاكرة»" / "Added 3 notes to "Study""، و"اتشالت المجموعة من ملاحظتين" / "Removed the group from 2 notes".

ملحوظات:

- «اربطهم ببعض» بيربط كل ملاحظة متختارة بكل واحدة تانية، من غير سبب. الزرار مقفول لملاحظة واحدة (`linkTogetherNeedsTwo` لقارئ الشاشة بس) ولأكتر من 6 (`linkTogetherLimit` بيظهر كسطر فوق الشريط). `{max}` رقم من الكود (6).
- `linksAdded` بيعد الروابط الجديدة بس. الروابط اللي كانت موجودة قبل كده مابتتعدش، والتراجع مابيشيلهاش. صيغة zero بتظهر لما كل الملاحظات المتختارة مربوطة ببعض أصلاً، ومن غير زرار تراجع.
- `undo` ("تراجع") بيفضل حوالي 6 ثواني. التراجع في المجموعة بيرجّع كل ملاحظة لمجموعتها اللي كانت فيها. مفيش تراجع للنقل والحذف، عشان كده ليهم رسالة تأكيد.
- الفعل قبل العدد ("اتحط 3 ملاحظات"، "اتحذف ملاحظتين"، "اتنقل ملاحظة واحدة")، زي القسم 17. و`groupRemovedFrom` بيبدأ بـ"اتشالت المجموعة" عشان الفعل يتطابق مع "المجموعة" مش مع العدد.
- `moveNotesBody` و`moveNotesBodyNoLinks` و`deleteNotesBody` بالجمع عشان المثنى: "الملاحظتين هيتنقلوا بملفاتهم" مش "الملاحظات". صيغة one موجودة للاكتمال بس، لأن ملاحظة واحدة بتستخدم نصوص القسم 17.
- اسم المجموعة واسم المشروع جوه الجمل بيتحطوا بين FSI وPDI من الكود (`Fmt.isolate`)، زي القسم 17.
- ألوان المجموعة أربعة من الألوان الموجودة (أزرق، أخضر، أصفر، رمادي) أو من غير لون. اللون بيظهر كنقطة صغيرة جنب الاسم بس، والاسم دايماً مكتوب، فاللون عمره ما بيبقى العلامة الوحيدة.
- حذف المجموعة مابيحذفش ملاحظات، فزرار التأكيد عادي مش أحمر، وزراره `delete`.
- رسايل `groupRule…` بتظهر في toast. `groupRuleSelfParent` و`groupRuleInvalidColor` و`groupRuleMissingProject` الشاشة نفسها بتمنعهم، بس موجودين لو حصلوا.

---

## ج) القرارات

مفيش حاجة مفتوحة. كل اللي كان محتاج قرار اتحسم، والجداول فوق مكتوبة على أساسه.

**قرارات عمر على الكلام (2026-11-10، في docs/plans/2026-11-10_restructure-plan.md):**

1. **concept = "المواضيع" / Topics**، مش "المفاهيم". الصفوف: `topicsHeader`، وسطر concept في القسم أ.
2. **تاب "الروابط" / Links بيفضل زي ما هو**، مش "الخريطة". الصفوف: `navLinks`، `linksTitle`.
3. **زرار قبول الصياغة المقترحة = "استخدمها" / Use it**، مش "اعتمد". الصف: `useRewrite`.
4. **عنوان شاشة الإضافة = "ملاحظة جديدة" / New note، والتاب بيفضل "إضافة" / Add.** الصفوف: `addTitle`، `navAdd`.
5. **زرار إنشاء المشروع = "إنشاء" / Create (بدون تغيير)**، مش "اعمله". ده الاستثناء التاني من قاعدة "الأزرار أفعال". الصف: `create`.
6. **"جرّب مشروع جاهز" / Try a sample project**، مش "مشروع تجريبي". الصفوف: `trySampleProject`، `sampleProjectFailed`، وسطر demo project في القسم أ.
7. **سطر "(إجابة تجريبية…)" اتشال من جوه الإجابة**، والبادج `askDemoBadge` بيكفي (UX-14). الصف: `demoAnswerFooter`.

**قرارات المنسق على مراجعة Argon (القسم ٥ في copy-review-argon.md):**

8. **المواضيع والمجموعات بتتخزن كنص بلغة التحليل (الاختيار ب).** مفيش مفاتيح ARB ليها. ده قيد معروف، مكتوب في القسم 13.
9. **`sample3Body` بيفضل ملاحظة تاريخية (الاختيار أ)**، والتابات بس اتكتبت بالترتيب والأسماء النهائية. شوف ملحوظات القسم 14.
10. **الخانة لما فيه ملف = `bodyHintWithFileLinks` (نسخة UX-04).** `bodyHintWithFile` اتشال، ومفيش غير مفتاح واحد للخانة دي (القسم 6).
