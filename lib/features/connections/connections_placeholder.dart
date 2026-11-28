import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../shared/note_presentation.dart';
import 'links_index.dart';

/// The same reserved title/preview geometry before and after the live note loads.
class ConnectionsNoteHeader extends StatelessWidget {
  const ConnectionsNoteHeader({super.key, this.note});
  final LibraryNote? note;

  @override
  Widget build(BuildContext context) {
    final caption = context.text.caption;
    final line = MediaQuery.textScalerOf(context).scale(caption.fontSize!) * (caption.height ?? 1);
    return SolidSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (note case final n?)
            SmartText(
              noteTitleText(context, n.title),
              style: context.text.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            SizedBox(
              height:
                  MediaQuery.textScalerOf(context).scale(context.text.body.fontSize!) * (context.text.body.height ?? 1),
              child: const Align(alignment: AlignmentDirectional.centerStart, child: _Shape(width: 180, height: 14)),
            ),
          const SizedBox(height: 4),
          SizedBox(
            height: line * 2,
            child: note == null
                ? const Align(alignment: AlignmentDirectional.topStart, child: _Shape(width: 240, height: 12))
                : SmartText(note!.text, style: caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class ConnectionsSectionPlaceholder extends StatelessWidget {
  const ConnectionsSectionPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: SolidSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Shape(width: 160, height: 14),
            SizedBox(height: 16),
            _Shape(width: double.infinity, height: 12),
            SizedBox(height: 16),
            _Shape(width: 200, height: 12),
          ],
        ),
      ),
    ),
  );
}

class _Shape extends StatelessWidget {
  const _Shape({required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: context.colors.chip, borderRadius: BorderRadius.circular(FikraRadius.sm)),
  );
}
