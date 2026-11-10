# جدول المصطلحات والكلام — فِكرة

التاريخ: 2026-11-10. الحالة: مسودة مستنية موافقة عمر. مفيش كود اتغير.

الملف ده فيه كل كلمة بتظهر للمستخدم في التطبيق، والكلام المقترح بدلها بالعربي، والإنجليزي. الهدف إن الكلام يبقى زي ما واحد بيكلم صاحبه: مصري، بسيط، ونفس الحاجة ليها نفس الاسم في كل حتة.

قواعد الكتابة اللي اتبعتها:

- عامية مصرية بسيطة، بنفس النبرة في كل الشاشات.
- مفيش كلمات متألفة أو منقولة بالحروف لو فيه كلمة عربي عادية. الكلمات التقنية اللي الناس بتقولها فعلاً بالإنجليزي (PDF، الباك إند، RAG) بتفضل زي ما هي.
- الأزرار أفعال: "احفظ"، "احذف"، "ضيف"، مش "حفظ" و"حذف" و"إضافة". الاستثناء الوحيد: "إلغاء"، لأنه متعارف عليه ومفيش فعل أوضح منه.
- رسالة الغلط بتقول إيه اللي حصل وتعمل إيه: "مقدرناش نحفظ الملاحظة. جرّب تاني."
- مفيش علامات تعجب.
- الإنجليزي بسيط، sentence case، ومش ترجمة حرفية.
- كل الفشل بقى "مقدرناش…" بدل الخليط بين "معرفناش" و"مقدرناش" و"مش قادرين".
- "احذف/اتحذف" للحاجات اللي ليها اسم (ملاحظة، مشروع، تسجيل). "امسح/اتمسح" للتنضيف الشامل (المحادثة، كل البيانات).

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
| concept | مفهوم / المفاهيم | موضوع / المواضيع | topic / Topics | "المفاهيم" كلمة كتب. اللي بيظهر فعلاً حاجات زي "الشبكات" و"RAG"، ودي مواضيع. (في قائمة الحاجات اللي محتاجة قرار تحت) |
| cluster (المجموعة في شاشة الروابط) | مجموعة | بدون تغيير | group | بيظهر كعنوان صف في الروابط وفي سطر التاريخ في صفحة الملاحظة. |
| link / related | رابط / الروابط / مرتبطة | رابط / الروابط / ملاحظات مرتبطة | link / Links / Related notes | "رابط" ممكن يتفهم لينك ويب، بس معناه هنا واضح من الشاشة. (في قائمة القرار) |
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
| analysis | التحليل | التحليل / بنحلل | analysis / analyzing | بيظهر في الحالة بس. |
| rewrite | اقتراح إعادة صياغة | صياغة مقترحة | Suggested rewrite | أقصر، ونفس المعنى. |
| original text | النص الأصلي / الأصل / التفريغ الأصلي | النص الأصلي / الأصلية | original text / Original | "التفريغ" غلط: التطبيق مش بيفرّغ الصوت لكلام أصلاً. |
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
| شاشة الإضافة، الخانة لما فيه ملف | ~~ضيف ملاحظة على الملف~~ | **بتتلخبط.** "ملاحظة" دلوقتي معناها الـnote كلها، فالجملة بقت معناها "ضيف note على الملف". البديل: **اكتب كام سطر عن الملف (اختياري)**. |
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
| `storageErrorBody` | lib/app/storage_error_screen.dart:17 | مش قادرين نقرأ بياناتك دلوقتي. اتأكد إن فيه مساحة فاضية وجرّب تاني. | مقدرناش نقرا بياناتك دلوقتي. اتأكد إن فيه مساحة فاضية على الموبايل، وجرّب تاني. | We can't read your data right now. Make sure your phone has free space, then try again. |
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
| `loadErrorBody` | lib/core/widgets/fikra_widgets.dart:705 | حصلت مشكلة وإحنا بنقرا البيانات. جرّب تاني. | بدون تغيير | Something went wrong while reading your data. Try again. |
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
| `sampleProjectFailed` | welcome_screen.dart:37 | مقدرناش نجهّز المشروع التجريبي، جرّب تاني | مقدرناش نجهّز المشروع الجاهز. جرّب تاني. | Couldn't set up the sample project. Try again. |
| `appTitle` | welcome_screen.dart:71 | فِكرة | بدون تغيير | Fikra |
| `tagline` | welcome_screen.dart:77 | اكتب. اربط. اسأل. | بدون تغيير | Write. Connect. Ask. |
| `welcomeCapture` | welcome_screen.dart:82 | اكتب أو سجّل صوت أو ارفع PDF | اكتب، أو سجّل صوتك، أو ضيف PDF وصور | Type, record your voice, or add a PDF and photos |
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
| `noteSavedAnalyzing` | add_screen.dart:314 | اتحفظت. فِكرة بتحللها دلوقتي | بدون تغيير | Saved. Fikra is analyzing it now. |
| `noteSaveFailed` | add_screen.dart:318 | معرفناش نحفظ النوت، جرّب تاني | مقدرناش نحفظ الملاحظة. جرّب تاني. | Couldn't save the note. Try again. |
| `voiceRecording` | add_screen.dart:327 | تسجيل صوتي (عنوان ملاحظة صوت بس) | بدون تغيير | Voice recording |
| `photosTitle` | add_screen.dart:327 | صور (عنوان ملاحظة صور بس) | بدون تغيير | Photos |
| `addTitle` | add_screen.dart:381 | إضافة | ملاحظة جديدة | New note |
| `titleOptionalHint` | add_screen.dart:431 | عنوان (اختياري) | بدون تغيير | Title (optional) |
| `bodyHintWithFile` | add_screen.dart:457 | ضيف ملاحظة على الملف (اختياري) | اكتب كام سطر عن الملف (اختياري) | Add a few lines about it (optional) |
| `bodyHint` | add_screen.dart:457 | اكتب فكرتك هنا… | بدون تغيير | Write your idea… |
| `addFooter` | add_screen.dart:482 | النوت بتتحفظ الأول، وبعدين فِكرة بتحلل النص وتربطه. الملفات بتفضل على موبايلك. | الملاحظة بتتحفظ على طول، وبعدين فِكرة بتقرا النص وتربطه بالباقي. الملفات بتفضل على موبايلك. | Your note is saved right away. Then Fikra reads the text and links it. Files stay on your phone. |
| `discardRecording` | add_screen.dart:538 | إلغاء التسجيل | بدون تغيير | Discard recording |
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

