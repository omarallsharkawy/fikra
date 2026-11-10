import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/demo/demo_seed.dart';
import 'project_header.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _seeding = false;

  Future<void> _create() async {
    final name = await askProjectName(context, title: context.l10n.firstProjectTitle, action: context.l10n.create);
    if (name == null || !mounted) return;
    await runAction(
      context,
      () => ref.read(projectsRepoProvider).create(name),
      failure: context.l10n.createProjectFailed,
    );
  }

  Future<void> _seed() async {
    if (_seeding) return;
    setState(() => _seeding = true);
    try {
      await runAction(
        context,
        () => seedDemoProject(
          ref.read(projectsRepoProvider),
          ref.read(notesRepoProvider),
          locale: ref.read(appLocaleProvider),
          clock: ref.read(appClockProvider),
        ),
        failure: context.l10n.sampleProjectFailed,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scrolls on short screens and large font scales; spacers keep it centered otherwise.
    return FikraScaffold(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: context.colors.selectedGradient,
                        borderRadius: BorderRadius.circular(FikraRadius.xl),
                      ),
                      child: Icon(Icons.lightbulb_outline_rounded, size: 42, color: context.colors.textOnSelected),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: context.text.title.copyWith(fontSize: 34, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.tagline,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge.copyWith(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  _Point(icon: Icons.edit_note_rounded, text: context.l10n.welcomeCapture),
                  _Point(icon: Icons.hub_outlined, text: context.l10n.welcomeLinks),
                  _Point(icon: Icons.chat_bubble_outline_rounded, text: context.l10n.welcomeAsk),
                  const Spacer(flex: 4),
                  if (isDemo) ...[
                    Center(
                      child: FikraBadge(kind: BadgeKind.demo, label: context.l10n.welcomeDemoBadge),
                    ),
                    const SizedBox(height: 14),
                  ],
                  FikraButton(
                    label: context.l10n.startNewProject,
                    icon: Icons.add_rounded,
                    onPressed: _seeding ? null : _create,
                  ),
                  const SizedBox(height: 10),
                  FikraButton.secondary(
                    label: context.l10n.trySampleProject,
                    icon: Icons.auto_awesome_outlined,
                    loading: _seeding,
                    onPressed: _seed,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        radius: FikraRadius.md,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: context.colors.accentLight, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: context.text.body)),
          ],
        ),
      ),
    );
  }
}
