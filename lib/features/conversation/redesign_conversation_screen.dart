import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/navigation_inset.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../data/product/models.dart';
import '../../l10n/localizations.dart';
import '../workspace/product_widgets.dart';
import 'conversation_controller.dart';

class ProductConversationScreen extends StatefulWidget {
  const ProductConversationScreen({super.key});
  @override
  State<ProductConversationScreen> createState() => _ProductConversationScreenState();
}

class _ProductConversationScreenState extends State<ProductConversationScreen> {
  final _scroll = ScrollController();
  String? _conversation, _signature;
  bool _follow = true, _starting = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients) _follow = _scroll.position.extentAfter < 80;
    });
  }

  void _observe(ConversationController c) {
    final id = c.current?.conversation.id;
    final changed = _conversation != id;
    if (changed) {
      _conversation = id;
      _follow = true;
    }
    final signature =
        '$id:${c.current?.messages.length}:${c.preview.length}:${c.sendState}:${MediaQuery.viewInsetsOf(context).bottom}';
    if (_signature == signature) return;
    _signature = signature;
    final follow = _follow;
    final hasMessages = (c.current?.messages.isNotEmpty ?? false) || c.preview.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (changed && !hasMessages) {
        _scroll.jumpTo(0);
      } else if (follow && hasMessages) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _ask(ConversationController c, String question) async {
    if (_starting ||
        c.loading ||
        c.sendState == SendState.sending ||
        c.sendState == SendState.uncertain ||
        c.sendState == SendState.reconciling) {
      return;
    }
    final account = c.accountId, project = c.projectId;
    setState(() => _starting = true);
    try {
      if (c.current == null) {
        c.updateDraft(question);
        await c.create();
      }
      if (!mounted || c.accountId != account || c.projectId != project || c.current == null) return;
      c.updateDraft(question);
      if (c.canSend) await c.send();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.chat],
    builder: (context, r) {
      final c = r.chat, w = r.workspace, l = context.l10n;
      _observe(c);
      final locked =
          _starting ||
          c.loading ||
          c.sendState == SendState.sending ||
          c.sendState == SendState.uncertain ||
          c.sendState == SendState.reconciling;
      final empty = c.current == null || c.current!.messages.isEmpty;
      final scope = w.projects.any((p) => !p.isGeneral)
          ? l.uxProjectContext(rdIsolate(w.selected?.name ?? ''))
          : l.rdScope;
      final children = <Widget>[
        Padding(padding: const EdgeInsets.only(bottom: 12), child: RdChip(scope, small: true)),
        if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
        if (c.failure != null)
          ProductFailureView(c.failure!, onRetry: c.sendState == SendState.uncertain ? c.reconcile : c.reloadList),
        if (c.loading || c.sendState == SendState.reconciling)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!c.loading && empty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 36),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: context.rd.purpleSoft, borderRadius: BorderRadius.circular(18)),
                  child: Center(child: RdIcon('spark', color: context.rd.purple)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: RdText(
                    l.rdHello(w.notes.length),
                    size: 19,
                    weight: FontWeight.w700,
                    color: context.rd.text,
                    align: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final q in [l.rdChips0, l.rdChips1, l.rdChips2])
                        _ConversationChip(
                          q,
                          size: 14,
                          color: context.rd.muted,
                          onTap: locked ? null : () => _ask(c, q),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (c.current != null) ...[
          for (final message in c.current!.messages) _MessageBubble(message),
          if (c.preview.isNotEmpty) _MessageBubble.preview(c.preview),
          if (c.sendState == SendState.sending) TextButton(onPressed: c.interrupt, child: Text(l.productStopWaiting)),
          if (c.sendState == SendState.uncertain)
            RdButton(
              l.rdCheckConversation,
              key: const ValueKey('reconcile-chat'),
              primary: false,
              onPressed: c.reconcile,
            ),
          if (c.sendState == SendState.reviewed) RdText(l.rdReviewConversation, size: 13, color: context.rd.muted),
        ],
      ];
      final visibleHeight =
          MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom -
          MediaQuery.paddingOf(context).vertical;
      final lineHeight = MediaQuery.textScalerOf(context).scale(15) * 1.6;
      final composerLines = ((visibleHeight - 68 - 46 - 80) / lineHeight).floor().clamp(1, 5);
      return RdPage(
        title: l.rdAsktt,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            RdIconButton(
              'hist',
              key: const ValueKey('conversation-history'),
              label: l.rdHist,
              onPressed: () => context.push('/conversations'),
            ),
            RdIconButton(
              'plus',
              key: const ValueKey('new-conversation'),
              label: l.rdNewc,
              onPressed: locked ? null : c.create,
            ),
          ],
        ),
        body: ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + (c.current == null ? NavigationInset.of(context) : 0)),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: children,
        ),
        footer: c.current == null
            ? null
            : NavigationInsetPadding(
                child: _ChatComposer(
                  key: ValueKey('chat-draft-${c.current!.conversation.id}'),
                  controller: c,
                  maxLines: composerLines,
                ),
              ),
      );
    },
  );
}