ملحوظة على `addTitle`: التاب نفسه يفضل "إضافة"، بس عنوان الشاشة "ملاحظة جديدة" بيقول إنت بتعمل إيه. بالإنجليزي "Add" لوحدها كعنوان شاشة شكلها ناقص. (في قائمة القرار)

### 7. قائمة الملاحظات — `lib/features/notes/`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `notesTitle` | notes_screen.dart:118 | النوتس | الملاحظات | Notes |
| `searchNotesHint` | notes_screen.dart:124 | دوّر في النوتس | دوّر في الملاحظات | Search notes |
| `notesEmptyTitle` | notes_screen.dart:152 | لسه مفيش نوتس | لسه مفيش ملاحظات | No notes yet |
| `notesEmptyBody` | notes_screen.dart:153 | اكتب فكرة أو سجّل صوت أو ارفع PDF، وفِكرة هتنظمها وتربطها لوحدها. | اكتب فكرة، أو سجّل صوتك، أو ضيف PDF أو صور، وفِكرة هترتّبها وتربطها لوحدها. | Type an idea, record your voice, or add a PDF or photos. Fikra sorts and links them for you. |
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
| `deleteNoteBody` | note_details_screen.dart:69 | النوت وروابطها هيتحذفوا، ومش هينفع ترجّعها. | الملاحظة وملفاتها وروابطها هيتحذفوا، ومش هتعرف ترجّعها. | The note, its files and its links will be deleted. You can't undo this. |
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
| `analyzingBody` | note_details_screen.dart:226 | فِكرة بتحلل النوت: بتطلّع المفاهيم وبتدوّر على نوتس مرتبطة. النوت نفسها محفوظة. | فِكرة بتقرا الملاحظة عشان تطلّع مواضيعها وتلاقي الملاحظات القريبة منها. الملاحظة نفسها محفوظة. | Fikra is reading this note to find its topics and related notes. The note itself is saved. |
| `suggestedRewrite` | note_details_screen.dart:272 | اقتراح إعادة صياغة | صياغة مقترحة | Suggested rewrite |
| `demoBadge` | note_details_screen.dart:273 | تجريبي | بدون تغيير | Demo |
| `useRewrite` | note_details_screen.dart:283 | اعتمد | استخدمها | Use it |
| `keepOriginal` | note_details_screen.dart:292 | خلي الأصل | خلّي الأصلي | Keep original |
| `pdfFile` | note_details_screen.dart:310 | ملف PDF | بدون تغيير | PDF file |
| `openFileA11y` | note_details_screen.dart:320 | افتح ملف {name} | افتح {name} | Open {name} |
| `openPhotoA11y` | note_details_screen.dart:364 | افتح الصورة {n} | بدون تغيير | Open photo {n} |
| `relatedLoadFailed` | note_details_screen.dart:382 | مقدرناش نجيب النوتس المرتبطة دلوقتي. | مقدرناش نجيب الملاحظات المرتبطة دلوقتي. | Couldn't load related notes right now. |
| `relatedEmpty` | note_details_screen.dart:397 | لسه مفيش نوتس شبهها في المشروع ده. | لسه مفيش ملاحظات قريبة منها في المشروع ده. | No related notes in this project yet. |
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
| `noLinksYet` | links_screen.dart:412 | لسه مفيش روابط. النوتس اللي فيها مفاهيم مشتركة هتترابط. | لسه مفيش روابط. الملاحظات اللي بتتكلم في نفس المواضيع هتترابط لوحدها. | No links yet. Notes on the same topics get linked automatically. |
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
| `notFoundInNotes` | ask_screen.dart:297 | ملقيناش إجابة في نوتسك | ملقيناش إجابة في ملاحظاتك | Not in your notes |
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
| `eraseAllDone` | settings_screen.dart:31 | كل حاجة اتمسحت | بدون تغيير | Everything was erased |
| `eraseAllPartial` | settings_screen.dart:33 | البيانات اتمسحت، بس شوية ملفات لسه. هتتمسح لوحدها أول ما تفتح التطبيق تاني. | البيانات اتمسحت، بس فيه ملفات لسه. هتتمسح لوحدها أول ما تفتح التطبيق تاني. | Your data was erased, but a few files are left. They'll be removed next time you open the app. |
| `eraseAllFailed` | settings_screen.dart:35 | مقدرناش نمسح البيانات، جرّب تاني | مقدرناش نمسح البيانات. جرّب تاني. | Couldn't erase your data. Try again. |
| `back` | settings_screen.dart:57 | رجوع | بدون تغيير | Back |
| `settingsTitle` | settings_screen.dart:64 | الإعدادات | بدون تغيير | Settings |
| `appearance` | settings_screen.dart:65 | المظهر | بدون تغيير | Appearance |
| `themeSystem` | settings_screen.dart:67 | زي الموبايل | بدون تغيير | System |
| `themeLight` | settings_screen.dart:67 | فاتح | بدون تغيير | Light |
| `themeDark` | settings_screen.dart:67 | غامق | بدون تغيير | Dark |
| `themeHint` | settings_screen.dart:73 | لو اخترت "زي الموبايل"، فِكرة هتمشي على وضع الموبايل الفاتح أو الغامق. | «زي الموبايل» يعني فِكرة هتبقى فاتحة أو غامقة على حسب موبايلك. | "System" follows your phone's light or dark mode. |
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
| `demoAnswerFooter` | demo_ai_service.dart:151 | (إجابة تجريبية من نوتسك) | يتشال (شوف UX-14) | (removed) |
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

