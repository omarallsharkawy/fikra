// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'فِكرة';

  @override
  String get navAdd => 'إضافة';

  @override
  String get navNotes => 'الملاحظات';

  @override
  String get navLinks => 'الروابط';

  @override
  String get navAsk => 'اسأل';

  @override
  String get storageErrorTitle => 'فيه مشكلة في التخزين';

  @override
  String get storageErrorBody => 'مقدرناش نقرا بياناتك دلوقتي. اتأكد إن فيه مساحة فاضية على الموبايل، وجرّب تاني.';

  @override
  String get retry => 'جرّب تاني';

  @override
  String get today => 'النهارده';

  @override
  String get yesterday => 'امبارح';

  @override
  String get justNow => 'دلوقتي';

  @override
  String sizeBytes(String size) {
    return '$size بايت';
  }

  @override
  String sizeKb(String size) {
    return '$size KB';
  }

  @override
  String sizeMb(String size) {
    return '$size MB';
  }

  @override
  String get badgeSampleData => 'بيانات تجريبية';

  @override
  String get badgeSaved => 'اتحفظت';

  @override
  String get badgeAnalyzing => 'بنحللها…';

  @override
  String get badgeFailed => 'فيه مشكلة';

  @override
  String get delete => 'احذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get loadErrorTitle => 'مقدرناش نحمّل البيانات';

  @override
  String get loadErrorBody => 'مقدرناش نقرا بياناتك دلوقتي. جرّب تاني.';

  @override
  String get genericError => 'حصلت مشكلة. جرّب تاني.';

  @override
  String get voicePlayA11y => 'شغّل';

  @override
  String get voicePauseA11y => 'وقّف';

  @override
  String get voiceUnavailableA11y => 'التسجيل مش متاح';

  @override
  String get voiceRecording => 'تسجيل صوتي';

  @override
  String get fileUnavailable => 'الملف مش متاح';

  @override
  String get deleteRecording => 'احذف التسجيل';

  @override
  String get firstProjectTitle => 'سمّي أول مشروع';

  @override
  String get create => 'إنشاء';

  @override
  String get createProjectFailed => 'مقدرناش نعمل المشروع. جرّب تاني.';

  @override
  String get sampleProjectFailed => 'مقدرناش نفتح المشروع الجاهز. جرّب تاني.';

  @override
  String get tagline => 'اكتب. اربط. اسأل.';

  @override
  String get welcomeCapture => 'اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور';

  @override
  String get welcomeLinks => 'فِكرة بتربط الملاحظات القريبة من بعض لوحدها';

  @override
  String get welcomeAsk => 'اسأل، والإجابة بتيجي من ملاحظاتك ومعاها المصدر';

  @override
  String get welcomeDemoBadge => 'نسخة تجريبية: كل حاجة بتفضل على موبايلك';

  @override
  String get startNewProject => 'ابدأ مشروع جديد';

  @override
  String get trySampleProject => 'جرّب مشروع جاهز';

  @override
  String projectPillA11y(String name) {
    return 'المشروع: $name. دوس عشان تغيّره';
  }

  @override
  String get noProject => 'مفيش مشروع';

  @override
  String get settings => 'الإعدادات';

  @override
  String get projectsTitle => 'المشاريع';

  @override
  String get newProject => 'مشروع جديد';

  @override
  String projectOptionsA11y(String name) {
    return 'خيارات «$name»';
  }

  @override
  String get renameProject => 'غيّر الاسم';

  @override
  String get save => 'احفظ';

  @override
  String get deleteProject => 'احذف المشروع';

  @override
  String deleteProjectTitle(String name) {
    return 'تحذف «$name»؟';
  }

  @override
  String deleteProjectBody(String items) {
    return 'هيتحذف $items، والمحادثات كمان. مش هتعرف ترجّعهم.';
  }

  @override
  String get projectDeleted => 'المشروع اتحذف';

  @override
  String get projectNameHint => 'اسم المشروع';

  @override
  String get recordStartFailed => 'مقدرناش نبدأ التسجيل. جرّب تاني.';

  @override
  String get recordInterrupted => 'التسجيل اتقطع. سجّل تاني.';

  @override
  String get pdfOnly => 'الملف ده مش PDF. اختار ملف PDF.';

  @override
  String get fileOpenFailed => 'مقدرناش نفتح الملف. جرّب ملف تاني.';

  @override
  String get photosOpenFailed => 'مقدرناش نفتح الصور. جرّب تاني.';

  @override
  String get noteSaved => 'الملاحظة اتحفظت';

  @override
  String get noteSavedAnalyzing => 'الملاحظة اتحفظت، وفِكرة بتحللها دلوقتي';

  @override
  String get noteSaveFailed => 'مقدرناش نحفظ الملاحظة. جرّب تاني.';

  @override
  String get photosTitle => 'صور';

  @override
  String get addTitle => 'ملاحظة جديدة';

  @override
  String get titleOptionalHint => 'عنوان (اختياري)';

  @override
  String get bodyHintWithFileLinks => 'اكتب كام سطر عن الملف عشان فِكرة تربطه (اختياري)';

  @override
  String get bodyHint => 'اكتب فكرتك هنا…';

  @override
  String get addFooter => 'الملاحظة بتتحفظ على طول، وبعدين فِكرة بتحلل النص وتربطه بالباقي. الملفات بتفضل على موبايلك.';

  @override
  String get discardRecording => 'الغي التسجيل';

  @override
  String get stopRecording => 'وقّف التسجيل';

  @override
  String get recordVoice => 'سجّل صوت';

  @override
  String get addPdf => 'ضيف PDF';

  @override
  String get addPhotos => 'ضيف صور';

  @override
  String get removeFile => 'شيل الملف';

  @override
  String removePhoto(int n) {
    return 'شيل الصورة $n';
  }

  @override
  String get micNeededTitle => 'محتاجين إذن المايك';

  @override
  String get close => 'اقفل';

  @override
  String get micBlockedBody => 'المايك مقفول لفِكرة. افتح إعدادات التطبيق واسمح بالمايك.';

  @override
  String get micAskBody => 'عشان تسجّل فكرة بصوتك، اسمح لفِكرة تستخدم المايك.';

  @override
  String get openSettings => 'افتح الإعدادات';

  @override
  String get allowMic => 'اسمح بالمايك';

  @override
  String get recordingNow => 'بيسجّل';

  @override
  String get notesTitle => 'الملاحظات';

  @override
  String get searchNotesHint => 'دوّر في الملاحظات';

  @override
  String get notesEmptyTitle => 'لسه مفيش ملاحظات';

  @override
  String get notesEmptyBody => 'اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور، وفِكرة هترتّبها وتربطها لوحدها.';

  @override
  String get addFirstNote => 'ضيف أول ملاحظة';

  @override
  String get noResultsTitle => 'مفيش نتايج';

  @override
  String noResultsBody(String query) {
    return 'مفيش ملاحظة فيها «$query». جرّب كلمة تانية.';
  }

  @override
  String get noteAnalysisFailed => 'مقدرناش نحللها';

  @override
  String get noteRewriteSuggested => 'فيه صياغة مقترحة';

  @override
  String get noteSavedBadge => 'محفوظة';

  @override
  String openFileA11y(String name) {
    return 'افتح $name';
  }

  @override
  String get untitledNote => 'ملاحظة جديدة';

  @override
  String get openFileFailed => 'مقدرناش نفتح الملف. اتأكد إن عندك تطبيق يفتح النوع ده.';

  @override
  String get noteOptions => 'خيارات الملاحظة';

  @override
  String get edit => 'عدّل';

  @override
  String get restoreOriginal => 'رجّع النص الأصلي';

  @override
  String get originalRestored => 'رجّعنا النص الأصلي';

  @override
  String get deleteNote => 'احذف الملاحظة';

  @override
  String get deleteNoteTitle => 'تحذف الملاحظة دي؟';

  @override
  String get deleteNoteBody => 'الملاحظة وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.';

  @override
  String get noteDeleted => 'الملاحظة اتحذفت';

  @override
  String get back => 'رجوع';

  @override
  String get options => 'خيارات';

  @override
  String get noteNotFoundTitle => 'الملاحظة دي مش موجودة';

  @override
  String get noteNotFoundBody => 'يمكن تكون اتحذفت.';

  @override
  String get analysisFailedBanner => 'مقدرناش نحلل الملاحظة، بس هي محفوظة زي ما هي.';

  @override
  String get analyzeAgain => 'حلّلها تاني';

  @override
  String get viewEdited => 'المعدّلة';

  @override
  String get viewOriginal => 'الأصلية';

  @override
  String get originalTextLabel => 'النص الأصلي';

  @override
  String get topicsHeader => 'المواضيع';

  @override
  String get analyzingBody =>
      'فِكرة بتحلل الملاحظة دلوقتي عشان تطلّع مواضيعها وتلاقي الملاحظات المرتبطة بيها. الملاحظة نفسها محفوظة.';

  @override
  String get suggestedRewrite => 'صياغة مقترحة';

  @override
  String get demoBadge => 'تجريبي';

  @override
  String get useRewrite => 'استخدمها';

  @override
  String get keepOriginal => 'خلّي النص الأصلي';

  @override
  String get pdfFile => 'ملف PDF';

  @override
  String openPhotoA11y(int n) {
    return 'افتح الصورة $n';
  }

  @override
  String get changesSaved => 'التعديل اتحفظ';

  @override
  String get changesSaveFailed => 'مقدرناش نحفظ التعديل. جرّب تاني.';

  @override
  String get unsavedTitle => 'عندك تعديلات مش محفوظة';

  @override
  String get saveChanges => 'احفظ التعديل';

  @override
  String get discardChanges => 'اخرج من غير حفظ';

  @override
  String get keepEditing => 'كمّل تعديل';

  @override
  String get editNoteTitle => 'تعديل الملاحظة';

  @override
  String get titleHint => 'العنوان';

  @override
  String get noteTextA11y => 'نص الملاحظة';

  @override
  String get originalKeptHint => 'النص الأصلي بيفضل محفوظ، وتقدر ترجّعه من خيارات الملاحظة.';

  @override
  String get clusterGeneral => 'أفكار عامة';

  @override
  String get moreGroups => 'باقي المجموعات';

  @override
  String get linksTitle => 'الروابط';

  @override
  String get linksEmptyTitle => 'الروابط بتظهر هنا';

  @override
  String get linksEmptyBody => 'ضيف ملاحظتين أو أكتر عن مواضيع قريبة، وفِكرة هتربطهم ببعض.';

  @override
  String get addNote => 'ضيف ملاحظة';

  @override
  String linksSummary(String notesCount, String linksCount) {
    return '$notesCount · $linksCount';
  }

  @override
  String get zoomIn => 'كبّر';

  @override
  String get zoomOut => 'صغّر';

  @override
  String get resetView => 'رجّع العرض';

  @override
  String showGroupA11y(String notesCount, String cluster) {
    return 'اعرض $notesCount في «$cluster»';
  }

  @override
  String moreGroupsCount(int count) {
    return 'باقي المجموعات ($count)';
  }

  @override
  String get noLinksYet => 'لسه مفيش روابط. الملاحظات اللي بتتكلم في نفس المواضيع هتتربط ببعض لوحدها.';

  @override
  String nodeMeta(String cluster, String linksCount) {
    return '$cluster · $linksCount';
  }

  @override
  String get openNote => 'افتح الملاحظة';

  @override
  String get askFailed => 'مقدرناش نجاوب دلوقتي. جرّب تاني.';

  @override
  String get clearChatTitle => 'تمسح المحادثة؟';

  @override
  String get clearChatBody => 'الأسئلة والإجابات هتتمسح، والملاحظات نفسها مش هيحصلها حاجة.';

  @override
  String get clear => 'امسح';

  @override
  String askSuggestion(String title) {
    return 'إيه اللي كتبته عن $title؟';
  }

  @override
  String get askTitle => 'اسأل';

  @override
  String get clearChatA11y => 'امسح المحادثة';

  @override
  String get askDemoBadge => 'إجابات تجريبية من ملاحظاتك';

  @override
  String get askEmptyTitle => 'اسأل عن ملاحظاتك';

  @override
  String get askEmptyNoNotes => 'ضيف ملاحظات الأول، وبعدين اسأل عنها هنا. الإجابة بتيجي من ملاحظاتك بس، ومعاها المصدر.';

  @override
  String get askEmptyBody => 'الإجابة بتيجي من ملاحظات المشروع ده بس، ومعاها المصدر.';

  @override
  String get askHint => 'اسأل عن أي حاجة في ملاحظاتك';

  @override
  String get send => 'ابعت';

  @override
  String get notFoundInNotes => 'ملقيناش إجابة في ملاحظاتك';

  @override
  String get sources => 'المصادر';

  @override
  String sourceA11y(int index, String title) {
    return 'مصدر $index: $title';
  }

  @override
  String get eraseAllTitle => 'تمسح كل البيانات؟';

  @override
  String get eraseAllBody =>
      'كل المشاريع والملاحظات والتسجيلات والملفات والمحادثات هتتمسح من الموبايل، ومش هتعرف ترجّعها.';

  @override
  String get eraseAllConfirm => 'امسح كل حاجة';

  @override
  String get eraseAllDone => 'كل حاجة اتمسحت';

  @override
  String get eraseAllPartial => 'البيانات اتمسحت، بس فيه ملفات لسه. هتتمسح لوحدها أول ما تفتح التطبيق تاني.';

  @override
  String get eraseAllFailed => 'مقدرناش نمسح البيانات. جرّب تاني.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeSystem => 'زي الموبايل';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'غامق';

  @override
  String get themeHint => '«زي الموبايل» بيخلّي شكل التطبيق فاتح أو غامق على حسب موبايلك.';

  @override
  String get dataSection => 'البيانات';

  @override
  String get dataStaysLocal => 'ملاحظاتك وملفاتك محفوظة على الموبايل ده بس، ومش بتتبعت لأي مكان.';

  @override
  String get eraseAll => 'امسح كل البيانات';

  @override
  String get aboutSection => 'عن التطبيق';

  @override
  String get demoVersion => 'نسخة تجريبية';

  @override
  String get languageSection => 'اللغة';

  @override
  String get languageSystem => 'زي الموبايل';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String demoLinkReason(String concept) {
    return 'مرتبطة بـ$concept';
  }

  @override
  String get demoAnswerNotFound =>
      'مفيش ملاحظة في المشروع ده بتتكلم عن الموضوع ده. جرّب تسأل بطريقة تانية، أو ضيف ملاحظة عنه.';

  @override
  String get demoAnswerIntro => 'من ملاحظاتك في المشروع ده:';

  @override
  String get untitledNoteFallback => 'ملاحظة من غير عنوان';

  @override
  String get expandLlm => 'LLM (نموذج لغوي كبير)';

  @override
  String get expandRag => 'RAG (Retrieval-Augmented Generation)';

  @override
  String get sampleProjectName => 'مشروع التخرج';

  @override
  String get sample1Title => 'فكرة المشروع';

  @override
  String get sample1Body =>
      'تطبيق ملاحظات بيستخدم الذكاء الاصطناعي عشان يربط الأفكار ببعض ويجاوب على أسئلتي من ملاحظاتي بس.';

  @override
  String get sample2Title => 'إزاي RAG بيشتغل';

  @override
  String get sample2Body =>
      'الـrag بيجيب أقرب أجزاء من الملاحظات بالـembedding وبعدين الـllm بيكتب الإجابة منها مع ذكر المصدر';

  @override
  String get sample3Title => 'شكل الواجهة';

  @override
  String get sample3Body =>
      'تصميم الواجهة غامق وبسيط، بالعربي من اليمين للشمال، وفيه أربع تابات: إضافة، الملاحظات، الروابط، اسأل.';

  @override
  String get sample4Title => 'إدارة الحالة في Flutter';

  @override
  String get sample4Body => 'هستخدم riverpod لإدارة الحالة في flutter، وقاعدة بيانات محلية للنسخة التجريبية.';

  @override
  String get sample5Title => 'الباك إند';

  @override
  String get sample5Body => 'علاء هيعمل الباك إند بـfastapi و postgres مع pgvector، والتطبيق هيكلمه عن طريق api.';

  @override
  String get sample6Title => 'البحث الدلالي';

  @override
  String get sample6Body =>
      'البحث الدلالي بيدوّر بالمعنى مش بالكلمة، وده معتمد على الـembedding اللي بيتخزن في قاعدة بيانات.';

  @override
  String get sample7Title => 'محاضرة الشبكات';

  @override
  String get sample7Body => 'محاضرة الشبكات النهارده كانت عن TCP و UDP، لازم أراجعها قبل الامتحان.';

  @override
  String get clearSearch => 'امسح البحث';

  @override
  String get noteSavedNoText => 'الملاحظة اتحفظت. اكتب عنها كام سطر عشان تتربط بالباقي';

  @override
  String get noTextNoLinks => 'الملاحظة دي مفيهاش نص، عشان كده فِكرة مش هتعرف تربطها بحاجة.';

  @override
  String get pdfOpenElsewhere => 'افتح في تطبيق تاني';

  @override
  String pdfPageOf(int page, int total) {
    return '$page من $total';
  }

  @override
  String get pdfLoadFailed => 'مقدرناش نفتح الملف ده. ممكن يكون بايظ أو اتحذف.';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظة',
      many: '$count ملاحظة',
      few: '$count ملاحظات',
      two: 'ملاحظتين',
      one: 'ملاحظة واحدة',
      zero: 'مفيش ملاحظات',
    );
    return '$_temp0';
  }

  @override
  String linksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رابط',
      many: '$count رابط',
      few: '$count روابط',
      two: 'رابطين',
      one: 'رابط واحد',
      zero: 'مفيش روابط',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count دقيقة',
      many: 'من $count دقيقة',
      few: 'من $count دقايق',
      two: 'من دقيقتين',
      one: 'من دقيقة',
      zero: 'دلوقتي',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count ساعة',
      many: 'من $count ساعة',
      few: 'من $count ساعات',
      two: 'من ساعتين',
      one: 'من ساعة',
      zero: 'من $count ساعة',
    );
    return '$_temp0';
  }

  @override
  String get pdfFormat => 'PDF';

  @override
  String get removeAttachmentBody => 'الملف هيتحذف من الملاحظة لما تحفظ التغييرات، ومش هتعرف ترجّعه.';

  @override
  String get emptyNoteBlocked => 'الملاحظة مينفعش تبقى فاضية. اكتب نص أو ضيف ملف.';

  @override
  String get pdfPasswordProtected => 'الملف ده محمي بكلمة سر. تقدر تفتحه في تطبيق تاني.';

  @override
  String get noteLinksHeader => 'الروابط';

  @override
  String get linkToNote => 'اربط بملاحظة';

  @override
  String get noteLinksEmpty => 'لسه مفيش روابط للملاحظة دي. دوس «اربط بملاحظة» عشان تربطها بملاحظات تانية.';

  @override
  String get noteLinksLoadFailed => 'مقدرناش نجيب الروابط دلوقتي.';

  @override
  String get linkSuggestedTag => 'اقتراح';

  @override
  String linkRowA11y(String title, String detail) {
    return '$title، $detail';
  }

  @override
  String suggestedLinkA11y(String title) {
    return 'اقتراح: $title';
  }

  @override
  String get acceptLink => 'اقبل';

  @override
  String acceptLinkA11y(String title) {
    return 'اقبل الربط بـ«$title»';
  }

  @override
  String get rejectLink => 'ارفض';

  @override
  String rejectLinkA11y(String title) {
    return 'ارفض الربط بـ«$title»';
  }

  @override
  String linkOptionsA11y(String title) {
    return 'خيارات الرابط مع «$title»';
  }

  @override
  String get linkOptionsTitle => 'خيارات الرابط';

  @override
  String get editLinkReason => 'عدّل السبب';

  @override
  String get removeLink => 'شيل الرابط';

  @override
  String get removeLinkTitle => 'تشيل الرابط ده؟';

  @override
  String get removeLinkBody => 'الملاحظتين هيفضلوا زي ما هم، بس فِكرة مش هتقترح تربطهم ببعض تاني.';

  @override
  String get removeLinkConfirm => 'شيل';

  @override
  String get linkRemoved => 'الرابط اتشال';

  @override
  String get linkUpdateFailed => 'مقدرناش نعدّل الرابط. جرّب تاني.';

  @override
  String get linkReasonHint => 'السبب (اختياري)';

  @override
  String get alreadyLinked => 'مربوطة أصلاً';

  @override
  String get linkPickerEmpty => 'مفيش ملاحظات تانية في المشروع ده تربطها بالملاحظة دي.';

  @override
  String get linkFailed => 'مقدرناش نربط الملاحظات. جرّب تاني.';

  @override
  String linkSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اربط $count ملاحظة',
      many: 'اربط $count ملاحظة',
      few: 'اربط $count ملاحظات',
      two: 'اربط ملاحظتين',
      one: 'اربط ملاحظة واحدة',
      zero: 'اربط',
    );
    return '$_temp0';
  }

  @override
  String notesLinked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الملاحظة اتربطت بـ$count ملاحظة',
      many: 'الملاحظة اتربطت بـ$count ملاحظة',
      few: 'الملاحظة اتربطت بـ$count ملاحظات',
      two: 'الملاحظة اتربطت بملاحظتين',
      one: 'الملاحظة اتربطت بملاحظة واحدة',
      zero: 'مفيش ملاحظات اتربطت',
    );
    return '$_temp0';
  }

  @override
  String get moveToProject => 'انقل لمشروع تاني';

  @override
  String get moveNoOtherProject => 'مفيش مشروع تاني تنقل له الملاحظة.';

  @override
  String moveNoteTitle(String project) {
    return 'تنقل الملاحظة لـ«$project»؟';
  }

  @override
  String moveNoteBody(String lost) {
    return 'الملاحظة هتتنقل بملفاتها، وهيتشال $lost بينها وبين الملاحظات اللي هتفضل هنا.';
  }

  @override
  String get moveNoteBodyNoLinks => 'الملاحظة هتتنقل بملفاتها، ومفيش روابط هتتشال.';

  @override
  String get moveConfirm => 'انقل';

  @override
  String noteMoved(String project) {
    return 'الملاحظة اتنقلت لـ«$project»';
  }

  @override
  String get moveNoteFailed => 'مقدرناش ننقل الملاحظة. جرّب تاني.';

  @override
  String suggestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اقتراح',
      many: '$count اقتراح',
      few: '$count اقتراحات',
      two: 'اقتراحين',
      one: 'اقتراح واحد',
      zero: 'مفيش اقتراحات',
    );
    return '$_temp0';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملف',
      many: '$count ملف',
      few: '$count ملفات',
      two: 'ملفين',
      one: 'ملف واحد',
      zero: 'مفيش ملفات',
    );
    return '$_temp0';
  }

  @override
  String listTwo(String first, String second) {
    return '$first و$second';
  }

  @override
  String listThree(String first, String second, String third) {
    return '$first و$second و$third';
  }

  @override
  String get deleteProjectEmptyBody => 'المشروع ده فاضي، مفيهوش ملاحظات.';

  @override
  String get firstProjectNameHint => 'اسم المشروع، مثلاً: مذاكرة';

  @override
  String get sourceMissing => 'ملاحظة مابقتش في المشروع ده';

  @override
  String sourceMissingA11y(int index) {
    return 'مصدر $index: ملاحظة مابقتش في المشروع ده';
  }

  @override
  String get deleteProjectEmptyChatBody => 'المشروع ده مفيهوش ملاحظات، بس المحادثة اللي فيه هتتحذف. مش هتعرف ترجّعها.';
}
