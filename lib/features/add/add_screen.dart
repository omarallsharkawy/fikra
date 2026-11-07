import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/voice_player.dart';
import '../../data/ai/ai_service.dart';
import '../../data/files/attachment_store.dart';
import '../../data/local/database.dart';
import '../projects/project_header.dart';
import 'inline_recorder.dart';

enum _Mic { unknown, denied, blocked }

enum _Rec { idle, starting, recording, stopping }

class AddScreen extends ConsumerStatefulWidget {
  const AddScreen({super.key});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> {
  static const maxRecording = Duration(minutes: 5);

  final _title = TextEditingController();
  final _text = TextEditingController();
  final _titleFocus = FocusNode();
  final _textFocus = FocusNode();
  // Created on first use: no recorder (or plugin channel) until the user records.
  AudioRecorder? _recorderInstance;
  AudioRecorder get _recorder => _recorderInstance ??= AudioRecorder();

  // Voice. Every transition is claimed synchronously before the first await so
  // double taps can't start two recordings or stop one twice.
  _Rec _rec = _Rec.idle;
  final List<double> _levels = [];
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  String? _voicePath;
  int? _voiceMs;
  _Mic _mic = _Mic.unknown;

  // PDF
  PlatformFile? _pdf;
  int _pdfBytes = 0;
  double? _progress;
  String? _uploadError;
  StreamSubscription<double>? _uploadSub;
  bool _picking = false;

  bool _saving = false;

  bool get _recording => _rec != _Rec.idle;
  bool get _pdfReady => _pdf != null && _progress == 1 && _uploadError == null;
  bool get _hasAttachment => _voicePath != null || _pdf != null;
  bool get _canSave {
    if (_saving || _recording) return false;
    if (_pdf != null) return _pdfReady;
    return _voicePath != null || _text.text.trim().isNotEmpty;
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _ticker?.cancel();
    _uploadSub?.cancel();
    _recorderInstance?.dispose(); // also stops an active recording
    _title.dispose();
    _text.dispose();
    _titleFocus.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // The composer border follows focus.
    _titleFocus.addListener(_onFocus);
    _textFocus.addListener(_onFocus);
  }

  void _onFocus() => _set(() {});

  // ---------------------------------------------------------------- voice

  Future<void> _startRecording() async {
    if (_rec != _Rec.idle || _saving || _hasAttachment) return;
    _set(() => _rec = _Rec.starting);
    FocusScope.of(context).unfocus();
    try {
      final status = await Permission.microphone.request();
      if (!mounted) return;
      if (!status.isGranted) {
        _set(() {
          _rec = _Rec.idle;
          _mic = status.isPermanentlyDenied ? _Mic.blocked : _Mic.denied;
        });
        return;
      }
      final path = await ref.read(attachmentStoreProvider).newRecordingPath();
      // Disposed meanwhile: never create a recorder that nothing will dispose.
      if (!mounted) return;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, bitRate: 64000),
        path: path,
      );
      if (!mounted) return;
      _levels.clear();
      _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 90)).listen((a) {
        _set(() {
          _levels.add(levelFromDb(a.current));
          if (_levels.length > kWaveformSamples) _levels.removeAt(0);
        });
      }, onError: (_) {});
      _elapsed = Duration.zero;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _set(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= maxRecording) _stopRecording();
      });
      _set(() {
        _mic = _Mic.unknown;
        _rec = _Rec.recording;
      });
    } catch (_) {
      await _teardown();
      try {
        await _recorderInstance?.cancel();
      } catch (_) {}
      _set(() => _rec = _Rec.idle);
      if (mounted) showToast(context, 'التسجيل مش شغال دلوقتي، جرّب تاني');
    }
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
  }

  Future<void> _stopRecording() async {
    if (_rec != _Rec.recording) return;
    _set(() => _rec = _Rec.stopping);
    await _teardown();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    _set(() {
      _rec = _Rec.idle;
      if (path != null) {
        _voicePath = path;
        _voiceMs = _elapsed.inMilliseconds;
      }
    });
    if (path == null && mounted) showToast(context, 'التسجيل اتقطع، جرّب تاني');
  }

  Future<void> _cancelRecording() async {
    if (_rec != _Rec.recording) return;
    _set(() => _rec = _Rec.stopping);
    await _teardown();
    try {
      await _recorder.cancel(); // deletes the partial file
    } catch (_) {}
    _set(() => _rec = _Rec.idle);
  }

  Future<void> _discardVoice() async {
    final path = _voicePath;
    _set(() {
      _voicePath = null;
      _voiceMs = null;
    });
    if (path != null) await AttachmentStore.deleteQuietly([path]);
  }

  // ---------------------------------------------------------------- pdf

  Future<void> _pickPdf() async {
    if (_picking || _saving || _rec != _Rec.idle || _hasAttachment) return;
    _picking = true;
    FocusScope.of(context).unfocus();
    try {
      final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']);
      if (f == null || f.path == null || !mounted) return;
      if (p.extension(f.name).toLowerCase() != '.pdf') {
        showToast(context, 'اختار ملف PDF بس');
        return;
      }
      final bytes = await File(f.path!).length();
      _set(() {
        _pdf = f;
        _pdfBytes = bytes;
      });
      _upload();
    } catch (_) {
      if (mounted) showToast(context, 'معرفناش نفتح الملف');
    } finally {
      _picking = false;
    }
  }

  void _upload() {
    final f = _pdf;
    if (f == null) return;
    _uploadSub?.cancel();
    _set(() {
      _progress = 0;
      _uploadError = null;
    });
    _uploadSub = ref
        .read(uploaderProvider)
        .upload(path: f.path!, name: f.name, bytes: _pdfBytes)
        .listen(
          (v) => _set(() => _progress = v),
          onError: (Object e) => _set(
            () => _uploadError = e is UploadException ? e.message : 'تعذّر تجهيز الملف. جرّب تاني أو اختار ملف تاني.',
          ),
        );
  }

  void _removePdf() {
    if (_saving) return;
    _uploadSub?.cancel();
    _set(() {
      _pdf = null;
      _progress = null;
      _uploadError = null;
    });
  }

  // ---------------------------------------------------------------- save

  Future<void> _save() async {
    final project = ref.read(selectedProjectProvider);
    if (project == null || !_canSave) return;
    final store = ref.read(attachmentStoreProvider);
    // Snapshot the draft: nothing below reads mutable state after an await.
    final title = _title.text;
    final text = _text.text;
    final pdf = _pdf;
    final pdfBytes = _pdfBytes;
    final voicePath = _voicePath;
    final voiceMs = _voiceMs;
    _set(() => _saving = true);

    String? stored;
    try {
      final NoteSource source;
      String? name;
      int? bytes;
      if (pdf != null) {
        source = NoteSource.pdf;
        stored = await store.persist(pdf.path!, extension: 'pdf');
        name = pdf.name;
        bytes = pdfBytes;
      } else if (voicePath != null) {
        source = NoteSource.voice;
        stored = await store.persist(voicePath, extension: 'm4a');
        name = 'تسجيل صوتي';
        bytes = await File(stored).length();
      } else {
        source = NoteSource.text;
      }
      final note = await ref
          .read(notesRepoProvider)
          .create(
            projectId: project.id,
            title: title,
            text: text,
            source: source,
            attachmentPath: stored,
            attachmentName: name,
            attachmentBytes: bytes,
            durationMs: source == NoteSource.voice ? voiceMs : null,
          );
      // Saved: only now is it safe to drop the temporary recording.
      if (voicePath != null) await AttachmentStore.deleteQuietly([voicePath]);
      unawaited(ref.read(noteProcessorProvider).process(note));
      if (!mounted) return;
      _title.clear();
      _text.clear();
      _set(() {
        _voicePath = null;
        _voiceMs = null;
        _pdf = null;
        _progress = null;
      });
      showToast(context, 'اتحفظت. فِكرة بتحللها دلوقتي');
      context.go('/notes');
    } catch (_) {
      if (stored != null) await AttachmentStore.deleteQuietly([stored]);
      if (mounted) showToast(context, 'معرفناش نحفظ النوت، جرّب تاني');
    } finally {
      _set(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------- ui

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final focused = _titleFocus.hasFocus || _textFocus.hasFocus;
    final Widget attachment;
    if (_voicePath != null && !_recording) {
      attachment = Padding(
        key: const ValueKey('voice'),
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: VoicePlayer(path: _voicePath!, durationMs: _voiceMs ?? 0, onDelete: _discardVoice, embedded: true),
      );
    } else if (_pdf != null) {
      attachment = Padding(
        key: const ValueKey('pdf'),
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: _PdfChip(
          name: _pdf!.name,
          bytes: _pdfBytes,
          progress: _progress,
          error: _uploadError,
          onRetry: _upload,
          onRemove: _removePdf,
        ),
      );
    } else {
      attachment = const SizedBox(key: ValueKey('none'), width: double.infinity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProjectHeader(title: 'إضافة'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              FikraSwitcher(
                animateSize: true,
                child: _mic == _Mic.unknown
                    ? const SizedBox(key: ValueKey('mic-ok'), width: double.infinity)
                    : Padding(
                        key: const ValueKey('mic-card'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MicPermissionCard(
                          blocked: _mic == _Mic.blocked,
                          onRetry: _startRecording,
                          onClose: () => setState(() => _mic = _Mic.unknown),
                        ),
                      ),
              ),
              AnimatedContainer(
                duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.enter,
                curve: FikraMotion.enterCurve,
                padding: const EdgeInsets.fromLTRB(16, 4, 10, 10),
                decoration: BoxDecoration(
                  gradient: c.glassGradient,
                  borderRadius: BorderRadius.circular(FikraRadius.xl),
                  border: Border.all(
                    color: _recording
                        ? c.danger.withValues(alpha: 0.55)
                        : focused
                        ? c.borderFocus.withValues(alpha: 0.6)
                        : c.border,
                    width: _recording || focused ? 1 : FikraSpace.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _title,
                      focusNode: _titleFocus,
                      maxLength: 80,
                      maxLines: 1,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _textFocus.requestFocus(),
                      style: context.text.cardTitleSmall,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: 'عنوان (اختياري)',
                        hintStyle: context.text.cardTitleSmall.copyWith(color: c.textPlaceholder),
                      ),
                    ),
                    Container(height: FikraSpace.hairline, color: c.border),
                    FikraSwitcher(
                      animateSize: true,
                      child: _recording
                          ? InlineRecorder(
                              key: const ValueKey('recording'),
                              levels: _levels,
                              elapsed: _elapsed,
                              max: maxRecording,
                            )
                          : TextField(
                              key: const ValueKey('text'),
                              controller: _text,
                              focusNode: _textFocus,
                              minLines: 5,
                              maxLines: 14,
                              maxLength: 5000,
                              onChanged: (_) => setState(() {}),
                              style: context.text.bodyLarge,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: _hasAttachment ? 'ضيف ملاحظة على الملف (اختياري)' : 'اكتب فكرتك هنا…',
                                hintStyle: context.text.bodyLarge.copyWith(color: c.textPlaceholder),
                              ),
                            ),
                    ),
                    FikraSwitcher(animateSize: true, child: attachment),
                    _Toolbar(
                      recording: _recording,
                      attachmentsEnabled: !_hasAttachment && !_saving && _rec == _Rec.idle,
                      canSave: _canSave,
                      saving: _saving,
                      onMic: _startRecording,
                      onPdf: _pickPdf,
                      onStop: _rec == _Rec.recording ? _stopRecording : null,
                      onCancel: _rec == _Rec.recording ? _cancelRecording : null,
                      onSave: _save,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'النوت بتتحفظ الأول، وبعدين فِكرة بتحللها وتربطها.',
                textAlign: TextAlign.center,
                style: context.text.meta.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom row of the composer. Idle: mic + PDF on the start side, save on the
/// end. Recording: cancel + stop.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.recording,
    required this.attachmentsEnabled,
    required this.canSave,
    required this.saving,
    required this.onMic,
    required this.onPdf,
    required this.onStop,
    required this.onCancel,
    required this.onSave,
  });
  final bool recording;
  final bool attachmentsEnabled;
  final bool canSave;
  final bool saving;
  final VoidCallback onMic;
  final VoidCallback onPdf;
  final VoidCallback? onStop;
  final VoidCallback? onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 48,
      child: FikraSwitcher(
        alignment: Alignment.center,
        child: recording
            ? Row(
                key: const ValueKey('rec-tools'),
                children: [
                  _ToolButton(
                    key: const ValueKey('add-cancel-rec'),
                    icon: Icons.close_rounded,
                    label: 'إلغاء التسجيل',
                    onTap: onCancel,
                  ),
                  const Spacer(),
                  _RoundAction(
                    key: const ValueKey('add-stop'),
                    icon: Icons.stop_rounded,
                    label: 'إيقاف التسجيل',
                    color: c.danger,
                    foreground: c.textOnSelected,
                    onTap: onStop,
                  ),
                ],
              )
            : Row(
                key: const ValueKey('idle-tools'),
                children: [
                  _ToolButton(
                    key: const ValueKey('add-mic'),
                    icon: Icons.mic_none_rounded,
                    label: 'تسجيل صوت',
                    onTap: attachmentsEnabled ? onMic : null,
                  ),
                  const SizedBox(width: 6),
                  _ToolButton(
                    key: const ValueKey('add-pdf'),
                    icon: Icons.attach_file_rounded,
                    label: 'رفع ملف PDF',
                    onTap: attachmentsEnabled ? onPdf : null,
                  ),
                  const Spacer(),
                  _RoundAction(
                    key: const ValueKey('add-save'),
                    icon: Icons.check_rounded,
                    label: 'حفظ',
                    gradient: c.sendGradient,
                    foreground: c.textOnSend,
                    loading: saving,
                    onTap: canSave ? onSave : null,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Small round tool (mic, attach, cancel): subtle fill, 48 dp hit area.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      minTarget: true,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.35 : 1,
        duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.exit,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.pressed,
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.border, width: FikraSpace.hairline),
          ),
          child: Icon(icon, size: 21, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

/// The composer's main action (save, stop): filled circle at the end side.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.onTap,
    this.gradient,
    this.color,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final Color foreground;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onTap,
      semanticLabel: label,
      minTarget: true,
      child: AnimatedOpacity(
        opacity: onTap == null && !loading ? 0.35 : 1,
        duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.exit,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(gradient: gradient, color: color, shape: BoxShape.circle),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                )
              : Icon(icon, size: 24, color: foreground),
        ),
      ),
    );
  }
}

class _PdfChip extends StatelessWidget {
  const _PdfChip({
    required this.name,
    required this.bytes,
    required this.progress,
    required this.error,
    required this.onRetry,
    required this.onRemove,
  });
  final String name;
  final int bytes;
  final double? progress;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final done = progress == 1 && error == null;
    return Glass(
      radius: FikraRadius.md,
      color: context.colors.pressed,
      borderColor: error != null ? context.colors.danger : Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: context.colors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.text.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      error ??
                          (done
                              ? '${Fmt.bytes(bytes)} · اترفع'
                              : '${Fmt.bytes(bytes)} · بيترفع ${((progress ?? 0) * 100).round()}%'),
                      style: context.text.meta.copyWith(
                        color: error != null ? context.colors.danger : context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (error != null)
                Pressable(
                  onTap: onRetry,
                  minTarget: true,
                  semanticLabel: 'إعادة المحاولة',
                  child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.refresh_rounded)),
                ),
              Pressable(
                onTap: onRemove,
                minTarget: true,
                semanticLabel: 'شيل الملف',
                child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.close_rounded)),
              ),
            ],
          ),
          if (!done && error == null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: context.colors.pressed,
                  color: context.colors.accentLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MicPermissionCard extends StatelessWidget {
  const _MicPermissionCard({required this.blocked, required this.onRetry, required this.onClose});
  final bool blocked;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.lg,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.mic_off_outlined, color: context.colors.warning),
              const SizedBox(width: 10),
              Expanded(child: Text('محتاجين إذن المايك', style: context.text.cardTitleSmall)),
              Pressable(
                onTap: onClose,
                minTarget: true,
                semanticLabel: 'إغلاق',
                child: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            blocked
                ? 'الإذن مقفول من الإعدادات. افتح إعدادات التطبيق وفعّل المايك.'
                : 'عشان تسجّل فكرة بصوتك، اسمح لفِكرة تستخدم المايك.',
            style: context.text.caption,
          ),
          const SizedBox(height: 14),
          FikraButton.secondary(
            label: blocked ? 'افتح الإعدادات' : 'اسمح بالمايك',
            icon: blocked ? Icons.settings_outlined : Icons.mic_none_rounded,
            onPressed: blocked ? openAppSettings : onRetry,
          ),
        ],
      ),
    );
  }
}