ملحوظة لمرحلة اللغات: القاموس دلوقتي بيعرف "محاضرة" و"امتحان" و"مذاكرة" و"شبكات" و"فيديو" و"تصميم" و"واجهة" و"ذكاء اصطناعي" بالعربي بس. عشان نص الـdemo الإنجليزي يطلّع نفس المواضيع، لازم تتضاف مفاتيح إنجليزي: `lecture`، `exam`، `study`، `network`، `video`، `design`، `interface`، `ai`. كمان المواضيع بتتخزن في الداتابيز وقت التحليل، فلو المستخدم غيّر اللغة بعدين، الملاحظات القديمة هتفضل مواضيعها بلغة التحليل.

### 14. المشروع الجاهز — `lib/data/demo/demo_seed.dart`

| المفتاح | المكان | الحالي | المقترح | English |
|---|---|---|---|---|
| `sampleProjectName` | demo_seed.dart:7 | مشروع التخرج | بدون تغيير | Graduation project |
| `sample1Title` | demo_seed.dart:11 | فكرة المشروع | بدون تغيير | Project idea |
| `sample1Body` | demo_seed.dart:11 | تطبيق نوتس بيستخدم الذكاء الاصطناعي عشان يربط الأفكار ببعض ويجاوب على أسئلتي من نوتسي بس. | تطبيق ملاحظات بيستخدم الذكاء الاصطناعي عشان يربط الأفكار ببعض ويجاوب على أسئلتي من ملاحظاتي بس. | A notes app that uses AI to connect ideas and answer my questions from my own notes only. |
| `sample2Title` | demo_seed.dart:13 | إزاي RAG بيشتغل | بدون تغيير | How RAG works |
| `sample2Body` | demo_seed.dart:14 | الـrag بيجيب أقرب أجزاء من النوتس بالـembedding وبعدين الـllm بيكتب الإجابة منها مع ذكر المصدر | الـrag بيجيب أقرب أجزاء من الملاحظات بالـembedding وبعدين الـllm بيكتب الإجابة منها مع ذكر المصدر | rag finds the closest chunks of my notes using embeddings, then the llm writes the answer from them and cites the source |
| `sample3Title` | demo_seed.dart:17 | شكل الواجهة | بدون تغيير | The UI |
| `sample3Body` | demo_seed.dart:18 | تصميم الواجهة داكن وبسيط، بالعربي من اليمين للشمال، وفيه أربع تابات: إضافة، النوتس، الروابط، اسأل. | تصميم الواجهة غامق وبسيط، بالعربي من اليمين للشمال، وفيه أربع تابات: {أسماء التابات بالترتيب النهائي}. | The UI is dark and simple, right-to-left in Arabic, with four tabs: {final tab names in order}. |
| `sample4Title` | demo_seed.dart:20 | إدارة الحالة في Flutter | بدون تغيير | State management in Flutter |
| `sample4Body` | demo_seed.dart:20 | هستخدم riverpod لإدارة الحالة في flutter، وقاعدة بيانات محلية للنسخة التجريبية. | بدون تغيير | I'll use riverpod for state management in flutter, with a local database for the demo. |
| `sample5Title` | demo_seed.dart:21 | الباك إند | بدون تغيير | Backend |
| `sample5Body` | demo_seed.dart:21 | علاء هيعمل الباك إند بـfastapi و postgres مع pgvector، والتطبيق هيكلمه عن طريق api. | بدون تغيير | Alaa is building the backend with fastapi and postgres with pgvector. The app talks to it through an api. |
| `sample6Title` | demo_seed.dart:22 | البحث الدلالي | بدون تغيير | Semantic search |
| `sample6Body` | demo_seed.dart:22 | البحث الدلالي بيدوّر بالمعنى مش بالكلمة، وده معتمد على التضمينات اللي بتتخزن في قاعدة بيانات. | بدون تغيير | Semantic search looks for meaning, not exact words. It relies on embeddings stored in a database. |
| `sample7Title` | demo_seed.dart:23 | محاضرة الشبكات | بدون تغيير | Networks lecture |
| `sample7Body` | demo_seed.dart:23 | محاضرة الشبكات النهارده كانت عن TCP و UDP، لازم أراجعها قبل الامتحان. | بدون تغيير | Today's networks lecture was about TCP and UDP. I need to review it before the exam. |

