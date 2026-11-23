import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../workspace/product_widgets.dart';
import '../workspace/project_controls.dart';
import 'conversation_controller.dart';

class ProductConversationScreen extends StatelessWidget {
  const ProductConversationScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.chat],
    builder: (context, r) {
      final c = r.chat;
      return ProductScaffold(
        title: context.l10n.productAsk,
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
            for (final message in c.current!.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SolidSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.role == 'user' ? context.l10n.productYou : 'FIKRAH', style: context.text.meta),
                      SelectableText(
                        message.content,
                        key: ValueKey('message-${message.id}'),
                        style: context.text.answer,
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
            ProductTextInput(
              key: ValueKey('chat-draft-${c.current!.conversation.id}'),
              value: c.draft,
              onChanged: c.updateDraft,
              lines: 2,
              label: context.l10n.productAskThisProject,
              onSubmitted: (_) => c.send(),
            ),
            FikraButton(
              key: const ValueKey('send-chat'),
              label: context.l10n.productSend,
              loading: c.sendState == SendState.sending,
              onPressed: c.canSend ? c.send : null,
            ),
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
