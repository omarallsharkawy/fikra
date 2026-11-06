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
    final name = await askProjectName(context, title: 'أول مشروع', action: 'إنشاء');
    if (name != null) await ref.read(projectsRepoProvider).create(name);
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await seedDemoProject(ref.read(projectsRepoProvider), ref.read(notesRepoProvider));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FikraColors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: FikraColors.selectedGradient,
                      borderRadius: BorderRadius.circular(FikraRadius.xl),
                    ),
                    child: const Icon(Icons.lightbulb_outline_rounded, size: 42),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'فِكرة',
                  textAlign: TextAlign.center,
                  style: FikraText.title.copyWith(fontSize: 34, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'اكتب. اربط. اسأل.',
                  textAlign: TextAlign.center,
                  style: FikraText.bodyLarge.copyWith(color: FikraColors.textSecondary),
                ),
                const SizedBox(height: 28),
                const _Point(icon: Icons.edit_note_rounded, text: 'اكتب أو سجّل صوت أو ارفع PDF'),
                const _Point(icon: Icons.hub_outlined, text: 'فِكرة بتربط النوتس اللي شبه بعض لوحدها'),
                const _Point(icon: Icons.chat_bubble_outline_rounded, text: 'اسأل والإجابة تيجي من نوتسك مع المصدر'),
                const Spacer(flex: 4),
                if (isDemo) ...[
                  const Center(
                    child: FikraBadge(kind: BadgeKind.demo, label: 'نسخة تجريبية: البيانات على الموبايل بس'),
                  ),
                  const SizedBox(height: 14),
                ],
                FikraButton(label: 'ابدأ مشروع جديد', icon: Icons.add_rounded, onPressed: _seeding ? null : _create),
                const SizedBox(height: 10),
                FikraButton.secondary(
                  label: 'جرّب مشروع تجريبي',
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
            Icon(icon, color: FikraColors.accentLight, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: FikraText.body)),
          ],
        ),
      ),
    );
  }
}
