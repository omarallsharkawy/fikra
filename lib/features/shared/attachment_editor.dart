import 'package:fikra/l10n/localizations.dart';

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/recording_pulse.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/photo_thumb.dart';
import '../../core/widgets/voice_player.dart';
import '../../data/files/attachment_store.dart';
import '../../data/local/database.dart';
import 'inline_recorder.dart';
import 'group_form.dart';
import 'save_tick_button.dart';
import '../../data/attachment_draft.dart';

export 'save_tick_button.dart' show SaveTickMark;

part 'attachment_files.dart';
part 'attachment_voice.dart';
part 'attachment_toolbar.dart';
part 'attachment_chips.dart';
part 'mic_permission_card.dart';

enum MicPermission { unknown, denied, blocked }

enum RecordingState { idle, starting, recording, stopping }

mixin AttachmentEditing<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  static const maxRecording = Duration(minutes: 5);
  AudioRecorder? recorderInstance;
  AudioRecorder get recorder => recorderInstance ??= ref.read(audioRecorderFactoryProvider)();
  Future<void>? recorderStart;
  RecordingActivity? recordingActivity;
  void releaseRecording() {
    recordingActivity?.release(this);
    recordingActivity = null;
  }

  RecordingState rec = RecordingState.idle;
  final List<double> levels = [];
  final ValueNotifier<int> levelUpdates = ValueNotifier<int>(0);
  StreamSubscription<Amplitude>? ampSub;
  Timer? ticker;
  Duration elapsed = Duration.zero;
  MicPermission mic = MicPermission.unknown;
  List<AttachmentDraft> draftFiles = [];
  String? activeRecordingPath;
  bool picking = false;
  bool saving = false;
  bool get recording => rec != RecordingState.idle;
  bool get attachmentBusy => saving || picking || recording;
  bool get hasAttachment => draftFiles.isNotEmpty;
  bool get confirmAttachmentRemoval => false;
  bool get isAddComposer => false;

  void updateDraft(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> removeDraft(AttachmentDraft a) async {
    if (attachmentBusy) return;
    if (confirmAttachmentRemoval && a.id != null) {
      final ok = await confirmDestructive(
        context,
        title: context.l10n.removeFile,
        message: context.l10n.removeAttachmentBody,
      );
      if (!ok || !mounted || attachmentBusy) return;
    }
    updateDraft(() => draftFiles = [...draftFiles]..remove(a));
    if (a.id == null && a.kind == AttachmentKind.voice) await AttachmentStore.deleteQuietly([a.path]);
  }

  Future<void> cleanDraftRecordings() => AttachmentStore.deleteQuietly([
    for (final a in draftFiles)
      if (a.id == null && a.kind == AttachmentKind.voice) a.path,
  ]);

  Widget attachmentPreviews() => FikraSwitcher(
    animateSize: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, a) in draftFiles.indexed)
          if (a.kind != AttachmentKind.image || i == 0 || draftFiles[i - 1].kind != AttachmentKind.image)
            Padding(
              key: a.kind == AttachmentKind.voice ? ValueKey((a.id ?? a.path, i)) : ObjectKey(a),
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: switch (a.kind) {
                AttachmentKind.pdf => _PdfChip(
                  name: a.name ?? context.l10n.pdfFile,
                  bytes: a.bytes ?? 0,
                  onRemove: attachmentBusy ? null : () => removeDraft(a),
                ),
                AttachmentKind.voice => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VoicePlayer(
                      key: ValueKey(a.path),
                      path: a.path,
                      durationMs: a.durationMs ?? 0,
                      embedded: true,
                      onDelete: attachmentBusy ? null : () => removeDraft(a),
                    ),
                    Wrap(
                      spacing: FikraSpace.s8,
                      runSpacing: FikraSpace.s8,
                      children: [
                        for (final policy in [TranscriptionPolicy.off, TranscriptionPolicy.afterSave])
                          ChoiceTag(
                            key: ValueKey(
                              policy == TranscriptionPolicy.afterSave
                                  ? 'transcribe-draft-${a.path}'
                                  : 'transcribe-off-${a.path}',
                            ),
                            label: policy == TranscriptionPolicy.off ? context.l10n.v2Off : context.l10n.trAfterSave,
                            selected:
                                (a.policy ??
                                    ((ref.watch(autoTranscribeProvider).value ?? false)
                                        ? TranscriptionPolicy.afterSave
                                        : TranscriptionPolicy.off)) ==
                                policy,
                            onTap: attachmentBusy
                                ? null
                                : () => updateDraft(() {
                                    draftFiles = [
                                      for (final file in draftFiles)
                                        identical(file, a) ? file.withPolicy(policy) : file,
                                    ];
                                  }),
                          ),
                      ],
                    ),
                  ],
                ),
                AttachmentKind.image => _ImageStrip(
                  images: draftFiles.skip(i).takeWhile((a) => a.kind == AttachmentKind.image).toList(),
                  onRemove: attachmentBusy ? null : removeDraft,
                ),
              },
            ),
      ],
    ),
  );

  Widget recordingPreview() => InlineRecorder(
    key: const ValueKey('recording'),
    levels: levels,
    elapsed: elapsed,
    max: maxRecording,
    levelUpdates: levelUpdates,
  );
  Widget permissionCard() => FikraSwitcher(
    animateSize: true,
    child: mic == MicPermission.unknown
        ? const SizedBox(key: ValueKey('mic-ok'), width: double.infinity)
        : Padding(
            key: const ValueKey('mic-card'),
            padding: const EdgeInsets.only(bottom: 12),
            child: _MicPermissionCard(
              blocked: mic == MicPermission.blocked,
              onRetry: startRecording,
              onClose: () => updateDraft(() => mic = MicPermission.unknown),
            ),
          ),
  );
  Widget attachmentToolbar({
    required bool canSave,
    required VoidCallback onSave,
    bool enabled = true,
    bool showSave = true,
    Animation<double>? saveTick,
    bool saveTickActive = false,
  }) => _Toolbar(
    showSave: showSave,
    recording: recording,
    micEnabled: enabled && !attachmentBusy && !ref.watch(recordingActiveProvider),
    pdfEnabled: enabled && !attachmentBusy,
    imagesEnabled: enabled && !attachmentBusy,
    canSave: canSave,
    saving: saving,
    saveTick: saveTick,
    saveTickActive: saveTickActive,
    onMic: startRecording,
    onPdf: pickPdf,
    onImages: pickImages,
    onStop: rec == RecordingState.recording ? stopRecording : null,
    onCancel: rec == RecordingState.recording ? cancelRecording : null,
    onSave: onSave,
  );

  @override
  void dispose() {
    ampSub?.cancel();
    ticker?.cancel();
    levelUpdates.dispose();
    final activeRecorder = recorderInstance;
    if (activeRecorder != null) {
      unawaited(() async {
        try {
          await recorderStart;
        } catch (_) {}
        try {
          await activeRecorder.cancel();
        } catch (_) {}
        try {
          await activeRecorder.dispose();
        } catch (_) {}
        await AttachmentStore.deleteQuietly([?activeRecordingPath]);
        releaseRecording();
      }());
    } else {
      // Widget disposal may run during a build; release outside that frame.
      scheduleMicrotask(releaseRecording);
    }
    unawaited(cleanDraftRecordings());
    super.dispose();
  }
}
