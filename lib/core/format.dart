import 'package:intl/intl.dart';

/// Arabic-friendly formatting. Digits stay Western (0-9) like the design.
abstract final class Fmt {
  static final _time = DateFormat('h:mm a', 'ar');
  static final _day = DateFormat('EEEE d MMMM', 'ar');

  static String time(DateTime d) => _ascii(_time.format(d));

  static String dayHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'النهارده';
    if (diff == 1) return 'امبارح';
    return _ascii(_day.format(d));
  }

  static String relative(DateTime d) {
    final m = DateTime.now().difference(d).inMinutes;
    if (m < 1) return 'دلوقتي';
    if (m < 60) return 'من $m دقيقة';
    final h = m ~/ 60;
    if (h < 24) return 'من $h ساعة';
    return dayHeader(d);
  }

  static String duration(int ms) {
    final s = (ms / 1000).round();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  static String bytes(int b) {
    if (b < 1024) return '$b بايت';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} ك.ب';
    return '${(b / 1024 / 1024).toStringAsFixed(1)} م.ب';
  }

  static String _ascii(String s) {
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final ch in s.runes) {
      final i = ar.indexOf(String.fromCharCode(ch));
      b.write(i >= 0 ? '$i' : String.fromCharCode(ch));
    }
    return b.toString();
  }
}
