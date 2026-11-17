import 'package:fikra/l10n/localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../projects/project_header.dart';
import '../shared/attachment_editor.dart';
import '../shared/note_presentation.dart';
import '../shared/transcription_notifications.dart';
import '../../data/attachment_draft.dart';

part 'add_save.dart';

class AddScreen extends ConsumerStatefulWidget {
  const AddScreen({super.key});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen>
    with SingleTickerProviderStateMixin, AttachmentEditing<AddScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _titleFocus = FocusNode();
  final _textFocus = FocusNode();
  late final AnimationController _saveTick = AnimationController.unbounded(vsync: this, value: 0);
  bool _saveTickActive = false;
  Timer? _saveTickTimer;
  int _saveCount = 0;
  bool _clearingDraft = false;

  @override
  bool get isAddComposer => true;

  @override
  void updateDraft(VoidCallback fn) {
    if (!_clearingDraft) _saveCount++;
    super.updateDraft(fn);
  }

  bool get _canSave {
    if (saving || _saveTickActive || recording || picking) return false;
    return hasAttachment || _text.text.trim().isNotEmpty;
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _cancelSaveTick() {
    _saveTickTimer?.cancel();
    _saveTickTimer = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final activeOnAdd = tickerEnabled && (ModalRoute.isCurrentOf(context) ?? true);
    if (!activeOnAdd && _saveTickActive) {
      _saveCount++;
    }
    if (_saveTick.isAnimating && (FikraMotion.reduced(context) || !tickerEnabled)) {
      _saveTick.stop();
      _saveTick.value = 1;
    }
  }

  @override
  void dispose() {
    _cancelSaveTick();
    _saveTick.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectHeader(title: context.l10n.addTitle),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 24 + NavigationInset.of(context)),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              permissionCard(),
              AnimatedContainer(
                duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.enter,
                curve: FikraMotion.enterCurve,
                padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 16, 10),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(FikraRadius.xl),
                  border: Border.all(
                    color: recording
                        ? c.danger.withValues(alpha: 0.55)
                        : focused
                        ? c.accent.withValues(alpha: 0.6)
                        : c.line,
                    width: recording || focused ? 1 : FikraSpace.hairline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _title,
                      readOnly: saving,
                      focusNode: _titleFocus,
                      maxLength: 80,
                      maxLines: 1,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _saveCount++,
                      onSubmitted: (_) => _textFocus.requestFocus(),
                      style: context.text.cardTitleSmall,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: context.l10n.titleOptionalHint,
                        hintStyle: context.text.cardTitleSmall.copyWith(color: c.textSecondary),
                      ),
                    ),
                    Container(height: FikraSpace.hairline, color: c.line),
                    FikraSwitcher(
                      animateSize: true,
                      child: recording
                          ? recordingPreview()
                          : TextField(
                              key: const ValueKey('text'),
                              controller: _text,
                              readOnly: saving,
                              focusNode: _textFocus,
                              minLines: 5,
                              maxLines: 14,
                              maxLength: 5000,
                              onChanged: (_) {
                                _saveCount++;
                                setState(() {});
                              },
                              style: context.text.bodyLarge,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: hasAttachment ? context.l10n.bodyHintWithFileLinks : context.l10n.bodyHint,
                                hintStyle: context.text.bodyLarge.copyWith(color: c.textSecondary),
                              ),
                            ),
                    ),
                    attachmentPreviews(),
                    attachmentToolbar(
                      canSave: _canSave,
                      onSave: _save,
                      saveTick: _saveTick,
                      saveTickActive: _saveTickActive,
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
