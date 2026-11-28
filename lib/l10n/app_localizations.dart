import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// Proper app name; retain the approved brand spelling.
  ///
  /// In ar, this message translates to:
  /// **'FIKRAH'**
  String get appTitle;

  /// No description provided for @navAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get navAdd;

  /// No description provided for @navNotes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get navNotes;

  /// No description provided for @navLinks.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get navLinks;

  /// No description provided for @navAsk.
  ///
  /// In ar, this message translates to:
  /// **'اسأل'**
  String get navAsk;

  /// No description provided for @storageErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'فيه مشكلة في التخزين'**
  String get storageErrorTitle;

  /// No description provided for @storageErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرا بياناتك دلوقتي. اتأكد إن فيه مساحة فاضية على الموبايل، وجرّب تاني.'**
  String get storageErrorBody;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تاني'**
  String get retry;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'النهارده'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'امبارح'**
  String get yesterday;

  /// No description provided for @justNow.
  ///
  /// In ar, this message translates to:
  /// **'دلوقتي'**
  String get justNow;

  /// No description provided for @sizeBytes.
  ///
  /// In ar, this message translates to:
  /// **'{size} بايت'**
  String sizeBytes(String size);

  /// No description provided for @sizeKb.
  ///
  /// In ar, this message translates to:
  /// **'{size} KB'**
  String sizeKb(String size);

  /// No description provided for @sizeMb.
  ///
  /// In ar, this message translates to:
  /// **'{size} MB'**
  String sizeMb(String size);

  /// No description provided for @badgeSampleData.
  ///
  /// In ar, this message translates to:
  /// **'بيانات تجريبية'**
  String get badgeSampleData;

  /// No description provided for @badgeSaved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت'**
  String get badgeSaved;

  /// No description provided for @badgeAnalyzing.
  ///
  /// In ar, this message translates to:
  /// **'بنحللها…'**
  String get badgeAnalyzing;

  /// No description provided for @badgeFailed.
  ///
  /// In ar, this message translates to:
  /// **'فيه مشكلة'**
  String get badgeFailed;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @loadErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحمّل البيانات'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرا بياناتك دلوقتي. جرّب تاني.'**
  String get loadErrorBody;

  /// No description provided for @genericError.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة. جرّب تاني.'**
  String get genericError;

  /// No description provided for @voicePlayA11y.
  ///
  /// In ar, this message translates to:
  /// **'شغّل'**
  String get voicePlayA11y;

  /// No description provided for @voicePauseA11y.
  ///
  /// In ar, this message translates to:
  /// **'وقّف'**
  String get voicePauseA11y;

  /// No description provided for @voiceUnavailableA11y.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل مش متاح'**
  String get voiceUnavailableA11y;

  /// No description provided for @voiceRecording.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل صوتي'**
  String get voiceRecording;

  /// No description provided for @fileUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الملف مش متاح'**
  String get fileUnavailable;

  /// No description provided for @deleteRecording.
  ///
  /// In ar, this message translates to:
  /// **'احذف التسجيل'**
  String get deleteRecording;

  /// No description provided for @firstProjectTitle.
  ///
  /// In ar, this message translates to:
  /// **'سمّي أول مشروع'**
  String get firstProjectTitle;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get create;

  /// No description provided for @createProjectFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نعمل المشروع. جرّب تاني.'**
  String get createProjectFailed;

  /// No description provided for @sampleProjectFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفتح المشروع الجاهز. جرّب تاني.'**
  String get sampleProjectFailed;

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'اكتب. اربط. اسأل.'**
  String get tagline;

  /// No description provided for @welcomeCapture.
  ///
  /// In ar, this message translates to:
  /// **'اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور'**
  String get welcomeCapture;

  /// No description provided for @welcomeLinks.
  ///
  /// In ar, this message translates to:
  /// **'FIKRAH بتربط الملاحظات القريبة من بعض لوحدها'**
  String get welcomeLinks;

  /// No description provided for @welcomeAsk.
  ///
  /// In ar, this message translates to:
  /// **'اسأل، والإجابة بتيجي من ملاحظاتك ومعاها المصدر'**
  String get welcomeAsk;

  /// No description provided for @welcomeDemoBadge.
  ///
  /// In ar, this message translates to:
  /// **'نسخة تجريبية: كل حاجة بتفضل على موبايلك'**
  String get welcomeDemoBadge;

  /// No description provided for @startNewProject.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ مشروع جديد'**
  String get startNewProject;

  /// No description provided for @trySampleProject.
  ///
  /// In ar, this message translates to:
  /// **'جرّب مشروع جاهز'**
  String get trySampleProject;

  /// No description provided for @projectPillA11y.
  ///
  /// In ar, this message translates to:
  /// **'المشروع: {name}. دوس عشان تغيّره'**
  String projectPillA11y(String name);

  /// No description provided for @noProject.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مشروع'**
  String get noProject;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @projectsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المشاريع'**
  String get projectsTitle;

  /// No description provided for @newProject.
  ///
  /// In ar, this message translates to:
  /// **'مشروع جديد'**
  String get newProject;

  /// No description provided for @projectOptionsA11y.
  ///
  /// In ar, this message translates to:
  /// **'خيارات «{name}»'**
  String projectOptionsA11y(String name);

  /// No description provided for @renameProject.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الاسم'**
  String get renameProject;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'احفظ'**
  String get save;

  /// No description provided for @deleteProject.
  ///
  /// In ar, this message translates to:
  /// **'احذف المشروع'**
  String get deleteProject;

  /// No description provided for @deleteProjectTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحذف «{name}»؟'**
  String deleteProjectTitle(String name);

  /// No description provided for @deleteProjectBody.
  ///
  /// In ar, this message translates to:
  /// **'هيتحذف {items}، والمحادثة كمان. مش هتعرف ترجّعهم.'**
  String deleteProjectBody(String items);

  /// No description provided for @projectDeleted.
  ///
  /// In ar, this message translates to:
  /// **'المشروع اتحذف'**
  String get projectDeleted;

  /// No description provided for @projectNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم المشروع'**
  String get projectNameHint;

  /// No description provided for @recordStartFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نبدأ التسجيل. جرّب تاني.'**
  String get recordStartFailed;

  /// No description provided for @recordInterrupted.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل اتقطع. سجّل تاني.'**
  String get recordInterrupted;

  /// No description provided for @pdfOnly.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده مش PDF. اختار ملف PDF.'**
  String get pdfOnly;

  /// No description provided for @fileOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفتح الملف. جرّب ملف تاني.'**
  String get fileOpenFailed;

  /// No description provided for @photosOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفتح الصور. جرّب تاني.'**
  String get photosOpenFailed;

  /// No description provided for @noteSaved.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة اتحفظت'**
  String get noteSaved;

  /// No description provided for @noteSavedAnalyzing.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة اتحفظت، وFIKRAH بتحللها دلوقتي'**
  String get noteSavedAnalyzing;

  /// No description provided for @noteSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحفظ الملاحظة. جرّب تاني.'**
  String get noteSaveFailed;

  /// Default title for a photo-only note. The parenthetical location note in the glossary is not UI copy.
  ///
  /// In ar, this message translates to:
  /// **'صور'**
  String get photosTitle;

  /// No description provided for @addTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get addTitle;

  /// No description provided for @titleOptionalHint.
  ///
  /// In ar, this message translates to:
  /// **'عنوان (اختياري)'**
  String get titleOptionalHint;

  /// No description provided for @bodyHintWithFileLinks.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كام سطر عن الملف عشان FIKRAH تربطه (اختياري)'**
  String get bodyHintWithFileLinks;

  /// No description provided for @bodyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب فكرتك هنا…'**
  String get bodyHint;

  /// No description provided for @addFooter.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة بتتحفظ على طول، وبعدين FIKRAH بتحلل النص وتربطه بالباقي. الملفات بتفضل على موبايلك.'**
  String get addFooter;

  /// No description provided for @discardRecording.
  ///
  /// In ar, this message translates to:
  /// **'الغي التسجيل'**
  String get discardRecording;

  /// No description provided for @stopRecording.
  ///
  /// In ar, this message translates to:
  /// **'وقّف التسجيل'**
  String get stopRecording;

  /// No description provided for @recordVoice.
  ///
  /// In ar, this message translates to:
  /// **'سجّل صوت'**
  String get recordVoice;

  /// No description provided for @addPdf.
  ///
  /// In ar, this message translates to:
  /// **'ضيف PDF'**
  String get addPdf;

  /// No description provided for @addPhotos.
  ///
  /// In ar, this message translates to:
  /// **'ضيف صور'**
  String get addPhotos;

  /// No description provided for @removeFile.
  ///
  /// In ar, this message translates to:
  /// **'شيل الملف'**
  String get removeFile;

  /// No description provided for @removePhoto.
  ///
  /// In ar, this message translates to:
  /// **'شيل الصورة {n}'**
  String removePhoto(int n);

  /// No description provided for @micNeededTitle.
  ///
  /// In ar, this message translates to:
  /// **'محتاجين إذن المايك'**
  String get micNeededTitle;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'اقفل'**
  String get close;

  /// No description provided for @micBlockedBody.
  ///
  /// In ar, this message translates to:
  /// **'المايك مقفول لـ FIKRAH. افتح إعدادات التطبيق واسمح بالمايك.'**
  String get micBlockedBody;

  /// No description provided for @micAskBody.
  ///
  /// In ar, this message translates to:
  /// **'عشان تسجّل فكرة بصوتك، اسمح لـ FIKRAH تستخدم المايك.'**
  String get micAskBody;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'افتح الإعدادات'**
  String get openSettings;

  /// No description provided for @allowMic.
  ///
  /// In ar, this message translates to:
  /// **'اسمح بالمايك'**
  String get allowMic;

  /// No description provided for @recordingNow.
  ///
  /// In ar, this message translates to:
  /// **'بيسجّل'**
  String get recordingNow;

  /// No description provided for @notesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get notesTitle;

  /// No description provided for @searchNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'دوّر في الملاحظات'**
  String get searchNotesHint;

  /// No description provided for @notesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش ملاحظات'**
  String get notesEmptyTitle;

  /// No description provided for @notesEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور، وFIKRAH هترتّبها وتربطها لوحدها.'**
  String get notesEmptyBody;

  /// No description provided for @addFirstNote.
  ///
  /// In ar, this message translates to:
  /// **'ضيف أول ملاحظة'**
  String get addFirstNote;

  /// No description provided for @noResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتايج'**
  String get noResultsTitle;

  /// No description provided for @noResultsBody.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظة فيها «{query}». جرّب كلمة تانية.'**
  String noResultsBody(String query);

  /// No description provided for @noteAnalysisFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحللها'**
  String get noteAnalysisFailed;

  /// No description provided for @noteRewriteSuggested.
  ///
  /// In ar, this message translates to:
  /// **'فيه صياغة مقترحة'**
  String get noteRewriteSuggested;

  /// No description provided for @noteSavedBadge.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة'**
  String get noteSavedBadge;

  /// No description provided for @openFileA11y.
  ///
  /// In ar, this message translates to:
  /// **'افتح {name}'**
  String openFileA11y(String name);

  /// No description provided for @untitledNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة جديدة'**
  String get untitledNote;

  /// No description provided for @openFileFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفتح الملف. اتأكد إن عندك تطبيق يفتح النوع ده.'**
  String get openFileFailed;

  /// No description provided for @noteOptions.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الملاحظة'**
  String get noteOptions;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'عدّل'**
  String get edit;

  /// No description provided for @restoreOriginal.
  ///
  /// In ar, this message translates to:
  /// **'رجّع النص الأصلي'**
  String get restoreOriginal;

  /// No description provided for @originalRestored.
  ///
  /// In ar, this message translates to:
  /// **'رجّعنا النص الأصلي'**
  String get originalRestored;

  /// No description provided for @deleteNote.
  ///
  /// In ar, this message translates to:
  /// **'احذف الملاحظة'**
  String get deleteNote;

  /// No description provided for @deleteNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحذف الملاحظة دي؟'**
  String get deleteNoteTitle;

  /// No description provided for @deleteNoteBody.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.'**
  String get deleteNoteBody;

  /// No description provided for @noteDeleted.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة اتحذفت'**
  String get noteDeleted;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @options.
  ///
  /// In ar, this message translates to:
  /// **'خيارات'**
  String get options;

  /// No description provided for @noteNotFoundTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة دي مش موجودة'**
  String get noteNotFoundTitle;

  /// No description provided for @noteNotFoundBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكن تكون اتحذفت.'**
  String get noteNotFoundBody;

  /// No description provided for @analysisFailedBanner.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحلل الملاحظة، بس هي محفوظة زي ما هي.'**
  String get analysisFailedBanner;

  /// No description provided for @analyzeAgain.
  ///
  /// In ar, this message translates to:
  /// **'حلّلها تاني'**
  String get analyzeAgain;

  /// No description provided for @viewEdited.
  ///
  /// In ar, this message translates to:
  /// **'المعدّلة'**
  String get viewEdited;

  /// No description provided for @viewOriginal.
  ///
  /// In ar, this message translates to:
  /// **'الأصلية'**
  String get viewOriginal;

  /// No description provided for @originalTextLabel.
  ///
  /// In ar, this message translates to:
  /// **'النص الأصلي'**
  String get originalTextLabel;

  /// No description provided for @topicsHeader.
  ///
  /// In ar, this message translates to:
  /// **'المواضيع'**
  String get topicsHeader;

  /// No description provided for @analyzingBody.
  ///
  /// In ar, this message translates to:
  /// **'FIKRAH بتحلل الملاحظة دلوقتي عشان تطلّع مواضيعها وتلاقي الملاحظات المرتبطة بيها. الملاحظة نفسها محفوظة.'**
  String get analyzingBody;

  /// No description provided for @suggestedRewrite.
  ///
  /// In ar, this message translates to:
  /// **'صياغة مقترحة'**
  String get suggestedRewrite;

  /// No description provided for @demoBadge.
  ///
  /// In ar, this message translates to:
  /// **'تجريبي'**
  String get demoBadge;

  /// No description provided for @useRewrite.
  ///
  /// In ar, this message translates to:
  /// **'استخدمها'**
  String get useRewrite;

  /// No description provided for @keepOriginal.
  ///
  /// In ar, this message translates to:
  /// **'خلّي النص الأصلي'**
  String get keepOriginal;

  /// No description provided for @pdfFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف PDF'**
  String get pdfFile;

  /// No description provided for @openPhotoA11y.
  ///
  /// In ar, this message translates to:
  /// **'افتح الصورة {n}'**
  String openPhotoA11y(int n);

  /// No description provided for @changesSaved.
  ///
  /// In ar, this message translates to:
  /// **'التعديل اتحفظ'**
  String get changesSaved;

  /// No description provided for @changesSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحفظ التعديل. جرّب تاني.'**
  String get changesSaveFailed;

  /// No description provided for @unsavedTitle.
  ///
  /// In ar, this message translates to:
  /// **'عندك تعديلات مش محفوظة'**
  String get unsavedTitle;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'احفظ التعديل'**
  String get saveChanges;

  /// No description provided for @discardChanges.
  ///
  /// In ar, this message translates to:
  /// **'اخرج من غير حفظ'**
  String get discardChanges;

  /// No description provided for @keepEditing.
  ///
  /// In ar, this message translates to:
  /// **'كمّل تعديل'**
  String get keepEditing;

  /// No description provided for @editNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get editNoteTitle;

  /// No description provided for @titleHint.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get titleHint;

  /// No description provided for @noteTextA11y.
  ///
  /// In ar, this message translates to:
  /// **'نص الملاحظة'**
  String get noteTextA11y;

  /// Applies to every note source. Saved recordings can be transcribed locally after saving.
  ///
  /// In ar, this message translates to:
  /// **'النص الأصلي بيفضل محفوظ، وتقدر ترجّعه من خيارات الملاحظة.'**
  String get originalKeptHint;

  /// No description provided for @clusterGeneral.
  ///
  /// In ar, this message translates to:
  /// **'أفكار عامة'**
  String get clusterGeneral;

  /// No description provided for @moreGroups.
  ///
  /// In ar, this message translates to:
  /// **'باقي المجموعات'**
  String get moreGroups;

  /// No description provided for @linksTitle.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get linksTitle;

  /// No description provided for @linksEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الروابط بتظهر هنا'**
  String get linksEmptyTitle;

  /// No description provided for @linksEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'ضيف ملاحظتين أو أكتر عن مواضيع قريبة، وFIKRAH هتربطهم ببعض.'**
  String get linksEmptyBody;

  /// No description provided for @addNote.
  ///
  /// In ar, this message translates to:
  /// **'ضيف ملاحظة'**
  String get addNote;

  /// No description provided for @linksSummary.
  ///
  /// In ar, this message translates to:
  /// **'{notesCount} · {linksCount}'**
  String linksSummary(String notesCount, String linksCount);

  /// No description provided for @zoomIn.
  ///
  /// In ar, this message translates to:
  /// **'كبّر'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In ar, this message translates to:
  /// **'صغّر'**
  String get zoomOut;

  /// No description provided for @resetView.
  ///
  /// In ar, this message translates to:
  /// **'رجّع العرض'**
  String get resetView;

  /// No description provided for @showGroupA11y.
  ///
  /// In ar, this message translates to:
  /// **'اعرض {notesCount} في «{cluster}»'**
  String showGroupA11y(String notesCount, String cluster);

  /// No description provided for @moreGroupsCount.
  ///
  /// In ar, this message translates to:
  /// **'باقي المجموعات ({count})'**
  String moreGroupsCount(int count);

  /// No description provided for @noLinksYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش روابط. الملاحظات اللي بتتكلم في نفس المواضيع هتتربط ببعض لوحدها.'**
  String get noLinksYet;

  /// No description provided for @nodeMeta.
  ///
  /// In ar, this message translates to:
  /// **'{cluster} · {linksCount}'**
  String nodeMeta(String cluster, String linksCount);

  /// No description provided for @openNote.
  ///
  /// In ar, this message translates to:
  /// **'افتح الملاحظة'**
  String get openNote;

  /// No description provided for @askFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجاوب دلوقتي. جرّب تاني.'**
  String get askFailed;

  /// No description provided for @clearChatTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمسح المحادثة؟'**
  String get clearChatTitle;

  /// No description provided for @clearChatBody.
  ///
  /// In ar, this message translates to:
  /// **'الأسئلة والإجابات هتتمسح، والملاحظات نفسها مش هيحصلها حاجة.'**
  String get clearChatBody;

  /// No description provided for @clear.
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get clear;

  /// No description provided for @askSuggestion.
  ///
  /// In ar, this message translates to:
  /// **'إيه اللي كتبته عن {title}؟'**
  String askSuggestion(String title);

  /// No description provided for @askTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسأل'**
  String get askTitle;

  /// No description provided for @clearChatA11y.
  ///
  /// In ar, this message translates to:
  /// **'امسح المحادثة'**
  String get clearChatA11y;

  /// No description provided for @askDemoBadge.
  ///
  /// In ar, this message translates to:
  /// **'إجابات تجريبية من ملاحظاتك'**
  String get askDemoBadge;

  /// No description provided for @askEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسأل عن ملاحظاتك'**
  String get askEmptyTitle;

  /// No description provided for @askEmptyNoNotes.
  ///
  /// In ar, this message translates to:
  /// **'ضيف ملاحظات الأول، وبعدين اسأل عنها هنا. الإجابة بتيجي من ملاحظاتك بس، ومعاها المصدر.'**
  String get askEmptyNoNotes;

  /// No description provided for @askEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'الإجابة بتيجي من ملاحظات المشروع ده بس، ومعاها المصدر.'**
  String get askEmptyBody;

  /// No description provided for @askHint.
  ///
  /// In ar, this message translates to:
  /// **'اسأل عن أي حاجة في ملاحظاتك'**
  String get askHint;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'ابعت'**
  String get send;

  /// No description provided for @notFoundInNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملقيناش إجابة في ملاحظاتك'**
  String get notFoundInNotes;

  /// No description provided for @sources.
  ///
  /// In ar, this message translates to:
  /// **'المصادر'**
  String get sources;

  /// No description provided for @sourceA11y.
  ///
  /// In ar, this message translates to:
  /// **'مصدر {index}: {title}'**
  String sourceA11y(int index, String title);

  /// No description provided for @eraseAllTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمسح كل البيانات؟'**
  String get eraseAllTitle;

  /// Local wipe confirmation. Includes user-added transcription configuration and secure API keys; does not delete copies held by providers.
  ///
  /// In ar, this message translates to:
  /// **'كل المشاريع والملاحظات والتسجيلات والملفات والمحادثات وخدمات التفريغ ومفاتيحها هتتمسح من الموبايل، ومش هتعرف ترجّعها.'**
  String get eraseAllBody;

  /// No description provided for @eraseAllConfirm.
  ///
  /// In ar, this message translates to:
  /// **'امسح كل حاجة'**
  String get eraseAllConfirm;

  /// No description provided for @eraseAllDone.
  ///
  /// In ar, this message translates to:
  /// **'كل حاجة اتمسحت'**
  String get eraseAllDone;

  /// No description provided for @eraseAllPartial.
  ///
  /// In ar, this message translates to:
  /// **'البيانات اتمسحت، بس فيه ملفات لسه. هتتمسح لوحدها أول ما تفتح التطبيق تاني.'**
  String get eraseAllPartial;

  /// No description provided for @eraseAllFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نمسح البيانات. جرّب تاني.'**
  String get eraseAllFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'زي الموبايل'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'غامق'**
  String get themeDark;

  /// No description provided for @themeHint.
  ///
  /// In ar, this message translates to:
  /// **'«زي الموبايل» بيخلّي شكل التطبيق فاتح أو غامق على حسب موبايلك.'**
  String get themeHint;

  /// No description provided for @dataStaysLocal.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك وملفاتك محفوظة على الموبايل ده بس، ومش بتتبعت لأي مكان.'**
  String get dataStaysLocal;

  /// No description provided for @eraseAll.
  ///
  /// In ar, this message translates to:
  /// **'امسح كل البيانات'**
  String get eraseAll;

  /// No description provided for @aboutSection.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutSection;

  /// No description provided for @demoVersion.
  ///
  /// In ar, this message translates to:
  /// **'نسخة تجريبية'**
  String get demoVersion;

  /// No description provided for @languageSection.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageSection;

  /// No description provided for @languageSystem.
  ///
  /// In ar, this message translates to:
  /// **'زي الموبايل'**
  String get languageSystem;

  /// Language name shown in Arabic in both UI languages so users can recognize it.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Language name shown in English in both UI languages so users can recognize it.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// The concept is a stored topic label from a note; do not translate the placeholder value.
  ///
  /// In ar, this message translates to:
  /// **'مرتبطة بـ{concept}'**
  String demoLinkReason(String concept);

  /// No description provided for @demoAnswerNotFound.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظة في المشروع ده بتتكلم عن الموضوع ده. جرّب تسأل بطريقة تانية، أو ضيف ملاحظة عنه.'**
  String get demoAnswerNotFound;

  /// No description provided for @demoAnswerIntro.
  ///
  /// In ar, this message translates to:
  /// **'من ملاحظاتك في المشروع ده:'**
  String get demoAnswerIntro;

  /// No description provided for @untitledNoteFallback.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة من غير عنوان'**
  String get untitledNoteFallback;

  /// No description provided for @expandLlm.
  ///
  /// In ar, this message translates to:
  /// **'LLM (نموذج لغوي كبير)'**
  String get expandLlm;

  /// No description provided for @expandRag.
  ///
  /// In ar, this message translates to:
  /// **'RAG (Retrieval-Augmented Generation)'**
  String get expandRag;

  /// No description provided for @sampleProjectName.
  ///
  /// In ar, this message translates to:
  /// **'مشروع التخرج'**
  String get sampleProjectName;

  /// No description provided for @sample1Title.
  ///
  /// In ar, this message translates to:
  /// **'فكرة المشروع'**
  String get sample1Title;

  /// No description provided for @sample1Body.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق ملاحظات بيستخدم الذكاء الاصطناعي عشان يربط الأفكار ببعض ويجاوب على أسئلتي من ملاحظاتي بس.'**
  String get sample1Body;

  /// No description provided for @sample2Title.
  ///
  /// In ar, this message translates to:
  /// **'إزاي RAG بيشتغل'**
  String get sample2Title;

  /// No description provided for @sample2Body.
  ///
  /// In ar, this message translates to:
  /// **'الـrag بيجيب أقرب أجزاء من الملاحظات بالـembedding وبعدين الـllm بيكتب الإجابة منها مع ذكر المصدر'**
  String get sample2Body;

  /// No description provided for @sample3Title.
  ///
  /// In ar, this message translates to:
  /// **'شكل الواجهة'**
  String get sample3Title;

  /// Historical student note describing the original UI; preserve the dark/RTL description in both languages.
  ///
  /// In ar, this message translates to:
  /// **'تصميم الواجهة غامق وبسيط، بالعربي من اليمين للشمال، وفيه أربع تابات: إضافة، الملاحظات، الروابط، اسأل.'**
  String get sample3Body;

  /// No description provided for @sample4Title.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الحالة في Flutter'**
  String get sample4Title;

  /// No description provided for @sample4Body.
  ///
  /// In ar, this message translates to:
  /// **'هستخدم riverpod لإدارة الحالة في flutter، وقاعدة بيانات محلية للنسخة التجريبية.'**
  String get sample4Body;

  /// No description provided for @sample5Title.
  ///
  /// In ar, this message translates to:
  /// **'الباك إند'**
  String get sample5Title;

  /// No description provided for @sample5Body.
  ///
  /// In ar, this message translates to:
  /// **'علاء هيعمل الباك إند بـfastapi و postgres مع pgvector، والتطبيق هيكلمه عن طريق api.'**
  String get sample5Body;

  /// No description provided for @sample6Title.
  ///
  /// In ar, this message translates to:
  /// **'البحث الدلالي'**
  String get sample6Title;

  /// No description provided for @sample6Body.
  ///
  /// In ar, this message translates to:
  /// **'البحث الدلالي بيدوّر بالمعنى مش بالكلمة، وده معتمد على الـembedding اللي بيتخزن في قاعدة بيانات.'**
  String get sample6Body;

  /// No description provided for @sample7Title.
  ///
  /// In ar, this message translates to:
  /// **'محاضرة الشبكات'**
  String get sample7Title;

  /// No description provided for @sample7Body.
  ///
  /// In ar, this message translates to:
  /// **'محاضرة الشبكات النهارده كانت عن TCP و UDP، لازم أراجعها قبل الامتحان.'**
  String get sample7Body;

  /// No description provided for @clearSearch.
  ///
  /// In ar, this message translates to:
  /// **'امسح البحث'**
  String get clearSearch;

  /// No description provided for @noteSavedNoText.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة اتحفظت. اكتب عنها كام سطر عشان تتربط بالباقي'**
  String get noteSavedNoText;

  /// No description provided for @noTextNoLinks.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة دي مفيهاش نص، عشان كده FIKRAH مش هتعرف تربطها بحاجة.'**
  String get noTextNoLinks;

  /// No description provided for @pdfOpenElsewhere.
  ///
  /// In ar, this message translates to:
  /// **'افتح في تطبيق تاني'**
  String get pdfOpenElsewhere;

  /// No description provided for @pdfPageOf.
  ///
  /// In ar, this message translates to:
  /// **'{page} من {total}'**
  String pdfPageOf(int page, int total);

  /// No description provided for @pdfLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفتح الملف ده. ممكن يكون بايظ أو اتحذف.'**
  String get pdfLoadFailed;

  /// No description provided for @notesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{مفيش ملاحظات} one{ملاحظة واحدة} two{ملاحظتين} few{{count} ملاحظات} many{{count} ملاحظة} other{{count} ملاحظة}}'**
  String notesCount(int count);

  /// No description provided for @linksCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{مفيش روابط} one{رابط واحد} two{رابطين} few{{count} روابط} many{{count} رابط} other{{count} رابط}}'**
  String linksCount(int count);

  /// No description provided for @minutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{دلوقتي} one{من دقيقة} two{من دقيقتين} few{من {count} دقايق} many{من {count} دقيقة} other{من {count} دقيقة}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{من {count} ساعة} one{من ساعة} two{من ساعتين} few{من {count} ساعات} many{من {count} ساعة} other{من {count} ساعة}}'**
  String hoursAgo(int count);

  /// File-format fallback when an attachment has no stored filename; this technical abbreviation is identical in both languages.
  ///
  /// In ar, this message translates to:
  /// **'PDF'**
  String get pdfFormat;

  /// No description provided for @removeAttachmentBody.
  ///
  /// In ar, this message translates to:
  /// **'الملف هيتحذف من الملاحظة لما تحفظ التغييرات، ومش هتعرف ترجّعه.'**
  String get removeAttachmentBody;

  /// No description provided for @emptyNoteBlocked.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة مينفعش تبقى فاضية. اكتب نص أو ضيف ملف.'**
  String get emptyNoteBlocked;

  /// No description provided for @pdfPasswordProtected.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده محمي بكلمة سر. تقدر تفتحه في تطبيق تاني.'**
  String get pdfPasswordProtected;

  /// No description provided for @noteLinksHeader.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get noteLinksHeader;

  /// No description provided for @linkToNote.
  ///
  /// In ar, this message translates to:
  /// **'اربط بملاحظة'**
  String get linkToNote;

  /// No description provided for @noteLinksEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش روابط للملاحظة دي. دوس «اربط بملاحظة» عشان تربطها بملاحظات تانية.'**
  String get noteLinksEmpty;

  /// No description provided for @noteLinksLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نجيب الروابط دلوقتي.'**
  String get noteLinksLoadFailed;

  /// No description provided for @linkSuggestedTag.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح'**
  String get linkSuggestedTag;

  /// No description provided for @linkRowA11y.
  ///
  /// In ar, this message translates to:
  /// **'{title}، {detail}'**
  String linkRowA11y(String title, String detail);

  /// No description provided for @suggestedLinkA11y.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح: {title}'**
  String suggestedLinkA11y(String title);

  /// No description provided for @acceptLink.
  ///
  /// In ar, this message translates to:
  /// **'اقبل'**
  String get acceptLink;

  /// No description provided for @acceptLinkA11y.
  ///
  /// In ar, this message translates to:
  /// **'اقبل الربط بـ«{title}»'**
  String acceptLinkA11y(String title);

  /// No description provided for @rejectLink.
  ///
  /// In ar, this message translates to:
  /// **'ارفض'**
  String get rejectLink;

  /// No description provided for @rejectLinkA11y.
  ///
  /// In ar, this message translates to:
  /// **'ارفض الربط بـ«{title}»'**
  String rejectLinkA11y(String title);

  /// No description provided for @linkOptionsA11y.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الرابط مع «{title}»'**
  String linkOptionsA11y(String title);

  /// No description provided for @linkOptionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الرابط'**
  String get linkOptionsTitle;

  /// No description provided for @editLinkReason.
  ///
  /// In ar, this message translates to:
  /// **'عدّل السبب'**
  String get editLinkReason;

  /// No description provided for @removeLink.
  ///
  /// In ar, this message translates to:
  /// **'شيل الرابط'**
  String get removeLink;

  /// No description provided for @removeLinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'تشيل الرابط ده؟'**
  String get removeLinkTitle;

  /// No description provided for @removeLinkBody.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظتين هيفضلوا زي ما هم، بس FIKRAH مش هتقترح تربطهم ببعض تاني.'**
  String get removeLinkBody;

  /// No description provided for @removeLinkConfirm.
  ///
  /// In ar, this message translates to:
  /// **'شيل'**
  String get removeLinkConfirm;

  /// No description provided for @linkRemoved.
  ///
  /// In ar, this message translates to:
  /// **'الرابط اتشال'**
  String get linkRemoved;

  /// No description provided for @linkUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نعدّل الرابط. جرّب تاني.'**
  String get linkUpdateFailed;

  /// No description provided for @linkReasonHint.
  ///
  /// In ar, this message translates to:
  /// **'السبب (اختياري)'**
  String get linkReasonHint;

  /// No description provided for @alreadyLinked.
  ///
  /// In ar, this message translates to:
  /// **'مربوطة أصلاً'**
  String get alreadyLinked;

  /// No description provided for @linkPickerEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظات تانية في المشروع ده تربطها بالملاحظة دي.'**
  String get linkPickerEmpty;

  /// No description provided for @linkFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نربط الملاحظات. جرّب تاني.'**
  String get linkFailed;

  /// No description provided for @linkSelected.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{اربط} one{اربط ملاحظة واحدة} two{اربط ملاحظتين} few{اربط {count} ملاحظات} many{اربط {count} ملاحظة} other{اربط {count} ملاحظة}}'**
  String linkSelected(int count);

  /// No description provided for @notesLinked.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{مفيش ملاحظات اتربطت} one{الملاحظة اتربطت بملاحظة واحدة} two{الملاحظة اتربطت بملاحظتين} few{الملاحظة اتربطت بـ{count} ملاحظات} many{الملاحظة اتربطت بـ{count} ملاحظة} other{الملاحظة اتربطت بـ{count} ملاحظة}}'**
  String notesLinked(int count);

  /// No description provided for @moveToProject.
  ///
  /// In ar, this message translates to:
  /// **'انقل لمشروع تاني'**
  String get moveToProject;

  /// No description provided for @moveNoOtherProject.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مشروع تاني تنقل له الملاحظة.'**
  String get moveNoOtherProject;

  /// No description provided for @moveNoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنقل الملاحظة لـ«{project}»؟'**
  String moveNoteTitle(String project);

  /// No description provided for @moveNoteBody.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا.'**
  String moveNoteBody(String lost);

  /// No description provided for @moveNoteBodyNoLinks.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة هتتنقل بملفاتها، ومفيش روابط هتتشال.'**
  String get moveNoteBodyNoLinks;

  /// No description provided for @moveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'انقل'**
  String get moveConfirm;

  /// No description provided for @noteMoved.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة اتنقلت لـ«{project}»'**
  String noteMoved(String project);

  /// No description provided for @moveNoteFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش ننقل الملاحظة. جرّب تاني.'**
  String get moveNoteFailed;

  /// No description provided for @suggestionsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{مفيش اقتراحات} one{اقتراح واحد} two{اقتراحين} few{{count} اقتراحات} many{{count} اقتراح} other{{count} اقتراح}}'**
  String suggestionsCount(int count);

  /// No description provided for @filesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{مفيش ملفات} one{ملف واحد} two{ملفين} few{{count} ملفات} many{{count} ملف} other{{count} ملف}}'**
  String filesCount(int count);

  /// No description provided for @listTwo.
  ///
  /// In ar, this message translates to:
  /// **'{first} و{second}'**
  String listTwo(String first, String second);

  /// No description provided for @listThree.
  ///
  /// In ar, this message translates to:
  /// **'{first} و{second} و{third}'**
  String listThree(String first, String second, String third);

  /// No description provided for @deleteProjectEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'المشروع ده فاضي، مفيهوش ملاحظات.'**
  String get deleteProjectEmptyBody;

  /// No description provided for @firstProjectNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم المشروع، مثلاً: مذاكرة'**
  String get firstProjectNameHint;

  /// No description provided for @sourceMissing.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة مابقتش في المشروع ده'**
  String get sourceMissing;

  /// No description provided for @sourceMissingA11y.
  ///
  /// In ar, this message translates to:
  /// **'مصدر {index}: ملاحظة مابقتش في المشروع ده'**
  String sourceMissingA11y(int index);

  /// No description provided for @deleteProjectEmptyChatBody.
  ///
  /// In ar, this message translates to:
  /// **'المشروع ده مفيهوش ملاحظات، بس المحادثة اللي فيه هتتحذف. مش هتعرف ترجّعها.'**
  String get deleteProjectEmptyChatBody;

  /// No description provided for @selectedCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{مفيش حاجة متختارة} one{ملاحظة واحدة متختارة} two{ملاحظتين متختارين} few{{count} ملاحظات متختارة} many{{count} ملاحظة متختارة} other{{count} ملاحظة متختارة}}'**
  String selectedCount(int count);

  /// No description provided for @closeSelection.
  ///
  /// In ar, this message translates to:
  /// **'اقفل الاختيار'**
  String get closeSelection;

  /// No description provided for @linkTogether.
  ///
  /// In ar, this message translates to:
  /// **'اربطهم ببعض'**
  String get linkTogether;

  /// No description provided for @groupAction.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة'**
  String get groupAction;

  /// No description provided for @linkTogetherLimit.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تربط لحد {max} ملاحظات ببعض. لو أكتر، حطهم في مجموعة.'**
  String linkTogetherLimit(int max);

  /// No description provided for @linkTogetherNeedsTwo.
  ///
  /// In ar, this message translates to:
  /// **'اختار ملاحظتين على الأقل عشان تربطهم.'**
  String get linkTogetherNeedsTwo;

  /// No description provided for @linksAdded.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{الملاحظات دي مربوطة ببعض أصلاً} one{اتعمل رابط جديد} two{اتعمل رابطين جداد} few{اتعمل {count} روابط جديدة} many{اتعمل {count} رابط جديد} other{اتعمل {count} رابط جديد}}'**
  String linksAdded(int count);

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

  /// No description provided for @undoFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نتراجع عن اللي اتعمل.'**
  String get undoFailed;

  /// No description provided for @chooseGroup.
  ///
  /// In ar, this message translates to:
  /// **'اختار مجموعة'**
  String get chooseGroup;

  /// No description provided for @newGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة جديدة'**
  String get newGroup;

  /// No description provided for @removeFromGroup.
  ///
  /// In ar, this message translates to:
  /// **'شيل من المجموعة'**
  String get removeFromGroup;

  /// No description provided for @noGroupsYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مجموعات في المشروع ده.'**
  String get noGroupsYet;

  /// No description provided for @subGroupA11y.
  ///
  /// In ar, this message translates to:
  /// **'{group}، جوه «{parent}»، {notes}'**
  String subGroupA11y(String group, String parent, String notes);

  /// No description provided for @notesGrouped.
  ///
  /// In ar, this message translates to:
  /// **'اتحط {notes} في «{group}»'**
  String notesGrouped(String notes, String group);

  /// No description provided for @groupRemovedFrom.
  ///
  /// In ar, this message translates to:
  /// **'اتشالت المجموعة من {notes}'**
  String groupRemovedFrom(String notes);

  /// No description provided for @groupFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نعدّل المجموعة. جرّب تاني.'**
  String get groupFailed;

  /// No description provided for @groupNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم المجموعة'**
  String get groupNameHint;

  /// No description provided for @groupColorLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللون: {color}'**
  String groupColorLabel(String color);

  /// No description provided for @colorNone.
  ///
  /// In ar, this message translates to:
  /// **'من غير لون'**
  String get colorNone;

  /// Name of a note group colour in the group colour picker (a muted blue marker); also its screen reader label.
  ///
  /// In ar, this message translates to:
  /// **'أزرق'**
  String get colorBlue;

  /// Name of a note group colour in the group colour picker (a sage green marker); also its screen reader label.
  ///
  /// In ar, this message translates to:
  /// **'أخضر'**
  String get colorGreen;

  /// Name of a note group colour in the group colour picker (a sand yellow marker); also its screen reader label.
  ///
  /// In ar, this message translates to:
  /// **'أصفر'**
  String get colorYellow;

  /// Name of a note group colour in the group colour picker (a neutral gray marker); also its screen reader label.
  ///
  /// In ar, this message translates to:
  /// **'رمادي'**
  String get colorGray;

  /// No description provided for @groupParentLabel.
  ///
  /// In ar, this message translates to:
  /// **'جوه مجموعة (اختياري)'**
  String get groupParentLabel;

  /// No description provided for @groupParentNone.
  ///
  /// In ar, this message translates to:
  /// **'ولا واحدة'**
  String get groupParentNone;

  /// No description provided for @moveNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنقل {notes} لـ«{project}»؟'**
  String moveNotesTitle(String notes, String project);

  /// No description provided for @moveNotesBody.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا.} one{الملاحظة هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا.} two{الملاحظتين هيتنقلوا بملفاتهم، وهيتشال {lost} بينهم وبين الملاحظات اللي هتفضل هنا.} few{الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا.} many{الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا.} other{الملاحظات هتتنقل بملفاتها، وهيتشال {lost} بينها وبين الملاحظات اللي هتفضل هنا.}}'**
  String moveNotesBody(int count, String lost);

  /// No description provided for @moveNotesBodyNoLinks.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.} one{الملاحظة هتتنقل بملفاتها، ومفيش روابط هتتشال.} two{الملاحظتين هيتنقلوا بملفاتهم، ومفيش روابط هتتشال.} few{الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.} many{الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.} other{الملاحظات هتتنقل بملفاتها، ومفيش روابط هتتشال.}}'**
  String moveNotesBodyNoLinks(int count);

  /// No description provided for @notesMoved.
  ///
  /// In ar, this message translates to:
  /// **'اتنقل {notes} لـ«{project}»'**
  String notesMoved(String notes, String project);

  /// No description provided for @moveNotesFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش ننقل الملاحظات. جرّب تاني.'**
  String get moveNotesFailed;

  /// No description provided for @moveNotesNoOtherProject.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مشروع تاني تنقل له الملاحظات.'**
  String get moveNotesNoOtherProject;

  /// No description provided for @deleteNotesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحذف {notes}؟'**
  String deleteNotesTitle(String notes);

  /// No description provided for @deleteNotesBody.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.} one{الملاحظة وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.} two{الملاحظتين وملفاتهم وروابطهم هيتحذفوا، ومش هتعرف ترجّعهم.} few{الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.} many{الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.} other{الملاحظات دي وملفاتها وروابطها هتتحذف، ومش هتعرف ترجّعها.}}'**
  String deleteNotesBody(int count);

  /// No description provided for @notesDeleted.
  ///
  /// In ar, this message translates to:
  /// **'اتحذف {notes}'**
  String notesDeleted(String notes);

  /// No description provided for @deleteNotesFailed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحذف كل الملاحظات. جرّب تاني.'**
  String get deleteNotesFailed;

  /// No description provided for @allGroupsFilter.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allGroupsFilter;

  /// No description provided for @groupOptionsA11y.
  ///
  /// In ar, this message translates to:
  /// **'خيارات المجموعة «{group}»'**
  String groupOptionsA11y(String group);

  /// No description provided for @groupEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة دي فاضية'**
  String get groupEmptyTitle;

  /// No description provided for @groupEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'دوس ضغطة طويلة على ملاحظة عشان تختارها، وبعدين «مجموعة».'**
  String get groupEmptyBody;

  /// No description provided for @noteGroupA11y.
  ///
  /// In ar, this message translates to:
  /// **'في مجموعة «{group}»'**
  String noteGroupA11y(String group);

  /// No description provided for @renameGroup.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الاسم'**
  String get renameGroup;

  /// No description provided for @changeGroupColor.
  ///
  /// In ar, this message translates to:
  /// **'غيّر اللون'**
  String get changeGroupColor;

  /// No description provided for @putInGroup.
  ///
  /// In ar, this message translates to:
  /// **'حطها جوه مجموعة تانية'**
  String get putInGroup;

  /// No description provided for @takeOutOfGroup.
  ///
  /// In ar, this message translates to:
  /// **'طلّعها برة «{parent}»'**
  String takeOutOfGroup(String parent);

  /// No description provided for @deleteGroup.
  ///
  /// In ar, this message translates to:
  /// **'احذف المجموعة'**
  String get deleteGroup;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحذف المجموعة «{group}»؟'**
  String deleteGroupTitle(String group);

  /// No description provided for @deleteGroupBody.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات اللي فيها هتفضل زي ما هي، بس من غير مجموعة. والمجموعات اللي جواها هتطلع برة.'**
  String get deleteGroupBody;

  /// No description provided for @groupDeleted.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة اتحذفت'**
  String get groupDeleted;

  /// No description provided for @noParentGroups.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مجموعة تانية تحطها جواها.'**
  String get noParentGroups;

  /// No description provided for @groupRuleEmptyName.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم للمجموعة.'**
  String get groupRuleEmptyName;

  /// No description provided for @groupRuleInvalidColor.
  ///
  /// In ar, this message translates to:
  /// **'اللون ده مش متاح.'**
  String get groupRuleInvalidColor;

  /// No description provided for @groupRuleMissingProject.
  ///
  /// In ar, this message translates to:
  /// **'المشروع ده مابقاش موجود.'**
  String get groupRuleMissingProject;

  /// No description provided for @groupRuleMissingGroup.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة دي مابقتش موجودة.'**
  String get groupRuleMissingGroup;

  /// No description provided for @groupRuleInvalidParent.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تحط المجموعة جوه مجموعة رئيسية بس، مش جوه مجموعة فرعية.'**
  String get groupRuleInvalidParent;

  /// No description provided for @groupRuleSelfParent.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش تحط المجموعة جوه نفسها.'**
  String get groupRuleSelfParent;

  /// No description provided for @groupRuleHasChildren.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة دي جواها مجموعات، فمينفعش تتحط جوه مجموعة تانية.'**
  String get groupRuleHasChildren;

  /// No description provided for @suggestedTopics.
  ///
  /// In ar, this message translates to:
  /// **'مواضيع مقترحة'**
  String get suggestedTopics;

  /// No description provided for @makeTopicGroup.
  ///
  /// In ar, this message translates to:
  /// **'حوّل «{topic}» لمجموعة'**
  String makeTopicGroup(String topic);

  /// No description provided for @graphGroupA11y.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة «{group}»، {notes}'**
  String graphGroupA11y(String group, String notes);

  /// No description provided for @moreTopics.
  ///
  /// In ar, this message translates to:
  /// **'باقي المواضيع'**
  String get moreTopics;

  /// No description provided for @moreTopicsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, zero{مفيش مواضيع تانية} one{موضوع تاني} two{موضوعين تانيين} few{{count} مواضيع تانية} many{{count} موضوع تاني} other{{count} موضوع تاني}}'**
  String moreTopicsCount(int count);

  /// No description provided for @graphNoteInGroup.
  ///
  /// In ar, this message translates to:
  /// **'{title}، في مجموعة «{group}»'**
  String graphNoteInGroup(String title, String group);

  /// No description provided for @graphSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'دوّر في الرسم'**
  String get graphSearchHint;

  /// No description provided for @graphSearchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتايج'**
  String get graphSearchEmpty;

  /// No description provided for @graphSearchNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get graphSearchNote;

  /// No description provided for @graphSearchLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط'**
  String get graphSearchLink;

  /// No description provided for @graphSearchGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة'**
  String get graphSearchGroup;

  /// No description provided for @graphSearchLimited.
  ///
  /// In ar, this message translates to:
  /// **'مش ظاهرة في الرسم، هنفتح الملاحظة'**
  String get graphSearchLimited;

  /// No description provided for @graphCollapseGroup.
  ///
  /// In ar, this message translates to:
  /// **'اقفل مجموعة «{group}»'**
  String graphCollapseGroup(String group);

  /// No description provided for @graphExpandGroup.
  ///
  /// In ar, this message translates to:
  /// **'افتح مجموعة «{group}»'**
  String graphExpandGroup(String group);

  /// No description provided for @graphCollapsedGroup.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة «{group}»، {notes}، مقفولة'**
  String graphCollapsedGroup(String group, String notes);

  /// No description provided for @graphMinimap.
  ///
  /// In ar, this message translates to:
  /// **'خريطة الرسم، دوس أو اسحب عشان تتحرك'**
  String get graphMinimap;

  /// No description provided for @vtTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحويل الصوت لنص'**
  String get vtTitle;

  /// No description provided for @vtExperimental.
  ///
  /// In ar, this message translates to:
  /// **'تجريبي'**
  String get vtExperimental;

  /// No description provided for @vtIntro.
  ///
  /// In ar, this message translates to:
  /// **'الموديل بيشتغل على الموبايل، ومفيش حاجة بتترفع. محتاج تحميل مرة واحدة.'**
  String get vtIntro;

  /// No description provided for @vtModel.
  ///
  /// In ar, this message translates to:
  /// **'الموديل'**
  String get vtModel;

  /// No description provided for @vtTiny.
  ///
  /// In ar, this message translates to:
  /// **'صغير جدًا'**
  String get vtTiny;

  /// No description provided for @vtBase.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get vtBase;

  /// No description provided for @vtSmall.
  ///
  /// In ar, this message translates to:
  /// **'أدق'**
  String get vtSmall;

  /// No description provided for @vtFullName.
  ///
  /// In ar, this message translates to:
  /// **'{name} · من غير ضغط'**
  String vtFullName(String name);

  /// No description provided for @vtTinyHint.
  ///
  /// In ar, this message translates to:
  /// **'أصغر وأسرع، بس ممكن يغلط أكتر.'**
  String get vtTinyHint;

  /// No description provided for @vtBaseHint.
  ///
  /// In ar, this message translates to:
  /// **'توازن بين الحجم والدقة.'**
  String get vtBaseHint;

  /// No description provided for @vtSmallHint.
  ///
  /// In ar, this message translates to:
  /// **'ممكن يكون أدق، بس أبطأ وحجمه أكبر.'**
  String get vtSmallHint;

  /// No description provided for @vtFullHint.
  ///
  /// In ar, this message translates to:
  /// **'نسخة أكبر من غير ضغط. قارن دقتها بالنسخة الصغيرة.'**
  String get vtFullHint;

  /// No description provided for @vtOnPhone.
  ///
  /// In ar, this message translates to:
  /// **'موجود على الموبايل'**
  String get vtOnPhone;

  /// No description provided for @vtNotDownloaded.
  ///
  /// In ar, this message translates to:
  /// **'لسه متحمّلش'**
  String get vtNotDownloaded;

  /// No description provided for @vtUsed.
  ///
  /// In ar, this message translates to:
  /// **'المساحة المستخدمة للموديلات: {size}'**
  String vtUsed(String size);

  /// No description provided for @vtDownload.
  ///
  /// In ar, this message translates to:
  /// **'حمّل · {size}'**
  String vtDownload(String size);

  /// No description provided for @vtDownloadTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحمّل الموديل؟'**
  String get vtDownloadTitle;

  /// No description provided for @vtDownloadBody.
  ///
  /// In ar, this message translates to:
  /// **'حجمه {size}. الأفضل تحمّله على واي فاي. التحميل مرة واحدة.'**
  String vtDownloadBody(String size);

  /// No description provided for @vtDownloadConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حمّل'**
  String get vtDownloadConfirm;

  /// No description provided for @vtDeleteModel.
  ///
  /// In ar, this message translates to:
  /// **'احذف الموديل'**
  String get vtDeleteModel;

  /// No description provided for @vtDeleteModelTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحذف الموديل؟'**
  String get vtDeleteModelTitle;

  /// No description provided for @vtDeleteModelBody.
  ///
  /// In ar, this message translates to:
  /// **'هتحتاج تحمّله تاني عشان تستخدمه.'**
  String get vtDeleteModelBody;

  /// No description provided for @vtProgress.
  ///
  /// In ar, this message translates to:
  /// **'{received} من {total}'**
  String vtProgress(String received, String total);

  /// No description provided for @vtLanguage.
  ///
  /// In ar, this message translates to:
  /// **'لغة الكلام'**
  String get vtLanguage;

  /// No description provided for @vtAutomatic.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get vtAutomatic;

  /// No description provided for @vtAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'خيارات متقدمة'**
  String get vtAdvanced;

  /// No description provided for @vtThreads.
  ///
  /// In ar, this message translates to:
  /// **'مسارات المعالجة: {count}'**
  String vtThreads(String count);

  /// No description provided for @vtFormat.
  ///
  /// In ar, this message translates to:
  /// **'صيغة التسجيل'**
  String get vtFormat;

  /// No description provided for @vtWav.
  ///
  /// In ar, this message translates to:
  /// **'صيغة الاختبار (WAV)'**
  String get vtWav;

  /// No description provided for @vtAac.
  ///
  /// In ar, this message translates to:
  /// **'صيغة التطبيق العادية (AAC)'**
  String get vtAac;

  /// No description provided for @vtClips.
  ///
  /// In ar, this message translates to:
  /// **'آخر تسجيلاتك'**
  String get vtClips;

  /// No description provided for @vtNoRecordings.
  ///
  /// In ar, this message translates to:
  /// **'سجّل كام كلمة عشان تجرّب التفريغ. آخر 10 تسجيلات بيفضلوا هنا.'**
  String get vtNoRecordings;

  /// No description provided for @vtClip.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل {number} · {format}'**
  String vtClip(String number, String format);

  /// No description provided for @vtDeleteRecordingBody.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل ده هيتحذف من التجربة.'**
  String get vtDeleteRecordingBody;

  /// No description provided for @vtTranscribe.
  ///
  /// In ar, this message translates to:
  /// **'فرّغ الصوت'**
  String get vtTranscribe;

  /// No description provided for @vtWorking.
  ///
  /// In ar, this message translates to:
  /// **'بيفرّغ الصوت…'**
  String get vtWorking;

  /// No description provided for @vtCannotCancel.
  ///
  /// In ar, this message translates to:
  /// **'بعد ما التفريغ يبدأ، استنى لحد ما يخلص.'**
  String get vtCannotCancel;

  /// No description provided for @vtWait.
  ///
  /// In ar, this message translates to:
  /// **'استنى لحد ما العملية تخلص، أو وقّف التسجيل الأول.'**
  String get vtWait;

  /// No description provided for @vtResult.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get vtResult;

  /// No description provided for @vtNoSpeech.
  ///
  /// In ar, this message translates to:
  /// **'مفيش كلام واضح في التسجيل. جرّب تاني.'**
  String get vtNoSpeech;

  /// No description provided for @vtNumbers.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام'**
  String get vtNumbers;

  /// No description provided for @vtAudioLength.
  ///
  /// In ar, this message translates to:
  /// **'مدة التسجيل: {seconds} ثانية'**
  String vtAudioLength(String seconds);

  /// No description provided for @vtWall.
  ///
  /// In ar, this message translates to:
  /// **'الوقت: {seconds} ثانية'**
  String vtWall(String seconds);

  /// No description provided for @vtFaster.
  ///
  /// In ar, this message translates to:
  /// **'أسرع من الكلام {times} مرة'**
  String vtFaster(String times);

  /// No description provided for @vtSlower.
  ///
  /// In ar, this message translates to:
  /// **'أبطأ من الكلام {times} مرة'**
  String vtSlower(String times);

  /// No description provided for @vtFactor.
  ///
  /// In ar, this message translates to:
  /// **'عامل الوقت: {factor}'**
  String vtFactor(String factor);

  /// Milliseconds, with a non-breaking space between the number and Latin unit.
  ///
  /// In ar, this message translates to:
  /// **'{ms} ms'**
  String vtMs(String ms);

  /// No description provided for @vtMemory.
  ///
  /// In ar, this message translates to:
  /// **'الذاكرة قبل: {before}، بعد: {after}'**
  String vtMemory(String before, String after);

  /// No description provided for @vtPeak.
  ///
  /// In ar, this message translates to:
  /// **'أعلى ذاكرة: {size}'**
  String vtPeak(String size);

  /// No description provided for @vtConversion.
  ///
  /// In ar, this message translates to:
  /// **'تجهيز الصوت: {ms}'**
  String vtConversion(String ms);

  /// No description provided for @vtEstimate.
  ///
  /// In ar, this message translates to:
  /// **'التفريغ وتشغيل الموديل، تقريبًا: {ms}'**
  String vtEstimate(String ms);

  /// No description provided for @vtModelLoad.
  ///
  /// In ar, this message translates to:
  /// **'بداية الموديل: {ms}'**
  String vtModelLoad(String ms);

  /// No description provided for @vtTimingHint.
  ///
  /// In ar, this message translates to:
  /// **'الوقت بيشمل تجهيز الصوت وتشغيل الموديل. الذاكرة للتطبيق كله.'**
  String get vtTimingHint;

  /// No description provided for @vtHistory.
  ///
  /// In ar, this message translates to:
  /// **'تجارب قبل كده'**
  String get vtHistory;

  /// No description provided for @vtLive.
  ///
  /// In ar, this message translates to:
  /// **'نص وإنت بتتكلم'**
  String get vtLive;

  /// No description provided for @vtLiveHint.
  ///
  /// In ar, this message translates to:
  /// **'النص بيتعدّل وإنت بتتكلم. لما توقّف، ممكن ياخد شوية وقت.'**
  String get vtLiveHint;

  /// No description provided for @vtLiveStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التفريغ المباشر'**
  String get vtLiveStart;

  /// No description provided for @vtLiveTiming.
  ///
  /// In ar, this message translates to:
  /// **'وقت التجربة المباشرة بيشمل وقت كلامك، فمش مقياس لسرعة التفريغ.'**
  String get vtLiveTiming;

  /// No description provided for @vtNetworkError.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحمّل الموديل. اتأكد من الإنترنت وجرّب تاني.'**
  String get vtNetworkError;

  /// No description provided for @vtInterruptedError.
  ///
  /// In ar, this message translates to:
  /// **'التحميل أو التسجيل اتقطع. جرّب تاني.'**
  String get vtInterruptedError;

  /// No description provided for @vtCorruptError.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرا الموديل. احذفه وحمّله تاني.'**
  String get vtCorruptError;

  /// No description provided for @vtEmptyError.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل فاضي أو مش سليم. سجّل كام كلمة وجرّب تاني.'**
  String get vtEmptyError;

  /// No description provided for @vtTranscriptionError.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفرّغ الصوت. جرّب تسجيل أقصر أو موديل أصغر.'**
  String get vtTranscriptionError;

  /// No description provided for @vtStorageError.
  ///
  /// In ar, this message translates to:
  /// **'المساحة مش كفاية. فضّي مساحة أو اختار موديل أصغر وجرّب تاني.'**
  String get vtStorageError;

  /// No description provided for @vtStorageCheckError.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نعرف المساحة الفاضية. اقفل الشاشة وافتحها وجرّب تاني.'**
  String get vtStorageCheckError;

  /// No description provided for @vtCancelled.
  ///
  /// In ar, this message translates to:
  /// **'التحميل اتلغى. تقدر تبدأه تاني.'**
  String get vtCancelled;

  /// No description provided for @vtEgyptian.
  ///
  /// In ar, this message translates to:
  /// **'مصري · تجريبي'**
  String get vtEgyptian;

  /// No description provided for @vtEgyptianHint.
  ///
  /// In ar, this message translates to:
  /// **'متدرّب على العامية المصرية والإنجليزي مع بعض.'**
  String get vtEgyptianHint;

  /// Settings section for voice features.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get vtVoiceSection;

  /// Everyday voice-to-text trial section.
  ///
  /// In ar, this message translates to:
  /// **'جرّب'**
  String get vtTry;

  /// Collapsed section containing measurement controls and technical run history.
  ///
  /// In ar, this message translates to:
  /// **'للقياس'**
  String get vtTesting;

  /// Measurement-only full-size model variants.
  ///
  /// In ar, this message translates to:
  /// **'موديلات من غير ضغط'**
  String get vtFullModels;

  /// Rescan model files, including an Egyptian model pushed by adb, from the testing area.
  ///
  /// In ar, this message translates to:
  /// **'حدّث ليستة الموديلات'**
  String get vtRefreshModels;

  /// Voice setting: transcribe only new recordings after a note save.
  ///
  /// In ar, this message translates to:
  /// **'فرّغ التسجيلات تلقائي'**
  String get trAutomatic;

  /// Hint below automatic recording transcription setting.
  ///
  /// In ar, this message translates to:
  /// **'بيشتغل على الموبايل بعد الحفظ، وممكن ياخد شوية وقت.'**
  String get trAutomaticHint;

  /// Explains why automatic transcription cannot be enabled without an installed model.
  ///
  /// In ar, this message translates to:
  /// **'حمّل موديل الأول عشان تفرّغ التسجيلات على الموبايل.'**
  String get trDownloadFirst;

  /// Toggle on a new recording draft; no inference runs before saving.
  ///
  /// In ar, this message translates to:
  /// **'فرّغه بعد الحفظ'**
  String get trAfterSave;

  /// Failure persisting or waking a saved recording transcription request.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل اتحفظ، بس مقدرناش نضيفه للتفريغ. جرّب من الملاحظة.'**
  String get trQueueFailed;

  /// Live status on a note card and its running voice attachment.
  ///
  /// In ar, this message translates to:
  /// **'بيفرّغ الصوت…'**
  String get trWorking;

  /// A saved recording is queued behind another job.
  ///
  /// In ar, this message translates to:
  /// **'مستني دوره للتفريغ…'**
  String get trQueued;

  /// Expand the collapsed transcript of a saved recording.
  ///
  /// In ar, this message translates to:
  /// **'اعرض النص كله'**
  String get trExpand;

  /// Collapse a saved recording transcript to three lines.
  ///
  /// In ar, this message translates to:
  /// **'اعرض أقل'**
  String get trCollapse;

  /// Engine label for the model that produced a saved transcript.
  ///
  /// In ar, this message translates to:
  /// **'على الموبايل · {model}'**
  String trLocalEngine(String model);

  /// Transcription failure with an action opening voice settings.
  ///
  /// In ar, this message translates to:
  /// **'الموديل مش موجود أو ملفه بايظ. حمّله من إعدادات الصوت وجرّب تاني.'**
  String get trModelMissing;

  /// Timed out waiting for the process-wide local engine lease.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ تاني أخد وقت طويل. جرّب تاني لما يخلص.'**
  String get trBusy;

  /// Unreadable or empty audio transcription failure.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرا التسجيل أو نطلع منه كلام. جرّب تشغّله الأول.'**
  String get trAudioUnreadable;

  /// Other saved recording transcription failure.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفرّغ التسجيل. جرّب تاني.'**
  String get trFailed;

  /// Saved recording transcription failure: the app closed during transcription twice (possibly a crash or the phone running out of memory), so it was not restarted automatically.
  ///
  /// In ar, this message translates to:
  /// **'التفريغ وقف مرتين لما التطبيق اتقفل. جرّب تاني أو اختار موديل أصغر.'**
  String get trInterruptedTwice;

  /// Android notification channel name, shown in the system's notification settings, for the low-importance notification while recordings are transcribed in the background.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ الصوت'**
  String get trNotificationChannel;

  /// Second line of the transcription notification: recordings still to transcribe, including the one in progress.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{فاضل تسجيل واحد} =2{فاضل تسجيلين} few{فاضل {count} تسجيلات} other{فاضل {count} تسجيل}}'**
  String trNotificationLeft(int count);

  /// One-line explanation shown just before Android asks for notification permission, the first time a recording is queued for transcription.
  ///
  /// In ar, this message translates to:
  /// **'اسمح بالإشعارات عشان تتابع التفريغ وإنت برّه التطبيق.'**
  String get trNotificationWhy;

  /// Open the model and speech settings after a missing-model failure.
  ///
  /// In ar, this message translates to:
  /// **'افتح إعدادات الصوت'**
  String get trOpenSettings;

  /// Queue a saved voice attachment for transcription.
  ///
  /// In ar, this message translates to:
  /// **'فرّغ الصوت'**
  String get trTranscribe;

  /// Redo a saved recording with the currently selected engine and model.
  ///
  /// In ar, this message translates to:
  /// **'فرّغ تاني'**
  String get trRedo;

  /// The test screen cannot start another model while the app-wide Whisper lease is held.
  ///
  /// In ar, this message translates to:
  /// **'فيه تسجيل بيتفرّغ دلوقتي. استنى لما يخلص وجرّب تاني.'**
  String get vtEngineBusy;

  /// External transcription: Engine. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'طريقة التفريغ'**
  String get vsEngine;

  /// External transcription: Local. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'على الموبايل'**
  String get vsLocal;

  /// External transcription: Add. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'ضيف خدمة'**
  String get vsAdd;

  /// External transcription: Edit. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الخدمة'**
  String get vsEdit;

  /// External transcription: Type. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'نوع الخدمة'**
  String get vsType;

  /// External transcription: OpenAi. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'خدمة متوافقة مع OpenAI'**
  String get vsOpenAi;

  /// External transcription: Name. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'اسم الخدمة'**
  String get vsName;

  /// External transcription: BaseUrl. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الخدمة'**
  String get vsBaseUrl;

  /// External transcription: Model. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'اسم الموديل'**
  String get vsModel;

  /// External transcription: Key. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'مفتاح API'**
  String get vsKey;

  /// External transcription: KeyKeep. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'سيبه فاضي لو هتستخدم نفس المفتاح.'**
  String get vsKeyKeep;

  /// External transcription: LanguageHint. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'لغة متوقعة (اختياري)'**
  String get vsLanguageHint;

  /// External transcription: LanguageHelp. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'كود زي ar أو en. سيبه فاضي عشان تستخدم لغة الكلام المختارة.'**
  String get vsLanguageHelp;

  /// External transcription: ShowKey. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'اعرض المفتاح'**
  String get vsShowKey;

  /// External transcription: HideKey. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'اخفي المفتاح'**
  String get vsHideKey;

  /// External transcription: Test. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'جرّب الاتصال'**
  String get vsTest;

  /// External transcription: Testing. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'بيجرّب الاتصال…'**
  String get vsTesting;

  /// External transcription: Connected. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال شغّال.'**
  String get vsConnected;

  /// External transcription: DeleteTitle. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'تحذف الخدمة دي؟'**
  String get vsDeleteTitle;

  /// External transcription: DeleteBody. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح هيتمسح، والتفريغ هيرجع للموبايل لو الخدمة دي متختارة.'**
  String get vsDeleteBody;

  /// External transcription: ConsentTitle. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'تبعت التسجيلات لـ«{service}»؟'**
  String vsConsentTitle(String service);

  /// External transcription: ConsentBody. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'التسجيلات هتتبعت برّه الموبايل لـ«{service}» على {host} عشان تتفرّغ. الخدمة ممكن تحتفظ بيها وتحاسبك على الاستخدام. مفيش حاجة هتتبعت غير لما توافق.'**
  String vsConsentBody(String service, String host);

  /// External transcription: ConsentConfirm. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get vsConsentConfirm;

  /// External transcription: HttpWarning. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال ده من غير تشفير. استخدمه على شبكة محلية موثوقة بس.'**
  String get vsHttpWarning;

  /// External transcription: InvalidUrl. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عنوان HTTPS، أو HTTP لموبايلك أو عنوان شبكة محلية.'**
  String get vsInvalidUrl;

  /// External transcription: InvalidFields. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'راجع الاسم والموديل وكود اللغة.'**
  String get vsInvalidFields;

  /// External transcription: KeyRequired. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مفتاح للخدمة دي الأول.'**
  String get vsKeyRequired;

  /// External transcription: SaveError. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحفظ الخدمة. جرّب تاني.'**
  String get vsSaveError;

  /// External transcription: LoadError. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرا إعدادات الخدمات. جرّب تاني.'**
  String get vsLoadError;

  /// External transcription: RemoteIntro. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'التسجيلات هتتبعت برّه الموبايل لـ«{service}» عشان تتفرّغ. استخدام الخدمة ممكن يكون بفلوس.'**
  String vsRemoteIntro(String service);

  /// External transcription: RemoteData. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك وملفاتك محفوظة على الموبايل. التسجيلات بتتبعت برّه الموبايل لـ«{service}» عشان تتفرّغ.'**
  String vsRemoteData(String service);

  /// External transcription: Via. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'عن طريق {service}'**
  String vsVia(String service);

  /// External transcription: RemovedService. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'خدمة اتحذفت'**
  String get vsRemovedService;

  /// External transcription: LiveLocal. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'النص وقت الكلام متاح على الموبايل بس. غيّر طريقة التفريغ عشان تجرّبه.'**
  String get vsLiveLocal;

  /// External transcription: RemoteAutoHint. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'التسجيلات الجديدة هتتبعت برّه الموبايل لـ«{service}» بعد الحفظ، وممكن تاخد شوية وقت.'**
  String vsRemoteAutoHint(String service);

  /// External transcription: Offline. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نوصل للخدمة. اتأكد من الاتصال وجرّب تاني.'**
  String get vsOffline;

  /// External transcription: KeyRejected. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة رفضت المفتاح. راجعه في إعدادات الصوت.'**
  String get vsKeyRejected;

  /// External transcription: RateLimited. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'وصلت لحد الاستخدام أو الرصيد خلص. راجع حسابك أو جرّب بعد شوية.'**
  String get vsRateLimited;

  /// External transcription: TooLarge. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل كبير أو طويل على الخدمة دي. جرّب تسجيل أقصر أو خدمة تانية.'**
  String get vsTooLarge;

  /// External transcription: ServiceError. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة عندها مشكلة دلوقتي. جرّب بعد شوية.'**
  String get vsServiceError;

  /// External transcription: Unexpected. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة رجّعت رد مش مفهوم. راجع عنوانها والموديل في إعدادات الصوت.'**
  String get vsUnexpected;

  /// External transcription: Timeout. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة اتأخرت في الرد. اتأكد من الاتصال وجرّب تاني.'**
  String get vsTimeout;

  /// External transcription: NeedsConsent. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'وافق إن التسجيلات تتبعت برّه الموبايل من إعدادات الصوت الأول.'**
  String get vsNeedsConsent;

  /// External transcription: Region. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get vsRegion;

  /// External transcription: Singapore. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'دولي (سنغافورة)'**
  String get vsSingapore;

  /// External transcription: Beijing. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'الصين (بكين)'**
  String get vsBeijing;

  /// External transcription: OpenAiKeyHint. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'هات المفتاح والعنوان والموديل من الخدمة اللي بتستخدمها، زي OpenAI أو Groq أو SiliconFlow.'**
  String get vsOpenAiKeyHint;

  /// External transcription: GeminiKeyHint. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'هات المفتاح من Google AI Studio.'**
  String get vsGeminiKeyHint;

  /// External transcription: ElevenKeyHint. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'هات المفتاح من إعدادات حسابك في ElevenLabs.'**
  String get vsElevenKeyHint;

  /// External transcription: QwenKeyHint. User-added services only; no upload before consent.
  ///
  /// In ar, this message translates to:
  /// **'هات مفتاح لنفس المنطقة من Alibaba Cloud Model Studio. تقدر تستخدم عنوان مساحة العمل كمان.'**
  String get vsQwenKeyHint;

  /// External transcription service type; product name, identical in both languages.
  ///
  /// In ar, this message translates to:
  /// **'Google Gemini'**
  String get vsGemini;

  /// External transcription service type; product name, identical in both languages.
  ///
  /// In ar, this message translates to:
  /// **'ElevenLabs'**
  String get vsElevenLabs;

  /// External transcription service type; product name, identical in both languages.
  ///
  /// In ar, this message translates to:
  /// **'Qwen ASR'**
  String get vsQwen;

  /// Technical trial measurements for a remote engine: network/service wall time and whole-process RSS.
  ///
  /// In ar, this message translates to:
  /// **'الوقت بيشمل رفع التسجيل وانتظار الخدمة. الذاكرة للتطبيق كله.'**
  String get vsRemoteTiming;

  /// Per-recording off policy.
  ///
  /// In ar, this message translates to:
  /// **'من غير تفريغ'**
  String get v2Off;

  /// Recommended catalog group.
  ///
  /// In ar, this message translates to:
  /// **'مقترح'**
  String get v2Recommended;

  /// Other supported models group.
  ///
  /// In ar, this message translates to:
  /// **'موديلات تانية'**
  String get v2Other;

  /// Legacy models group.
  ///
  /// In ar, this message translates to:
  /// **'قديم'**
  String get v2Legacy;

  /// Known provider shutdown warning.
  ///
  /// In ar, this message translates to:
  /// **'موديل قديم، وهيقف يوم {date}. اختار موديل مقترح لو تقدر.'**
  String v2Shutdown(String date);

  /// Legacy without a published shutdown date.
  ///
  /// In ar, this message translates to:
  /// **'موديل قديم. لسه مفيش ميعاد هيقف فيه.'**
  String get v2LegacyUnknown;

  /// Arabic suitability; no unmeasured quality claim.
  ///
  /// In ar, this message translates to:
  /// **'بيدعم العربي. جرّبه على المصري والإنجليزي مع بعض.'**
  String get v2Arabic;

  /// Generative model suitability caveat.
  ///
  /// In ar, this message translates to:
  /// **'بيفهم العربي، بس ممكن يعيد صياغة الكلام. راجع التفريغ.'**
  String get v2Generative;

  /// Catalog entry requires a different API.
  ///
  /// In ar, this message translates to:
  /// **'لسه مش مدعوم هنا'**
  String get v2Unsupported;

  /// Collapsed custom model ID field.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم موديل'**
  String get v2Custom;

  /// Explicit model discovery action.
  ///
  /// In ar, this message translates to:
  /// **'حدّث الليستة'**
  String get v2Refresh;

  /// Discovery working state.
  ///
  /// In ar, this message translates to:
  /// **'بيحدّث الليستة…'**
  String get v2Refreshing;

  /// Discovered catalog ID.
  ///
  /// In ar, this message translates to:
  /// **'متاح في حسابك'**
  String get v2Available;

  /// Discovery cache timestamp.
  ///
  /// In ar, this message translates to:
  /// **'آخر مراجعة: {time}'**
  String v2Checked(String time);

  /// Discovery privacy explanation.
  ///
  /// In ar, this message translates to:
  /// **'بيراجع الموديلات عند الخدمة برّه الموبايل، من غير ما يبعت صوت.'**
  String get v2DiscoveryHint;

  /// Qwen discovery skipped without workspace context.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الموديلات مش متاحة لـQwen هنا. استخدم الموديل المقترح أو اكتب اسم الموديل.'**
  String get v2DiscoveryQwen;

  /// Transcript correction action and editor title.
  ///
  /// In ar, this message translates to:
  /// **'عدّل التفريغ'**
  String get v2EditTranscript;

  /// Clear correction without changing machine output.
  ///
  /// In ar, this message translates to:
  /// **'رجّع التفريغ الأصلي'**
  String get v2RestoreTranscript;

  /// Redo completed while a correction exists.
  ///
  /// In ar, this message translates to:
  /// **'فيه تفريغ جديد'**
  String get v2NewTranscript;

  /// Adopt new machine output, clearing correction.
  ///
  /// In ar, this message translates to:
  /// **'استخدمه'**
  String get v2UseTranscript;

  /// Unsafe paragraph replacement outcome.
  ///
  /// In ar, this message translates to:
  /// **'التفريغ اتحفظ، بس نص الملاحظة متغيّرش عشان اتعدّل قبل كده.'**
  String get v2CopyUnchanged;

  /// Explicit append after an unsafe replacement.
  ///
  /// In ar, this message translates to:
  /// **'ضيفه للملاحظة'**
  String get v2AppendTranscript;

  /// Optimistic revision conflict; draft retained.
  ///
  /// In ar, this message translates to:
  /// **'التفريغ اتغيّر وإنت بتعدّل. ارجع وافتحه تاني.'**
  String get v2TranscriptConflict;

  /// Correction save failure.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحفظ التفريغ. جرّب تاني.'**
  String get v2TranscriptFailed;

  /// Empty correction validation.
  ///
  /// In ar, this message translates to:
  /// **'اكتب التفريغ الأول.'**
  String get v2TranscriptEmpty;

  /// Correction success feedback.
  ///
  /// In ar, this message translates to:
  /// **'التفريغ اتحفظ'**
  String get v2TranscriptSaved;

  /// Links library browse segment.
  ///
  /// In ar, this message translates to:
  /// **'تصفّح'**
  String get linksBrowse;

  /// Links library suggestions segment and section heading.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات'**
  String get linksSuggestions;

  /// Confirmed connections section heading.
  ///
  /// In ar, this message translates to:
  /// **'روابط مؤكدة'**
  String get linksConfirmed;

  /// Links library group chips heading.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات'**
  String get linksGroups;

  /// Explains that topic chips are AI suggestions.
  ///
  /// In ar, this message translates to:
  /// **'مقترحة ليك'**
  String get linksSuggestedForYou;

  /// Search the links library by note text and title.
  ///
  /// In ar, this message translates to:
  /// **'دوّر في الروابط'**
  String get searchLinksHint;

  /// Filter dock tooltip and sort sheet title.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الروابط'**
  String get linksSort;

  /// Links library sort order.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث الأول'**
  String get linksNewest;

  /// Links library sort by confirmed degree.
  ///
  /// In ar, this message translates to:
  /// **'اللي فيها روابط أكتر'**
  String get linksMostLinked;

  /// Links library sort order.
  ///
  /// In ar, this message translates to:
  /// **'الأقدم الأول'**
  String get linksOldest;

  /// Header action to open the optional graph.
  ///
  /// In ar, this message translates to:
  /// **'افتح خريطة الروابط'**
  String get linksOpenGraph;

  /// Muted fallback for an empty link reason.
  ///
  /// In ar, this message translates to:
  /// **'من غير سبب مكتوب'**
  String get linkNoReason;

  /// Empty suggestions list title.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اقتراحات دلوقتي'**
  String get linksSuggestionsEmpty;

  /// Empty suggestions list explanation.
  ///
  /// In ar, this message translates to:
  /// **'لما يبقى فيه اقتراحات جديدة، هتلاقيها هنا.'**
  String get linksSuggestionsEmptyBody;

  /// Empty confirmed library directs the user to suggestions.
  ///
  /// In ar, this message translates to:
  /// **'فيه اقتراحات مستنية رأيك. اقبل أي رابط عشان يظهر هنا.'**
  String get linksBrowseSuggestionsBody;

  /// Suggestions segment label with the number of waiting suggestions (shown only when above zero).
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات {count}'**
  String linksSuggestionsCount(int count);

  /// TalkBack label of the suggestions segment with the number of waiting suggestions.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات، {count}'**
  String linksSuggestionsCountA11y(int count);

  /// Links library empty state when a group or topic chip is selected and the search is empty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حاجة هنا لسه. جرّب مجموعة أو موضوع تاني.'**
  String get linksFilterEmptyBody;

  /// Toast after rejecting a suggested link; carries Undo.
  ///
  /// In ar, this message translates to:
  /// **'الاقتراح اترفض'**
  String get linkSuggestionRejected;

  /// Settings section heading for the speech-to-text services the user added and the button to add one.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات المتصلة'**
  String get servicesSection;

  /// Settings section explaining where notes and recordings are stored.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والبيانات'**
  String get privacySection;

  /// Notes list sort button label and sort sheet title.
  ///
  /// In ar, this message translates to:
  /// **'ترتيب الملاحظات'**
  String get notesSort;

  /// Short caption under the open-graph icon in the Links header.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get headerGraph;

  /// Short caption under the search icon in the graph header.
  ///
  /// In ar, this message translates to:
  /// **'دوّر'**
  String get headerSearch;

  /// Status label in the floating activity capsule above the tab bar while recording on another tab.
  ///
  /// In ar, this message translates to:
  /// **'بيسجّل…'**
  String get capsuleRecording;

  /// Screen reader label for the floating recording activity capsule.
  ///
  /// In ar, this message translates to:
  /// **'بيسجّل. دوس عشان تفتح التسجيل'**
  String get capsuleRecordingA11y;

  /// Status label in the floating activity capsule above the tab bar while a background transcription job runs.
  ///
  /// In ar, this message translates to:
  /// **'بيفرّغ الصوت…'**
  String get capsuleTranscribing;

  /// Screen reader label for the floating transcription activity capsule.
  ///
  /// In ar, this message translates to:
  /// **'بيفرّغ التسجيل. دوس عشان تفتح الملاحظة'**
  String get capsuleTranscribingA11y;

  /// Concept navigation and Me screen: navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// Concept navigation and Me screen: navMap.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get navMap;

  /// Concept navigation and Me screen: navMe.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get navMe;

  /// Concept navigation and Me screen: newIdea.
  ///
  /// In ar, this message translates to:
  /// **'فكرة جديدة'**
  String get newIdea;

  /// Concept navigation and Me screen: meIdeas.
  ///
  /// In ar, this message translates to:
  /// **'الأفكار'**
  String get meIdeas;

  /// Concept navigation and Me screen: meLinks.
  ///
  /// In ar, this message translates to:
  /// **'الروابط'**
  String get meLinks;

  /// Concept navigation and Me screen: meWeekDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام الأسبوع ده'**
  String get meWeekDays;

  /// Concept navigation and Me screen: meAppearanceLanguage.
  ///
  /// In ar, this message translates to:
  /// **'المظهر واللغة'**
  String get meAppearanceLanguage;

  /// Concept navigation and Me screen: meVoiceServices.
  ///
  /// In ar, this message translates to:
  /// **'الصوت والخدمات'**
  String get meVoiceServices;

  /// Small brand eyebrow label above the hero title on the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'FIKRAH'**
  String get welcomeEyebrow;

  /// Large brand title on the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'FIKRAH'**
  String get welcomeBrandTitle;

  /// Short three-word tagline on the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'اكتب. اربط. اسأل.'**
  String get welcomeTagline;

  /// Supporting line on the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'أفكارك متوصّلة ببعض. اسأل ملاحظاتك وخد إجابات من تفكيرك.'**
  String get welcomeSubtitle;

  /// Primary CTA on the welcome screen that creates the default project and opens Notes.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الكتابة'**
  String get welcomeStartWriting;

  /// Secondary CTA on the welcome screen that seeds the sample project.
  ///
  /// In ar, this message translates to:
  /// **'جرّب بمشروع تجريبي'**
  String get welcomeTrySample;

  /// Privacy footer on the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك محفوظة على جهازك · بدون حساب'**
  String get welcomeFooter;

  /// Default project name created directly from the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'أفكاري'**
  String get defaultProjectName;

  /// Filter chip and note-card badge label for voice notes.
  ///
  /// In ar, this message translates to:
  /// **'صوت'**
  String get filterVoice;

  /// Filter chip label for notes with PDF or image attachments.
  ///
  /// In ar, this message translates to:
  /// **'ملفات'**
  String get filterFiles;

  /// Short PDF badge label on note cards.
  ///
  /// In ar, this message translates to:
  /// **'PDF'**
  String get badgePdf;

  /// Empty state title when a type filter (voice/files) matches no notes.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظات هنا'**
  String get filterEmptyTitle;

  /// Empty state body when a type filter matches no notes.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظات بالفلتر ده لسه.'**
  String get filterEmptyBody;

  /// Action strip message when one or more notes failed analysis.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{ملاحظة فشل تحليلها} two{ملاحظتين فشل تحليلهم} few{{count} ملاحظات فشل تحليلها} other{{count} ملاحظة فشل تحليلها}}'**
  String actionStripFailed(int count);

  /// Short retry label on the failed-analysis action strip.
  ///
  /// In ar, this message translates to:
  /// **'أعد المحاولة'**
  String get actionStripRetry;

  /// Action strip message when new link suggestions are waiting.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{رابط مقترح جديد} two{رابطين مقترحين جداد} few{{count} روابط مقترحة جديدة} other{{count} رابط مقترح جديد}}'**
  String actionStripSuggestions(int count);

  /// Action strip message when note rewrites are waiting for review.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{صياغة مستنية رأيك} two{صياغتين مستنيين رأيك} few{{count} صياغات مستنية رأيك} other{{count} صياغة مستنية رأيك}}'**
  String actionStripRewrites(int count);

  /// Screen reader label for dismissing the notes action strip for the current session.
  ///
  /// In ar, this message translates to:
  /// **'اخفي التنبيه'**
  String get actionStripDismiss;

  /// Chip showing how many distinct days in the rolling 7-day window have at least one note.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{يوم واحد الأسبوع ده} two{يومين الأسبوع ده} few{{count} أيام الأسبوع ده} other{{count} يوم الأسبوع ده}}'**
  String activeDaysThisWeek(int count);

  /// Links Map: linksMap
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get linksMap;

  /// Links Map: mapOthers
  ///
  /// In ar, this message translates to:
  /// **'تانيين'**
  String get mapOthers;

  /// Links Map: mapShowMore
  ///
  /// In ar, this message translates to:
  /// **'اعرض أكتر'**
  String get mapShowMore;

  /// Links Map: mapOpen
  ///
  /// In ar, this message translates to:
  /// **'افتح'**
  String get mapOpen;

  /// Links Map: mapNotes
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش ملاحظات} =1{ملاحظة واحدة} =2{ملاحظتين} few{{count} ملاحظات} many{{count} ملاحظة} other{{count} ملاحظة}}'**
  String mapNotes(int count);

  /// Links Map: mapConnections
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{مفيش روابط} =1{رابط واحد} =2{رابطين} few{{count} روابط} many{{count} رابط} other{{count} رابط}}'**
  String mapConnections(int count);

  /// Links Map: mapCanvasSummary
  ///
  /// In ar, this message translates to:
  /// **'خريطة الملاحظات، الإجمالي: {total}، مش ظاهر: {omitted}'**
  String mapCanvasSummary(int total, int omitted);

  /// Links Map: mapTotals
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات: {total} · روابط: {confirmed} · اقتراحات: {suggestions} · مش ظاهر: {omitted}'**
  String mapTotals(int total, int confirmed, int suggestions, int omitted);

  /// Hint for the unshrunk Map world; panning preserves readable text and touch targets.
  ///
  /// In ar, this message translates to:
  /// **'اسحب عشان تشوف باقي الخريطة'**
  String get mapPanHint;

  /// No description provided for @productMyAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get productMyAccount;

  /// No description provided for @productThisIsAVolatileDevelopmentWorkspaceExistingLocal.
  ///
  /// In ar, this message translates to:
  /// **'دي مساحة تطوير مؤقتة. ملاحظاتك المحلية القديمة موجودة بشكل منفصل في وضع الديمو القديم.'**
  String get productThisIsAVolatileDevelopmentWorkspaceExistingLocal;

  /// No description provided for @productSignOutLocally.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل خروج محلي'**
  String get productSignOutLocally;

  /// No description provided for @productProductionSetupPending.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الإنتاج لسه معلّقة'**
  String get productProductionSetupPending;

  /// No description provided for @productPasswordPolicyEmailActionRoutingAndGooglePlatform.
  ///
  /// In ar, this message translates to:
  /// **'سياسة كلمة المرور وروابط البريد وإعدادات Google محتاجة اتفاق. مفيش استخدام لبيانات دخول حقيقية أو إرسال بريد هنا.'**
  String get productPasswordPolicyEmailActionRoutingAndGooglePlatform;

  /// No description provided for @productYourSessionExpiredSignInAgain.
  ///
  /// In ar, this message translates to:
  /// **'الجلسة انتهت. سجّل دخول تاني.'**
  String get productYourSessionExpiredSignInAgain;

  /// No description provided for @productPreviewAccountJourneys.
  ///
  /// In ar, this message translates to:
  /// **'تجربة رحلات الحساب'**
  String get productPreviewAccountJourneys;

  /// No description provided for @productUseFixtureAddressesOnlyRegistrationVerificationAndRecovery.
  ///
  /// In ar, this message translates to:
  /// **'استخدم عناوين التطوير فقط. التسجيل والتفعيل والاسترجاع بيعرضوا حالات تجريبية، بدون إرسال بريد أو إنشاء حساب حقيقي.'**
  String get productUseFixtureAddressesOnlyRegistrationVerificationAndRecovery;

  /// No description provided for @productEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get productEmail;

  /// No description provided for @productNewPasswordPreview.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور جديدة (تجربة)'**
  String get productNewPasswordPreview;

  /// No description provided for @productPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get productPassword;

  /// No description provided for @productFixtureActionToken.
  ///
  /// In ar, this message translates to:
  /// **'رمز إجراء تجريبي'**
  String get productFixtureActionToken;

  /// No description provided for @productAwaitingVerificationUseFixtureVerifyToPreviewSuccess.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار التفعيل. استخدم fixture-verify لتجربة النجاح. لم يتم إرسال بريد.'**
  String get productAwaitingVerificationUseFixtureVerifyToPreviewSuccess;

  /// No description provided for @productPreviewVerification.
  ///
  /// In ar, this message translates to:
  /// **'تجربة التفعيل'**
  String get productPreviewVerification;

  /// No description provided for @productPreviewResendRequest.
  ///
  /// In ar, this message translates to:
  /// **'تجربة طلب إعادة الإرسال'**
  String get productPreviewResendRequest;

  /// No description provided for @productGenericRecoveryAcknowledgmentFixtureNoDeliveryIsClaimed.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد عام لطلب الاسترجاع (تجربة). بدون ادعاء وصول رسالة.'**
  String get productGenericRecoveryAcknowledgmentFixtureNoDeliveryIsClaimed;

  /// No description provided for @productPreviewResetForm.
  ///
  /// In ar, this message translates to:
  /// **'تجربة نموذج إعادة التعيين'**
  String get productPreviewResetForm;

  /// No description provided for @productUseFixtureResetTheRealPasswordPolicyIs.
  ///
  /// In ar, this message translates to:
  /// **'استخدم fixture-reset. سياسة كلمة المرور الحقيقية لم تُحسم بعد.'**
  String get productUseFixtureResetTheRealPasswordPolicyIs;

  /// No description provided for @productPreviewPasswordReset.
  ///
  /// In ar, this message translates to:
  /// **'تجربة إعادة التعيين'**
  String get productPreviewPasswordReset;

  /// No description provided for @productPreviewRecoveryRequest.
  ///
  /// In ar, this message translates to:
  /// **'تجربة طلب الاسترجاع'**
  String get productPreviewRecoveryRequest;

  /// No description provided for @productPreviewRegistration.
  ///
  /// In ar, this message translates to:
  /// **'تجربة التسجيل'**
  String get productPreviewRegistration;

  /// No description provided for @productOpenFixtureSession.
  ///
  /// In ar, this message translates to:
  /// **'فتح جلسة تجريبية'**
  String get productOpenFixtureSession;

  /// No description provided for @productBackToSignIn.
  ///
  /// In ar, this message translates to:
  /// **'رجوع للدخول'**
  String get productBackToSignIn;

  /// No description provided for @productPreviewNewAccount.
  ///
  /// In ar, this message translates to:
  /// **'تجربة حساب جديد'**
  String get productPreviewNewAccount;

  /// No description provided for @productForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور'**
  String get productForgotPassword;

  /// No description provided for @productGoogleSignInWaitingForApprovedPlatformConfiguration.
  ///
  /// In ar, this message translates to:
  /// **'دخول Google: في انتظار إعدادات المنصة المعتمدة. مفيش طلب بيتم إرساله لـ Google.'**
  String get productGoogleSignInWaitingForApprovedPlatformConfiguration;

  /// No description provided for @productPreviewSampleWorkspace.
  ///
  /// In ar, this message translates to:
  /// **'تجربة مساحة بملاحظات جاهزة'**
  String get productPreviewSampleWorkspace;

  /// No description provided for @productPreviewSeparateEmptyAccount.
  ///
  /// In ar, this message translates to:
  /// **'تجربة حساب منفصل وفارغ'**
  String get productPreviewSeparateEmptyAccount;

  /// No description provided for @productVerificationPreviewCompleteSignInSeparately.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت تجربة التفعيل. سجّل الدخول بشكل منفصل.'**
  String get productVerificationPreviewCompleteSignInSeparately;

  /// No description provided for @productResetPreviewCompleteSignInAgain.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت تجربة إعادة التعيين. سجّل دخول تاني.'**
  String get productResetPreviewCompleteSignInAgain;

  /// No description provided for @productLocalPrivateStateClearedServerRevocationIsNot.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح الحالة الخاصة محليًا. إلغاء جلسة الخادم غير مؤكد.'**
  String get productLocalPrivateStateClearedServerRevocationIsNot;

  /// No description provided for @productDevelopmentAcknowledgmentOnlyNoRealDeliveryOrAccount.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تجريبي فقط؛ لم يتم إرسال بريد أو تنفيذ إجراء على حساب حقيقي.'**
  String get productDevelopmentAcknowledgmentOnlyNoRealDeliveryOrAccount;

  /// No description provided for @productCaptureAThought.
  ///
  /// In ar, this message translates to:
  /// **'سجّل فكرة'**
  String get productCaptureAThought;

  /// No description provided for @productCloseComposer.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق الكتابة'**
  String get productCloseComposer;

  /// No description provided for @productASaveAttemptIsUnresolvedRetryItsOriginal.
  ///
  /// In ar, this message translates to:
  /// **'فيه محاولة حفظ لم تتأكد. أعدها بنفس المشروع والمحتوى قبل تغيير المسودة.'**
  String get productASaveAttemptIsUnresolvedRetryItsOriginal;

  /// No description provided for @productReturnToThePendingAttemptSProject.
  ///
  /// In ar, this message translates to:
  /// **'ارجع لمشروع محاولة الحفظ'**
  String get productReturnToThePendingAttemptSProject;

  /// No description provided for @productTitleOptional.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (اختياري)'**
  String get productTitleOptional;

  /// No description provided for @productYourThought.
  ///
  /// In ar, this message translates to:
  /// **'فكرتك'**
  String get productYourThought;

  /// No description provided for @productReconcileTheSameSaveAttempt.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة نفس محاولة الحفظ'**
  String get productReconcileTheSameSaveAttempt;

  /// No description provided for @productSaveTextNote.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ملاحظة نصية'**
  String get productSaveTextNote;

  /// No description provided for @productSavingAndProcessingAreSeparateAMissingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحفظ منفصل عن المعالجة. العنوان الناقص بيفضل مؤقت لحد ما نتيجة الباك إند ترجع بعنوان.'**
  String get productSavingAndProcessingAreSeparateAMissingTitle;

  /// No description provided for @productVoiceReviewedText.
  ///
  /// In ar, this message translates to:
  /// **'الصوت ← نص تراجعه'**
  String get productVoiceReviewedText;

  /// No description provided for @productAutomaticStopAt60SecondsTranscriptionDoesNot.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل بيقف تلقائيًا بعد 60 ثانية. التفريغ مش بيحفظ ملاحظة.'**
  String get productAutomaticStopAt60SecondsTranscriptionDoesNot;

  /// No description provided for @productStopRecording.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التسجيل'**
  String get productStopRecording;

  /// No description provided for @productRecordVoice.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل صوت'**
  String get productRecordVoice;

  /// No description provided for @productPreviewTranscription.
  ///
  /// In ar, this message translates to:
  /// **'تجربة التفريغ النصي'**
  String get productPreviewTranscription;

  /// No description provided for @productReviewAndEditTranscript.
  ///
  /// In ar, this message translates to:
  /// **'راجع وعدّل النص المفرّغ'**
  String get productReviewAndEditTranscript;

  /// No description provided for @productUseThisTextInTheDraft.
  ///
  /// In ar, this message translates to:
  /// **'استخدم النص في المسودة'**
  String get productUseThisTextInTheDraft;

  /// No description provided for @productThenPressSaveTextNoteWhenReady.
  ///
  /// In ar, this message translates to:
  /// **'بعد المراجعة اضغط حفظ ملاحظة نصية.'**
  String get productThenPressSaveTextNoteWhenReady;

  /// No description provided for @productDiscardRecording.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التسجيل'**
  String get productDiscardRecording;

  /// No description provided for @productLocalPDFs.
  ///
  /// In ar, this message translates to:
  /// **'ملفات PDF محلية'**
  String get productLocalPDFs;

  /// No description provided for @productPDFsStayOnThisDeviceTheyAreNot.
  ///
  /// In ar, this message translates to:
  /// **'ملفات PDF بتفضل على الجهاز. مش بيتم رفعها أو استخراج نصها أو ربطها بملاحظة على الخادم. احفظ النص بشكل منفصل.'**
  String get productPDFsStayOnThisDeviceTheyAreNot;

  /// No description provided for @productChooseLocalPDF.
  ///
  /// In ar, this message translates to:
  /// **'اختيار PDF محلي'**
  String get productChooseLocalPDF;

  /// No description provided for @productUntitledProcessing.
  ///
  /// In ar, this message translates to:
  /// **'بدون عنوان / قيد المعالجة'**
  String get productUntitledProcessing;

  /// No description provided for @productSavedQueued.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة · في الانتظار'**
  String get productSavedQueued;

  /// No description provided for @productSavedProcessing.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة · قيد المعالجة'**
  String get productSavedProcessing;

  /// No description provided for @productProcessingCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت المعالجة'**
  String get productProcessingCompleted;

  /// No description provided for @productSavedProcessingFailed.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة · فشلت المعالجة'**
  String get productSavedProcessingFailed;

  /// No description provided for @productSavedStatusUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'محفوظة · الحالة غير معروفة'**
  String get productSavedStatusUnavailable;

  /// No description provided for @productDevelopmentFixturesMemoryOnlyNoLiveBackend.
  ///
  /// In ar, this message translates to:
  /// **'بيانات تطوير · في الذاكرة فقط · بدون اتصال بالباك إند'**
  String get productDevelopmentFixturesMemoryOnlyNoLiveBackend;

  /// No description provided for @productMicrophonePermissionIsRequiredEnableItInDevice.
  ///
  /// In ar, this message translates to:
  /// **'اسمح باستخدام الميكروفون من إعدادات الجهاز ثم حاول تاني.'**
  String get productMicrophonePermissionIsRequiredEnableItInDevice;

  /// No description provided for @productCheckTheInputYourDraftHasBeenKept.
  ///
  /// In ar, this message translates to:
  /// **'راجع البيانات. المسودة محفوظة كما هي.'**
  String get productCheckTheInputYourDraftHasBeenKept;

  /// No description provided for @productSignInAgainOrCheckYourCredentials.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخول تاني أو راجع بيانات الدخول.'**
  String get productSignInAgainOrCheckYourCredentials;

  /// No description provided for @productVerifyYourEmailBeforeSigningIn.
  ///
  /// In ar, this message translates to:
  /// **'فعّل بريدك الإلكتروني قبل الدخول.'**
  String get productVerifyYourEmailBeforeSigningIn;

  /// No description provided for @productThisItemIsNoLongerAvailableReloadThe.
  ///
  /// In ar, this message translates to:
  /// **'العنصر ده مش متاح. حدّث المشروع الحالي.'**
  String get productThisItemIsNoLongerAvailableReloadThe;

  /// No description provided for @productTheStateChangedReloadAndReviewBeforeActing.
  ///
  /// In ar, this message translates to:
  /// **'الحالة اتغيرت. حدّث وراجعها قبل تنفيذ الإجراء تاني.'**
  String get productTheStateChangedReloadAndReviewBeforeActing;

  /// No description provided for @productThisCreationAttemptRefersToADeletedNote.
  ///
  /// In ar, this message translates to:
  /// **'محاولة الحفظ دي تخص ملاحظة اتحذفت، ومش هتتعمل تلقائيًا من جديد.'**
  String get productThisCreationAttemptRefersToADeletedNote;

  /// No description provided for @productTheInputIsTooLargeReduceItBefore.
  ///
  /// In ar, this message translates to:
  /// **'حجم المدخل كبير. قلّله قبل المحاولة.'**
  String get productTheInputIsTooLargeReduceItBefore;

  /// No description provided for @productThisRecordingFormatIsNotSupported.
  ///
  /// In ar, this message translates to:
  /// **'صيغة التسجيل دي غير مدعومة.'**
  String get productThisRecordingFormatIsNotSupported;

  /// No description provided for @productRequestLimitReachedWaitBeforeTryingAgain.
  ///
  /// In ar, this message translates to:
  /// **'وصلت لحد الطلبات. استنى قبل المحاولة.'**
  String get productRequestLimitReachedWaitBeforeTryingAgain;

  /// No description provided for @productThisServiceIsUnavailableYourInputHasBeen.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة مش متاحة حاليًا. البيانات اللي كتبتها موجودة.'**
  String get productThisServiceIsUnavailableYourInputHasBeen;

  /// No description provided for @productTheResultIsUncertainReconcileBeforeTryingAgain.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة العملية غير مؤكدة. راجع الحالة قبل المحاولة تاني.'**
  String get productTheResultIsUncertainReconcileBeforeTryingAgain;

  /// No description provided for @productRetryAfterSeconds.
  ///
  /// In ar, this message translates to:
  /// **'حاول بعد {seconds} ثانية.'**
  String productRetryAfterSeconds(int seconds);

  /// No description provided for @productReloadRetry.
  ///
  /// In ar, this message translates to:
  /// **'تحديث / إعادة المحاولة'**
  String get productReloadRetry;

  /// No description provided for @productBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get productBack;

  /// No description provided for @productRenameProject.
  ///
  /// In ar, this message translates to:
  /// **'تعديل اسم المشروع'**
  String get productRenameProject;

  /// No description provided for @productNewProject.
  ///
  /// In ar, this message translates to:
  /// **'مشروع جديد'**
  String get productNewProject;

  /// No description provided for @productName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get productName;

  /// No description provided for @productCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get productCancel;

  /// No description provided for @productSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get productSave;

  /// No description provided for @productProject.
  ///
  /// In ar, this message translates to:
  /// **'المشروع'**
  String get productProject;

  /// No description provided for @productRename.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الاسم'**
  String get productRename;

  /// No description provided for @productDeleteProject.
  ///
  /// In ar, this message translates to:
  /// **'حذف المشروع؟'**
  String get productDeleteProject;

  /// No description provided for @productThisPermanentlyDeletesItsNotesConversationsAndKnowledge.
  ///
  /// In ar, this message translates to:
  /// **'ده هيحذف ملاحظاته ومحادثاته وعلاقاته المعرفية نهائيًا.'**
  String get productThisPermanentlyDeletesItsNotesConversationsAndKnowledge;

  /// No description provided for @productDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get productDelete;

  /// No description provided for @productDeleteProject2.
  ///
  /// In ar, this message translates to:
  /// **'حذف المشروع'**
  String get productDeleteProject2;

  /// No description provided for @productNotes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get productNotes;

  /// No description provided for @productReload.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get productReload;

  /// No description provided for @productSearchThisProject.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في المشروع ده'**
  String get productSearchThisProject;

  /// No description provided for @productSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get productSearch;

  /// No description provided for @productDevelopmentSearchUsesLiteralFixtureMatchingNotSemantic.
  ///
  /// In ar, this message translates to:
  /// **'بحث التطوير بيطابق النصوص التجريبية حرفيًا، مش بحث دلالي.'**
  String get productDevelopmentSearchUsesLiteralFixtureMatchingNotSemantic;

  /// No description provided for @productStillProcessingReloadLaterTheSavedNoteIs.
  ///
  /// In ar, this message translates to:
  /// **'لسه قيد المعالجة. حدّث لاحقًا؛ الملاحظة محفوظة.'**
  String get productStillProcessingReloadLaterTheSavedNoteIs;

  /// No description provided for @productSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'نتائج البحث'**
  String get productSearchResults;

  /// No description provided for @productNoResultsInThisProject.
  ///
  /// In ar, this message translates to:
  /// **'مفيش نتائج في المشروع ده.'**
  String get productNoResultsInThisProject;

  /// No description provided for @productShowAllSavedNotes.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل الملاحظات المحفوظة'**
  String get productShowAllSavedNotes;

  /// No description provided for @productNoNotesYet.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظات لسه'**
  String get productNoNotesYet;

  /// No description provided for @productNote.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة'**
  String get productNote;

  /// No description provided for @productTheCurrentProposalWasReloadedReviewItBefore.
  ///
  /// In ar, this message translates to:
  /// **'تم تحميل الاقتراح الحالي. راجعه قبل اختيار إجراء جديد.'**
  String get productTheCurrentProposalWasReloadedReviewItBefore;

  /// No description provided for @productThisNoteIsUnavailableInTheSelectedProject.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة مش متاحة في المشروع الحالي.'**
  String get productThisNoteIsUnavailableInTheSelectedProject;

  /// No description provided for @productSavedContent.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى المحفوظ'**
  String get productSavedContent;

  /// No description provided for @productSaveEdit.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديل'**
  String get productSaveEdit;

  /// No description provided for @productCancelEditing.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التعديل'**
  String get productCancelEditing;

  /// No description provided for @productEditNote.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملاحظة'**
  String get productEditNote;

  /// No description provided for @productRefinementProposal.
  ///
  /// In ar, this message translates to:
  /// **'اقتراح تحسين'**
  String get productRefinementProposal;

  /// No description provided for @productAcceptAndReplaceSavedContent.
  ///
  /// In ar, this message translates to:
  /// **'قبول واستبدال المحتوى المحفوظ'**
  String get productAcceptAndReplaceSavedContent;

  /// No description provided for @productReplaceSavedContent.
  ///
  /// In ar, this message translates to:
  /// **'استبدال المحتوى المحفوظ؟'**
  String get productReplaceSavedContent;

  /// No description provided for @productAcceptancePermanentlyReplacesTheContentAndStartsProcessing.
  ///
  /// In ar, this message translates to:
  /// **'القبول بيستبدل المحتوى نهائيًا وبيبدأ المعالجة من جديد. مفيش تراجع أو سجل نسخ.'**
  String get productAcceptancePermanentlyReplacesTheContentAndStartsProcessing;

  /// No description provided for @productAccept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get productAccept;

  /// No description provided for @productRejectProposal.
  ///
  /// In ar, this message translates to:
  /// **'رفض الاقتراح'**
  String get productRejectProposal;

  /// No description provided for @productRequestAnotherProposal.
  ///
  /// In ar, this message translates to:
  /// **'طلب اقتراح جديد'**
  String get productRequestAnotherProposal;

  /// No description provided for @productRetryReprocess.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المعالجة'**
  String get productRetryReprocess;

  /// No description provided for @productReloadStatus.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الحالة'**
  String get productReloadStatus;

  /// No description provided for @productRelatedNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات مرتبطة'**
  String get productRelatedNotes;

  /// No description provided for @productNoCurrentRelationships.
  ///
  /// In ar, this message translates to:
  /// **'مفيش علاقات حالية.'**
  String get productNoCurrentRelationships;

  /// No description provided for @productDeleteNote.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظة'**
  String get productDeleteNote;

  /// No description provided for @productDeleteNote2.
  ///
  /// In ar, this message translates to:
  /// **'حذف الملاحظة؟'**
  String get productDeleteNote2;

  /// No description provided for @productItsRelationshipsAndSourceCitationsWillAlsoBe.
  ///
  /// In ar, this message translates to:
  /// **'العلاقات والإشارات للملاحظة كمصدر هتتحذف كمان.'**
  String get productItsRelationshipsAndSourceCitationsWillAlsoBe;

  /// No description provided for @productKnowledgeMap.
  ///
  /// In ar, this message translates to:
  /// **'خريطة المعرفة'**
  String get productKnowledgeMap;

  /// No description provided for @productReloadMap.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الخريطة'**
  String get productReloadMap;

  /// No description provided for @productEveryNodeIsANoteLinesShowSupplied.
  ///
  /// In ar, this message translates to:
  /// **'كل نقطة ملاحظة. الخطوط بتعرض العلاقات الواردة فقط. اسحب الملاحظات أو استخدم إصبعين للتكبير.'**
  String get productEveryNodeIsANoteLinesShowSupplied;

  /// No description provided for @productNoCompletedNotesInThisProjectYet.
  ///
  /// In ar, this message translates to:
  /// **'مفيش ملاحظات مكتملة المعالجة في المشروع لسه.'**
  String get productNoCompletedNotesInThisProjectYet;

  /// No description provided for @productZoomIn.
  ///
  /// In ar, this message translates to:
  /// **'تكبير'**
  String get productZoomIn;

  /// No description provided for @productResetView.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط العرض'**
  String get productResetView;

  /// No description provided for @productGraphCounts.
  ///
  /// In ar, this message translates to:
  /// **'{notes, plural, =0{مفيش ملاحظات} =1{ملاحظة واحدة} =2{ملاحظتان} few{{notes} ملاحظات} many{{notes} ملاحظة} other{{notes} ملاحظة}} · {relationships, plural, =0{مفيش علاقات} =1{علاقة واحدة} =2{علاقتان} few{{relationships} علاقات} many{{relationships} علاقة} other{{relationships} علاقة}}'**
  String productGraphCounts(int notes, int relationships);

  /// No description provided for @productAsk.
  ///
  /// In ar, this message translates to:
  /// **'اسأل'**
  String get productAsk;

  /// No description provided for @productNewConversation.
  ///
  /// In ar, this message translates to:
  /// **'محادثة جديدة'**
  String get productNewConversation;

  /// No description provided for @productReloadHistoryList.
  ///
  /// In ar, this message translates to:
  /// **'تحديث قائمة المحادثات'**
  String get productReloadHistoryList;

  /// No description provided for @productConversationHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل المحادثات'**
  String get productConversationHistory;

  /// No description provided for @productStartAConversationOrOpenItsHistoryConversations.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ محادثة أو افتح سجلها. كل محادثة بتفضل داخل المشروع المختار.'**
  String get productStartAConversationOrOpenItsHistoryConversations;

  /// No description provided for @productYou.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get productYou;

  /// No description provided for @productNotSupportedByThisProjectSKnowledge.
  ///
  /// In ar, this message translates to:
  /// **'غير مدعوم بمعرفة المشروع ده'**
  String get productNotSupportedByThisProjectSKnowledge;

  /// No description provided for @productProvisionalNotConfirmedSaved.
  ///
  /// In ar, this message translates to:
  /// **'عرض مؤقت · لم يتأكد حفظه'**
  String get productProvisionalNotConfirmedSaved;

  /// No description provided for @productStopWaiting.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الانتظار'**
  String get productStopWaiting;

  /// No description provided for @productReloadHistoryBeforeSendingAgain.
  ///
  /// In ar, this message translates to:
  /// **'حمّل السجل قبل الإرسال تاني'**
  String get productReloadHistoryBeforeSendingAgain;

  /// No description provided for @productHistoryReloadedReviewItBeforeDeliberatelySendingYour.
  ///
  /// In ar, this message translates to:
  /// **'السجل اتحدّث. راجعه قبل ما تختار إرسال المسودة الموجودة تاني.'**
  String get productHistoryReloadedReviewItBeforeDeliberatelySendingYour;

  /// No description provided for @productAskThisProject.
  ///
  /// In ar, this message translates to:
  /// **'اسأل المشروع ده'**
  String get productAskThisProject;

  /// No description provided for @productSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get productSend;

  /// No description provided for @productDeleteConversation.
  ///
  /// In ar, this message translates to:
  /// **'حذف المحادثة؟'**
  String get productDeleteConversation;

  /// No description provided for @productThisDeletesTheConversationAndMessagesWhileKeeping.
  ///
  /// In ar, this message translates to:
  /// **'ده بيحذف المحادثة ورسائلها وبيحتفظ بالملاحظات.'**
  String get productThisDeletesTheConversationAndMessagesWhileKeeping;

  /// No description provided for @productDeleteConversation2.
  ///
  /// In ar, this message translates to:
  /// **'حذف المحادثة'**
  String get productDeleteConversation2;

  /// No description provided for @productReviewFailedSave.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة المسودة لمحاولة حفظ جديدة'**
  String get productReviewFailedSave;

  /// No description provided for @productNewIntentionalSaveExplanation.
  ///
  /// In ar, this message translates to:
  /// **'المحاولة السابقة اترفضت أو تخص ملاحظة اتحذفت. هنحتفظ بالمسودة، ومحاولة جديدة هتبدأ فقط لما تختار الحفظ تاني.'**
  String get productNewIntentionalSaveExplanation;

  /// No description provided for @uiSignUpEmail.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب بالبريد الإلكتروني'**
  String get uiSignUpEmail;

  /// No description provided for @uiLogIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get uiLogIn;

  /// No description provided for @uiContinueGoogle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باستخدام Google'**
  String get uiContinueGoogle;

  /// No description provided for @uiCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حسابك'**
  String get uiCreateAccount;

  /// No description provided for @uiWelcomeBack.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا بعودتك'**
  String get uiWelcomeBack;

  /// No description provided for @uiShowPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get uiShowPassword;

  /// No description provided for @uiHidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get uiHidePassword;

  /// No description provided for @uiNewIdea.
  ///
  /// In ar, this message translates to:
  /// **'فكرة جديدة'**
  String get uiNewIdea;

  /// No description provided for @uiVoice.
  ///
  /// In ar, this message translates to:
  /// **'صوت'**
  String get uiVoice;

  /// No description provided for @uiFile.
  ///
  /// In ar, this message translates to:
  /// **'ملف'**
  String get uiFile;

  /// No description provided for @uiProfile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get uiProfile;

  /// No description provided for @uiSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get uiSettings;

  /// No description provided for @uiIdeas.
  ///
  /// In ar, this message translates to:
  /// **'الأفكار'**
  String get uiIdeas;

  /// No description provided for @uiAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get uiAll;

  /// No description provided for @uiToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get uiToday;

  /// No description provided for @uiEarlier.
  ///
  /// In ar, this message translates to:
  /// **'سابقًا'**
  String get uiEarlier;

  /// No description provided for @uiIdeaMap.
  ///
  /// In ar, this message translates to:
  /// **'خريطة الأفكار'**
  String get uiIdeaMap;

  /// No description provided for @uiSearchIdeas.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في أفكارك'**
  String get uiSearchIdeas;

  /// No description provided for @uiMapHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب الأفكار، وكبّر بإصبعين، واضغط للفتح'**
  String get uiMapHint;

  /// No description provided for @uiZoomOut.
  ///
  /// In ar, this message translates to:
  /// **'تصغير'**
  String get uiZoomOut;

  /// No description provided for @uiFitIdeas.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كل الأفكار'**
  String get uiFitIdeas;

  /// No description provided for @uiOpenNote.
  ///
  /// In ar, this message translates to:
  /// **'فتح الملاحظة'**
  String get uiOpenNote;

  /// No description provided for @uiConnectedIdeas.
  ///
  /// In ar, this message translates to:
  /// **'أفكار مرتبطة'**
  String get uiConnectedIdeas;

  /// No description provided for @uiUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح بعد'**
  String get uiUnavailable;

  /// No description provided for @uiPreviewNotice.
  ///
  /// In ar, this message translates to:
  /// **'معاينة تطوير · بيانات مؤقتة'**
  String get uiPreviewNotice;

  /// No description provided for @uiGoogleUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول عبر Google غير متاح في هذه المعاينة.'**
  String get uiGoogleUnavailable;

  /// No description provided for @uiWelcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أفكارك مترابطة. اسأل ملاحظاتك عن أي شيء.'**
  String get uiWelcomeSubtitle;

  /// No description provided for @uxPreviewInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات المعاينة'**
  String get uxPreviewInfo;

  /// No description provided for @uxCaptureDetails.
  ///
  /// In ar, this message translates to:
  /// **'عن الصوت والملفات'**
  String get uxCaptureDetails;

  /// No description provided for @uxCaptureHint.
  ///
  /// In ar, this message translates to:
  /// **'راجع النص الصوتي قبل الحفظ. ملفات PDF تفضل على الجهاز ده.'**
  String get uxCaptureHint;

  /// No description provided for @uxLocalPdf.
  ///
  /// In ar, this message translates to:
  /// **'PDF محلي'**
  String get uxLocalPdf;

  /// No description provided for @uxChatIntro.
  ///
  /// In ar, this message translates to:
  /// **'اسأل عن الأفكار المحفوظة في المشروع ده.'**
  String get uxChatIntro;

  /// No description provided for @uxConversationList.
  ///
  /// In ar, this message translates to:
  /// **'المحادثات'**
  String get uxConversationList;

  /// No description provided for @uxVerifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد بريدك الإلكتروني'**
  String get uxVerifyTitle;

  /// No description provided for @uxRecoveryTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get uxRecoveryTitle;

  /// No description provided for @uxRecoverySentTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم طلب الاستعادة'**
  String get uxRecoverySentTitle;

  /// No description provided for @uxResetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختار كلمة مرور جديدة'**
  String get uxResetTitle;

  /// No description provided for @uxRequestReset.
  ///
  /// In ar, this message translates to:
  /// **'طلب الاستعادة'**
  String get uxRequestReset;

  /// No description provided for @uxResetPassword.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة المرور'**
  String get uxResetPassword;

  /// No description provided for @uxEmptyChat.
  ///
  /// In ar, this message translates to:
  /// **'اسأل أفكارك'**
  String get uxEmptyChat;

  /// No description provided for @uxSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في أفكار المشروع'**
  String get uxSearchHint;

  /// No description provided for @uxNoConversations.
  ///
  /// In ar, this message translates to:
  /// **'مفيش محادثات لسه'**
  String get uxNoConversations;

  /// No description provided for @uxProjectsHelp.
  ///
  /// In ar, this message translates to:
  /// **'اختار مساحة أفكارك. تقدر تنشئ مشروع وقت ما تحتاج.'**
  String get uxProjectsHelp;

  /// No description provided for @uxProjectContext.
  ///
  /// In ar, this message translates to:
  /// **'المشروع: {name}'**
  String uxProjectContext(String name);

  /// No description provided for @authLoginHint.
  ///
  /// In ar, this message translates to:
  /// **'مساحة صغيرة لفكرتك الكبيرة الجاية.'**
  String get authLoginHint;

  /// No description provided for @authSignupHint.
  ///
  /// In ar, this message translates to:
  /// **'خلّي لأفكارك مكان تكبر فيه.'**
  String get authSignupHint;

  /// No description provided for @authRecoveryHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب البريد الإلكتروني المستخدم لحسابك.'**
  String get authRecoveryHint;

  /// No description provided for @authRecoverySentHint.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلب استعادة كلمة المرور.'**
  String get authRecoverySentHint;

  /// No description provided for @authVerifyHint.
  ///
  /// In ar, this message translates to:
  /// **'أكمل تأكيد البريد الإلكتروني للمتابعة إلى تسجيل الدخول.'**
  String get authVerifyHint;

  /// No description provided for @authResetHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رمز الاستعادة وكلمة مرور جديدة.'**
  String get authResetHint;

  /// No description provided for @authHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'عندك حساب؟ سجّل الدخول'**
  String get authHaveAccount;

  /// No description provided for @authNewAccount.
  ///
  /// In ar, this message translates to:
  /// **'أول مرة هنا؟ أنشئ حسابًا'**
  String get authNewAccount;

  /// No description provided for @apiGoogleUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول بجوجل غير مُعدّ بعد.'**
  String get apiGoogleUnavailable;

  /// No description provided for @apiSignOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get apiSignOut;

  /// No description provided for @apiSixDigitCode.
  ///
  /// In ar, this message translates to:
  /// **'كود من ٦ أرقام'**
  String get apiSixDigitCode;

  /// No description provided for @apiNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get apiNewPassword;

  /// No description provided for @apiPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'استخدم من ٥ إلى ١٢٨ حرفًا.'**
  String get apiPasswordHint;

  /// No description provided for @apiVerifyEmail.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد البريد الإلكتروني'**
  String get apiVerifyEmail;

  /// No description provided for @apiResendCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الكود'**
  String get apiResendCode;

  /// No description provided for @apiHaveCode.
  ///
  /// In ar, this message translates to:
  /// **'معايا الكود'**
  String get apiHaveCode;

  /// No description provided for @apiVerifyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود تأكيد البريد المكوّن من ٦ أرقام.'**
  String get apiVerifyHint;

  /// No description provided for @apiResetHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود الاستعادة المكوّن من ٦ أرقام وكلمة مرور جديدة.'**
  String get apiResetHint;

  /// No description provided for @apiRecoveryAcknowledgment.
  ///
  /// In ar, this message translates to:
  /// **'لو الحساب مؤهل للاستعادة، راجع بريدك للحصول على كود من ٦ أرقام.'**
  String get apiRecoveryAcknowledgment;

  /// No description provided for @apiCodeAcknowledgment.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام الطلب. راجع بريدك للحصول على كود من ٦ أرقام إذا كان الحساب مؤهلًا.'**
  String get apiCodeAcknowledgment;

  /// No description provided for @apiVerified.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد البريد. تقدر تسجّل الدخول دلوقتي.'**
  String get apiVerified;

  /// No description provided for @apiResetComplete.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور. سجّل الدخول بالكلمة الجديدة.'**
  String get apiResetComplete;

  /// No description provided for @apiSignedOut.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الخروج.'**
  String get apiSignedOut;

  /// No description provided for @apiTranscribe.
  ///
  /// In ar, this message translates to:
  /// **'تحويل التسجيل لنص'**
  String get apiTranscribe;

  /// No description provided for @apiInvalidCode.
  ///
  /// In ar, this message translates to:
  /// **'الكود غير صحيح أو لم يعد صالحًا. راجعه أو اطلب كودًا جديدًا.'**
  String get apiInvalidCode;

  /// No description provided for @apiInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'راجع عنوان البريد الإلكتروني.'**
  String get apiInvalidEmail;

  /// No description provided for @authConnectionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال. راجع اتصال الإنترنت وحاول مرة أخرى.'**
  String get authConnectionError;

  /// No description provided for @authTimeoutError.
  ///
  /// In ar, this message translates to:
  /// **'الخادم استغرق وقتًا طويلًا للرد. حاول بعد قليل.'**
  String get authTimeoutError;

  /// No description provided for @authSecureConnectionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إنشاء اتصال آمن. راجع اتصالك وتاريخ الجهاز.'**
  String get authSecureConnectionError;

  /// No description provided for @authServiceError.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الحسابات غير متاحة مؤقتًا. حاول بعد قليل.'**
  String get authServiceError;

  /// No description provided for @authResponseError.
  ///
  /// In ar, this message translates to:
  /// **'وصل رد غير متوقع من الخادم. حاول لاحقًا.'**
  String get authResponseError;

  /// No description provided for @authCredentialsError.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة. راجع بياناتك وحاول مرة أخرى.'**
  String get authCredentialsError;

  /// No description provided for @authRequestError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إكمال الطلب. حاول مرة أخرى.'**
  String get authRequestError;

  /// No description provided for @authCheckDetails.
  ///
  /// In ar, this message translates to:
  /// **'راجع البيانات وحاول مرة أخرى.'**
  String get authCheckDetails;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
