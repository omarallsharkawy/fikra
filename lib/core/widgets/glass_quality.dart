import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'glass_power.dart';
import 'glass_watchdog.dart';

export 'glass_watchdog.dart' show GlassTier;

/// No product UI. Debug and profile harnesses can request a ceiling; release
/// ignores it entirely. Safety caps still win over a requested optical tier.
class GlassTierOverride extends Notifier<GlassTier?> {
  @override
  GlassTier? build() => null;
  void force(GlassTier? tier) {
    if (!kReleaseMode) state = tier;
  }
}

final glassTierOverrideProvider = NotifierProvider<GlassTierOverride, GlassTier?>(GlassTierOverride.new);

/// Experimental scroll-shrinking floating tab bar. Off by default and ignored
/// in release builds.
class NavBarShrinkOverride extends Notifier<bool> {
  @override
  bool build() => false;
  void setEnabled(bool enabled) {
    if (!kReleaseMode) state = enabled;
  }

  void toggle() {
    if (!kReleaseMode) state = !state;
  }
}

final navBarShrinkEnabledProvider = NotifierProvider<NavBarShrinkOverride, bool>(NavBarShrinkOverride.new);

/// The boolean is exclusively MediaQuery.disableAnimations from the consumer.
final glassTierProvider = Provider.family<GlassTier, bool>((ref, disableAnimations) {
  var tier = ref.watch(glassWatchdogProvider);
  void cap(GlassTier ceiling) {
    if (ceiling.index < tier.index) tier = ceiling;
  }

  // Before Android answers, keep the material cheap.
  if (ref.watch(glassPowerSaveProvider).value ?? true) cap(GlassTier.solid);
  if (disableAnimations) cap(GlassTier.solid);
  if (!kReleaseMode) cap(ref.watch(glassTierOverrideProvider) ?? GlassTier.optical);
  return tier;
});

/// Resolves the active [GlassTier] for [context], forcing [GlassTier.solid]
/// when the platform requests high contrast or reduced transparency.
GlassTier effectiveGlassTier(BuildContext context, WidgetRef ref) {
  if (MediaQuery.maybeHighContrastOf(context) ?? false) return GlassTier.solid;
  return ref.watch(glassTierProvider(MediaQuery.maybeDisableAnimationsOf(context) ?? false));
}