ملحوظات:

- demo_seed.dart:5 كومنت.
- النص الإنجليزي للعينات متعمّد يكون بحروف صغيرة في `rag` و`llm` و`fastapi`، عشان الـdemo بيوري "الصياغة المقترحة" بتكبّر الحروف وتشرح الاختصارات.
- `sample3Body` بيذكر أسماء التابات، فلازم يتكتب بعد ما عمر يقرر ترتيبها (UX-01).

### 15. نصوص جديدة (من الخطة ومن docs/plans/ux-proposals.md)

مش موجودة في الكود لسه، ومش داخلة في العدد اللي تحت.

| المفتاح | لفين | المقترح | English |
|---|---|---|---|
| `clearSearch` | زرار ✕ في البحث، وزرار حالة "مفيش نتايج" (UX-05) | امسح البحث | Clear search |
| `bodyHintWithFileLinks` | خانة الإضافة لما فيه ملف (UX-04). بديل `bodyHintWithFile` لو UX-04 اتوافق عليه | اكتب كام سطر عن الملف عشان فِكرة تربطه (اختياري) | Add a few lines so Fikra can link it (optional) |
| `noteSavedNoText` | toast بعد حفظ ملف من غير نص (UX-04) | اتحفظت. اكتب عنها كام سطر عشان تتربط بالباقي | Saved. Add a few lines so it can be linked. |
| `noTextNoLinks` | صفحة الملاحظة لما مفيش نص (UX-04) | الملاحظة دي ملهاش نص، ففِكرة مش هتربطها بحاجة. | This note has no text, so Fikra can't link it. |
| `pdfOpenElsewhere` | عارض الـPDF | افتح في تطبيق تاني | Open in another app |
| `pdfPageOf` | عارض الـPDF | {page} من {total} | {page} of {total} |
| `pdfLoadFailed` | عارض الـPDF | مقدرناش نفتح الملف ده. ممكن يكون بايظ أو اتمسح. | Couldn't open this file. It may be damaged or missing. |
| `languageSection` وأخواتها | الإعدادات | شوف القسم 12 | |

