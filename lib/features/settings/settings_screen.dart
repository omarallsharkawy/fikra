import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/format.dart';
import '../../core/widgets/fikra_widgets.dart';

/// Appearance, local data and what this build is.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Order matches the segmented control.
  static const _themes = [AppTheme.system, AppTheme.light, AppTheme.dark];

  static const _languages = [AppLanguage.system, AppLanguage.ar, AppLanguage.en];

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: context.l10n.eraseAllTitle,
      message: context.l10n.eraseAllBody,
      confirmLabel: context.l10n.eraseAllConfirm,
    );
    if (!ok || !context.mounted) return;
    // With no projects left, the router sends the user to the welcome screen.
    final messenger = ScaffoldMessenger.of(context);
    void toast(String m) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
    try {
      await ref.read(settingsRepoProvider).wipeAllData();
      toast(l10n.eraseAllDone);
    } on WipeFilesException {
      toast(l10n.eraseAllPartial);
    } catch (_) {
      toast(l10n.eraseAllFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider).value ?? AppTheme.system;
    final language = ref.watch(appLanguageProvider).value ?? AppLanguage.system;
    final services = ref.watch(transcriptionServicesStateProvider);
    final c = context.colors;
    final t = context.text;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(title, style: t.section.copyWith(fontWeight: FontWeight.w600)),
    );

    return FikraScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                FikraIconButton(icon: Icons.arrow_back_rounded, label: context.l10n.back, onTap: () => context.pop()),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 8, FikraSpace.screen, 32),
              children: [
                Text(context.l10n.settingsTitle, style: t.title.copyWith(fontWeight: FontWeight.w700)),
                section(context.l10n.appearance),
                SegmentedPill(
                  options: [context.l10n.themeSystem, context.l10n.themeLight, context.l10n.themeDark],
                  selected: _themes.indexOf(theme),
                  onChanged: (i) => runAction(context, () => ref.read(settingsRepoProvider).setTheme(_themes[i])),
                ),
                const SizedBox(height: 8),
                Text(context.l10n.themeHint, style: t.meta.copyWith(fontSize: 12)),
                section(context.l10n.languageSection),
                SegmentedPill(
                  options: [context.l10n.languageSystem, context.l10n.languageArabic, context.l10n.languageEnglish],
                  selected: _languages.indexOf(language),
                  onChanged: (i) => runAction(context, () => ref.read(settingsRepoProvider).setLanguage(_languages[i])),
                ),
                section(context.l10n.vtVoiceSection),
                SheetOption(
                  key: const ValueKey('settings-voice-text'),
                  label: '${context.l10n.vtTitle} · ${context.l10n.vtExperimental}',
                  icon: Icons.record_voice_over_outlined,
                  onTap: () => context.push('/settings/voice-text'),
                ),
                section(context.l10n.dataSection),
                Glass(
                  radius: FikraRadius.md,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 20, color: c.accentLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          services.hasError
                              ? context.l10n.vsLoadError
                              : !services.hasValue
                              ? context.l10n.vtWait
                              : services.requireValue.selected == 'local'
                              ? context.l10n.dataStaysLocal
                              : context.l10n.vsRemoteData(
                                  Fmt.isolate(
                                    services.requireValue.selectedService?.name ?? context.l10n.vsRemovedService,
                                  ),
                                ),
                          key: const ValueKey('settings-data-location'),
                          style: t.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SheetOption(
                  label: context.l10n.eraseAll,
                  icon: Icons.delete_forever_outlined,
                  danger: true,
                  onTap: () => _wipe(context, ref),
                ),
                section(context.l10n.aboutSection),
                Glass(
                  radius: FikraRadius.md,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.appTitle, style: t.cardTitleSmall),
                            Text(context.l10n.tagline, style: t.meta.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isDemo) FikraBadge(kind: BadgeKind.demo, label: context.l10n.demoVersion),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
