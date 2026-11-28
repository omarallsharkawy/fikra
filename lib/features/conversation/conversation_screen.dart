import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/product/models.dart';
import '../../core/widgets/fikra_widgets.dart';
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
  bool _follow = true;
  bool _scrollScheduled = false;
  ConversationController? _attachedChat;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients) _follow = _scroll.position.extentAfter < 80;
    });
  }

  void _scheduleScrollToBottom() {
    if (!_follow || _scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (mounted && _follow && _scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _onPreviewChanged() => _scheduleScrollToBottom();

  void _observe(ConversationController c) {
    if (!identical(_attachedChat, c)) {
      _attachedChat?.previewListenable.removeListener(_onPreviewChanged);
      _attachedChat = c;
      c.previewListenable.addListener(_onPreviewChanged);
    }
    final id = c.current?.conversation.id;
    if (_conversation != id) {
      _conversation = id;
      _follow = true;
    }
    final signature = '$id:${c.current?.messages.length}:${c.sendState}';
    if (_signature == signature) return;
    _signature = signature;
    _scheduleScrollToBottom();
  }

  @override
  void dispose() {
    _attachedChat?.previewListenable.removeListener(_onPreviewChanged);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.chat],
    builder: (context, r) {
      final c = r.chat;
      _observe(c);
      final messages = c.current?.messages ?? const <KnowledgeMessage>[];
      return ProductScaffold(
        title: context.l10n.productAsk,
        subtitle: r.workspace.projects.any((p) => !p.isGeneral)
            ? context.l10n.uxProjectContext(r.workspace.selected?.name ?? '')
            : null,
        controller: _scroll,
        selectable: true,
        footer: c.current == null
            ? null
            : ValueListenableBuilder<int>(
                valueListenable: c.draftListenable,
                builder: (context, _, _) {
                  final current = c.current;
                  if (current == null) return const SizedBox.shrink();
                  return ProductTextInput(
                    key: ValueKey('chat-draft-${current.conversation.id}'),
                    value: c.draft,
                    onChanged: c.updateDraft,
                    lines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    label: context.l10n.productAskThisProject,
                    suffix: IconButton.filled(
                      key: const ValueKey('send-chat'),
                      tooltip: context.l10n.productSend,
                      onPressed: c.canSend ? c.send : null,
                      icon: c.sendState == SendState.sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_upward),
                    ),
                  );
                },
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const ValueKey('conversation-history'),
              tooltip: context.l10n.uxConversationList,
              onPressed: () => context.push('/conversations'),
              icon: const Icon(Icons.history),
            ),
            IconButton(
              key: const ValueKey('new-conversation'),
              tooltip: context.l10n.productNewConversation,
              onPressed: c.loading || c.sendState == SendState.sending ? null : c.create,
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ],
        ),
        beforeItems: [
          if (r.workspace.failure != null)
            ProductFailureView(r.workspace.failure!, onRetry: r.workspace.retryWorkspace),
          if (c.failure != null) ProductFailureView(c.failure!),
          if (c.loading || c.sendState == SendState.reconciling)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!c.loading && (c.current == null || c.current!.messages.isEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: context.colors.textSecondary),
                  const SizedBox(height: 16),
                  Text(context.l10n.uxEmptyChat, style: context.text.section),
                  const SizedBox(height: 8),
                  Text(context.l10n.uxChatIntro, style: context.text.caption, textAlign: TextAlign.center),
                  if (c.current == null) ...[
                    const SizedBox(height: 20),
                    FikraButton(label: context.l10n.productNewConversation, onPressed: c.create, growForText: true),
                  ],
                ],
              ),
            ),
          if (c.current != null) const SizedBox(height: 20),
        ],
        itemCount: c.current != null ? messages.length : 0,
        itemBuilder: (context, index) => _MessageBubble(messages[index]),
        afterItems: [
          if (c.current != null) ...[
            RepaintBoundary(
              child: ValueListenableBuilder<String>(
                valueListenable: c.previewListenable,
                builder: (context, preview, _) {
                  if (preview.isEmpty) return const SizedBox.shrink();
                  return SolidSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.productProvisionalNotConfirmedSaved, style: context.text.meta),
                        Text(
                          preview,
                          key: const ValueKey('chat-preview'),
                          textDirection: productContentDirection(preview),
                          style: context.text.answer,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (c.sendState == SendState.sending)
              TextButton(onPressed: c.interrupt, child: Text(context.l10n.productStopWaiting)),
            if (c.sendState == SendState.uncertain)
              FikraButton.secondary(
                key: const ValueKey('reconcile-chat'),
                label: context.l10n.productReloadHistoryBeforeSendingAgain,
                growForText: true,
                onPressed: c.reconcile,
              ),
            if (c.sendState == SendState.reviewed)
              Text(context.l10n.productHistoryReloadedReviewItBeforeDeliberatelySendingYour),
          ],
        ],
      );
    },
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble(this.message);
  final KnowledgeMessage message;
  @override
  Widget build(BuildContext context) {
    final user = message.role == 'user';
    final ink = user ? context.colors.onBrandBlue : context.colors.textPrimary;
    return Align(
      alignment: user ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: .92,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: user ? context.colors.brandBlue : context.colors.surface,
            border: user ? null : Border.all(color: context.colors.line),
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(22),
              topEnd: const Radius.circular(22),
              bottomStart: Radius.circular(user ? 22 : 6),
              bottomEnd: Radius.circular(user ? 6 : 22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user ? context.l10n.productYou : 'FIKRAH', style: context.text.meta.copyWith(color: ink)),
              Text(
                message.content,
                textDirection: productContentDirection(message.content),
                key: ValueKey('message-${message.id}'),
                style: context.text.answer.copyWith(color: ink),
              ),
              if (message.supported == false)
                Text(context.l10n.productNotSupportedByThisProjectSKnowledge, style: context.text.meta),
              for (final source in message.sources)
                TextButton.icon(
                  onPressed: () => context.push('/note/${source.noteId}'),
                  icon: const Icon(Icons.description_outlined),
                  label: Text(productTitle(context, source.title)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductConversationHistoryScreen extends StatelessWidget {
  const ProductConversationHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.chat],
    builder: (context, r) {
      final c = r.chat;
      final locked = c.loading || c.sendState == SendState.sending;
      return ProductScaffold(
        title: context.l10n.uxConversationList,
        subtitle: r.workspace.projects.any((p) => !p.isGeneral)
            ? context.l10n.uxProjectContext(r.workspace.selected?.name ?? '')
            : null,
        back: true,
        trailing: IconButton(
          tooltip: context.l10n.productReloadHistoryList,
          onPressed: locked ? null : c.reloadList,
          icon: const Icon(Icons.refresh),
        ),
        beforeItems: [
          FikraButton.secondary(
            key: const ValueKey('new-from-history'),
            label: context.l10n.productNewConversation,
            growForText: true,
            onPressed: locked
                ? null
                : () async {
                    final previous = c.current?.conversation.id;
                    await c.create();
                    if (context.mounted && c.current != null && c.current!.conversation.id != previous) context.pop();
                  },
          ),
          const SizedBox(height: 16),
          if (c.failure != null) ProductFailureView(c.failure!, onRetry: c.reloadList),
          if (c.loading) const Center(child: CircularProgressIndicator()),
          if (!c.loading && c.conversations.isEmpty) Text(context.l10n.uxNoConversations, style: context.text.caption),
        ],
        itemCount: c.conversations.length,
        itemBuilder: (context, index) {
          final conversation = c.conversations[index];
          return Card(
            child: ListTile(
              key: ValueKey('open-conversation-${conversation.id}'),
              enabled: !locked,
              selected: c.current?.conversation.id == conversation.id,
              leading: Icon(
                c.current?.conversation.id == conversation.id
                    ? Icons.check_circle_outline
                    : Icons.chat_bubble_outline,
              ),
              title: Text(conversation.title ?? context.l10n.productNewConversation),
              onTap: () async {
                await c.open(conversation.id);
                if (context.mounted && c.failure == null && c.current?.conversation.id == conversation.id) {
                  context.pop();
                }
              },
            ),
          );
        },
        afterItems: [
          if (c.current != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.productDeleteConversation2),
              onPressed: locked
                  ? null
                  : () async {
                      final id = c.current!.conversation.id;
                      final yes = await confirmDestructive(
                        context,
                        title: context.l10n.productDeleteConversation,
                        message: context.l10n.productThisDeletesTheConversationAndMessagesWhileKeeping,
                        confirmLabel: context.l10n.productDelete,
                      );
                      if (yes && context.mounted && c.current?.conversation.id == id) await c.deleteCurrent();
                    },
            ),
          ],
        ],
      );
    },
  );
}
