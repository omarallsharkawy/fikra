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
import '../../core/widgets/photo_thumb.dart';
import '../../core/widgets/voice_player.dart';
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

  // PDF and photos. They stay on the phone: nothing is uploaded or parsed.
  PlatformFile? _pdf;
  int _pdfBytes = 0;
  List<PlatformFile> _images = const [];
  bool _picking = false;

  bool _saving = false;

  bool get _recording => _rec != _Rec.idle;
  bool get _hasAttachment => _voicePath != null || _pdf != null || _images.isNotEmpty;
  bool get _canSave {
    if (_saving || _recording || _picking) return false;
    return _hasAttachment || _text.text.trim().isNotEmpty;
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _ticker?.cancel();
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
    if (_rec != _Rec.idle || _saving || _picking || _voicePath != null) return;
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
    if (_saving) return; // the save is copying this file right now
    final path = _voicePath;
    _set(() {
      _voicePath = null;
      _voiceMs = null;
    });
    if (path != null) await AttachmentStore.deleteQuietly([path]);
  }

  // ---------------------------------------------------------------- pdf

  Future<void> _pickPdf() async {
    if (_picking || _saving || _rec != _Rec.idle || _pdf != null) return;
    _set(() => _picking = true);
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
    } catch (_) {
      if (mounted) showToast(context, 'معرفناش نفتح الملف');
    } finally {
      _set(() => _picking = false);
    }
  }

  void _removePdf() {
    if (_saving) return;
    _set(() => _pdf = null);
  }

  // ---------------------------------------------------------------- photos

  Future<void> _pickImages() async {
    if (_picking || _saving || _rec != _Rec.idle) return;
    _set(() => _picking = true);
    FocusScope.of(context).unfocus();
    try {
      final picked = await FilePicker.pickFiles(type: FileType.image);
      if (!mounted) return;
      final usable = picked.where((f) => f.path != null);
      _set(() => _images = [..._images, ...usable]);
    } catch (_) {
      if (mounted) showToast(context, 'معرفناش نفتح الصور');
    } finally {
      _set(() => _picking = false);
    }
  }

  void _removeImage(PlatformFile image) {
    if (_saving) return;
    _set(() => _images = [..._images]..remove(image));
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
    final images = _images;
    _set(() => _saving = true);

    // A PDF, a recording and photos can share one note; all are copied in first.
    final stored = <String>[];
    try {
      String? pdfPath;
      String? voiceStored;
      if (pdf != null) {
        pdfPath = await store.persist(pdf.path!, extension: 'pdf');
        stored.add(pdfPath);
      }
      if (voicePath != null) {
        voiceStored = await store.persist(voicePath, extension: 'm4a');
        stored.add(voiceStored);
      }
      final imagePaths = <String>[];
      for (final image in images) {
        final path = await store.persist(image.path!, extension: AttachmentStore.imageExtension(image.name));
        stored.add(path);
        imagePaths.add(path);
      }
      final source = pdf != null
          ? NoteSource.pdf
          : voicePath != null
          ? NoteSource.voice
          : NoteSource.text;
      final note = await ref
          .read(notesRepoProvider)
          .create(
            projectId: project.id,
            title: text.trim().isEmpty && title.trim().isEmpty ? _fileOnlyTitle(pdf, voiceStored) : title,
            text: text,
            source: source,
            attachmentPath: pdfPath,
            attachmentName: pdf?.name,
            attachmentBytes: pdf != null ? pdfBytes : null,
            voicePath: voiceStored,
            durationMs: voiceStored != null ? voiceMs : null,
            imagePaths: imagePaths,
          );
      // Saved: only now is it safe to drop the temporary recording.
      if (voicePath != null) await AttachmentStore.deleteQuietly([voicePath]);
      await store.clearPickerCopies();
      unawaited(ref.read(noteProcessorProvider).process(note));
      if (!mounted) return;
      _title.clear();
      _text.clear();
      _set(() {
        _voicePath = null;
        _voiceMs = null;
        _pdf = null;
        _images = const [];
      });
      showToast(context, text.trim().isEmpty ? 'اتحفظت' : 'اتحفظت. فِكرة بتحللها دلوقتي');
      context.go('/notes');
    } catch (_) {
      await AttachmentStore.deleteQuietly(stored);
      if (mounted) showToast(context, 'معرفناش نحفظ النوت، جرّب تاني');
    } finally {
      _set(() => _saving = false);
    }
  }

  /// Nothing typed means no analysis, so no AI title will ever come.
  String _fileOnlyTitle(PlatformFile? pdf, String? voice) {
    if (pdf != null) return p.basenameWithoutExtension(pdf.name);
    return voice != null ? 'تسجيل صوتي' : 'صور';
  }

  // ---------------------------------------------------------------- ui

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final focused = _titleFocus.hasFocus || _textFocus.hasFocus;
    // PDF and recording can both be attached; each chip enters on its own.
    final attachments = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FikraSwitcher(
          animateSize: true,
          child: _pdf == null
              ? const SizedBox(key: ValueKey('no-pdf'), width: double.infinity)
              : Padding(
                  key: const ValueKey('pdf'),
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: _PdfChip(name: _pdf!.name, bytes: _pdfBytes, onRemove: _removePdf),
                ),
        ),
        FikraSwitcher(
          animateSize: true,
          child: _voicePath == null
              ? const SizedBox(key: ValueKey('no-voice'), width: double.infinity)
              : Padding(
                  key: ValueKey(_voicePath),
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: VoicePlayer(
                    path: _voicePath!,
                    durationMs: _voiceMs ?? 0,
                    onDelete: _saving ? null : _discardVoice,
                    embedded: true,
                  ),
                ),
        ),
        FikraSwitcher(
          animateSize: true,
          child: _images.isEmpty
              ? const SizedBox(key: ValueKey('no-images'), width: double.infinity)
              : Padding(
                  key: const ValueKey('images'),
                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                  child: _ImageStrip(images: _images, onRemove: _removeImage),
                ),
        ),
      ],
    );

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
                    attachments,
                    _Toolbar(
                      recording: _recording,
                      micEnabled: _voicePath == null && !_saving && !_picking && _rec == _Rec.idle,
                      pdfEnabled: _pdf == null && !_saving && !_picking && _rec == _Rec.idle,
                      imagesEnabled: !_saving && !_picking && _rec == _Rec.idle,
                      canSave: _canSave,
                      saving: _saving,
                      onMic: _startRecording,
                      onPdf: _pickPdf,
                      onImages: _pickImages,
                      onStop: _rec == _Rec.recording ? _stopRecording : null,
                      onCancel: _rec == _Rec.recording ? _cancelRecording : null,
                      onSave: _save,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'النوت بتتحفظ الأول، وبعدين فِكرة بتحلل النص وتربطه. الملفات بتفضل على موبايلك.',
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

/// Bottom row of the composer. Idle: mic, PDF and photos on the start side, save on the
/// end. Recording: cancel + stop.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.recording,
    required this.micEnabled,
    required this.pdfEnabled,
    required this.imagesEnabled,
    required this.canSave,
    required this.saving,
    required this.onMic,
    required this.onPdf,
    required this.onImages,
    required this.onStop,
    required this.onCancel,
    required this.onSave,
  });
  final bool recording;
  final bool micEnabled;
  final bool pdfEnabled;
  final bool imagesEnabled;
  final bool canSave;
  final bool saving;
  final VoidCallback onMic;
  final VoidCallback onPdf;
  final VoidCallback onImages;
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
                    onTap: micEnabled ? onMic : null,
                  ),
                  const SizedBox(width: 6),
                  _ToolButton(
                    key: const ValueKey('add-pdf'),
                    icon: Icons.attach_file_rounded,
                    label: 'إرفاق ملف PDF',
                    onTap: pdfEnabled ? onPdf : null,
                  ),
                  const SizedBox(width: 6),
                  _ToolButton(
                    key: const ValueKey('add-image'),
                    icon: Icons.image_outlined,
                    label: 'إضافة صور',
                    onTap: imagesEnabled ? onImages : null,
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
  const _PdfChip({required this.name, required this.bytes, required this.onRemove});
  final String name;
  final int bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.md,
      color: context.colors.pressed,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: context.colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.text.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(Fmt.bytes(bytes), style: context.text.meta.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
          Pressable(
            onTap: onRemove,
            minTarget: true,
            semanticLabel: 'شيل الملف',
            child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.close_rounded)),
          ),
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.images, required this.onRemove});
  final List<PlatformFile> images;
  final ValueChanged<PlatformFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final image = images[i];
          return SizedBox(
            key: ObjectKey(image),
            width: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoThumb(path: image.path!),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Pressable(
                    onTap: () => onRemove(image),
                    minTarget: true,
                    semanticLabel: 'شيل الصورة ${i + 1}',
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: context.colors.scrim, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 16, color: context.colors.textOnSelected),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
