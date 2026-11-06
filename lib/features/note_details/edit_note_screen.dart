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
  bool _saving = false;

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
      context.pop();
      showToast(context, 'التعديل اتحفظ');
    } catch (_) {
      if (mounted) showToast(context, 'معرفناش نحفظ التعديل، جرّب تاني');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(noteProvider(widget.noteId)).value;
    if (note != null && _title == null) {
      _title = TextEditingController(text: note.title);
      _text = TextEditingController(text: note.displayText);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FikraColors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: note == null || _title == null
              ? const SizedBox.shrink()
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
                      child: TextField(
                        controller: _text,
                        minLines: 8,
                        maxLines: 20,
                        maxLength: 5000,
                        style: FikraText.bodyLarge,
                        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
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
                    FikraButton.secondary(label: 'إلغاء', onPressed: () => context.pop()),
                  ],
                ),
        ),
      ),
    );
  }
}