class _ConversationChip extends StatelessWidget {
  const _ConversationChip(this.label, {this.size = 13, this.onTap, this.small = false, this.color});
  final String label;
  final double size;
  final VoidCallback? onTap;
  final bool small;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
    color: small ? context.rd.purpleSoft : context.rd.surface2,
    shape: StadiumBorder(side: BorderSide(color: context.rd.line)),
    child: InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: small ? 11 : 13, vertical: 4),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: RdText(label, size: size, color: color, align: TextAlign.center),
          ),
        ),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(this.message) : preview = null;
  const _MessageBubble.preview(this.preview) : message = null;
  final KnowledgeMessage? message;
  final String? preview;
  @override
  Widget build(BuildContext context) {
    final user = message?.role == 'user', l = context.l10n, streaming = message == null;
    final sources = <String, NoteSourceReference>{
      for (final source in message?.sources ?? const <NoteSourceReference>[]) source.noteId: source,
    };
    return Align(
      alignment: user
          ? (rdDirection(message!.content) == TextDirection.ltr ? Alignment.centerRight : Alignment.centerLeft)
          : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: .88,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: user
              ? BoxDecoration(color: context.rd.surface2, borderRadius: BorderRadius.circular(18))
              : ShapeDecoration(color: context.rd.surface, shape: _AssistantBorder(context.rd.line, context.rd.purple)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RdText(
                message?.content ?? preview!,
                selectable: true,
                key: ValueKey(streaming ? 'chat-preview' : 'message-${message!.id}'),
              ),
              if (streaming)
                Semantics(liveRegion: true, child: RdText(l.rdReplying, size: 13, color: context.rd.muted)),
              if (message?.supported == false)
                RdText(l.productNotSupportedByThisProjectSKnowledge, size: 13, color: context.rd.muted),
              if (sources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _ConversationChip(l.rdBased(sources.length), small: true, size: 12),
                      for (final source in sources.values)
                        Semantics(
                          key: ValueKey('chat-source-${source.noteId}'),
                          label: source.title ?? l.rdUntitled,
                          child: _ConversationChip(
                            (source.title ?? l.rdUntitled).characters.take(14).toString(),
                            onTap: () => context.push('/note/${source.noteId}'),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CSS uses a 3px logical-start border and 1px elsewhere. Flutter's stock
/// rounded BoxBorder cannot paint different side colors, so paint its ring.
class _AssistantBorder extends ShapeBorder {
  const _AssistantBorder(this.line, this.purple, [this.factor = 1]);
  final Color line, purple;
  final double factor;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsetsDirectional.fromSTEB(3 * factor, factor, factor, factor);
  RRect _outer(Rect r) => RRect.fromRectAndRadius(r, Radius.circular(18 * factor));
  RRect _inner(Rect r, bool rtl) {
    final left = (rtl ? 1 : 3) * factor, right = (rtl ? 3 : 1) * factor;
    return RRect.fromRectAndCorners(
      Rect.fromLTRB(r.left + left, r.top + factor, r.right - right, r.bottom - factor),
      topLeft: Radius.elliptical(18 * factor - left, 17 * factor),
      bottomLeft: Radius.elliptical(18 * factor - left, 17 * factor),
      topRight: Radius.elliptical(18 * factor - right, 17 * factor),
      bottomRight: Radius.elliptical(18 * factor - right, 17 * factor),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRRect(_outer(rect));
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_inner(rect, textDirection == TextDirection.rtl));
  @override
  ShapeBorder scale(double t) => _AssistantBorder(line, purple, factor * t);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.save();
    if (textDirection == TextDirection.rtl) {
      canvas.translate(rect.left + rect.right, 0);
      canvas.scale(-1, 1);
    }
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(_outer(rect))
      ..addRRect(_inner(rect, false));
    canvas.drawPath(ring, Paint()..color = line);
    canvas.clipRect(Rect.fromLTRB(rect.left, rect.top, rect.center.dx, rect.bottom));
    canvas.clipPath(
      Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.left + rect.height * 1.5, rect.center.dy)
        ..lineTo(rect.left, rect.bottom)
        ..close(),
      doAntiAlias: true,
    );
    canvas.drawPath(ring, Paint()..color = purple);
    canvas.restore();
  }
}

class _ChatComposer extends StatefulWidget {
  const _ChatComposer({super.key, required this.controller, required this.maxLines});
  final int maxLines;
  final ConversationController controller;
  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  late final _text = TextEditingController(text: widget.controller.draft);
  @override
  void didUpdateWidget(_ChatComposer old) {
    super.didUpdateWidget(old);
    final value = widget.controller.draft;
    if (_text.text != value) {
      _text.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 6, 4),
      decoration: BoxDecoration(
        color: context.rd.surface,
        border: Border.all(color: context.rd.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('chat-question'),
              controller: _text,
              onChanged: c.updateDraft,
              textDirection: rdDirection(_text.text, Directionality.of(context)),
              style: RdTokens.style(context),
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: widget.maxLines,
              decoration: InputDecoration(
                hintText: context.l10n.rdPh,
                hintStyle: RdTokens.style(context, color: context.rd.muted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.canSend ? context.rd.lime : context.rd.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: RdIconButton(
              'send',
              key: const ValueKey('send-chat'),
              label: context.l10n.productSend,
              color: c.canSend ? context.rd.onLime : context.rd.muted,
              onPressed: c.canSend ? c.send : null,
            ),
          ),
        ],
      ),
    );
  }
}
