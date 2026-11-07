import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';

/// Appearance, local data and what this build is.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Order matches the segmented control.
  static const _themes = [AppTheme.system, AppTheme.light, AppTheme.dark];

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDestructive(
      context,
      title: 'تمسح كل البيانات؟',
      message: 'كل المشاريع والنوتس والتسجيلات والملفات والمحادثات هتتمسح من الموبايل، ومش هينفع ترجّعها.',
      confirmLabel: 'امسح كله',
    );
    if (!ok || !context.mounted) return;
    // With no projects left, the router sends the user to the welcome screen.
    final messenger = ScaffoldMessenger.of(context);
    void toast(String m) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
    try {
      await ref.read(settingsRepoProvider).wipeAllData();
      toast('كل حاجة اتمسحت');
    } on WipeFilesException {
      toast('البيانات اتمسحت، بس شوية ملفات لسه. هتتمسح لوحدها أول ما تفتح التطبيق تاني.');
    } catch (_) {
      toast('مقدرناش نمسح البيانات، جرّب تاني');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider).value ?? AppTheme.system;
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
              children: [FikraIconButton(icon: Icons.arrow_back_rounded, label: 'رجوع', onTap: () => context.pop())],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 8, FikraSpace.screen, 32),
              children: [
                Text('الإعدادات', style: t.title.copyWith(fontWeight: FontWeight.w700)),
                section('المظهر'),
                SegmentedPill(
                  options: const ['زي الموبايل', 'فاتح', 'غامق'],
                  selected: _themes.indexOf(theme),
                  onChanged: (i) => runAction(context, () => ref.read(settingsRepoProvider).setTheme(_themes[i])),
                ),
                const SizedBox(height: 8),
                Text(
                  'لو اخترت "زي الموبايل"، فِكرة هتمشي على وضع الموبايل الفاتح أو الغامق.',
                  style: t.meta.copyWith(fontSize: 12),
                ),
                section('البيانات'),
                Glass(
                  radius: FikraRadius.md,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 20, color: c.accentLight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('نوتسك وملفاتك محفوظة على الموبايل ده بس، ومش بتتنقل لأي مكان.', style: t.caption),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SheetOption(
                  label: 'مسح كل البيانات',
                  icon: Icons.delete_forever_outlined,
                  danger: true,
                  onTap: () => _wipe(context, ref),
                ),
                section('عن التطبيق'),
                Glass(
                  radius: FikraRadius.md,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('فِكرة', style: t.cardTitleSmall),
                            Text('اكتب. اربط. اسأل.', style: t.meta.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isDemo) const FikraBadge(kind: BadgeKind.demo, label: 'نسخة تجريبية'),
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
