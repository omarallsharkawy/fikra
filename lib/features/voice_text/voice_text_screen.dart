import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../shared/inline_recorder.dart';
import 'voice_text_controller.dart';
import 'voice_text_copy.dart';
import 'voice_text_models.dart';
import 'voice_text_providers.dart';
import 'voice_text_recording.dart';
import 'voice_text_result.dart';
import 'whisper_metrics.dart';

class VoiceTextScreen extends ConsumerWidget {
  const VoiceTextScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(voiceTextControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final l = context.l10n;
        Future<void> act(Future<void> Function() action) async {
          await action();
          if (context.mounted && c.issue != null) showToast(context, issueMessage(context.l10n, c.issue!));
        }

        Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: FikraSpace.s24, bottom: FikraSpace.s10),
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.section.copyWith(fontWeight: FontWeight.w600)),
          ),
        );
        Future<void> language() => showFikraSheet<void>(
          context,
          title: l.vtLanguage,
          builder: (sheet) => Column(
            children: [
              for (final entry in [('ar', l.languageArabic), ('en', l.languageEnglish), ('auto', l.vtAutomatic)])
                VoiceTextChoice(
                  label: entry.$2,
                  selected: c.language == entry.$1,
                  onTap: () {
                    c.chooseLanguage(entry.$1);
                    Navigator.pop(sheet);
                  },
                ),
            ],
          ),
        );
        Future<void> advanced() => showFikraSheet<void>(
          context,
          title: l.vtAdvanced,
          builder: (sheet) => Column(
            children: [
              for (final threads in [2, 4, 6])
                VoiceTextChoice(
                  label: l.vtThreads('$threads'),
                  selected: c.threads == threads,
                  onTap: () {
                    c.chooseThreads(threads);
                    Navigator.pop(sheet);
                  },
                ),
            ],
          ),
        );
        final live = c.phase == VoiceTextPhase.live;
        return PopScope(
          canPop: !c.locked,
          onPopInvokedWithResult: (popped, _) {
            if (!popped) showToast(context, l.vtWait);
          },
          child: FikraScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(FikraSpace.s12, FikraSpace.s8, FikraSpace.s12, FikraSpace.s4),
                  child: Row(
                    children: [
                      FikraIconButton(
                        icon: Icons.arrow_back_rounded,
                        label: l.back,
                        onTap: c.locked ? () => showToast(context, l.vtWait) : () => context.pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    key: const ValueKey('vt-scroll'),
                    padding: const EdgeInsets.fromLTRB(
                      FikraSpace.screen,
                      FikraSpace.s8,
                      FikraSpace.screen,
                      FikraSpace.s32,
                    ),
                    children: [
                      Text(l.vtTitle, style: context.text.title.copyWith(fontWeight: FontWeight.w700)),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FikraBadge(kind: BadgeKind.demo, label: l.vtExperimental),
                      ),
                      const SizedBox(height: FikraSpace.s12),
                      Text(l.vtIntro, style: context.text.body),
                      if (c.issue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: FikraSpace.s12),
                          child: Semantics(
                            liveRegion: true,
                            child: StatusBanner(kind: BannerKind.error, message: issueMessage(l, c.issue!)),
                          ),
                        ),
                      if (c.phase == VoiceTextPhase.loading ||
                          c.phase == VoiceTextPhase.starting ||
                          c.phase == VoiceTextPhase.stopping)
                        Padding(
                          padding: const EdgeInsets.only(top: FikraSpace.s12),
                          child: VoiceTextProgress(label: l.vtWait),
                        ),
                      section(l.vtModel),
                      VoiceTextModels(controller: c, act: act),
                      section(l.vtLanguage),
                      IgnorePointer(
                        ignoring: !c.idle,
                        child: ExcludeSemantics(
                          excluding: !c.idle,
                          child: SheetOption(
                            key: const ValueKey('vt-language'),
                            label: switch (c.language) {
                              'ar' => l.languageArabic,
                              'en' => l.languageEnglish,
                              _ => l.vtAutomatic,
                            },
                            icon: Icons.language_rounded,
                            onTap: language,
                          ),
                        ),
                      ),
                      section(l.recordVoice),
                      VoiceTextRecording(controller: c, act: act),
                      const SizedBox(height: FikraSpace.s16),
                      FikraButton(
                        key: const ValueKey('vt-transcribe'),
                        label: c.phase == VoiceTextPhase.transcribing ? l.vtWorking : l.vtTranscribe,
                        growForText: true,
                        icon: Icons.text_fields_rounded,
                        onPressed: c.idle && c.selected != null && c.downloaded ? () => act(c.transcribe) : null,
                      ),
                      const SizedBox(height: FikraSpace.s8),
                      Text(l.vtCannotCancel, style: context.text.caption),
                      if (c.phase == VoiceTextPhase.transcribing) ...[
                        const SizedBox(height: FikraSpace.s12),
                        VoiceTextProgress(key: const ValueKey('vt-working'), label: l.vtWorking),
                      ],
                      if (c.history.isNotEmpty) ...[section(l.vtResult), VoiceTextResult(run: c.history.first)],
                      section(l.vtLive),
                      Text(l.vtLiveHint, style: context.text.caption),
                      if (live) ...[
                        InlineRecorder(
                          levels: List.of(c.levels),
                          elapsed: c.elapsed,
                          max: VoiceTextController.maxRecording,
                        ),
                        SelectableText(
                          c.partial,
                          style: context.text.bodyLarge,
                          textDirection: containsArabic(c.partial) ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ],
                      const SizedBox(height: FikraSpace.s12),
                      FikraButton.secondary(
                        key: const ValueKey('vt-live'),
                        label: live ? l.stopRecording : l.vtLiveStart,
                        growForText: true,
                        icon: live ? Icons.stop_rounded : Icons.mic_none_rounded,
                        onPressed: live
                            ? () => act(c.stop)
                            : (c.idle && c.downloaded ? () => act(() => c.start(live: true)) : null),
                      ),
                      section(l.vtAdvanced),
                      IgnorePointer(
                        ignoring: !c.idle,
                        child: ExcludeSemantics(
                          excluding: !c.idle,
                          child: SheetOption(
                            key: const ValueKey('vt-advanced'),
                            label: '${l.vtAdvanced}\n${l.vtThreads('${c.threads}')}',
                            icon: Icons.tune_rounded,
                            onTap: advanced,
                          ),
                        ),
                      ),
                      if (c.history.length > 1) ...[
                        section(l.vtHistory),
                        for (final run in c.history.skip(1))
                          Padding(
                            padding: const EdgeInsets.only(bottom: FikraSpace.s12),
                            child: VoiceTextResult(run: run),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
