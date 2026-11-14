import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../shared/inline_recorder.dart';
import 'voice_text_backend.dart';
import 'voice_text_controller.dart';
import 'voice_text_copy.dart';
import 'voice_text_models.dart';
import 'voice_text_providers.dart';
import 'voice_text_recording.dart';
import 'voice_text_result.dart';
import 'voice_text_testing.dart';
import 'whisper_metrics.dart';

class VoiceTextScreen extends ConsumerStatefulWidget {
  const VoiceTextScreen({super.key});
  @override
  ConsumerState<VoiceTextScreen> createState() => _VoiceTextScreenState();
}

class _VoiceTextScreenState extends ConsumerState<VoiceTextScreen> {
  final _scroll = ScrollController();
  bool _testing = false;
  bool _errorQueued = false;
  VoiceTextIssue? _lastError;

  void _queueError(VoiceTextController c) {
    if (_errorQueued) return;
    _errorQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _errorQueued = false;
      if (!mounted || c.issue == null) return;
      showToast(context, issueMessage(context.l10n, c.issue!));
      if (!_scroll.hasClients) return;
      // The banner can be unbuilt while a lazy list shows a bottom action.
      // Return to the banner, rather than relying on a null GlobalKey context.
      if (!FikraMotion.reduced(context)) {
        await _scroll.animateTo(0, duration: FikraMotion.expand, curve: FikraMotion.expandCurve);
        return;
      }
      // After a long jump, rows the lazy list skipped still carry offsets from
      // before the banner was inserted, so the first layout at the top shifts
      // the offset by the banner's height. Jump again once those rows are measured.
      // (The animated scroll passes through those rows and ends at the top.)
      _scroll.jumpTo(0);
      for (var i = 0; i < 2; i++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !_scroll.hasClients || _scroll.offset == 0) return;
        _scroll.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(voiceTextControllerProvider);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final l = context.l10n;
        if (c.issue == null) {
          _lastError = null;
        } else if (_lastError != c.issue) {
          _lastError = c.issue;
          _queueError(c);
        }
        Future<void> act(Future<void> Function() action) async {
          await action();
          if (mounted && c.issue != null) _queueError(c);
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
                    Navigator.pop(sheet);
                    act(() => c.chooseLanguage(entry.$1));
                  },
                ),
            ],
          ),
        );
        final live = c.phase == VoiceTextPhase.live;
        final testing = _testing ? VoiceTextTesting(controller: c, act: act) : const SizedBox.shrink();
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
                    controller: _scroll,
                    key: const ValueKey('vt-scroll'),
                    padding: const EdgeInsets.fromLTRB(
                      FikraSpace.screen,
                      FikraSpace.s8,
                      FikraSpace.screen,
                      FikraSpace.s32,
                    ),
                    children: [
                      Text(l.vtTitle, style: context.text.title.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: FikraSpace.s8),
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
                            child: StatusBanner(
                              key: const ValueKey('vt-error'),
                              kind: BannerKind.error,
                              message: issueMessage(l, c.issue!),
                            ),
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
                      VoiceTextModels(
                        controller: c,
                        act: act,
                        models: c.models.where((m) => m.quantized || m == c.model).toList(),
                      ),
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
                      section(l.vtTry),
                      VoiceTextRecording(controller: c, act: act),
                      const SizedBox(height: FikraSpace.s12),
                      FikraButton(
                        key: const ValueKey('vt-try-transcribe'),
                        growForText: true,
                        label: c.phase == VoiceTextPhase.transcribing ? l.vtWorking : l.vtTranscribe,
                        onPressed: c.idle && c.selected != null && c.downloaded ? () => act(c.transcribe) : null,
                      ),
                      const SizedBox(height: FikraSpace.s8),
                      Text(l.vtCannotCancel, style: context.text.caption),
                      if (c.phase == VoiceTextPhase.transcribing) VoiceTextProgress(label: l.vtWorking),
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
                          key: const ValueKey('vt-partial'),
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
                            : c.idle && c.downloaded
                            ? () => act(() => c.start(live: true))
                            : null,
                      ),
                      if (c.history.isNotEmpty) ...[section(l.vtResult), VoiceTextTranscript(run: c.history.first)],
                      const SizedBox(height: FikraSpace.s24),
                      Semantics(
                        expanded: _testing,
                        child: SheetOption(
                          key: const ValueKey('vt-testing-toggle'),
                          label: l.vtTesting,
                          icon: _testing ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          onTap: () => setState(() => _testing = !_testing),
                        ),
                      ),
                      // A zero-duration AnimatedSize re-dirties itself inside its own layout
                      // (a debug assertion), so Reduce Motion shows the section at once.
                      if (FikraMotion.reduced(context))
                        testing
                      else
                        AnimatedSize(
                          duration: FikraMotion.expand,
                          curve: FikraMotion.expandCurve,
                          alignment: Alignment.topCenter,
                          child: testing,
                        ),
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
