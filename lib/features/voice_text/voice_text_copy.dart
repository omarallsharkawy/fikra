import '../../core/format.dart';
import '../../l10n/app_localizations.dart';
import 'voice_text_backend.dart';

String modelName(AppLocalizations l, SpikeModel model) {
  if (model.localOnly) return l.vtEgyptian;
  final name = switch (model.family) {
    'tiny' => l.vtTiny,
    'base' => l.vtBase,
    _ => l.vtSmall,
  };
  return model.quantized ? name : l.vtFullName(name);
}

String modelLabel(AppLocalizations l, SpikeModel model, {int? bytes}) =>
    '${modelName(l, model)} · ${Fmt.isolate(model.localOnly ? Fmt.bytes(l, bytes ?? 0) : l.sizeMb(model.downloadMb))}';
String modelHint(AppLocalizations l, SpikeModel model) => model.localOnly
    ? l.vtEgyptianHint
    : !model.quantized
    ? l.vtFullHint
    : switch (model.family) {
        'tiny' => l.vtTinyHint,
        'base' => l.vtBaseHint,
        _ => l.vtSmallHint,
      };
String issueMessage(AppLocalizations l, VoiceTextIssue issue) => switch (issue) {
  VoiceTextIssue.remote => l.trFailed,
  VoiceTextIssue.busy => l.vtEngineBusy,
  VoiceTextIssue.network => l.vtNetworkError,
  VoiceTextIssue.interrupted => l.vtInterruptedError,
  VoiceTextIssue.corrupt => l.vtCorruptError,
  VoiceTextIssue.permission => l.micBlockedBody,
  VoiceTextIssue.empty => l.vtEmptyError,
  VoiceTextIssue.transcription => l.vtTranscriptionError,
  VoiceTextIssue.storage => l.vtStorageError,
  VoiceTextIssue.storageCheck => l.vtStorageCheckError,
  VoiceTextIssue.cancelled => l.vtCancelled,
  VoiceTextIssue.unknown => l.genericError,
};
