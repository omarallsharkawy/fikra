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
  /// **'فِكرة'**
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
  /// **'فِكرة بتربط الملاحظات القريبة من بعض لوحدها'**
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
  /// **'الملاحظة اتحفظت، وفِكرة بتحللها دلوقتي'**
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
  /// **'اكتب كام سطر عن الملف عشان فِكرة تربطه (اختياري)'**
  String get bodyHintWithFileLinks;

  /// No description provided for @bodyHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب فكرتك هنا…'**
  String get bodyHint;

  /// No description provided for @addFooter.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة بتتحفظ على طول، وبعدين فِكرة بتحلل النص وتربطه بالباقي. الملفات بتفضل على موبايلك.'**
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
  /// **'المايك مقفول لفِكرة. افتح إعدادات التطبيق واسمح بالمايك.'**
  String get micBlockedBody;

  /// No description provided for @micAskBody.
  ///
  /// In ar, this message translates to:
  /// **'عشان تسجّل فكرة بصوتك، اسمح لفِكرة تستخدم المايك.'**
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
  /// **'اكتب فكرة، أو سجّل صوت، أو ضيف PDF أو صور، وفِكرة هترتّبها وتربطها لوحدها.'**
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
  /// **'فِكرة بتحلل الملاحظة دلوقتي عشان تطلّع مواضيعها وتلاقي الملاحظات المرتبطة بيها. الملاحظة نفسها محفوظة.'**
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

  /// Applies to every note source. There is no automatic voice transcription.
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
  /// **'ضيف ملاحظتين أو أكتر عن مواضيع قريبة، وفِكرة هتربطهم ببعض.'**
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

  /// No description provided for @eraseAllBody.
  ///
  /// In ar, this message translates to:
  /// **'كل المشاريع والملاحظات والتسجيلات والملفات والمحادثات هتتمسح من الموبايل، ومش هتعرف ترجّعها.'**
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

  /// No description provided for @dataSection.
  ///
  /// In ar, this message translates to:
  /// **'البيانات'**
  String get dataSection;

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
  /// **'الملاحظة دي مفيهاش نص، عشان كده فِكرة مش هتعرف تربطها بحاجة.'**
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
  /// **'الملاحظتين هيفضلوا زي ما هم، بس فِكرة مش هتقترح تربطهم ببعض تاني.'**
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

  /// No description provided for @colorBlue.
  ///
  /// In ar, this message translates to:
  /// **'أزرق'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In ar, this message translates to:
  /// **'أخضر'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In ar, this message translates to:
  /// **'أصفر'**
  String get colorYellow;

  /// No description provided for @colorGray.
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

  /// No description provided for @graphNavigateGroup.
  ///
  /// In ar, this message translates to:
  /// **'روح لمجموعة «{group}» في الرسم، من غير فلترة'**
  String graphNavigateGroup(String group);

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
