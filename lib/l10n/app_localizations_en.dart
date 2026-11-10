// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fikra';

  @override
  String get navAdd => 'Add';

  @override
  String get navNotes => 'Notes';

  @override
  String get navLinks => 'Links';

  @override
  String get navAsk => 'Ask';

  @override
  String get storageErrorTitle => 'There\'s a storage problem';

  @override
  String get storageErrorBody =>
      'Couldn\'t read your data right now. Make sure your phone has free space, then try again.';

  @override
  String get retry => 'Try again';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get justNow => 'Just now';

  @override
  String sizeBytes(String size) {
    return '$size B';
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
  String get badgeSampleData => 'Sample data';

  @override
  String get badgeSaved => 'Saved';

  @override
  String get badgeAnalyzing => 'Analyzing…';

  @override
  String get badgeFailed => 'Failed';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get loadErrorTitle => 'Couldn\'t load your data';

  @override
  String get loadErrorBody => 'Couldn\'t read your data right now. Try again.';

  @override
  String get genericError => 'Something went wrong. Try again.';

  @override
  String get voicePlayA11y => 'Play';

  @override
  String get voicePauseA11y => 'Pause';

  @override
  String get voiceUnavailableA11y => 'Recording unavailable';

  @override
  String get voiceRecording => 'Voice recording';

  @override
  String get fileUnavailable => 'File unavailable';

  @override
  String get deleteRecording => 'Delete recording';

  @override
  String get firstProjectTitle => 'Name your first project';

  @override
  String get create => 'Create';

  @override
  String get createProjectFailed => 'Couldn\'t create the project. Try again.';

  @override
  String get sampleProjectFailed => 'Couldn\'t open the sample project. Try again.';

  @override
  String get tagline => 'Write. Connect. Ask.';

  @override
  String get welcomeCapture => 'Type, record your voice, or add a PDF or photos';

  @override
  String get welcomeLinks => 'Fikra links related notes for you';

  @override
  String get welcomeAsk => 'Ask, and get answers from your notes with sources';

  @override
  String get welcomeDemoBadge => 'Demo version: everything stays on your phone';

  @override
  String get startNewProject => 'Start a new project';

  @override
  String get trySampleProject => 'Try a sample project';

  @override
  String projectPillA11y(String name) {
    return 'Project: $name. Tap to change';
  }

  @override
  String get noProject => 'None';

  @override
  String get settings => 'Settings';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get newProject => 'New project';

  @override
  String projectOptionsA11y(String name) {
    return 'Options for $name';
  }

  @override
  String get renameProject => 'Rename';

  @override
  String get save => 'Save';

  @override
  String get deleteProject => 'Delete project';

  @override
  String deleteProjectTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteProjectBody => 'All notes, files and chats in this project will be deleted. You can\'t undo this.';

  @override
  String get projectDeleted => 'Project deleted';

  @override
  String get projectNameHint => 'Project name, e.g. Study';

  @override
  String get recordStartFailed => 'Couldn\'t start recording. Try again.';

  @override
  String get recordInterrupted => 'The recording stopped. Record again.';

  @override
  String get pdfOnly => 'That file isn\'t a PDF. Choose a PDF.';

  @override
  String get fileOpenFailed => 'Couldn\'t open that file. Try another one.';

  @override
  String get photosOpenFailed => 'Couldn\'t open the photos. Try again.';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get noteSavedAnalyzing => 'Note saved. Fikra is analyzing it now.';

  @override
  String get noteSaveFailed => 'Couldn\'t save the note. Try again.';

  @override
  String get photosTitle => 'Photos';

  @override
  String get addTitle => 'New note';

  @override
  String get titleOptionalHint => 'Title (optional)';

  @override
  String get bodyHintWithFileLinks => 'Add a few lines about the file so Fikra can link it (optional)';

  @override
  String get bodyHint => 'Write your idea…';

  @override
  String get addFooter =>
      'Your note is saved right away, then Fikra analyzes the text and links it to related notes. Files stay on your phone.';

  @override
  String get discardRecording => 'Discard recording';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get recordVoice => 'Record voice';

  @override
  String get addPdf => 'Add PDF';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get removeFile => 'Remove file';

  @override
  String removePhoto(int n) {
    return 'Remove photo $n';
  }

  @override
  String get micNeededTitle => 'Microphone access needed';

  @override
  String get close => 'Close';

  @override
  String get micBlockedBody => 'Microphone access is off. Open app settings and allow the microphone.';

  @override
  String get micAskBody => 'To record your voice, let Fikra use the microphone.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get allowMic => 'Allow microphone';

  @override
  String get recordingNow => 'Recording';

  @override
  String get notesTitle => 'Notes';

  @override
  String get searchNotesHint => 'Search notes';

  @override
  String get notesEmptyTitle => 'No notes yet';

  @override
  String get notesEmptyBody =>
      'Type an idea, record your voice, or add a PDF or photos. Fikra sorts and links them for you.';

  @override
  String get addFirstNote => 'Add your first note';

  @override
  String get noResultsTitle => 'No results';

  @override
  String noResultsBody(String query) {
    return 'No notes contain \"$query\". Try another word.';
  }

  @override
  String get noteAnalysisFailed => 'Couldn\'t analyze';

  @override
  String get noteRewriteSuggested => 'Rewrite suggested';

  @override
  String get noteSavedBadge => 'Saved';

  @override
  String openFileA11y(String name) {
    return 'Open $name';
  }

  @override
  String get untitledNote => 'New note';

  @override
  String get openFileFailed => 'Couldn\'t open the file. Make sure you have an app that can open it.';

  @override
  String get noteOptions => 'Note options';

  @override
  String get edit => 'Edit';

  @override
  String get restoreOriginal => 'Restore original text';

  @override
  String get originalRestored => 'Original text restored';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get deleteNoteTitle => 'Delete this note?';

  @override
  String get deleteNoteBody => 'The note, its files and its links will be deleted. You can\'t undo this.';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String get back => 'Back';

  @override
  String get options => 'Options';

  @override
  String get noteNotFoundTitle => 'Note not found';

  @override
  String get noteNotFoundBody => 'It may have been deleted.';

  @override
  String get analysisFailedBanner => 'Couldn\'t analyze this note, but it\'s saved as is.';

  @override
  String get analyzeAgain => 'Analyze again';

  @override
  String get viewEdited => 'Edited';

  @override
  String get viewOriginal => 'Original';

  @override
  String get originalTextLabel => 'Original text';

  @override
  String get topicsHeader => 'Topics';

  @override
  String get relatedNotesHeader => 'Related notes';

  @override
  String get analyzingBody =>
      'Fikra is analyzing this note to find its topics and related notes. The note itself is saved.';

  @override
  String get suggestedRewrite => 'Suggested rewrite';

  @override
  String get demoBadge => 'Demo';

  @override
  String get useRewrite => 'Use it';

  @override
  String get keepOriginal => 'Keep original text';

  @override
  String get pdfFile => 'PDF file';

  @override
  String openPhotoA11y(int n) {
    return 'Open photo $n';
  }

  @override
  String get relatedLoadFailed => 'Couldn\'t load related notes right now.';

  @override
  String get relatedEmpty => 'No related notes in this project yet.';

  @override
  String relatedRowA11y(String title, String reason) {
    return '$title, $reason';
  }

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get changesSaveFailed => 'Couldn\'t save your changes. Try again.';

  @override
  String get unsavedTitle => 'You have unsaved changes';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get editNoteTitle => 'Edit note';

  @override
  String get titleHint => 'Title';

  @override
  String get noteTextA11y => 'Note text';

  @override
  String get originalKeptHint => 'Your original text is kept. You can restore it from the note\'s options.';

  @override
  String get clusterGeneral => 'General';

  @override
  String get moreGroups => 'More groups';

  @override
  String get linksTitle => 'Links';

  @override
  String get linksEmptyTitle => 'Links show up here';

  @override
  String get linksEmptyBody => 'Add two or more notes on related topics, and Fikra will link them.';

  @override
  String get addNote => 'Add a note';

  @override
  String linksSummary(String notesCount, String linksCount) {
    return '$notesCount · $linksCount';
  }

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get resetView => 'Reset view';

  @override
  String showGroupA11y(String notesCount, String cluster) {
    return 'Show $notesCount in $cluster';
  }

  @override
  String moreGroupsCount(int count) {
    return 'More groups ($count)';
  }

  @override
  String get noLinksYet => 'No links yet. Notes on the same topics get linked automatically.';

  @override
  String nodeMeta(String cluster, String linksCount) {
    return '$cluster · $linksCount';
  }

  @override
  String get openNote => 'Open note';

  @override
  String get askFailed => 'Couldn\'t answer right now. Try again.';

  @override
  String get clearChatTitle => 'Clear this chat?';

  @override
  String get clearChatBody => 'Questions and answers will be cleared. Your notes stay as they are.';

  @override
  String get clear => 'Clear';

  @override
  String askSuggestion(String title) {
    return 'What did I write about $title?';
  }

  @override
  String get askTitle => 'Ask';

  @override
  String get clearChatA11y => 'Clear chat';

  @override
  String get askDemoBadge => 'Demo answers from your notes';

  @override
  String get askEmptyTitle => 'Ask about your notes';

  @override
  String get askEmptyNoNotes =>
      'Add some notes first, then ask about them here. Answers come only from your notes, with sources.';

  @override
  String get askEmptyBody => 'Answers come only from this project\'s notes, with sources.';

  @override
  String get askHint => 'Ask anything about your notes';

  @override
  String get send => 'Send';

  @override
  String get notFoundInNotes => 'No answer found in your notes';

  @override
  String get sources => 'Sources';

  @override
  String sourceA11y(int index, String title) {
    return 'Source $index: $title';
  }

  @override
  String sourceDeletedA11y(int index) {
    return 'Source $index: deleted note';
  }

  @override
  String get deletedNote => 'Deleted note';

  @override
  String get eraseAllTitle => 'Erase all data?';

  @override
  String get eraseAllBody =>
      'All projects, notes, recordings, files and chats will be erased from this phone. You can\'t undo this.';

  @override
  String get eraseAllConfirm => 'Erase everything';

  @override
  String get eraseAllDone => 'All data erased';

  @override
  String get eraseAllPartial =>
      'Your data was erased, but a few files are left. They\'ll be removed next time you open the app.';

  @override
  String get eraseAllFailed => 'Couldn\'t erase your data. Try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeHint => '\"System\" follows your phone\'s light or dark mode.';

  @override
  String get dataSection => 'Data';

  @override
  String get dataStaysLocal => 'Your notes and files are stored only on this phone and are never sent anywhere.';

  @override
  String get eraseAll => 'Erase all data';

  @override
  String get aboutSection => 'About';

  @override
  String get demoVersion => 'Demo version';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String demoLinkReason(String concept) {
    return 'Both mention $concept';
  }

  @override
  String get demoAnswerNotFound =>
      'None of the notes in this project cover that. Try asking another way, or add a note about it.';

  @override
  String get demoAnswerIntro => 'From your notes in this project:';

  @override
  String get untitledNoteFallback => 'Untitled note';

  @override
  String get expandLlm => 'LLM (large language model)';

  @override
  String get expandRag => 'RAG (Retrieval-Augmented Generation)';

  @override
  String get sampleProjectName => 'Graduation project';

  @override
  String get sample1Title => 'Project idea';

  @override
  String get sample1Body => 'A notes app that uses AI to connect ideas and answer my questions from my own notes only.';

  @override
  String get sample2Title => 'How RAG works';

  @override
  String get sample2Body =>
      'rag finds the closest chunks of my notes using embeddings, then the llm writes the answer from them and cites the source';

  @override
  String get sample3Title => 'The UI';

  @override
  String get sample3Body =>
      'The UI is dark and simple, right-to-left in Arabic, with four tabs: Add, Notes, Links, Ask.';

  @override
  String get sample4Title => 'State management in Flutter';

  @override
  String get sample4Body => 'I\'ll use riverpod for state management in flutter, with a local database for the demo.';

  @override
  String get sample5Title => 'Backend';

  @override
  String get sample5Body =>
      'Alaa is building the backend with fastapi and postgres with pgvector. The app talks to it through an api.';

  @override
  String get sample6Title => 'Semantic search';

  @override
  String get sample6Body =>
      'Semantic search looks for meaning, not exact words. It relies on embeddings stored in a database.';

  @override
  String get sample7Title => 'Networks lecture';

  @override
  String get sample7Body => 'Today\'s networks lecture was about TCP and UDP. I need to review it before the exam.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noteSavedNoText => 'Note saved. Add a few lines so it can be linked.';

  @override
  String get noTextNoLinks => 'This note has no text, so Fikra can\'t link it.';

  @override
  String get pdfOpenElsewhere => 'Open in another app';

  @override
  String pdfPageOf(int page, int total) {
    return '$page of $total';
  }

  @override
  String get pdfLoadFailed => 'Couldn\'t open this file. It may be damaged or missing.';

  @override
  String notesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
      zero: 'No notes',
    );
    return '$_temp0';
  }

  @override
  String linksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links',
      one: '1 link',
      zero: 'No links',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
      zero: 'Just now',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count hours ago', one: '1 hour ago');
    return '$_temp0';
  }

  @override
  String get pdfFormat => 'PDF';

  @override
  String get removeAttachmentBody =>
      'The file will be deleted from this note when you save changes. You can\'t undo this.';

  @override
  String get emptyNoteBlocked => 'A note can\'t be empty. Add text or a file.';

  @override
  String get pdfPasswordProtected => 'This PDF is password-protected. Open it in another app.';
}
