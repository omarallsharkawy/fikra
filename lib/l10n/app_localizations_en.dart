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
  String get sampleProjectFailed =>
      'Couldn\'t open the sample project. Try again.';

  @override
  String get tagline => 'Write. Connect. Ask.';

  @override
  String get welcomeCapture =>
      'Type, record your voice, or add a PDF or photos';

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
  String deleteProjectBody(String items) {
    return 'This deletes $items, plus the chat. You can\'t undo this.';
  }

  @override
  String get projectDeleted => 'Project deleted';

  @override
  String get projectNameHint => 'Project name';

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
  String get bodyHintWithFileLinks =>
      'Add a few lines about the file so Fikra can link it (optional)';

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
  String get micBlockedBody =>
      'Microphone access is off. Open app settings and allow the microphone.';

  @override
  String get micAskBody =>
      'To record your voice, let Fikra use the microphone.';

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
  String get openFileFailed =>
      'Couldn\'t open the file. Make sure you have an app that can open it.';

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
  String get deleteNoteBody =>
      'The note, its files and its links will be deleted. You can\'t undo this.';

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
  String get analysisFailedBanner =>
      'Couldn\'t analyze this note, but it\'s saved as is.';

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
  String get originalKeptHint =>
      'Your original text is kept. You can restore it from the note\'s options.';

  @override
  String get clusterGeneral => 'General';

  @override
  String get moreGroups => 'More groups';

  @override
  String get linksTitle => 'Links';

  @override
  String get linksEmptyTitle => 'Links show up here';

  @override
  String get linksEmptyBody =>
      'Add two or more notes on related topics, and Fikra will link them.';

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
  String get noLinksYet =>
      'No links yet. Notes on the same topics get linked automatically.';

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
  String get clearChatBody =>
      'Questions and answers will be cleared. Your notes stay as they are.';

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
  String get askEmptyBody =>
      'Answers come only from this project\'s notes, with sources.';

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
  String get eraseAllTitle => 'Erase all data?';

  @override
  String get eraseAllBody =>
      'All projects, notes, recordings, files, chats, transcription services and their keys will be erased from this phone. You can\'t undo this.';

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
  String get themeHint =>
      '\"System\" follows your phone\'s light or dark mode.';

  @override
  String get dataSection => 'Data';

  @override
  String get dataStaysLocal =>
      'Your notes and files are stored only on this phone and are never sent anywhere.';

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
  String get sample1Body =>
      'A notes app that uses AI to connect ideas and answer my questions from my own notes only.';

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
  String get sample4Body =>
      'I\'ll use riverpod for state management in flutter, with a local database for the demo.';

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
  String get sample7Body =>
      'Today\'s networks lecture was about TCP and UDP. I need to review it before the exam.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noteSavedNoText =>
      'Note saved. Add a few lines so it can be linked.';

  @override
  String get noTextNoLinks => 'This note has no text, so Fikra can\'t link it.';

  @override
  String get pdfOpenElsewhere => 'Open in another app';

  @override
  String pdfPageOf(int page, int total) {
    return '$page of $total';
  }

  @override
  String get pdfLoadFailed =>
      'Couldn\'t open this file. It may be damaged or missing.';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
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
  String get pdfPasswordProtected =>
      'This PDF is password-protected. Open it in another app.';

  @override
  String get noteLinksHeader => 'Links';

  @override
  String get linkToNote => 'Link to a note';

  @override
  String get noteLinksEmpty =>
      'No links yet. Tap \"Link to a note\" to connect this note to others.';

  @override
  String get noteLinksLoadFailed => 'Couldn\'t load links right now.';

  @override
  String get linkSuggestedTag => 'Suggested';

  @override
  String linkRowA11y(String title, String detail) {
    return '$title, $detail';
  }

  @override
  String suggestedLinkA11y(String title) {
    return 'Suggested: $title';
  }

  @override
  String get acceptLink => 'Accept';

  @override
  String acceptLinkA11y(String title) {
    return 'Accept link to $title';
  }

  @override
  String get rejectLink => 'Reject';

  @override
  String rejectLinkA11y(String title) {
    return 'Reject link to $title';
  }

  @override
  String linkOptionsA11y(String title) {
    return 'Link options for $title';
  }

  @override
  String get linkOptionsTitle => 'Link options';

  @override
  String get editLinkReason => 'Edit reason';

  @override
  String get removeLink => 'Remove link';

  @override
  String get removeLinkTitle => 'Remove this link?';

  @override
  String get removeLinkBody =>
      'Both notes stay as they are, but Fikra won\'t suggest linking them again.';

  @override
  String get removeLinkConfirm => 'Remove';

  @override
  String get linkRemoved => 'Link removed';

  @override
  String get linkUpdateFailed => 'Couldn\'t update the link. Try again.';

  @override
  String get linkReasonHint => 'Reason (optional)';

  @override
  String get alreadyLinked => 'Already linked';

  @override
  String get linkPickerEmpty =>
      'There are no other notes in this project to link.';

  @override
  String get linkFailed => 'Couldn\'t link the notes. Try again.';

  @override
  String linkSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Link $count notes',
      one: 'Link 1 note',
      zero: 'Link',
    );
    return '$_temp0';
  }

  @override
  String notesLinked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Linked to $count notes',
      one: 'Linked to 1 note',
      zero: 'No notes were linked',
    );
    return '$_temp0';
  }

  @override
  String get moveToProject => 'Move to another project';

  @override
  String get moveNoOtherProject =>
      'There\'s no other project to move this note to.';

  @override
  String moveNoteTitle(String project) {
    return 'Move this note to \"$project\"?';
  }

  @override
  String moveNoteBody(String lost) {
    return 'The note moves with its files. Its $lost to notes that stay here will be removed.';
  }

  @override
  String get moveNoteBodyNoLinks =>
      'The note moves with its files. No links will be removed.';

  @override
  String get moveConfirm => 'Move';

  @override
  String noteMoved(String project) {
    return 'Note moved to \"$project\"';
  }

  @override
  String get moveNoteFailed => 'Couldn\'t move the note. Try again.';

  @override
  String suggestionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suggestions',
      one: '1 suggestion',
      zero: 'No suggestions',
    );
    return '$_temp0';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
      zero: 'No files',
    );
    return '$_temp0';
  }

  @override
  String listTwo(String first, String second) {
    return '$first and $second';
  }

  @override
  String listThree(String first, String second, String third) {
    return '$first, $second and $third';
  }

  @override
  String get deleteProjectEmptyBody =>
      'This project is empty. It has no notes.';

  @override
  String get firstProjectNameHint => 'Project name, e.g. Study';

  @override
  String get sourceMissing => 'Note no longer in this project';

  @override
  String sourceMissingA11y(int index) {
    return 'Source $index: note no longer in this project';
  }

  @override
  String get deleteProjectEmptyChatBody =>
      'This project has no notes, but its chat will be deleted. You can\'t undo this.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'Nothing selected',
    );
    return '$_temp0';
  }

  @override
  String get closeSelection => 'Close selection';

  @override
  String get linkTogether => 'Link together';

  @override
  String get groupAction => 'Group';

  @override
  String linkTogetherLimit(int max) {
    return 'You can link up to $max notes together. For more, use a group.';
  }

  @override
  String get linkTogetherNeedsTwo => 'Select at least 2 notes to link them.';

  @override
  String linksAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count links',
      one: 'Added 1 link',
      zero: 'These notes were already linked',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Undo';

  @override
  String get undoFailed => 'Couldn\'t undo that.';

  @override
  String get chooseGroup => 'Choose a group';

  @override
  String get newGroup => 'New group';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String get noGroupsYet => 'No groups in this project yet.';

  @override
  String subGroupA11y(String group, String parent, String notes) {
    return '$group, inside $parent, $notes';
  }

  @override
  String notesGrouped(String notes, String group) {
    return 'Added $notes to \"$group\"';
  }

  @override
  String groupRemovedFrom(String notes) {
    return 'Removed the group from $notes';
  }

  @override
  String get groupFailed => 'Couldn\'t update the group. Try again.';

  @override
  String get groupNameHint => 'Group name';

  @override
  String groupColorLabel(String color) {
    return 'Color: $color';
  }

  @override
  String get colorNone => 'No color';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorGray => 'Gray';

  @override
  String get groupParentLabel => 'Inside a group (optional)';

  @override
  String get groupParentNone => 'None';

  @override
  String moveNotesTitle(String notes, String project) {
    return 'Move $notes to \"$project\"?';
  }

  @override
  String moveNotesBody(int count, String lost) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The notes move with their files. Their $lost to notes that stay here will be removed.',
      one:
          'The note moves with its files. Its $lost to notes that stay here will be removed.',
    );
    return '$_temp0';
  }

  @override
  String moveNotesBodyNoLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The notes move with their files. No links will be removed.',
      one: 'The note moves with its files. No links will be removed.',
    );
    return '$_temp0';
  }

  @override
  String notesMoved(String notes, String project) {
    return 'Moved $notes to \"$project\"';
  }

  @override
  String get moveNotesFailed => 'Couldn\'t move the notes. Try again.';

  @override
  String get moveNotesNoOtherProject =>
      'There\'s no other project to move these notes to.';

  @override
  String deleteNotesTitle(String notes) {
    return 'Delete $notes?';
  }

  @override
  String deleteNotesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'These notes, their files and their links will be deleted. You can\'t undo this.',
      one: 'The note, its files and its links will be deleted. You can\'t undo this.',
    );
    return '$_temp0';
  }

  @override
  String notesDeleted(String notes) {
    return 'Deleted $notes';
  }

  @override
  String get deleteNotesFailed => 'Couldn\'t delete all the notes. Try again.';

  @override
  String get allGroupsFilter => 'All';

  @override
  String groupOptionsA11y(String group) {
    return 'Options for the group $group';
  }

  @override
  String get groupEmptyTitle => 'This group is empty';

  @override
  String get groupEmptyBody =>
      'Long-press a note to select it, then tap Group.';

  @override
  String noteGroupA11y(String group) {
    return 'In group $group';
  }

  @override
  String get renameGroup => 'Rename';

  @override
  String get changeGroupColor => 'Change color';

  @override
  String get putInGroup => 'Put inside another group';

  @override
  String takeOutOfGroup(String parent) {
    return 'Take out of \"$parent\"';
  }

  @override
  String get deleteGroup => 'Delete group';

  @override
  String deleteGroupTitle(String group) {
    return 'Delete the group \"$group\"?';
  }

  @override
  String get deleteGroupBody =>
      'Its notes stay as they are, just without a group. Groups inside it move out.';

  @override
  String get groupDeleted => 'Group deleted';

  @override
  String get noParentGroups => 'There\'s no other group to put it in.';

  @override
  String get groupRuleEmptyName => 'Write a name for the group.';

  @override
  String get groupRuleInvalidColor => 'That color isn\'t available.';

  @override
  String get groupRuleMissingProject => 'This project no longer exists.';

  @override
  String get groupRuleMissingGroup => 'This group no longer exists.';

  @override
  String get groupRuleInvalidParent =>
      'A group can only go inside a top-level group, not inside a sub-group.';

  @override
  String get groupRuleSelfParent => 'A group can\'t go inside itself.';

  @override
  String get groupRuleHasChildren =>
      'This group has groups inside it, so it can\'t go inside another group.';

  @override
  String get suggestedTopics => 'Suggested topics';

  @override
  String makeTopicGroup(String topic) {
    return 'Make $topic a group';
  }

  @override
  String graphGroupA11y(String group, String notes) {
    return 'Group $group, $notes';
  }

  @override
  String get moreTopics => 'More topics';

  @override
  String moreTopicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more topics',
      one: '$count more topic',
    );
    return '$_temp0';
  }

  @override
  String graphNoteInGroup(String title, String group) {
    return '$title, in group $group';
  }

  @override
  String get graphSearchHint => 'Search the graph';

  @override
  String get graphSearchEmpty => 'No results';

  @override
  String get graphSearchNote => 'Note';

  @override
  String get graphSearchLink => 'Link';

  @override
  String get graphSearchGroup => 'Group';

  @override
  String get graphSearchLimited => 'Hidden by graph limits. Opening the note.';

  @override
  String graphNavigateGroup(String group) {
    return 'Go to group $group in the graph, without filtering';
  }

  @override
  String graphCollapseGroup(String group) {
    return 'Collapse group $group';
  }

  @override
  String graphExpandGroup(String group) {
    return 'Expand group $group';
  }

  @override
  String graphCollapsedGroup(String group, String notes) {
    return 'Group $group, $notes, collapsed';
  }

  @override
  String get graphMinimap => 'Graph minimap. Tap or drag to move';

  @override
  String get vtTitle => 'Voice to text';

  @override
  String get vtExperimental => 'Experimental';

  @override
  String get vtIntro =>
      'The model runs on your phone. Nothing is uploaded. It needs a one-time download.';

  @override
  String get vtModel => 'Model';

  @override
  String get vtTiny => 'Tiny';

  @override
  String get vtBase => 'Medium';

  @override
  String get vtSmall => 'More accurate';

  @override
  String vtFullName(String name) {
    return '$name · uncompressed';
  }

  @override
  String get vtTinyHint => 'Smallest and fastest, with more mistakes.';

  @override
  String get vtBaseHint => 'Balances size and accuracy.';

  @override
  String get vtSmallHint => 'May be more accurate, but slower and larger.';

  @override
  String get vtFullHint =>
      'Larger, uncompressed version. Compare its accuracy with the smaller version.';

  @override
  String get vtOnPhone => 'On your phone';

  @override
  String get vtNotDownloaded => 'Not downloaded';

  @override
  String vtUsed(String size) {
    return 'Model storage used: $size';
  }

  @override
  String vtDownload(String size) {
    return 'Download · $size';
  }

  @override
  String get vtDownloadTitle => 'Download this model?';

  @override
  String vtDownloadBody(String size) {
    return 'The download is $size. Wi-Fi is better. You only need to download it once.';
  }

  @override
  String get vtDownloadConfirm => 'Download';

  @override
  String get vtDeleteModel => 'Delete model';

  @override
  String get vtDeleteModelTitle => 'Delete this model?';

  @override
  String get vtDeleteModelBody =>
      'You will need to download it again to use it.';

  @override
  String vtProgress(String received, String total) {
    return '$received of $total';
  }

  @override
  String get vtLanguage => 'Speech language';

  @override
  String get vtAutomatic => 'Automatic';

  @override
  String get vtAdvanced => 'Advanced';

  @override
  String vtThreads(String count) {
    return 'CPU threads: $count';
  }

  @override
  String get vtFormat => 'Recording format';

  @override
  String get vtWav => 'Test format (WAV)';

  @override
  String get vtAac => 'The app\'s normal format (AAC)';

  @override
  String get vtClips => 'Recent recordings';

  @override
  String get vtNoRecordings =>
      'Record a few words to try transcription. Your last 10 recordings stay here.';

  @override
  String vtClip(String number, String format) {
    return 'Recording $number · $format';
  }

  @override
  String get vtDeleteRecordingBody =>
      'This recording will be deleted from the experiment.';

  @override
  String get vtTranscribe => 'Transcribe';

  @override
  String get vtWorking => 'Transcribing…';

  @override
  String get vtCannotCancel =>
      'Once transcription starts, wait for it to finish.';

  @override
  String get vtWait =>
      'Wait for the operation to finish, or stop recording first.';

  @override
  String get vtResult => 'Transcript';

  @override
  String get vtNoSpeech => 'No clear speech was found. Try again.';

  @override
  String get vtNumbers => 'Numbers';

  @override
  String vtAudioLength(String seconds) {
    return 'Audio length: $seconds s';
  }

  @override
  String vtWall(String seconds) {
    return 'Time taken: $seconds s';
  }

  @override
  String vtFaster(String times) {
    return '$times times faster than speech';
  }

  @override
  String vtSlower(String times) {
    return '$times times slower than speech';
  }

  @override
  String vtFactor(String factor) {
    return 'Real-time factor: $factor';
  }

  @override
  String vtMs(String ms) {
    return '$ms ms';
  }

  @override
  String vtMemory(String before, String after) {
    return 'Memory before: $before, after: $after';
  }

  @override
  String vtPeak(String size) {
    return 'Peak memory: $size';
  }

  @override
  String vtConversion(String ms) {
    return 'Audio conversion: $ms';
  }

  @override
  String vtEstimate(String ms) {
    return 'Transcription and model load, approximately: $ms';
  }

  @override
  String vtModelLoad(String ms) {
    return 'Model startup: $ms';
  }

  @override
  String get vtTimingHint =>
      'Time includes audio conversion and model loading. Memory is for the whole app.';

  @override
  String get vtHistory => 'Recent runs';

  @override
  String get vtLive => 'Text while you speak';

  @override
  String get vtLiveHint =>
      'Text updates while you speak. Stopping may take a little time.';

  @override
  String get vtLiveStart => 'Start live transcription';

  @override
  String get vtLiveTiming =>
      'Live session time includes speaking, so it does not measure transcription speed.';

  @override
  String get vtNetworkError =>
      'Couldn\'t download the model. Check your connection and try again.';

  @override
  String get vtInterruptedError =>
      'The download or recording was interrupted. Try again.';

  @override
  String get vtCorruptError =>
      'Couldn\'t read the model. Delete it and download it again.';

  @override
  String get vtEmptyError =>
      'The recording is empty or invalid. Record a few words and try again.';

  @override
  String get vtTranscriptionError =>
      'Couldn\'t transcribe the audio. Try a shorter recording or a smaller model.';

  @override
  String get vtStorageError =>
      'There is not enough storage. Free some space or choose a smaller model, then try again.';

  @override
  String get vtStorageCheckError =>
      'Couldn\'t check free storage. Reopen this screen and try again.';

  @override
  String get vtCancelled => 'Download cancelled. You can start it again.';

  @override
  String get vtEgyptian => 'Egyptian · experimental';

  @override
  String get vtEgyptianHint => 'Trained on Egyptian Arabic mixed with English.';

  @override
  String get vtVoiceSection => 'Voice';

  @override
  String get vtTry => 'Try it';

  @override
  String get vtTesting => 'For testing';

  @override
  String get vtFullModels => 'Uncompressed models';

  @override
  String get vtRefreshModels => 'Refresh model list';

  @override
  String get trAutomatic => 'Transcribe recordings automatically';

  @override
  String get trAutomaticHint =>
      'Runs on your phone after saving and can take a while.';

  @override
  String get trDownloadFirst =>
      'Download a model first to transcribe recordings on your phone.';

  @override
  String get trAfterSave => 'Transcribe after saving';

  @override
  String get trQueueFailed =>
      'The recording is saved, but we couldn’t queue it. Try from the note.';

  @override
  String get trWorking => 'Transcribing audio…';

  @override
  String get trQueued => 'Waiting to transcribe…';

  @override
  String get trExpand => 'Show full transcript';

  @override
  String get trCollapse => 'Show less';

  @override
  String trLocalEngine(String model) {
    return 'On your phone · $model';
  }

  @override
  String get trModelMissing =>
      'The model is missing or damaged. Download it in voice settings and try again.';

  @override
  String get trBusy =>
      'Another transcription took too long. Try again when it finishes.';

  @override
  String get trAudioUnreadable =>
      'We couldn’t read the recording or find speech. Try playing it first.';

  @override
  String get trFailed => 'We couldn’t transcribe the recording. Try again.';

  @override
  String get trInterruptedTwice =>
      'Transcription stopped twice because the app closed. Try again or choose a smaller model.';

  @override
  String get trNotificationChannel => 'Transcription';

  @override
  String trNotificationLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings left',
      one: '1 recording left',
    );
    return '$_temp0';
  }

  @override
  String get trNotificationWhy =>
      'Allow notifications to follow transcription after you leave the app.';

  @override
  String get trOpenSettings => 'Open voice settings';

  @override
  String get trTranscribe => 'Transcribe audio';

  @override
  String get trRedo => 'Transcribe again';

  @override
  String get vtEngineBusy =>
      'A recording is being transcribed. Wait for it to finish and try again.';

  @override
  String get vsEngine => 'Transcription engine';

  @override
  String get vsLocal => 'On your phone';

  @override
  String get vsAdd => 'Add a service';

  @override
  String get vsEdit => 'Edit service';

  @override
  String get vsType => 'Service type';

  @override
  String get vsOpenAi => 'OpenAI-compatible';

  @override
  String get vsName => 'Service name';

  @override
  String get vsBaseUrl => 'Base URL';

  @override
  String get vsModel => 'Model ID';

  @override
  String get vsKey => 'API key';

  @override
  String get vsKeyKeep => 'Leave blank to keep the saved key.';

  @override
  String get vsLanguageHint => 'Language hint (optional)';

  @override
  String get vsLanguageHelp =>
      'Use a code such as ar or en. Leave blank to use the selected speech language.';

  @override
  String get vsShowKey => 'Show key';

  @override
  String get vsHideKey => 'Hide key';

  @override
  String get vsTest => 'Test connection';

  @override
  String get vsTesting => 'Testing connection…';

  @override
  String get vsConnected => 'Connection works.';

  @override
  String get vsDeleteTitle => 'Delete this service?';

  @override
  String get vsDeleteBody =>
      'Its key will be deleted. If selected, transcription switches back to your phone.';

  @override
  String vsConsentTitle(String service) {
    return 'Send recordings to $service?';
  }

  @override
  String vsConsentBody(String service, String host) {
    return 'Recordings will be sent outside your phone to $service at $host for transcription. The service may retain them and charge for use. Nothing is sent until you agree.';
  }

  @override
  String get vsConsentConfirm => 'Agree';

  @override
  String get vsHttpWarning =>
      'This connection is unencrypted. Use it only on a trusted local network.';

  @override
  String get vsInvalidUrl =>
      'Use HTTPS, or HTTP to localhost or a private LAN address.';

  @override
  String get vsInvalidFields => 'Check the name, model and language code.';

  @override
  String get vsKeyRequired => 'Enter a key for this service first.';

  @override
  String get vsSaveError => 'We couldn’t save the service. Try again.';

  @override
  String get vsLoadError => 'We couldn’t read the service settings. Try again.';

  @override
  String vsRemoteIntro(String service) {
    return 'Recordings are sent outside your phone to $service for transcription. The service may charge for use.';
  }

  @override
  String vsRemoteData(String service) {
    return 'Your notes and files are stored on your phone. Recordings are sent outside your phone to $service for transcription.';
  }

  @override
  String vsVia(String service) {
    return 'Via $service';
  }

  @override
  String get vsRemovedService => 'Deleted service';

  @override
  String get vsLiveLocal =>
      'Live text is available only on your phone. Switch engines to try it.';

  @override
  String vsRemoteAutoHint(String service) {
    return 'New recordings are sent outside your phone to $service after saving and can take a while.';
  }

  @override
  String get vsOffline =>
      'We couldn’t reach the service. Check your connection and try again.';

  @override
  String get vsKeyRejected =>
      'The service rejected the key. Check it in voice settings.';

  @override
  String get vsRateLimited =>
      'You reached a usage limit or ran out of credit. Check your account or try later.';

  @override
  String get vsTooLarge =>
      'The recording is too large or long for this service. Try a shorter recording or another service.';

  @override
  String get vsServiceError => 'The service is having a problem. Try later.';

  @override
  String get vsUnexpected =>
      'The service returned an unexpected response. Check its URL and model in voice settings.';

  @override
  String get vsTimeout =>
      'The service took too long to respond. Check your connection and try again.';

  @override
  String get vsNeedsConsent =>
      'Agree to send recordings in voice settings first.';

  @override
  String get vsRegion => 'Region';

  @override
  String get vsSingapore => 'International (Singapore)';

  @override
  String get vsBeijing => 'Mainland China (Beijing)';

  @override
  String get vsOpenAiKeyHint =>
      'Get the key, URL and model from your provider, such as OpenAI, Groq or SiliconFlow.';

  @override
  String get vsGeminiKeyHint => 'Get a key from Google AI Studio.';

  @override
  String get vsElevenKeyHint =>
      'Get a key from your ElevenLabs account settings.';

  @override
  String get vsQwenKeyHint =>
      'Get a key for the same region from Alibaba Cloud Model Studio. Workspace URLs are also supported.';

  @override
  String get vsGemini => 'Google Gemini';

  @override
  String get vsElevenLabs => 'ElevenLabs';

  @override
  String get vsQwen => 'Qwen ASR';

  @override
  String get vsRemoteTiming =>
      'Time includes uploading and waiting for the service. Memory is for the whole app.';

  @override
  String get v2Off => 'No transcription';

  @override
  String get v2Recommended => 'Recommended';

  @override
  String get v2Other => 'Other';

  @override
  String get v2Legacy => 'Legacy';

  @override
  String v2Shutdown(String date) {
    return 'Legacy model. Shuts down on $date. Choose a recommended model if you can.';
  }

  @override
  String get v2LegacyUnknown =>
      'Legacy model. No shutdown date has been announced.';

  @override
  String get v2Arabic =>
      'Supports Arabic. Try it with mixed Egyptian Arabic and English.';

  @override
  String get v2Generative =>
      'Understands Arabic, but may rephrase speech. Check the transcript.';

  @override
  String get v2Unsupported => 'Not supported here yet';

  @override
  String get v2Custom => 'Custom model';

  @override
  String get v2Refresh => 'Refresh list';

  @override
  String get v2Refreshing => 'Refreshing list…';

  @override
  String get v2Available => 'Available in your account';

  @override
  String v2Checked(String time) {
    return 'Last checked: $time';
  }

  @override
  String get v2DiscoveryHint =>
      'Checks models with the service outside your phone, without sending audio.';

  @override
  String get v2DiscoveryQwen =>
      'Model discovery is unavailable for Qwen here. Use the recommended model or enter an ID.';

  @override
  String get v2EditTranscript => 'Edit transcript';

  @override
  String get v2RestoreTranscript => 'Restore machine transcript';

  @override
  String get v2NewTranscript => 'New transcript available';

  @override
  String get v2UseTranscript => 'Use it';

  @override
  String get v2CopyUnchanged =>
      'Transcript saved. The note text was left unchanged because it was edited.';

  @override
  String get v2AppendTranscript => 'Append to note';

  @override
  String get v2TranscriptConflict =>
      'The transcript changed while you were editing. Go back and reopen it.';

  @override
  String get v2TranscriptFailed => 'Couldn’t save the transcript. Try again.';

  @override
  String get v2TranscriptEmpty => 'Enter the transcript first.';

  @override
  String get v2TranscriptSaved => 'Transcript saved';

  @override
  String get linksBrowse => 'Browse';

  @override
  String get linksSuggestions => 'Suggestions';

  @override
  String get linksConfirmed => 'Confirmed links';

  @override
  String get linksGroups => 'Groups';

  @override
  String get linksSuggestedForYou => 'Suggested for you';

  @override
  String get searchLinksHint => 'Search links';

  @override
  String get linksSort => 'Sort links';

  @override
  String get linksNewest => 'Newest first';

  @override
  String get linksMostLinked => 'Most links first';

  @override
  String get linksOldest => 'Oldest first';

  @override
  String get linksOpenGraph => 'Open links graph';

  @override
  String get linkNoReason => 'No reason added';

  @override
  String get linksSuggestionsEmpty => 'No suggestions right now';

  @override
  String get linksSuggestionsEmptyBody => 'New suggestions will appear here.';

  @override
  String get linksBrowseSuggestionsBody =>
      'Some suggestions are waiting for you. Accept a link to see it here.';

  @override
  String linksSuggestionsCount(int count) {
    return 'Suggestions $count';
  }

  @override
  String linksSuggestionsCountA11y(int count) {
    return 'Suggestions, $count';
  }

  @override
  String get linksFilterEmptyBody =>
      'Nothing here yet. Try another group or topic.';
}
