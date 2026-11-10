part of 'add_screen.dart';

class _MicPermissionCard extends StatelessWidget {
  const _MicPermissionCard({required this.blocked, required this.onRetry, required this.onClose});
  final bool blocked;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.lg,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.mic_off_outlined, color: context.colors.warning),
              const SizedBox(width: 10),
              Expanded(child: Text('محتاجين إذن المايك', style: context.text.cardTitleSmall)),
              Pressable(
                onTap: onClose,
                minTarget: true,
                semanticLabel: 'إغلاق',
                child: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            blocked
                ? 'الإذن مقفول من الإعدادات. افتح إعدادات التطبيق وفعّل المايك.'
                : 'عشان تسجّل فكرة بصوتك، اسمح لفِكرة تستخدم المايك.',
            style: context.text.caption,
          ),
          const SizedBox(height: 14),
          FikraButton.secondary(
            label: blocked ? 'افتح الإعدادات' : 'اسمح بالمايك',
            icon: blocked ? Icons.settings_outlined : Icons.mic_none_rounded,
            onPressed: blocked ? openAppSettings : onRetry,
          ),
        ],
      ),
    );
  }
}
