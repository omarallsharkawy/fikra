import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../add/voice_widgets.dart';
import '../notes/note_card.dart';

class NoteDetailsScreen extends ConsumerStatefulWidget {
  const NoteDetailsScreen({super.key, required this.noteId});
  final String noteId;

  @override
  ConsumerState<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends ConsumerState<NoteDetailsScreen> {
  int _view = 0; // 0 = improved, 1 = original

  Future<void> _more(Note note) {
    return showFikraSheet<void>(
      context,
      title: 'خيارات النوت',
      builder: (sheet) => Column(
        children: [
          SheetOption(
            label: 'تعديل',
            icon: Icons.edit_outlined,
            onTap: () {
              Navigator.pop(sheet);
              context.push('/note/${note.id}/edit');
            },
          ),
          if (note.hasImprovedVersion)
            SheetOption(
              label: 'رجّع النص الأصلي',
              icon: Icons.restore_rounded,
              onTap: () {
                Navigator.pop(sheet);
                ref.read(notesRepoProvider).restoreOriginal(note.id);
                showToast(context, 'رجعنا النص الأصلي');
              },
            ),
          SheetOption(
            label: 'حذف النوت',
            icon: Icons.delete_outline_rounded,
            danger: true,
            onTap: () async {
              final ok = await confirmDestructive(
                sheet,
                title: 'تحذف النوت دي؟',
                message: 'النوت وروابطها هيتحذفوا، ومش هينفع ترجّعها.',
              );
              if (!ok) return;
              if (sheet.mounted) Navigator.pop(sheet);
              await ref.read(notesRepoProvider).delete(note.id);
              if (mounted) {
                context.pop();
                showToast(context, 'النوت اتحذفت');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final note = noteAsync.value;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FikraColors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    _IconBtn(icon: Icons.arrow_back_rounded, label: 'رجوع', onTap: () => context.pop()),
                    const Spacer(),
                    if (note != null)
                      _IconBtn(icon: Icons.more_horiz_rounded, label: 'خيارات', onTap: () => _more(note)),
                  ],
                ),
              ),
              Expanded(
                child: note == null
                    ? (noteAsync.isLoading
                          ? const SizedBox.shrink()
                          : const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'النوت مش موجودة',
                              description: 'يمكن تكون اتحذفت.',
                            ))
                    : _Body(note: note, view: _view, onView: (v) => setState(() => _view = v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.note, required this.view, required this.onView});
  final Note note;
  final int view;
  final ValueChanged<int> onView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepoProvider);
    final improved = note.hasImprovedVersion;
    final text = improved && view == 1 ? note.originalContent : note.displayText;

    final links = (ref.watch(linksProvider).value ?? const <NoteLink>[])
        .where((l) => l.sourceId == note.id || l.targetId == note.id)
        .toList();
    final notesById = {for (final n in ref.watch(notesProvider).value ?? const <Note>[]) n.id: n};
    final related = <(Note, NoteLink)>[
      for (final l in links)
        if (notesById[l.sourceId == note.id ? l.targetId : l.sourceId] case final other?) (other, l),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 8, FikraSpace.screen, 32),
      children: [
        Text(
          note.title.isEmpty ? 'نوت جديدة' : note.title,
          style: FikraText.title.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(sourceIcon(note.source), size: 16, color: FikraColors.textMeta),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                [Fmt.dayHeader(note.createdAt), Fmt.time(note.createdAt), ?note.cluster].join(' · '),
                style: FikraText.meta.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (note.status == ProcessingStatus.processing) ...[
          Glass(
            radius: FikraRadius.lg,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: FikraColors.accentLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'فِكرة بتحلل النوت: بتطلّع المفاهيم وبتدوّر على نوتس مرتبطة. النوت نفسها محفوظة.',
                    style: FikraText.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (note.status == ProcessingStatus.failed) ...[
          const StatusBanner(kind: BannerKind.error, message: 'التحليل فشل، بس النوت محفوظة زي ما هي.'),
          const SizedBox(height: 10),
          FikraButton.secondary(
            label: 'جرّب التحليل تاني',
            icon: Icons.refresh_rounded,
            onPressed: () => ref.read(noteProcessorProvider).retry(note.id),
          ),
          const SizedBox(height: 16),
        ],
        if (note.rewrite == RewriteStatus.pending && note.proposedText != null) ...[
          Glass(
            radius: FikraRadius.lg,
            borderColor: FikraColors.accentLight.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 18, color: FikraColors.accentLight),
                    const SizedBox(width: 8),
                    Expanded(child: Text('اقتراح إعادة صياغة', style: FikraText.cardTitleSmall)),
                    if (isDemo) const FikraBadge(kind: BadgeKind.demo, label: 'تجريبي'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(note.proposedText!, style: FikraText.body),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FikraButton(
                        label: 'اعتمد',
                        icon: Icons.check_rounded,
                        onPressed: () async {
                          await repo.acceptRewrite(note.id);
                          onView(0);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FikraButton.secondary(
                        label: 'سيبها زي ما هي',
                        onPressed: () => repo.rejectRewrite(note.id),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (improved) ...[
          SegmentedPill(options: const ['النسخة المحسّنة', 'الأصل'], selected: view, onChanged: onView),
          const SizedBox(height: 14),
        ],
        if (text.isNotEmpty) SelectableText(text, style: FikraText.bodyLarge.copyWith(height: 1.7)),
        if (note.attachmentPath != null) ...[
          const SizedBox(height: 16),
          if (note.source == NoteSource.voice)
            VoiceReview(path: note.attachmentPath!, durationMs: note.durationMs ?? 0)
          else
            Glass(
              radius: FikraRadius.lg,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined, color: FikraColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note.attachmentName ?? 'ملف PDF',
                      style: FikraText.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (note.attachmentBytes != null) Text(Fmt.bytes(note.attachmentBytes!), style: FikraText.meta),
                ],
              ),
            ),
        ],
        if (note.conceptList.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('المفاهيم', style: FikraText.section.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final c in note.conceptList) FikraChip(label: c)]),
        ],
        if (note.status == ProcessingStatus.ready) ...[
          const SizedBox(height: 24),
          Text('نوتس مرتبطة', style: FikraText.section.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (related.isEmpty)
            Text('لسه مفيش نوتس شبهها في المشروع ده.', style: FikraText.caption)
          else
            for (final (other, link) in related)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Pressable(
                  pressedScale: 0.98,
                  onTap: () => context.push('/note/${other.id}'),
                  child: Glass(
                    radius: FikraRadius.md,
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(other.title, style: FikraText.body.copyWith(fontWeight: FontWeight.w600)),
                              Text(link.label, style: FikraText.meta.copyWith(color: FikraColors.textLink)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: FikraColors.textMeta),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Glass(
        radius: FikraRadius.full,
        width: 44,
        height: 44,
        padding: EdgeInsets.zero,
        child: Icon(icon, size: 22),
      ),
    );
  }
}
