import 'package:fikra/l10n/localizations.dart';

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

part 'add_files.dart';
part 'add_save.dart';
part 'add_toolbar.dart';
part 'add_voice.dart';
part 'attachment_chips.dart';
part 'mic_permission_card.dart';

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
        ProjectHeader(title: context.l10n.addTitle),
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
                padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 16, 10),
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
                        hintText: context.l10n.titleOptionalHint,
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
                                hintText: _hasAttachment ? context.l10n.bodyHintWithFileLinks : context.l10n.bodyHint,
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
                context.l10n.addFooter,
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