### العدد

252 سطر في جداول القسم (ب): 228 نص في الجداول العادية، و17 موضوع و5 مجموعات من الـdemo AI، وصيغتين للوقت واليوم. ده من غير جدول الجمع (هو تفصيل لأربع سطور موجودة أصلاً)، ومن غير المفاتيح الأربعة الجديدة للغة. فيه 23 ملف جواهم حروف عربي، و22 منهم فيهم نص بيظهر للمستخدم. الملف الوحيد اللي مفيهوش هو lib/app/app_config.dart، لأن العربي اللي فيه كومنت بس.

---

## ج) حاجات محتاجة قرار من عمر

1. **concept: "المواضيع" ولا "المفاهيم"؟**
   - المواضيع / Topics (اقتراحي): أبسط، والـchips فعلاً مواضيع زي "الشبكات" و"RAG".
   - المفاهيم / Concepts: أدق تقنياً، بس كلمة كتب.
2. **تاب "الروابط": يفضل كده ولا يتغير؟**
   - الروابط / Links (اقتراحي، بدون تغيير): الناس فهماها من الرسم.
   - الخريطة / Map: بتوصف الشاشة أحسن، بس بتبعد عن كلمة "مرتبطة" اللي في صفحة الملاحظة.
3. **زرار قبول الصياغة المقترحة:**
   - استخدمها / Use it (اقتراحي)
   - اعتمد / Accept (الحالي): مفهوم، بس رسمي شوية.
4. **عنوان شاشة الإضافة:**
   - ملاحظة جديدة / New note (اقتراحي)، والتاب يفضل "إضافة".
   - إضافة / Add: نفس اسم التاب.
5. **زرار إنشاء المشروع:**
   - إنشاء / Create (اقتراحي، بدون تغيير): متعارف عليه.
   - اعمله: مصري أكتر، بس غريب على زرار.
6. **"جرّب مشروع جاهز" ولا "جرّب مشروع تجريبي"؟** اقتراحي "جاهز"، عشان كلمة "تجريبي" مستخدمة لنسخة التطبيق نفسها.
7. **سطر "(إجابة تجريبية…)" جوه كل إجابة:** اقتراحي نشيله ونكتفي بالبادج اللي تحت العنوان (UX-14). لو عمر عايز يفضل، يبقى "(إجابة تجريبية)" بس.
