// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'FIKRAH';

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
  String get welcomeLinks => 'FIKRAH بتربط الملاحظات القريبة من بعض لوحدها';

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
    return 'هيتحذف $items، والمحادثة كمان. مش هتعرف ترجّعهم.';
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
  String get noteSavedAnalyzing => 'الملاحظة اتحفظت، وFIKRAH بتحللها دلوقتي';

  @override
  String get noteSaveFailed => 'مقدرناش نحفظ الملاحظة. جرّب تاني.';

  @override
  String get photosTitle => 'صور';

  @override
  String get addTitle => 'ملاحظة جديدة';

  @override
  String get titleOptionalHint => 'عنوان (اختياري)';

  @override
  String get bodyHintWithFileLinks => 'اكتب كام سطر عن الملف عشان FIKRAH تربطه (اختياري)';

  @override
  String get bodyHint => 'اكتب فكرتك هنا…';

  @override
  String get addFooter =>
      'الملاحظة بتتحفظ على طول، وبعدين FIKRAH بتحلل النص وتربطه بالباقي. الملفات بتفضل على موبايلك.';

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
  String get micBlockedBody => 'المايك مقفول لـ FIKRAH. افتح إعدادات التطبيق واسمح بالمايك.';

  @override
  String get micAskBody => 'عشان تسجّل فكرة بصوتك، اسمح لـ FIKRAH تستخدم المايك.';

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
  String get notesEmptyBody => 'اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور، وFIKRAH هترتّبها وتربطها لوحدها.';

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
      'FIKRAH بتحلل الملاحظة دلوقتي عشان تطلّع مواضيعها وتلاقي الملاحظات المرتبطة بيها. الملاحظة نفسها محفوظة.';

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
  String get linksEmptyBody => 'ضيف ملاحظتين أو أكتر عن مواضيع قريبة، وFIKRAH هتربطهم ببعض.';

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
      'كل المشاريع والملاحظات والتسجيلات والملفات والمحادثات وخدمات التفريغ ومفاتيحها هتتمسح من الموبايل، ومش هتعرف ترجّعها.';

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
  String get noTextNoLinks => 'الملاحظة دي مفيهاش نص، عشان كده FIKRAH مش هتعرف تربطها بحاجة.';

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
  String get removeLinkBody => 'الملاحظتين هيفضلوا زي ما هم، بس FIKRAH مش هتقترح تربطهم ببعض تاني.';

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

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظة متختارة',
      many: '$count ملاحظة متختارة',
      few: '$count ملاحظات متختارة',
      two: 'ملاحظتين متختارين',
      one: 'ملاحظة واحدة متختارة',
      zero: 'مفيش حاجة متختارة',
    );
    return '$_temp0';
  }

  @override
  String get closeSelection => 'اقفل الاختيار';

  @override
  String get linkTogether => 'اربطهم ببعض';

  @override
  String get groupAction => 'مجموعة';

  @override
  String linkTogetherLimit(int max) {
    return 'تقدر تربط لحد $max ملاحظات ببعض. لو أكتر، حطهم في مجموعة.';
  }

  @override
  String get linkTogetherNeedsTwo => 'اختار ملاحظتين على الأقل عشان تربطهم.';

  @override
  String linksAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'اتعمل $count رابط جديد',
      many: 'اتعمل $count رابط جديد',
      few: 'اتعمل $count روابط جديدة',
      two: 'اتعمل رابطين جداد',
      one: 'اتعمل رابط جديد',
      zero: 'الملاحظات دي مربوطة ببعض أصلاً',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'تراجع';

  @override
  String get undoFailed => 'مقدرناش نتراجع عن اللي اتعمل.';

  @override
  String get chooseGroup => 'اختار مجموعة';

  @override
  String get newGroup => 'مجموعة جديدة';

  @override
  String get removeFromGroup => 'شيل من المجموعة';

  @override
  String get noGroupsYet => 'لسه مفيش مجموعات في المشروع ده.';

  @override
  String subGroupA11y(String group, String parent, String notes) {
    return '$group، جوه «$parent»، $notes';
  }

  @override
  String notesGrouped(String notes, String group) {
    return 'اتحط $notes في «$group»';
  }

  @override
  String groupRemovedFrom(String notes) {
    return 'اتشالت المجموعة من $notes';
  }

  @override
  String get groupFailed => 'مقدرناش نعدّل المجموعة. جرّب تاني.';

  @override
  String get groupNameHint => 'اسم المجموعة';

  @override
  String groupColorLabel(String color) {
    return 'اللون: $color';
  }

  @override
  String get colorNone => 'من غير لون';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get colorYellow => 'أصفر';

  @override
  String get colorGray => 'رمادي';

  @override
  String get groupParentLabel => 'جوه مجموعة (اختياري)';

  @override
  String get groupParentNone => 'ولا واحدة';

  @override
  String moveNotesTitle(String notes, String project) {
    return 'تنقل $notes لـ«$project»؟';
  }

  @override
  String moveNotesBody(int count, String lost) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الملاحظات هتتنقل بملفاتها، وهيتشال $lost بينها وبين الملاحظات اللي هتفضل هنا.',
      many: 'الملاحظات هتتنقل بملفاتها، وهيتشال $lost بينها وبين الملاحظات اللي هتفضل هنا.',
      few: 'الملاحظات هتتنقل بملفاتها، وهيتشال $lost بينها وبين الملاحظات اللي هتفضل هنا.',
      two: 'الملاحظتين هيتنقلوا بملفاتهم، وهيتشال $lost بينهم وبين الملاحظات اللي هتفضل هنا.',
      one: 'الملاحظة هتتنقل بملفاتها، وهيتشال $lost بينها وبين الملاحظات اللي هتفضل هنا.',
      zero: 'الملاحظات هتتنقل بملفاتها، وهيتشال $lost بينها وبين الملاحظات اللي هتفضل هنا.',
    );
    return '$_temp0';
  }

  @override
  String moveNotesBodyNoLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.',
      many: 'الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.',
      few: 'الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.',
      two: 'الملاحظتين هيتنقلوا بملفاتهم، ومفيش روابط هتتشال.',
      one: 'الملاحظة هتتنقل بملفاتها، ومفيش روابط هتتشال.',
      zero: 'الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.',
    );
    return '$_temp0';
  }

  @override
  String notesMoved(String notes, String project) {
    return 'اتنقل $notes لـ«$project»';
  }

  @override
  String get moveNotesFailed => 'مقدرناش ننقل الملاحظات. جرّب تاني.';

  @override
  String get moveNotesNoOtherProject => 'مفيش مشروع تاني تنقل له الملاحظات.';

  @override
  String deleteNotesTitle(String notes) {
    return 'تحذف $notes؟';
  }

  @override
  String deleteNotesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.',
      many: 'الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.',
      few: 'الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.',
      two: 'الملاحظتين وملفاتهم وروابطهم هيتحذفوا، ومش هتعرف ترجّعهم.',
      one: 'الملاحظة وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.',
      zero: 'الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.',
    );
    return '$_temp0';
  }

  @override
  String notesDeleted(String notes) {
    return 'اتحذف $notes';
  }

  @override
  String get deleteNotesFailed => 'مقدرناش نحذف كل الملاحظات. جرّب تاني.';

  @override
  String get allGroupsFilter => 'الكل';

  @override
  String groupOptionsA11y(String group) {
    return 'خيارات المجموعة «$group»';
  }

  @override
  String get groupEmptyTitle => 'المجموعة دي فاضية';

  @override
  String get groupEmptyBody => 'دوس ضغطة طويلة على ملاحظة عشان تختارها، وبعدين «مجموعة».';

  @override
  String noteGroupA11y(String group) {
    return 'في مجموعة «$group»';
  }

  @override
  String get renameGroup => 'غيّر الاسم';

  @override
  String get changeGroupColor => 'غيّر اللون';

  @override
  String get putInGroup => 'حطها جوه مجموعة تانية';

  @override
  String takeOutOfGroup(String parent) {
    return 'طلّعها برة «$parent»';
  }

  @override
  String get deleteGroup => 'احذف المجموعة';

  @override
  String deleteGroupTitle(String group) {
    return 'تحذف المجموعة «$group»؟';
  }

  @override
  String get deleteGroupBody =>
      'الملاحظات اللي فيها هتفضل زي ما هي، بس من غير مجموعة. والمجموعات اللي جواها هتطلع برة.';

  @override
  String get groupDeleted => 'المجموعة اتحذفت';

  @override
  String get noParentGroups => 'مفيش مجموعة تانية تحطها جواها.';

  @override
  String get groupRuleEmptyName => 'اكتب اسم للمجموعة.';

  @override
  String get groupRuleInvalidColor => 'اللون ده مش متاح.';

  @override
  String get groupRuleMissingProject => 'المشروع ده مابقاش موجود.';

  @override
  String get groupRuleMissingGroup => 'المجموعة دي مابقتش موجودة.';

  @override
  String get groupRuleInvalidParent => 'تقدر تحط المجموعة جوه مجموعة رئيسية بس، مش جوه مجموعة فرعية.';

  @override
  String get groupRuleSelfParent => 'مينفعش تحط المجموعة جوه نفسها.';

  @override
  String get groupRuleHasChildren => 'المجموعة دي جواها مجموعات، فمينفعش تتحط جوه مجموعة تانية.';

  @override
  String get suggestedTopics => 'مواضيع مقترحة';

  @override
  String makeTopicGroup(String topic) {
    return 'حوّل «$topic» لمجموعة';
  }

  @override
  String graphGroupA11y(String group, String notes) {
    return 'مجموعة «$group»، $notes';
  }

  @override
  String get moreTopics => 'باقي المواضيع';

  @override
  String moreTopicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موضوع تاني',
      many: '$count موضوع تاني',
      few: '$count مواضيع تانية',
      two: 'موضوعين تانيين',
      one: 'موضوع تاني',
      zero: 'مفيش مواضيع تانية',
    );
    return '$_temp0';
  }

  @override
  String graphNoteInGroup(String title, String group) {
    return '$title، في مجموعة «$group»';
  }

  @override
  String get graphSearchHint => 'دوّر في الرسم';

  @override
  String get graphSearchEmpty => 'مفيش نتايج';

  @override
  String get graphSearchNote => 'ملاحظة';

  @override
  String get graphSearchLink => 'رابط';

  @override
  String get graphSearchGroup => 'مجموعة';

  @override
  String get graphSearchLimited => 'مش ظاهرة في الرسم، هنفتح الملاحظة';

  @override
  String graphCollapseGroup(String group) {
    return 'اقفل مجموعة «$group»';
  }

  @override
  String graphExpandGroup(String group) {
    return 'افتح مجموعة «$group»';
  }

  @override
  String graphCollapsedGroup(String group, String notes) {
    return 'مجموعة «$group»، $notes، مقفولة';
  }

  @override
  String get graphMinimap => 'خريطة الرسم، دوس أو اسحب عشان تتحرك';

  @override
  String get vtTitle => 'تحويل الصوت لنص';

  @override
  String get vtExperimental => 'تجريبي';

  @override
  String get vtIntro => 'الموديل بيشتغل على الموبايل، ومفيش حاجة بتترفع. محتاج تحميل مرة واحدة.';

  @override
  String get vtModel => 'الموديل';

  @override
  String get vtTiny => 'صغير جدًا';

  @override
  String get vtBase => 'متوسط';

  @override
  String get vtSmall => 'أدق';

  @override
  String vtFullName(String name) {
    return '$name · من غير ضغط';
  }

  @override
  String get vtTinyHint => 'أصغر وأسرع، بس ممكن يغلط أكتر.';

  @override
  String get vtBaseHint => 'توازن بين الحجم والدقة.';

  @override
  String get vtSmallHint => 'ممكن يكون أدق، بس أبطأ وحجمه أكبر.';

  @override
  String get vtFullHint => 'نسخة أكبر من غير ضغط. قارن دقتها بالنسخة الصغيرة.';

  @override
  String get vtOnPhone => 'موجود على الموبايل';

  @override
  String get vtNotDownloaded => 'لسه متحمّلش';

  @override
  String vtUsed(String size) {
    return 'المساحة المستخدمة للموديلات: $size';
  }

  @override
  String vtDownload(String size) {
    return 'حمّل · $size';
  }

  @override
  String get vtDownloadTitle => 'تحمّل الموديل؟';

  @override
  String vtDownloadBody(String size) {
    return 'حجمه $size. الأفضل تحمّله على واي فاي. التحميل مرة واحدة.';
  }

  @override
  String get vtDownloadConfirm => 'حمّل';

  @override
  String get vtDeleteModel => 'احذف الموديل';

  @override
  String get vtDeleteModelTitle => 'تحذف الموديل؟';

  @override
  String get vtDeleteModelBody => 'هتحتاج تحمّله تاني عشان تستخدمه.';

  @override
  String vtProgress(String received, String total) {
    return '$received من $total';
  }

  @override
  String get vtLanguage => 'لغة الكلام';

  @override
  String get vtAutomatic => 'تلقائي';

  @override
  String get vtAdvanced => 'خيارات متقدمة';

  @override
  String vtThreads(String count) {
    return 'مسارات المعالجة: $count';
  }

  @override
  String get vtFormat => 'صيغة التسجيل';

  @override
  String get vtWav => 'صيغة الاختبار (WAV)';

  @override
  String get vtAac => 'صيغة التطبيق العادية (AAC)';

  @override
  String get vtClips => 'آخر تسجيلاتك';

  @override
  String get vtNoRecordings => 'سجّل كام كلمة عشان تجرّب التفريغ. آخر 10 تسجيلات بيفضلوا هنا.';

  @override
  String vtClip(String number, String format) {
    return 'تسجيل $number · $format';
  }

  @override
  String get vtDeleteRecordingBody => 'التسجيل ده هيتحذف من التجربة.';

  @override
  String get vtTranscribe => 'فرّغ الصوت';

  @override
  String get vtWorking => 'بيفرّغ الصوت…';

  @override
  String get vtCannotCancel => 'بعد ما التفريغ يبدأ، استنى لحد ما يخلص.';

  @override
  String get vtWait => 'استنى لحد ما العملية تخلص، أو وقّف التسجيل الأول.';

  @override
  String get vtResult => 'النص';

  @override
  String get vtNoSpeech => 'مفيش كلام واضح في التسجيل. جرّب تاني.';

  @override
  String get vtNumbers => 'الأرقام';

  @override
  String vtAudioLength(String seconds) {
    return 'مدة التسجيل: $seconds ثانية';
  }

  @override
  String vtWall(String seconds) {
    return 'الوقت: $seconds ثانية';
  }

  @override
  String vtFaster(String times) {
    return 'أسرع من الكلام $times مرة';
  }

  @override
  String vtSlower(String times) {
    return 'أبطأ من الكلام $times مرة';
  }

  @override
  String vtFactor(String factor) {
    return 'عامل الوقت: $factor';
  }

  @override
  String vtMs(String ms) {
    return '$ms ms';
  }

  @override
  String vtMemory(String before, String after) {
    return 'الذاكرة قبل: $before، بعد: $after';
  }

  @override
  String vtPeak(String size) {
    return 'أعلى ذاكرة: $size';
  }

  @override
  String vtConversion(String ms) {
    return 'تجهيز الصوت: $ms';
  }

  @override
  String vtEstimate(String ms) {
    return 'التفريغ وتشغيل الموديل، تقريبًا: $ms';
  }

  @override
  String vtModelLoad(String ms) {
    return 'بداية الموديل: $ms';
  }

  @override
  String get vtTimingHint => 'الوقت بيشمل تجهيز الصوت وتشغيل الموديل. الذاكرة للتطبيق كله.';

  @override
  String get vtHistory => 'تجارب قبل كده';

  @override
  String get vtLive => 'نص وإنت بتتكلم';

  @override
  String get vtLiveHint => 'النص بيتعدّل وإنت بتتكلم. لما توقّف، ممكن ياخد شوية وقت.';

  @override
  String get vtLiveStart => 'ابدأ التفريغ المباشر';

  @override
  String get vtLiveTiming => 'وقت التجربة المباشرة بيشمل وقت كلامك، فمش مقياس لسرعة التفريغ.';

  @override
  String get vtNetworkError => 'مقدرناش نحمّل الموديل. اتأكد من الإنترنت وجرّب تاني.';

  @override
  String get vtInterruptedError => 'التحميل أو التسجيل اتقطع. جرّب تاني.';

  @override
  String get vtCorruptError => 'مقدرناش نقرا الموديل. احذفه وحمّله تاني.';

  @override
  String get vtEmptyError => 'التسجيل فاضي أو مش سليم. سجّل كام كلمة وجرّب تاني.';

  @override
  String get vtTranscriptionError => 'مقدرناش نفرّغ الصوت. جرّب تسجيل أقصر أو موديل أصغر.';

  @override
  String get vtStorageError => 'المساحة مش كفاية. فضّي مساحة أو اختار موديل أصغر وجرّب تاني.';

  @override
  String get vtStorageCheckError => 'مقدرناش نعرف المساحة الفاضية. اقفل الشاشة وافتحها وجرّب تاني.';

  @override
  String get vtCancelled => 'التحميل اتلغى. تقدر تبدأه تاني.';

  @override
  String get vtEgyptian => 'مصري · تجريبي';

  @override
  String get vtEgyptianHint => 'متدرّب على العامية المصرية والإنجليزي مع بعض.';

  @override
  String get vtVoiceSection => 'الصوت';

  @override
  String get vtTry => 'جرّب';

  @override
  String get vtTesting => 'للقياس';

  @override
  String get vtFullModels => 'موديلات من غير ضغط';

  @override
  String get vtRefreshModels => 'حدّث ليستة الموديلات';

  @override
  String get trAutomatic => 'فرّغ التسجيلات تلقائي';

  @override
  String get trAutomaticHint => 'بيشتغل على الموبايل بعد الحفظ، وممكن ياخد شوية وقت.';

  @override
  String get trDownloadFirst => 'حمّل موديل الأول عشان تفرّغ التسجيلات على الموبايل.';

  @override
  String get trAfterSave => 'فرّغه بعد الحفظ';

  @override
  String get trQueueFailed => 'التسجيل اتحفظ، بس مقدرناش نضيفه للتفريغ. جرّب من الملاحظة.';

  @override
  String get trWorking => 'بيفرّغ الصوت…';

  @override
  String get trQueued => 'مستني دوره للتفريغ…';

  @override
  String get trExpand => 'اعرض النص كله';

  @override
  String get trCollapse => 'اعرض أقل';

  @override
  String trLocalEngine(String model) {
    return 'على الموبايل · $model';
  }

  @override
  String get trModelMissing => 'الموديل مش موجود أو ملفه بايظ. حمّله من إعدادات الصوت وجرّب تاني.';

  @override
  String get trBusy => 'تفريغ تاني أخد وقت طويل. جرّب تاني لما يخلص.';

  @override
  String get trAudioUnreadable => 'مقدرناش نقرا التسجيل أو نطلع منه كلام. جرّب تشغّله الأول.';

  @override
  String get trFailed => 'مقدرناش نفرّغ التسجيل. جرّب تاني.';

  @override
  String get trInterruptedTwice => 'التفريغ وقف مرتين لما التطبيق اتقفل. جرّب تاني أو اختار موديل أصغر.';

  @override
  String get trNotificationChannel => 'تفريغ الصوت';

  @override
  String trNotificationLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'فاضل $count تسجيل',
      few: 'فاضل $count تسجيلات',
      two: 'فاضل تسجيلين',
      one: 'فاضل تسجيل واحد',
    );
    return '$_temp0';
  }

  @override
  String get trNotificationWhy => 'اسمح بالإشعارات عشان تتابع التفريغ وإنت برّه التطبيق.';

  @override
  String get trOpenSettings => 'افتح إعدادات الصوت';

  @override
  String get trTranscribe => 'فرّغ الصوت';

  @override
  String get trRedo => 'فرّغ تاني';

  @override
  String get vtEngineBusy => 'فيه تسجيل بيتفرّغ دلوقتي. استنى لما يخلص وجرّب تاني.';

  @override
  String get vsEngine => 'طريقة التفريغ';

  @override
  String get vsLocal => 'على الموبايل';

  @override
  String get vsAdd => 'ضيف خدمة';

  @override
  String get vsEdit => 'عدّل الخدمة';

  @override
  String get vsType => 'نوع الخدمة';

  @override
  String get vsOpenAi => 'خدمة متوافقة مع OpenAI';

  @override
  String get vsName => 'اسم الخدمة';

  @override
  String get vsBaseUrl => 'عنوان الخدمة';

  @override
  String get vsModel => 'اسم الموديل';

  @override
  String get vsKey => 'مفتاح API';

  @override
  String get vsKeyKeep => 'سيبه فاضي لو هتستخدم نفس المفتاح.';

  @override
  String get vsLanguageHint => 'لغة متوقعة (اختياري)';

  @override
  String get vsLanguageHelp => 'كود زي ar أو en. سيبه فاضي عشان تستخدم لغة الكلام المختارة.';

  @override
  String get vsShowKey => 'اعرض المفتاح';

  @override
  String get vsHideKey => 'اخفي المفتاح';

  @override
  String get vsTest => 'جرّب الاتصال';

  @override
  String get vsTesting => 'بيجرّب الاتصال…';

  @override
  String get vsConnected => 'الاتصال شغّال.';

  @override
  String get vsDeleteTitle => 'تحذف الخدمة دي؟';

  @override
  String get vsDeleteBody => 'المفتاح هيتمسح، والتفريغ هيرجع للموبايل لو الخدمة دي متختارة.';

  @override
  String vsConsentTitle(String service) {
    return 'تبعت التسجيلات لـ«$service»؟';
  }

  @override
  String vsConsentBody(String service, String host) {
    return 'التسجيلات هتتبعت برّه الموبايل لـ«$service» على $host عشان تتفرّغ. الخدمة ممكن تحتفظ بيها وتحاسبك على الاستخدام. مفيش حاجة هتتبعت غير لما توافق.';
  }

  @override
  String get vsConsentConfirm => 'موافق';

  @override
  String get vsHttpWarning => 'الاتصال ده من غير تشفير. استخدمه على شبكة محلية موثوقة بس.';

  @override
  String get vsInvalidUrl => 'اكتب عنوان HTTPS، أو HTTP لموبايلك أو عنوان شبكة محلية.';

  @override
  String get vsInvalidFields => 'راجع الاسم والموديل وكود اللغة.';

  @override
  String get vsKeyRequired => 'اكتب مفتاح للخدمة دي الأول.';

  @override
  String get vsSaveError => 'مقدرناش نحفظ الخدمة. جرّب تاني.';

  @override
  String get vsLoadError => 'مقدرناش نقرا إعدادات الخدمات. جرّب تاني.';

  @override
  String vsRemoteIntro(String service) {
    return 'التسجيلات هتتبعت برّه الموبايل لـ«$service» عشان تتفرّغ. استخدام الخدمة ممكن يكون بفلوس.';
  }

  @override
  String vsRemoteData(String service) {
    return 'ملاحظاتك وملفاتك محفوظة على الموبايل. التسجيلات بتتبعت برّه الموبايل لـ«$service» عشان تتفرّغ.';
  }

  @override
  String vsVia(String service) {
    return 'عن طريق $service';
  }

  @override
  String get vsRemovedService => 'خدمة اتحذفت';

  @override
  String get vsLiveLocal => 'النص وقت الكلام متاح على الموبايل بس. غيّر طريقة التفريغ عشان تجرّبه.';

  @override
  String vsRemoteAutoHint(String service) {
    return 'التسجيلات الجديدة هتتبعت برّه الموبايل لـ«$service» بعد الحفظ، وممكن تاخد شوية وقت.';
  }

  @override
  String get vsOffline => 'مقدرناش نوصل للخدمة. اتأكد من الاتصال وجرّب تاني.';

  @override
  String get vsKeyRejected => 'الخدمة رفضت المفتاح. راجعه في إعدادات الصوت.';

  @override
  String get vsRateLimited => 'وصلت لحد الاستخدام أو الرصيد خلص. راجع حسابك أو جرّب بعد شوية.';

  @override
  String get vsTooLarge => 'التسجيل كبير أو طويل على الخدمة دي. جرّب تسجيل أقصر أو خدمة تانية.';

  @override
  String get vsServiceError => 'الخدمة عندها مشكلة دلوقتي. جرّب بعد شوية.';

  @override
  String get vsUnexpected => 'الخدمة رجّعت رد مش مفهوم. راجع عنوانها والموديل في إعدادات الصوت.';

  @override
  String get vsTimeout => 'الخدمة اتأخرت في الرد. اتأكد من الاتصال وجرّب تاني.';

  @override
  String get vsNeedsConsent => 'وافق إن التسجيلات تتبعت برّه الموبايل من إعدادات الصوت الأول.';

  @override
  String get vsRegion => 'المنطقة';

  @override
  String get vsSingapore => 'دولي (سنغافورة)';

  @override
  String get vsBeijing => 'الصين (بكين)';

  @override
  String get vsOpenAiKeyHint =>
      'هات المفتاح والعنوان والموديل من الخدمة اللي بتستخدمها، زي OpenAI أو Groq أو SiliconFlow.';

  @override
  String get vsGeminiKeyHint => 'هات المفتاح من Google AI Studio.';

  @override
  String get vsElevenKeyHint => 'هات المفتاح من إعدادات حسابك في ElevenLabs.';

  @override
  String get vsQwenKeyHint =>
      'هات مفتاح لنفس المنطقة من Alibaba Cloud Model Studio. تقدر تستخدم عنوان مساحة العمل كمان.';

  @override
  String get vsGemini => 'Google Gemini';

  @override
  String get vsElevenLabs => 'ElevenLabs';

  @override
  String get vsQwen => 'Qwen ASR';

  @override
  String get vsRemoteTiming => 'الوقت بيشمل رفع التسجيل وانتظار الخدمة. الذاكرة للتطبيق كله.';

  @override
  String get v2Off => 'من غير تفريغ';

  @override
  String get v2Recommended => 'مقترح';

  @override
  String get v2Other => 'موديلات تانية';

  @override
  String get v2Legacy => 'قديم';

  @override
  String v2Shutdown(String date) {
    return 'موديل قديم، وهيقف يوم $date. اختار موديل مقترح لو تقدر.';
  }

  @override
  String get v2LegacyUnknown => 'موديل قديم. لسه مفيش ميعاد هيقف فيه.';

  @override
  String get v2Arabic => 'بيدعم العربي. جرّبه على المصري والإنجليزي مع بعض.';

  @override
  String get v2Generative => 'بيفهم العربي، بس ممكن يعيد صياغة الكلام. راجع التفريغ.';

  @override
  String get v2Unsupported => 'لسه مش مدعوم هنا';

  @override
  String get v2Custom => 'اكتب اسم موديل';

  @override
  String get v2Refresh => 'حدّث الليستة';

  @override
  String get v2Refreshing => 'بيحدّث الليستة…';

  @override
  String get v2Available => 'متاح في حسابك';

  @override
  String v2Checked(String time) {
    return 'آخر مراجعة: $time';
  }

  @override
  String get v2DiscoveryHint => 'بيراجع الموديلات عند الخدمة برّه الموبايل، من غير ما يبعت صوت.';

  @override
  String get v2DiscoveryQwen => 'مراجعة الموديلات مش متاحة لـQwen هنا. استخدم الموديل المقترح أو اكتب اسم الموديل.';

  @override
  String get v2EditTranscript => 'عدّل التفريغ';

  @override
  String get v2RestoreTranscript => 'رجّع التفريغ الأصلي';

  @override
  String get v2NewTranscript => 'فيه تفريغ جديد';

  @override
  String get v2UseTranscript => 'استخدمه';

  @override
  String get v2CopyUnchanged => 'التفريغ اتحفظ، بس نص الملاحظة متغيّرش عشان اتعدّل قبل كده.';

  @override
  String get v2AppendTranscript => 'ضيفه للملاحظة';

  @override
  String get v2TranscriptConflict => 'التفريغ اتغيّر وإنت بتعدّل. ارجع وافتحه تاني.';

  @override
  String get v2TranscriptFailed => 'مقدرناش نحفظ التفريغ. جرّب تاني.';

  @override
  String get v2TranscriptEmpty => 'اكتب التفريغ الأول.';

  @override
  String get v2TranscriptSaved => 'التفريغ اتحفظ';

  @override
  String get linksBrowse => 'تصفّح';

  @override
  String get linksSuggestions => 'اقتراحات';

  @override
  String get linksConfirmed => 'روابط مؤكدة';

  @override
  String get linksGroups => 'المجموعات';

  @override
  String get linksSuggestedForYou => 'مقترحة ليك';

  @override
  String get searchLinksHint => 'دوّر في الروابط';

  @override
  String get linksSort => 'ترتيب الروابط';

  @override
  String get linksNewest => 'الأحدث الأول';

  @override
  String get linksMostLinked => 'اللي فيها روابط أكتر';

  @override
  String get linksOldest => 'الأقدم الأول';

  @override
  String get linksOpenGraph => 'افتح خريطة الروابط';

  @override
  String get linkNoReason => 'من غير سبب مكتوب';

  @override
  String get linksSuggestionsEmpty => 'مفيش اقتراحات دلوقتي';

  @override
  String get linksSuggestionsEmptyBody => 'لما يبقى فيه اقتراحات جديدة، هتلاقيها هنا.';

  @override
  String get linksBrowseSuggestionsBody => 'فيه اقتراحات مستنية رأيك. اقبل أي رابط عشان يظهر هنا.';

  @override
  String linksSuggestionsCount(int count) {
    return 'اقتراحات $count';
  }

  @override
  String linksSuggestionsCountA11y(int count) {
    return 'اقتراحات، $count';
  }

  @override
  String get linksFilterEmptyBody => 'مفيش حاجة هنا لسه. جرّب مجموعة أو موضوع تاني.';

  @override
  String get linkSuggestionRejected => 'الاقتراح اترفض';

  @override
  String get servicesSection => 'الخدمات المتصلة';

  @override
  String get privacySection => 'الخصوصية والبيانات';

  @override
  String get notesSort => 'ترتيب الملاحظات';

  @override
  String get headerGraph => 'الخريطة';

  @override
  String get headerSearch => 'دوّر';

  @override
  String get capsuleRecording => 'بيسجّل…';

  @override
  String get capsuleRecordingA11y => 'بيسجّل. دوس عشان تفتح التسجيل';

  @override
  String get capsuleTranscribing => 'بيفرّغ الصوت…';

  @override
  String get capsuleTranscribingA11y => 'بيفرّغ التسجيل. دوس عشان تفتح الملاحظة';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMap => 'الخريطة';

  @override
  String get navMe => 'أنا';

  @override
  String get newIdea => 'فكرة جديدة';

  @override
  String get meIdeas => 'الأفكار';

  @override
  String get meLinks => 'الروابط';

  @override
  String get meWeekDays => 'أيام الأسبوع ده';

  @override
  String get meAppearanceLanguage => 'المظهر واللغة';

  @override
  String get meVoiceServices => 'الصوت والخدمات';

  @override
  String get welcomeEyebrow => 'FIKRAH';

  @override
  String get welcomeBrandTitle => 'FIKRAH';

  @override
  String get welcomeTagline => 'اكتب. اربط. اسأل.';

  @override
  String get welcomeSubtitle => 'أفكارك متوصّلة ببعض. اسأل ملاحظاتك وخد إجابات من تفكيرك.';

  @override
  String get welcomeStartWriting => 'ابدأ الكتابة';

  @override
  String get welcomeTrySample => 'جرّب بمشروع تجريبي';

  @override
  String get welcomeFooter => 'ملاحظاتك محفوظة على جهازك · بدون حساب';

  @override
  String get defaultProjectName => 'أفكاري';

  @override
  String get filterVoice => 'صوت';

  @override
  String get filterFiles => 'ملفات';

  @override
  String get badgePdf => 'PDF';

  @override
  String get filterEmptyTitle => 'مفيش ملاحظات هنا';

  @override
  String get filterEmptyBody => 'مفيش ملاحظات بالفلتر ده لسه.';

  @override
  String actionStripFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظة فشل تحليلها',
      few: '$count ملاحظات فشل تحليلها',
      two: 'ملاحظتين فشل تحليلهم',
      one: 'ملاحظة فشل تحليلها',
    );
    return '$_temp0';
  }

  @override
  String get actionStripRetry => 'أعد المحاولة';

  @override
  String actionStripSuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رابط مقترح جديد',
      few: '$count روابط مقترحة جديدة',
      two: 'رابطين مقترحين جداد',
      one: 'رابط مقترح جديد',
    );
    return '$_temp0';
  }

  @override
  String actionStripRewrites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صياغة مستنية رأيك',
      few: '$count صياغات مستنية رأيك',
      two: 'صياغتين مستنيين رأيك',
      one: 'صياغة مستنية رأيك',
    );
    return '$_temp0';
  }

  @override
  String get actionStripDismiss => 'اخفي التنبيه';

  @override
  String activeDaysThisWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم الأسبوع ده',
      few: '$count أيام الأسبوع ده',
      two: 'يومين الأسبوع ده',
      one: 'يوم واحد الأسبوع ده',
    );
    return '$_temp0';
  }

  @override
  String get linksMap => 'الخريطة';

  @override
  String get mapOthers => 'تانيين';

  @override
  String get mapShowMore => 'اعرض أكتر';

  @override
  String get mapOpen => 'افتح';

  @override
  String mapNotes(int count) {
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
  String mapConnections(int count) {
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
  String mapCanvasSummary(int total, int omitted) {
    return 'خريطة الملاحظات، الإجمالي: $total، مش ظاهر: $omitted';
  }

  @override
  String mapTotals(int total, int confirmed, int suggestions, int omitted) {
    return 'ملاحظات: $total · روابط: $confirmed · اقتراحات: $suggestions · مش ظاهر: $omitted';
  }

  @override
  String get mapPanHint => 'اسحب عشان تشوف باقي الخريطة';

  @override
  String get productMyAccount => 'حسابي';

  @override
  String get productThisIsAVolatileDevelopmentWorkspaceExistingLocal =>
      'دي مساحة تطوير مؤقتة. ملاحظاتك المحلية القديمة موجودة بشكل منفصل في وضع الديمو القديم.';

  @override
  String get productSignOutLocally => 'تسجيل خروج محلي';

  @override
  String get productProductionSetupPending => 'إعدادات الإنتاج لسه معلّقة';

  @override
  String get productPasswordPolicyEmailActionRoutingAndGooglePlatform =>
      'سياسة كلمة المرور وروابط البريد وإعدادات Google محتاجة اتفاق. مفيش استخدام لبيانات دخول حقيقية أو إرسال بريد هنا.';

  @override
  String get productYourSessionExpiredSignInAgain => 'الجلسة انتهت. سجّل دخول تاني.';

  @override
  String get productPreviewAccountJourneys => 'تجربة رحلات الحساب';

  @override
  String get productUseFixtureAddressesOnlyRegistrationVerificationAndRecovery =>
      'استخدم عناوين التطوير فقط. التسجيل والتفعيل والاسترجاع بيعرضوا حالات تجريبية، بدون إرسال بريد أو إنشاء حساب حقيقي.';

  @override
  String get productEmail => 'البريد الإلكتروني';

  @override
  String get productNewPasswordPreview => 'كلمة مرور جديدة (تجربة)';

  @override
  String get productPassword => 'كلمة المرور';

  @override
  String get productFixtureActionToken => 'رمز إجراء تجريبي';

  @override
  String get productAwaitingVerificationUseFixtureVerifyToPreviewSuccess =>
      'في انتظار التفعيل. استخدم fixture-verify لتجربة النجاح. لم يتم إرسال بريد.';

  @override
  String get productPreviewVerification => 'تجربة التفعيل';

  @override
  String get productPreviewResendRequest => 'تجربة طلب إعادة الإرسال';

  @override
  String get productGenericRecoveryAcknowledgmentFixtureNoDeliveryIsClaimed =>
      'تأكيد عام لطلب الاسترجاع (تجربة). بدون ادعاء وصول رسالة.';

  @override
  String get productPreviewResetForm => 'تجربة نموذج إعادة التعيين';

  @override
  String get productUseFixtureResetTheRealPasswordPolicyIs =>
      'استخدم fixture-reset. سياسة كلمة المرور الحقيقية لم تُحسم بعد.';

  @override
  String get productPreviewPasswordReset => 'تجربة إعادة التعيين';

  @override
  String get productPreviewRecoveryRequest => 'تجربة طلب الاسترجاع';

  @override
  String get productPreviewRegistration => 'تجربة التسجيل';

  @override
  String get productOpenFixtureSession => 'فتح جلسة تجريبية';

  @override
  String get productBackToSignIn => 'رجوع للدخول';

  @override
  String get productPreviewNewAccount => 'تجربة حساب جديد';

  @override
  String get productForgotPassword => 'نسيت كلمة المرور';

  @override
  String get productGoogleSignInWaitingForApprovedPlatformConfiguration =>
      'دخول Google: في انتظار إعدادات المنصة المعتمدة. مفيش طلب بيتم إرساله لـ Google.';

  @override
  String get productPreviewSampleWorkspace => 'تجربة مساحة بملاحظات جاهزة';

  @override
  String get productPreviewSeparateEmptyAccount => 'تجربة حساب منفصل وفارغ';

  @override
  String get productVerificationPreviewCompleteSignInSeparately => 'اكتملت تجربة التفعيل. سجّل الدخول بشكل منفصل.';

  @override
  String get productResetPreviewCompleteSignInAgain => 'اكتملت تجربة إعادة التعيين. سجّل دخول تاني.';

  @override
  String get productLocalPrivateStateClearedServerRevocationIsNot =>
      'تم مسح الحالة الخاصة محليًا. إلغاء جلسة الخادم غير مؤكد.';

  @override
  String get productDevelopmentAcknowledgmentOnlyNoRealDeliveryOrAccount =>
      'تأكيد تجريبي فقط؛ لم يتم إرسال بريد أو تنفيذ إجراء على حساب حقيقي.';

  @override
  String get productCaptureAThought => 'سجّل فكرة';

  @override
  String get productCloseComposer => 'إغلاق الكتابة';

  @override
  String get productASaveAttemptIsUnresolvedRetryItsOriginal =>
      'فيه محاولة حفظ لم تتأكد. أعدها بنفس المشروع والمحتوى قبل تغيير المسودة.';

  @override
  String get productReturnToThePendingAttemptSProject => 'ارجع لمشروع محاولة الحفظ';

  @override
  String get productTitleOptional => 'العنوان (اختياري)';

  @override
  String get productYourThought => 'فكرتك';

  @override
  String get productReconcileTheSameSaveAttempt => 'مراجعة نفس محاولة الحفظ';

  @override
  String get productSaveTextNote => 'حفظ ملاحظة نصية';

  @override
  String get productSavingAndProcessingAreSeparateAMissingTitle =>
      'الحفظ منفصل عن المعالجة. العنوان الناقص بيفضل مؤقت لحد ما نتيجة الباك إند ترجع بعنوان.';

  @override
  String get productVoiceReviewedText => 'الصوت ← نص تراجعه';

  @override
  String get productAutomaticStopAt60SecondsTranscriptionDoesNot =>
      'التسجيل بيقف تلقائيًا بعد 60 ثانية. التفريغ مش بيحفظ ملاحظة.';

  @override
  String get productStopRecording => 'إيقاف التسجيل';

  @override
  String get productRecordVoice => 'تسجيل صوت';

  @override
  String get productPreviewTranscription => 'تجربة التفريغ النصي';

  @override
  String get productReviewAndEditTranscript => 'راجع وعدّل النص المفرّغ';

  @override
  String get productUseThisTextInTheDraft => 'استخدم النص في المسودة';

  @override
  String get productThenPressSaveTextNoteWhenReady => 'بعد المراجعة اضغط حفظ ملاحظة نصية.';

  @override
  String get productDiscardRecording => 'إلغاء التسجيل';

  @override
  String get productLocalPDFs => 'ملفات PDF محلية';

  @override
  String get productPDFsStayOnThisDeviceTheyAreNot =>
      'ملفات PDF بتفضل على الجهاز. مش بيتم رفعها أو استخراج نصها أو ربطها بملاحظة على الخادم. احفظ النص بشكل منفصل.';

  @override
  String get productChooseLocalPDF => 'اختيار PDF محلي';

  @override
  String get productUntitledProcessing => 'بدون عنوان / قيد المعالجة';

  @override
  String get productSavedQueued => 'محفوظة · في الانتظار';

  @override
  String get productSavedProcessing => 'محفوظة · قيد المعالجة';

  @override
  String get productProcessingCompleted => 'اكتملت المعالجة';

  @override
  String get productSavedProcessingFailed => 'محفوظة · فشلت المعالجة';

  @override
  String get productSavedStatusUnavailable => 'محفوظة · الحالة غير معروفة';

  @override
  String get productDevelopmentFixturesMemoryOnlyNoLiveBackend =>
      'بيانات تطوير · في الذاكرة فقط · بدون اتصال بالباك إند';

  @override
  String get productMicrophonePermissionIsRequiredEnableItInDevice =>
      'اسمح باستخدام الميكروفون من إعدادات الجهاز ثم حاول تاني.';

  @override
  String get productCheckTheInputYourDraftHasBeenKept => 'راجع البيانات. المسودة محفوظة كما هي.';

  @override
  String get productSignInAgainOrCheckYourCredentials => 'سجّل دخول تاني أو راجع بيانات الدخول.';

  @override
  String get productVerifyYourEmailBeforeSigningIn => 'فعّل بريدك الإلكتروني قبل الدخول.';

  @override
  String get productThisItemIsNoLongerAvailableReloadThe => 'العنصر ده مش متاح. حدّث المشروع الحالي.';

  @override
  String get productTheStateChangedReloadAndReviewBeforeActing => 'الحالة اتغيرت. حدّث وراجعها قبل تنفيذ الإجراء تاني.';

  @override
  String get productThisCreationAttemptRefersToADeletedNote =>
      'محاولة الحفظ دي تخص ملاحظة اتحذفت، ومش هتتعمل تلقائيًا من جديد.';

  @override
  String get productTheInputIsTooLargeReduceItBefore => 'حجم المدخل كبير. قلّله قبل المحاولة.';

  @override
  String get productThisRecordingFormatIsNotSupported => 'صيغة التسجيل دي غير مدعومة.';

  @override
  String get productRequestLimitReachedWaitBeforeTryingAgain => 'وصلت لحد الطلبات. استنى قبل المحاولة.';

  @override
  String get productThisServiceIsUnavailableYourInputHasBeen => 'الخدمة مش متاحة حاليًا. البيانات اللي كتبتها موجودة.';

  @override
  String get productTheResultIsUncertainReconcileBeforeTryingAgain =>
      'نتيجة العملية غير مؤكدة. راجع الحالة قبل المحاولة تاني.';

  @override
  String productRetryAfterSeconds(int seconds) {
    return 'حاول بعد $seconds ثانية.';
  }

  @override
  String get productReloadRetry => 'تحديث / إعادة المحاولة';

  @override
  String get productBack => 'رجوع';

  @override
  String get productRenameProject => 'تعديل اسم المشروع';

  @override
  String get productNewProject => 'مشروع جديد';

  @override
  String get productName => 'الاسم';

  @override
  String get productCancel => 'إلغاء';

  @override
  String get productSave => 'حفظ';

  @override
  String get productProject => 'المشروع';

  @override
  String get productRename => 'تغيير الاسم';

  @override
  String get productDeleteProject => 'حذف المشروع؟';

  @override
  String get productThisPermanentlyDeletesItsNotesConversationsAndKnowledge =>
      'ده هيحذف ملاحظاته ومحادثاته وعلاقاته المعرفية نهائيًا.';

  @override
  String get productDelete => 'حذف';

  @override
  String get productDeleteProject2 => 'حذف المشروع';

  @override
  String get productNotes => 'الملاحظات';

  @override
  String get productReload => 'تحديث';

  @override
  String get productSearchThisProject => 'ابحث في المشروع ده';

  @override
  String get productSearch => 'بحث';

  @override
  String get productDevelopmentSearchUsesLiteralFixtureMatchingNotSemantic =>
      'بحث التطوير بيطابق النصوص التجريبية حرفيًا، مش بحث دلالي.';

  @override
  String get productStillProcessingReloadLaterTheSavedNoteIs => 'لسه قيد المعالجة. حدّث لاحقًا؛ الملاحظة محفوظة.';

  @override
  String get productSearchResults => 'نتائج البحث';

  @override
  String get productNoResultsInThisProject => 'مفيش نتائج في المشروع ده.';

  @override
  String get productShowAllSavedNotes => 'عرض كل الملاحظات المحفوظة';

  @override
  String get productNoNotesYet => 'مفيش ملاحظات لسه';

  @override
  String get productNote => 'الملاحظة';

  @override
  String get productTheCurrentProposalWasReloadedReviewItBefore =>
      'تم تحميل الاقتراح الحالي. راجعه قبل اختيار إجراء جديد.';

  @override
  String get productThisNoteIsUnavailableInTheSelectedProject => 'الملاحظة مش متاحة في المشروع الحالي.';

  @override
  String get productSavedContent => 'المحتوى المحفوظ';

  @override
  String get productSaveEdit => 'حفظ التعديل';

  @override
  String get productCancelEditing => 'إلغاء التعديل';

  @override
  String get productEditNote => 'تعديل الملاحظة';

  @override
  String get productRefinementProposal => 'اقتراح تحسين';

  @override
  String get productAcceptAndReplaceSavedContent => 'قبول واستبدال المحتوى المحفوظ';

  @override
  String get productReplaceSavedContent => 'استبدال المحتوى المحفوظ؟';

  @override
  String get productAcceptancePermanentlyReplacesTheContentAndStartsProcessing =>
      'القبول بيستبدل المحتوى نهائيًا وبيبدأ المعالجة من جديد. مفيش تراجع أو سجل نسخ.';

  @override
  String get productAccept => 'قبول';

  @override
  String get productRejectProposal => 'رفض الاقتراح';

  @override
  String get productRequestAnotherProposal => 'طلب اقتراح جديد';

  @override
  String get productRetryReprocess => 'إعادة المعالجة';

  @override
  String get productReloadStatus => 'تحديث الحالة';

  @override
  String get productRelatedNotes => 'ملاحظات مرتبطة';

  @override
  String get productNoCurrentRelationships => 'مفيش علاقات حالية.';

  @override
  String get productDeleteNote => 'حذف الملاحظة';

  @override
  String get productDeleteNote2 => 'حذف الملاحظة؟';

  @override
  String get productItsRelationshipsAndSourceCitationsWillAlsoBe => 'العلاقات والإشارات للملاحظة كمصدر هتتحذف كمان.';

  @override
  String get productKnowledgeMap => 'خريطة المعرفة';

  @override
  String get productReloadMap => 'تحديث الخريطة';

  @override
  String get productEveryNodeIsANoteLinesShowSupplied =>
      'كل نقطة ملاحظة. الخطوط بتعرض العلاقات الواردة فقط. اسحب الملاحظات أو استخدم إصبعين للتكبير.';

  @override
  String get productNoCompletedNotesInThisProjectYet => 'مفيش ملاحظات مكتملة المعالجة في المشروع لسه.';

  @override
  String get productZoomIn => 'تكبير';

  @override
  String get productResetView => 'إعادة ضبط العرض';

  @override
  String productGraphCounts(int notes, int relationships) {
    String _temp0 = intl.Intl.pluralLogic(
      notes,
      locale: localeName,
      other: '$notes ملاحظة',
      many: '$notes ملاحظة',
      few: '$notes ملاحظات',
      two: 'ملاحظتان',
      one: 'ملاحظة واحدة',
      zero: 'مفيش ملاحظات',
    );
    String _temp1 = intl.Intl.pluralLogic(
      relationships,
      locale: localeName,
      other: '$relationships علاقة',
      many: '$relationships علاقة',
      few: '$relationships علاقات',
      two: 'علاقتان',
      one: 'علاقة واحدة',
      zero: 'مفيش علاقات',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get productAsk => 'اسأل';

  @override
  String get productNewConversation => 'محادثة جديدة';

  @override
  String get productReloadHistoryList => 'تحديث قائمة المحادثات';

  @override
  String get productConversationHistory => 'سجل المحادثات';

  @override
  String get productStartAConversationOrOpenItsHistoryConversations =>
      'ابدأ محادثة أو افتح سجلها. كل محادثة بتفضل داخل المشروع المختار.';

  @override
  String get productYou => 'أنت';

  @override
  String get productNotSupportedByThisProjectSKnowledge => 'غير مدعوم بمعرفة المشروع ده';

  @override
  String get productProvisionalNotConfirmedSaved => 'عرض مؤقت · لم يتأكد حفظه';

  @override
  String get productStopWaiting => 'إيقاف الانتظار';

  @override
  String get productReloadHistoryBeforeSendingAgain => 'حمّل السجل قبل الإرسال تاني';

  @override
  String get productHistoryReloadedReviewItBeforeDeliberatelySendingYour =>
      'السجل اتحدّث. راجعه قبل ما تختار إرسال المسودة الموجودة تاني.';

  @override
  String get productAskThisProject => 'اسأل المشروع ده';

  @override
  String get productSend => 'إرسال';

  @override
  String get productDeleteConversation => 'حذف المحادثة؟';

  @override
  String get productThisDeletesTheConversationAndMessagesWhileKeeping =>
      'ده بيحذف المحادثة ورسائلها وبيحتفظ بالملاحظات.';

  @override
  String get productDeleteConversation2 => 'حذف المحادثة';

  @override
  String get productReviewFailedSave => 'مراجعة المسودة لمحاولة حفظ جديدة';

  @override
  String get productNewIntentionalSaveExplanation =>
      'المحاولة السابقة اترفضت أو تخص ملاحظة اتحذفت. هنحتفظ بالمسودة، ومحاولة جديدة هتبدأ فقط لما تختار الحفظ تاني.';

  @override
  String get uiSignUpEmail => 'إنشاء حساب بالبريد الإلكتروني';

  @override
  String get uiLogIn => 'تسجيل الدخول';

  @override
  String get uiContinueGoogle => 'المتابعة باستخدام Google';

  @override
  String get uiCreateAccount => 'إنشاء حسابك';

  @override
  String get uiWelcomeBack => 'مرحبًا بعودتك';

  @override
  String get uiShowPassword => 'إظهار كلمة المرور';

  @override
  String get uiHidePassword => 'إخفاء كلمة المرور';

  @override
  String get uiNewIdea => 'فكرة جديدة';

  @override
  String get uiVoice => 'صوت';

  @override
  String get uiFile => 'ملف';

  @override
  String get uiProfile => 'الملف الشخصي';

  @override
  String get uiSettings => 'الإعدادات';

  @override
  String get uiIdeas => 'الأفكار';

  @override
  String get uiAll => 'الكل';

  @override
  String get uiToday => 'اليوم';

  @override
  String get uiEarlier => 'سابقًا';

  @override
  String get uiIdeaMap => 'خريطة الأفكار';

  @override
  String get uiSearchIdeas => 'ابحث في أفكارك';

  @override
  String get uiMapHint => 'اسحب الأفكار، وكبّر بإصبعين، واضغط للفتح';

  @override
  String get uiZoomOut => 'تصغير';

  @override
  String get uiFitIdeas => 'إظهار كل الأفكار';

  @override
  String get uiOpenNote => 'فتح الملاحظة';

  @override
  String get uiConnectedIdeas => 'أفكار مرتبطة';

  @override
  String get uiUnavailable => 'غير متاح بعد';

  @override
  String get uiPreviewNotice => 'معاينة تطوير · بيانات مؤقتة';

  @override
  String get uiGoogleUnavailable => 'تسجيل الدخول عبر Google غير متاح في هذه المعاينة.';

  @override
  String get uiWelcomeSubtitle => 'أفكارك مترابطة. اسأل ملاحظاتك عن أي شيء.';
}
