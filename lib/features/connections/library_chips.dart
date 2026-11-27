import '../../core/widgets/smart_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../shared/group_form.dart';
import '../../data/local/database.dart';
import '../../l10n/localizations.dart';
import '../shared/group_filter.dart';
import '../shared/group_options.dart';
import 'links_index.dart';

class LibraryChips extends ConsumerWidget {
  const LibraryChips({super.key, required this.index, required this.groups, required this.chip, required this.onChip});
  final LinksIndex index;
  final List<NoteGroup> groups;
  final LibraryChip chip;
  final ValueChanged<LibraryChip> onChip;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (groups.isNotEmpty) ...[
        _heading(context, context.l10n.linksGroups),
        GroupFilterRow(
          groups: groups,
          selectedId: chip.group,
          counts: index.groupCounts,
          clearSelectedChild: true,
          onSelect: (id) => onChip((group: id, topic: null)),
          onOptions: (group) => showGroupOptions(context, ref, group),
        ),
      ],
      if (index.topicCounts.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(FikraSpace.screen, 12, FikraSpace.screen, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 2,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: SmartText(
                  context.l10n.topicsHeader,
                  content: ReadOnlyContent.chrome,
                  style: context.text.section,
                ),
              ),
              SmartText(context.l10n.linksSuggestedForYou, content: ReadOnlyContent.chrome, style: context.text.meta),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
          child: Row(
            children: [
              for (final topic in index.topicCounts.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: ChoiceTag(
                      key: ValueKey('topic-filter-${topic.key}'),
                      label: '${topic.key} ${topic.value}',
                      selected: chip.topic == topic.key,
                      onTap: () => onChip((group: null, topic: chip.topic == topic.key ? null : topic.key)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
    ],
  );

  Widget _heading(BuildContext context, String title) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(FikraSpace.screen, 12, FikraSpace.screen, 4),
    child: Semantics(header: true, child: SmartText(title, style: context.text.section)),
  );
}
