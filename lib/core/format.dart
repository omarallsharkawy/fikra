import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// Locale-aware display formatting. Digits stay Western (0-9).
abstract final class Fmt {
  static String time(AppLocalizations l10n, DateTime d) => _ascii(DateFormat('h:mm a', l10n.localeName).format(d));

  static String dayHeader(AppLocalizations l10n, DateTime d, {DateTime? now}) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    return _ascii(DateFormat(l10n.localeName == 'ar' ? 'EEEE d MMMM' : 'EEEE, d MMMM', l10n.localeName).format(d));
  }

  static String relative(AppLocalizations l10n, DateTime d, {DateTime? now}) {
    now ??= DateTime.now();
    final m = now.difference(d).inMinutes;
    if (m < 1) return l10n.justNow;
    if (m < 60) return _ascii(l10n.minutesAgo(m));
    final h = m ~/ 60;
    if (h < 24) return _ascii(l10n.hoursAgo(h));
    return dayHeader(l10n, d, now: now);
  }

  static String notes(AppLocalizations l10n, int n) => _ascii(l10n.notesCount(n));
  static String links(AppLocalizations l10n, int n) => _ascii(l10n.linksCount(n));

  static String duration(int ms) {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  static String bytes(AppLocalizations l10n, int b) {
    String number(num n, String pattern) => _ascii(NumberFormat(pattern, l10n.localeName).format(n));
    if (b < 1024) return l10n.sizeBytes(number(b, '0'));
    if (b < 1024 * 1024) return l10n.sizeKb(number(b / 1024, '0'));
    return l10n.sizeMb(number(b / 1024 / 1024, '0.0'));
  }

  static String _ascii(String s) => s.replaceAllMapped(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'), (m) {
    final code = m[0]!.codeUnitAt(0);
    return '${code - (code >= 0x6f0 ? 0x6f0 : 0x660)}';
  });
}
