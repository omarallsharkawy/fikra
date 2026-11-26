import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../data/product/models.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../workspace/product_widgets.dart';
import '../workspace/project_controls.dart';
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
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients) _follow = _scroll.position.extentAfter < 80;
    });
  }

  void _observe(ConversationController c) {
    final id = c.current?.conversation.id;
    if (_conversation != id) {
      _conversation = id;
      _follow = true;
    }
    final signature = '$id:${c.current?.messages.length}:${c.preview.length}:${c.sendState}';
    if (_signature == signature) return;
    _signature = signature;
    final follow = _follow;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && follow && _scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
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
      final c = r.chat;
      _observe(c);
      return ProductScaffold(
        title: context.l10n.productAsk,
        controller: _scroll,
        footer: c.current == null
            ? null
            : ProductTextInput(
                key: ValueKey('chat-draft-${c.current!.conversation.id}'),
                value: c.draft,
                onChanged: c.updateDraft,
                lines: 2,
                label: context.l10n.productAskThisProject,
                suffix: IconButton.filled(
                  key: const ValueKey('send-chat'),
                  tooltip: context.l10n.productSend,
                  onPressed: c.canSend ? c.send : null,
                  icon: c.sendState == SendState.sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.arrow_upward),
                ),
              ),
        children: [
          ProductProjectControls(runtime: r),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                key: const ValueKey('new-conversation'),
                onPressed: c.loading || c.sendState == SendState.sending ? null : c.create,
                icon: const Icon(Icons.add_comment_outlined),
                label: Text(context.l10n.productNewConversation),
              ),
              TextButton(
                onPressed: c.loading ? null : c.reloadList,
                child: Text(context.l10n.productReloadHistoryList),
              ),
            ],
          ),
          if (c.conversations.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey('conversation-${c.current?.conversation.id}-${c.conversations.length}'),
              initialValue: c.current?.conversation.id,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.l10n.productConversationHistory),
              items: [
                for (final conversation in c.conversations)
                  DropdownMenuItem(
                    value: conversation.id,
                    child: Text(
                      conversation.title ?? context.l10n.productNewConversation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: c.loading || c.sendState == SendState.sending
                  ? null
                  : (id) {
                      if (id != null) c.open(id);
                    },
            ),
          if (c.failure != null) ProductFailureView(c.failure!),
          if (c.loading || c.sendState == SendState.reconciling)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!c.loading && c.current == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                context.l10n.productStartAConversationOrOpenItsHistoryConversations,
                style: context.text.bodyLarge,
              ),
            ),
          if (c.current != null) ...[
            const SizedBox(height: 20),
            for (final message in c.current!.messages) _MessageBubble(message),
            if (c.preview.isNotEmpty)
              SolidSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.productProvisionalNotConfirmedSaved, style: context.text.meta),
                    Text(c.preview, key: const ValueKey('chat-preview'), style: context.text.answer),
                  ],
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
            const SizedBox(height: 20),
            TextButton(
              onPressed: c.loading || c.sendState == SendState.sending
                  ? null
                  : () async {
                      final yes = await confirmDestructive(
                        context,
                        title: context.l10n.productDeleteConversation,
                        message: context.l10n.productThisDeletesTheConversationAndMessagesWhileKeeping,
                        confirmLabel: context.l10n.productDelete,
                      );
                      if (yes && context.mounted) await c.deleteCurrent();
                    },
              child: Text(context.l10n.productDeleteConversation2),
            ),
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
              SelectableText(
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
