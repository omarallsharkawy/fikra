import '../../data/processing/transcription_engine.dart';
import '../../data/transcription/service_config.dart';
import '../../l10n/app_localizations.dart';

String serviceTypeName(AppLocalizations l, TranscriptionServiceType type) => switch (type) {
  TranscriptionServiceType.openAi => l.vsOpenAi,
  TranscriptionServiceType.gemini => l.vsGemini,
  TranscriptionServiceType.elevenLabs => l.vsElevenLabs,
  TranscriptionServiceType.qwen => l.vsQwen,
};
String serviceKeyHint(AppLocalizations l, TranscriptionServiceType type) => switch (type) {
  TranscriptionServiceType.openAi => l.vsOpenAiKeyHint,
  TranscriptionServiceType.gemini => l.vsGeminiKeyHint,
  TranscriptionServiceType.elevenLabs => l.vsElevenKeyHint,
  TranscriptionServiceType.qwen => l.vsQwenKeyHint,
};
String transcriptionFailureMessage(AppLocalizations l, TranscriptionFailureReason reason) => switch (reason) {
  TranscriptionFailureReason.modelMissing => l.trModelMissing,
  TranscriptionFailureReason.busy => l.trBusy,
  TranscriptionFailureReason.audioUnreadable => l.trAudioUnreadable,
  TranscriptionFailureReason.interruptedTwice => l.trInterruptedTwice,
  TranscriptionFailureReason.offline => l.vsOffline,
  TranscriptionFailureReason.keyRejected => l.vsKeyRejected,
  TranscriptionFailureReason.rateLimited => l.vsRateLimited,
  TranscriptionFailureReason.tooLarge => l.vsTooLarge,
  TranscriptionFailureReason.serviceError => l.vsServiceError,
  TranscriptionFailureReason.unexpectedResponse => l.vsUnexpected,
  TranscriptionFailureReason.remoteTimeout => l.vsTimeout,
  TranscriptionFailureReason.consentRequired => l.vsNeedsConsent,
  TranscriptionFailureReason.other => l.trFailed,
};
String serviceErrorMessage(AppLocalizations l, Object error) {
  if (error is TranscriptionFailure) return transcriptionFailureMessage(l, error.reason);
  if (error is ServiceConfigException) {
    return switch (error.issue) {
      ServiceConfigIssue.invalidUrl => l.vsInvalidUrl,
      ServiceConfigIssue.invalidFields => l.vsInvalidFields,
      ServiceConfigIssue.keyRequired => l.vsKeyRequired,
      ServiceConfigIssue.consentRequired => l.vsNeedsConsent,
    };
  }
  return l.vsSaveError;
}
