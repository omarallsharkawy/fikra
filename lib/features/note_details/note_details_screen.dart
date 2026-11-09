import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/photo_thumb.dart';
import '../../core/widgets/voice_player.dart';
import '../../data/local/database.dart';
import '../shared/note_presentation.dart';
import '../shared/open_attachment.dart';

/// One note: content (improved / original), AI proposal, attachment,
/// concepts and related notes. Data is scoped to the note's own project, so
/// it works even when that isn't the selected project.
class NoteDetailsScreen extends ConsumerStatefulWidget {
  const NoteDetailsScreen({super.key, required this.noteId, this.initial});
  final String noteId;

  /// The note as the caller last saw it. Shown until the live query's first
  /// result, which replaces it without a transition.
  final Note? initial;

  @override
  ConsumerState<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

const _improvedView = 0, _originalView = 1;

class _NoteDetailsScreenState extends ConsumerState<NoteDetailsScreen> {
  int _view = _improvedView;

  Future<void> _showOptions(Note note) {
    final repo = ref.read(notesRepoProvider);
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
              onTap: () async {
                Navigator.pop(sheet);
                await runAction(context, () => repo.restoreOriginal(note.id), success: 'رجعنا النص الأصلي');
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
              if (!ok || !sheet.mounted) return;
              Navigator.pop(sheet);
              if (!mounted) return;
              final deleted = await runAction(context, () => repo.delete(note.id), success: 'النوت اتحذفت');
              if (deleted && mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(noteProvider(widget.noteId));
    final noteAsync = live.hasValue || live.hasError || widget.initial == null
        ? live
        : AsyncData<Note?>(widget.initial);
    final note = noteAsync.value;

    return FikraScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                FikraIconButton(icon: Icons.arrow_back_rounded, label: 'رجوع', onTap: () => context.pop()),
                const Spacer(),
                if (note != null)
                  FikraIconButton(icon: Icons.more_horiz_rounded, label: 'خيارات', onTap: () => _showOptions(note)),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody<Note?>(
              value: noteAsync,
              onRetry: () => ref.invalidate(noteProvider(widget.noteId)),
              data: (note) => note == null
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'النوت مش موجودة',
                      description: 'يمكن تكون اتحذفت.',
                    )
                  : _Body(note: note, view: _view, onView: (v) => setState(() => _view = v)),
            ),
          ),
        ],
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
    final improved = note.hasImprovedVersion;
    final text = improved && view == _originalView ? note.originalContent : note.displayText;

    return ListView(
      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 8, FikraSpace.screen, 32),
      children: [
        Text(noteTitle(note), style: context.text.title.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final icon in sourceIcons(note)) ...[
              Icon(icon, size: 16, color: context.colors.textMeta),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                [Fmt.dayHeader(note.createdAt), Fmt.time(note.createdAt), ?note.cluster].join(' · '),
                style: context.text.meta.copyWith(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FikraSwitcher(
          animateSize: true,
          child: Column(
            key: ValueKey(note.status),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note.status == ProcessingStatus.processing) ...[const _ProcessingCard(), const SizedBox(height: 16)],
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
            ],
          ),
        ),
        if (note.rewrite == RewriteStatus.pending && note.proposedText != null) ...[
          _ProposalCard(note: note, onAccepted: () => onView(_improvedView)),
          const SizedBox(height: 16),
        ],
        if (improved) ...[
          SegmentedPill(options: const ['النسخة المحسّنة', 'الأصل'], selected: view, onChanged: onView),
          const SizedBox(height: 14),
        ],
        if (note.rewrite == RewriteStatus.pending && note.proposedText != null && text.isNotEmpty) ...[
          Text('النص الأصلي', style: context.text.meta.copyWith(fontSize: 12, color: context.colors.textSecondary)),
          const SizedBox(height: 6),
        ],
        if (text.isNotEmpty) SelectableText(text, style: context.text.bodyLarge.copyWith(height: 1.7)),
        if (note.filePaths.isNotEmpty) ...[const SizedBox(height: 16), _Attachment(note: note)],
        if (note.conceptList.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('المفاهيم', style: context.text.section.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final c in note.conceptList) FikraChip(label: c)]),
        ],
        if (note.status == ProcessingStatus.ready) ...[
          const SizedBox(height: 24),
          Text('نوتس مرتبطة', style: context.text.section.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _RelatedNotes(note: note),
        ],
      ],
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.lg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accentLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'فِكرة بتحلل النوت: بتطلّع المفاهيم وبتدوّر على نوتس مرتبطة. النوت نفسها محفوظة.',
              style: context.text.caption,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI rewrite waiting for the user's decision. Buttons lock while saving.
class _ProposalCard extends ConsumerStatefulWidget {
  const _ProposalCard({required this.note, required this.onAccepted});
  final Note note;
  final VoidCallback onAccepted;

