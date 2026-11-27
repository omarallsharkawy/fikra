import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/format.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../me/me_stats_tiles.dart';
import '../projects/project_switcher.dart';

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
    try {
      await ref.read(settingsRepoProvider).wipeAllData();
      showMessengerToast(messenger, l10n.eraseAllDone);
    } on WipeFilesException {
      showMessengerToast(messenger, l10n.eraseAllPartial);
    } catch (_) {
      showMessengerToast(messenger, l10n.eraseAllFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider).value ?? AppTheme.system;
    final language = ref.watch(appLanguageProvider).value ?? AppLanguage.en;
    final services = ref.watch(transcriptionServicesStateProvider);
    final c = context.colors;
    final t = context.text;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Semantics(
        header: true,
        child: Text(title, style: t.section.copyWith(fontWeight: FontWeight.w600)),
      ),
    );

    final configuredServices = services.value?.services ?? const [];

    return FikraScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(FikraSpace.screen, 16, FikraSpace.screen, 32 + NavigationInset.of(context)),
              children: [
                Semantics(
                  header: true,
                  child: Text(context.l10n.navMe, style: t.title.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                const MeStatsTiles(),
                section(context.l10n.projectsTitle),
                SheetOption(
                  key: const ValueKey('me-projects'),
                  label: ref.watch(selectedProjectProvider)?.name ?? context.l10n.noProject,
                  icon: Icons.folder_outlined,
                  onTap: () => showProjectSwitcher(context, ref),
                ),
                section(context.l10n.meAppearanceLanguage),
                Text(context.l10n.appearance, style: t.caption),
                const SizedBox(height: 8),
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
                section(context.l10n.meVoiceServices),
                SheetOption(
                  key: const ValueKey('settings-voice-text'),
                  label: '${context.l10n.vtTitle} · ${context.l10n.vtExperimental}',
                  icon: Icons.record_voice_over_outlined,
                  onTap: () => context.push('/settings/voice-text'),
                ),
                section(context.l10n.servicesSection),
                for (final service in configuredServices)
                  SheetOption(
                    key: ValueKey('settings-service-${service.id}'),
                    label: service.name,
                    icon: Icons.cloud_outlined,
                    onTap: () => context.push('/settings/voice-text/service/${service.id}'),
                  ),
                SheetOption(
                  key: const ValueKey('settings-add-service'),
                  label: context.l10n.vsAdd,
                  icon: Icons.add_rounded,
                  onTap: () => context.push('/settings/voice-text/service/new'),
                ),
                section(context.l10n.privacySection),
                SolidSurface(
                  radius: FikraRadius.md,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 20, color: c.accent),
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
                section(context.l10n.aboutSection),
                SolidSurface(
                  radius: FikraRadius.md,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const FikraBrandMark(size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.appTitle, style: t.cardTitleSmall),
                            Text(context.l10n.tagline, style: t.meta.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (ref.watch(appModeProvider) != AppMode.connected)
                        FikraBadge(kind: BadgeKind.demo, label: context.l10n.demoVersion),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: FikraSpace.s32, bottom: FikraSpace.s20),
                  child: Container(height: FikraSpace.hairline, color: c.line),
                ),
                SheetOption(
                  key: const ValueKey('settings-erase-all'),
                  label: context.l10n.eraseAll,
                  icon: Icons.delete_forever_outlined,
                  danger: true,
                  onTap: () => _wipe(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
