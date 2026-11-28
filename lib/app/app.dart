import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/fikra_theme.dart';
import '../core/theme/product_theme.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/glass_preview.dart';
import 'providers.dart';
import 'router.dart';
import 'product_router.dart';
import 'product_runtime.dart';
import '../features/workspace/product_widgets.dart' show ProductEnvironment;

class FikraApp extends ConsumerWidget {
  const FikraApp({super.key});

  static final _productLight = buildProductTheme(Brightness.light);
  static final _productDark = buildProductTheme(Brightness.dark);
  static final _fikraLight = buildFikraTheme(Brightness.light);
  static final _fikraDark = buildFikraTheme(Brightness.dark);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final product = mode != AppMode.demo;
    if (!product) ref.watch(startupMaintenanceProvider);
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
      theme: product ? _productLight : _fikraLight,
      darkTheme: product ? _productDark : _fikraDark,
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
          child: GlassDebugOverlay(
            child: product
                ? ProductEnvironment(
                    development: mode == AppMode.development,
                    child: ProductBoundary(runtime: ref.watch(productRuntimeProvider), child: child!),
                  )
                : child!,
          ),
        );
      },
      locale: ref.watch(appLocaleProvider),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: product ? ref.watch(productRouterProvider) : ref.watch(routerProvider),
    );
  }
}