  @override
  ConsumerState<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<_ProposalCard> {
  bool _busy = false;

  Future<void> _decide({required bool accept}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(notesRepoProvider);
    final id = widget.note.id;
    final ok = await runAction(context, () => accept ? repo.acceptRewrite(id) : repo.rejectRewrite(id));
    if (ok && accept) widget.onAccepted();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.lg,
      borderColor: context.colors.accentLight.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: context.colors.accentLight),
              const SizedBox(width: 8),
              Expanded(child: Text('اقتراح إعادة صياغة', style: context.text.cardTitleSmall)),
              if (isDemo) const FikraBadge(kind: BadgeKind.demo, label: 'تجريبي'),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.note.proposedText!, style: context.text.body),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FikraButton(
                  label: 'اعتمد',
                  icon: Icons.check_rounded,
                  loading: _busy,
                  onPressed: () => _decide(accept: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FikraButton.secondary(
                  label: 'خلي الأصل',
                  onPressed: _busy ? null : () => _decide(accept: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Attachment extends ConsumerWidget {
  const _Attachment({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = note.attachmentName ?? 'ملف PDF';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (note.hasPdf)
          Pressable(
            key: const ValueKey('open-pdf'),
            onTap: () => openAttachment(context, ref, note.attachmentPath!),
            pressedScale: 0.98,
            semanticLabel: 'افتح ملف $name',
            child: Glass(
              radius: FikraRadius.lg,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined, color: context.colors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name, style: context.text.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (note.attachmentBytes != null) Text(Fmt.bytes(note.attachmentBytes!), style: context.text.meta),
                  const SizedBox(width: 10),
                  Icon(Icons.open_in_new_rounded, size: 18, color: context.colors.textMeta),
                ],
              ),
            ),
          ),
        if (note.hasVoice) VoicePlayer(path: note.voicePath!, durationMs: note.durationMs ?? 0),
        if (note.hasImages) _Photos(paths: note.imageList),
      ],
    );
  }
}

class _Photos extends ConsumerWidget {
  const _Photos({required this.paths});
  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        for (final (i, path) in paths.indexed)
          Pressable(
            key: ValueKey('open-photo-$i'),
            onTap: () => openAttachment(context, ref, path),
            pressedScale: 0.98,
            semanticLabel: 'افتح الصورة ${i + 1}',
            child: PhotoThumb(path: path),
          ),
      ],
    );
  }
}

/// Notes linked to [note] in either direction, one row per other note.
class _RelatedNotes extends ConsumerWidget {
  const _RelatedNotes({required this.note});
  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksOfProjectProvider(note.projectId));
    final notesAsync = ref.watch(notesOfProjectProvider(note.projectId));
    if ((linksAsync.hasError && !linksAsync.hasValue) || (notesAsync.hasError && !notesAsync.hasValue)) {
      return Text('مقدرناش نجيب النوتس المرتبطة دلوقتي.', style: context.text.caption);
    }
    if (!linksAsync.hasValue || !notesAsync.hasValue) return const SizedBox(height: 48);
    final links = linksAsync.value!;
    final notes = notesAsync.value!;
    final byId = {for (final n in notes) n.id: n};

    final related = <String, (Note, NoteLink)>{};
    for (final l in links) {
      if (l.sourceId != note.id && l.targetId != note.id) continue;
      final otherId = l.sourceId == note.id ? l.targetId : l.sourceId;
      final other = byId[otherId];
      if (other != null) related.putIfAbsent(otherId, () => (other, l));
    }

    if (related.isEmpty) return Text('لسه مفيش نوتس شبهها في المشروع ده.', style: context.text.caption);
    return Column(
      children: [
        for (final (other, link) in related.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Pressable(
              pressedScale: 0.98,
              semanticLabel: '${noteTitle(other)}، ${link.label}',
              onTap: () => context.push('/note/${other.id}', extra: other),
              child: Glass(
                radius: FikraRadius.md,
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(noteTitle(other), style: context.text.body.copyWith(fontWeight: FontWeight.w600)),
                          Text(link.label, style: context.text.meta.copyWith(color: context.colors.textLink)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: context.colors.textMeta),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
