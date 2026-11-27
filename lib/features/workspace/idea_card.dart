import 'package:flutter/material.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';
import 'local_tags_controller.dart';

class ProductIdeaCard extends StatelessWidget {
  const ProductIdeaCard({
    super.key,
    required this.title,
    required this.content,
    required this.onOpen,
    this.tags = const [],
    this.processing = false,
  });
  final String title, content;
  final VoidCallback onOpen;
  final List<LocalTag> tags;
  final bool processing;
  @override
  Widget build(BuildContext context) => RdCard(
    onTap: onOpen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(child: RdText(title, weight: FontWeight.w600)),
            if (processing) ProcessingDot(label: context.l10n.rdProc),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: RdText(content, size: 13.5, color: context.rd.muted, lines: 2),
        ),
        if (tags.isNotEmpty)
          Wrap(spacing: 6, runSpacing: 6, children: [for (final t in tags.take(3)) RdChip(t.label, small: true)]),
      ],
    ),
  );
}

class ProcessingDot extends StatefulWidget {
  const ProcessingDot({super.key, required this.label});
  final String label;
  @override
  State<ProcessingDot> createState() => _ProcessingDotState();
}

class _ProcessingDotState extends State<ProcessingDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final _opacity = Tween<double>(
    begin: 1,
    end: .25,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    child: FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: context.rd.purple, shape: BoxShape.circle),
      ),
    ),
  );
}
