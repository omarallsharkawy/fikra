import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../workspace/product_widgets.dart';
import 'conversation_controller.dart';

export 'redesign_conversation_screen.dart' show ProductConversationScreen;

class ProductConversationHistoryScreen extends StatelessWidget {
  const ProductConversationHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.chat],
    builder: (context, r) {
      final c = r.chat;
      final locked = c.loading || c.sendState == SendState.sending;
      return RdPage(
        title: context.l10n.rdHist,
        back: () => context.canPop() ? context.pop() : context.go('/ask'),
        trailing: RdIconButton(
          're',
          label: context.l10n.productReloadHistoryList,
          onPressed: locked ? null : c.reloadList,
        ),
        children: [
          RdButton(
            context.l10n.rdNewc,
            primary: false,
            key: const ValueKey('new-from-history'),
            onPressed: locked
                ? null
                : () async {
                    final previous = c.current?.conversation.id;
                    await c.create();
                    if (context.mounted && c.current != null && c.current!.conversation.id != previous) context.pop();
                  },
          ),
          const SizedBox(height: 16),
          if (c.failure != null) ProductFailureView(c.failure!),
          if (c.loading) const Center(child: CircularProgressIndicator()),
          if (!c.loading && c.conversations.isEmpty) RdText(context.l10n.uxNoConversations, color: context.rd.muted),
          for (final conversation in c.conversations)
            RdCard(
              padding: 0,
              child: ListTile(
                key: ValueKey('open-conversation-${conversation.id}'),
                enabled: !locked,
                selected: c.current?.conversation.id == conversation.id,
                leading: Icon(
                  c.current?.conversation.id == conversation.id
                      ? Icons.check_circle_outline
                      : Icons.chat_bubble_outline,
                ),
                title: RdText(conversation.title ?? context.l10n.rdNewc),
                onTap: () async {
                  await c.open(conversation.id);
                  if (context.mounted && c.failure == null && c.current?.conversation.id == conversation.id) {
                    context.pop();
                  }
                },
              ),
            ),
          if (c.current != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(context.l10n.productDeleteConversation2),
              onPressed: locked
                  ? null
                  : () async {
                      final id = c.current!.conversation.id;
                      final yes = await rdConfirm(
                        context,
                        title: context.l10n.productDeleteConversation,
                        message: context.l10n.productThisDeletesTheConversationAndMessagesWhileKeeping,
                        confirm: context.l10n.productDelete,
                        danger: true,
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
