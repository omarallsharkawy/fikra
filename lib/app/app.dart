import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/fikra_theme.dart';
import '../core/theme/tokens.dart';
import 'providers.dart';
import 'router.dart';

class FikraApp extends ConsumerWidget {
  const FikraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(startupMaintenanceProvider);
    // Wait for the saved theme (one quick DB read) so a restart never flashes
    // the wrong appearance. A read error falls back to the system setting.
    final savedTheme = ref.watch(appThemeProvider);
    final savedLanguage = ref.watch(appLanguageProvider);
    if ((savedTheme.isLoading && !savedTheme.hasValue) || (savedLanguage.isLoading && !savedLanguage.hasValue)) {
      return const SizedBox.shrink();
    }
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildFikraTheme(Brightness.light),
      darkTheme: buildFikraTheme(Brightness.dark),
      themeMode: switch (savedTheme.value ?? AppTheme.system) {
        AppTheme.system => ThemeMode.system,
        AppTheme.light => ThemeMode.light,
        AppTheme.dark => ThemeMode.dark,
      },
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: context.colors.canvas,
            systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          ),
          child: child!,
        );
      },
      locale: ref.watch(appLocaleProvider),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
