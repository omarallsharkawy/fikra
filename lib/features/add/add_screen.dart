import 'package:fikra/l10n/localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../projects/project_header.dart';
import '../shared/attachment_editor.dart';
import '../shared/note_presentation.dart';
import '../../data/attachment_draft.dart';

part 'add_save.dart';

class AddScreen extends ConsumerStatefulWidget {
  const AddScreen({super.key});

  @override
  ConsumerState<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends ConsumerState<AddScreen> with AttachmentEditing<AddScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _titleFocus = FocusNode();
  final _textFocus = FocusNode();

  bool get _canSave {
    if (saving || recording || picking) return false;
    return hasAttachment || _text.text.trim().isNotEmpty;
  }

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void dispose() {
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
            padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              permissionCard(),
              AnimatedContainer(
                duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.enter,
                curve: FikraMotion.enterCurve,
                padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 16, 10),
                decoration: BoxDecoration(
                  gradient: c.glassGradient,
                  borderRadius: BorderRadius.circular(FikraRadius.xl),
                  border: Border.all(
                    color: recording
                        ? c.danger.withValues(alpha: 0.55)
                        : focused
                        ? c.borderFocus.withValues(alpha: 0.6)
                        : c.border,
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
                              onChanged: (_) => setState(() {}),
                              style: context.text.bodyLarge,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: hasAttachment ? context.l10n.bodyHintWithFileLinks : context.l10n.bodyHint,
                                hintStyle: context.text.bodyLarge.copyWith(color: c.textPlaceholder),
                              ),
                            ),
                    ),
                    attachmentPreviews(),
                    attachmentToolbar(canSave: _canSave, onSave: _save),
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
