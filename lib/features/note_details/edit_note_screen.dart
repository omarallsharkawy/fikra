import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';

class EditNoteScreen extends ConsumerStatefulWidget {
  const EditNoteScreen({super.key, required this.noteId});
  final String noteId;

  @override
  ConsumerState<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends ConsumerState<EditNoteScreen> {
  TextEditingController? _title;
  TextEditingController? _text;
  String _initialTitle = '';
  String _initialText = '';
  bool _saving = false;
  bool _allowPop = false;

  bool get _dirty => _title != null && (_title!.text != _initialTitle || _text!.text != _initialText);

  @override
  void dispose() {
    _title?.dispose();
    _text?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(notesRepoProvider).edit(widget.noteId, title: _title!.text, text: _text!.text);
      if (!mounted) return;
      showToast(context, 'التعديل اتحفظ');
      _exit();
    } catch (_) {
      if (mounted) showToast(context, 'معرفناش نحفظ التعديل، جرّب تاني');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Leaves the screen, bypassing the unsaved-changes guard.
  void _exit() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  /// Back or Cancel: ask before throwing away unsaved edits.
  Future<void> _requestLeave() async {
    if (_saving) return;
    if (!_dirty) return _exit();
    final choice = await showFikraSheet<_Leave>(
      context,
      title: 'عندك تعديلات مش محفوظة',
      builder: (sheet) => Column(
        children: [
          SheetOption(label: 'احفظ التعديل', icon: Icons.check_rounded, onTap: () => Navigator.pop(sheet, _Leave.save)),
          SheetOption(
            label: 'اخرج من غير حفظ',
            icon: Icons.close_rounded,
            danger: true,
            onTap: () => Navigator.pop(sheet, _Leave.discard),
          ),
          SheetOption(label: 'كمّل تعديل', icon: Icons.edit_outlined, onTap: () => Navigator.pop(sheet, _Leave.stay)),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _Leave.save:
        await _save();
      case _Leave.discard:
        _exit();
      case _Leave.stay || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final note = noteAsync.value;
    if (note != null && _title == null) {
      _initialTitle = note.title;
      _initialText = note.displayText;
      _title = TextEditingController(text: _initialTitle);
      _text = TextEditingController(text: _initialText);
    }

    return PopScope(
      canPop: _allowPop || _title == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestLeave();
      },
      child: FikraScaffold(
        child: noteAsync.hasError && !noteAsync.hasValue
            ? LoadErrorView(onRetry: () => ref.invalidate(noteProvider(widget.noteId)))
            : note == null || _title == null
            ? (noteAsync.hasValue
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'النوت مش موجودة',
                      description: 'يمكن تكون اتحذفت.',
                    )
                  : const SizedBox.shrink())
            : ListView(
                padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 14, FikraSpace.screen, 24),
                children: [
                  Text('تعديل النوت', style: FikraText.title.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  FikraField(controller: _title, hint: 'العنوان', icon: Icons.title_rounded, maxLength: 80),
                  const SizedBox(height: 12),
                  Glass(
                    radius: FikraRadius.lg,
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                    child: Semantics(
                      label: 'نص النوت',
                      child: TextField(
                        controller: _text,
                        minLines: 8,
                        maxLines: 20,
                        maxLength: 5000,
                        style: FikraText.bodyLarge,
                        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    note.source == NoteSource.text
                        ? 'النص الأصلي بيفضل محفوظ، وتقدر ترجّعه من خيارات النوت.'
                        : 'التفريغ الأصلي بيفضل محفوظ، وتقدر ترجّعه من خيارات النوت.',
                    style: FikraText.meta.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                  FikraButton(label: 'حفظ التعديل', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
                  const SizedBox(height: 10),
                  FikraButton.secondary(label: 'إلغاء', onPressed: _saving ? null : _requestLeave),
                ],
              ),
      ),
    );
  }
}

enum _Leave { save, discard, stay }
