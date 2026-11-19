import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// Single-pass Arabic + Latin text normalization for search and matching.
///
/// Unifies أ/إ/آ/ٱ → ا, ة → ه, ى/ئ → ي, ؤ → و; strips tashkeel
/// (U+064B–U+0652, U+0670) and tatweel (U+0640); converts Arabic-Indic digits
/// (٠-٩, ۰-۹) to ASCII 0-9; lowercases Latin; and trims/collapses whitespace.
/// Keeps the article `ال` intact so words like ألوان/الله do not false-match.
String normalizeArabic(String s) {
  final len = s.length;
  if (len == 0) return '';
  final out = Uint16List(len);
  var count = 0;
  var pendingSpace = false;

  for (var i = 0; i < len; i++) {
    final cu = s.codeUnitAt(i);
    if (cu <= 0x20) {
      if (cu == 0x20 || (cu >= 0x09 && cu <= 0x0D)) {
        if (count > 0) pendingSpace = true;
        continue;
      }
    } else if (cu >= 0x00A0 && _isUnicodeWhitespace(cu)) {
      if (count > 0) pendingSpace = true;
      continue;
    }

    // Strip tashkeel (U+064B–U+0652, U+0670) and tatweel (U+0640).
    if ((cu >= 0x064B && cu <= 0x0652) || cu == 0x0640 || cu == 0x0670) {
      continue;
    }

    int mapped;
    if (cu >= 0x41 && cu <= 0x5A) {
      mapped = cu + 32;
    } else if (cu >= 0x0622 && cu <= 0x06F9) {
      mapped = switch (cu) {
        0x0622 || 0x0623 || 0x0625 || 0x0671 => 0x0627, // آ أ إ ٱ → ا
        0x0629 => 0x0647, // ة → ه
        0x0649 || 0x0626 => 0x064A, // ى ئ → ي
        0x0624 => 0x0648, // ؤ → و
        >= 0x0660 && <= 0x0669 => cu - 0x0660 + 0x30, // ٠-٩ → 0-9
        >= 0x06F0 && <= 0x06F9 => cu - 0x06F0 + 0x30, // ۰-۹ → 0-9
        _ => cu,
      };
    } else if ((cu >= 0x00C0 && cu <= 0x00D6) || (cu >= 0x00D8 && cu <= 0x00DE)) {
      mapped = cu + 32;
    } else {
      mapped = cu;
    }

    if (pendingSpace) {
      out[count++] = 0x20;
      pendingSpace = false;
    }
    out[count++] = mapped;
  }

  return count == 0 ? '' : String.fromCharCodes(out, 0, count);
}

bool _isUnicodeWhitespace(int cu) =>
    cu == 0x00A0 ||
    cu == 0x1680 ||
    (cu >= 0x2000 && cu <= 0x200A) ||
    cu == 0x2028 ||
    cu == 0x2029 ||
    cu == 0x202F ||
    cu == 0x205F ||
    cu == 0x3000;

bool _isWordChar(int cu) =>
    (cu >= 0x30 && cu <= 0x39) ||
    (cu >= 0x61 && cu <= 0x7A) ||
    (cu >= 0x0621 && cu <= 0x064A) ||
    (cu >= 0x066E && cu <= 0x06D5) ||
    (cu >= 0x00C0 && cu <= 0x024F && cu != 0x00D7 && cu != 0x00F7);

/// Matches a [normalizedQuery] against a [normalizedHaystack] (both produced by
/// [normalizeArabic]). A direct substring always matches. Otherwise every query
/// token must match its own haystack word, in any order: all tokens but the last
/// must equal a word, the last may be a word prefix (still typing), and a
/// haystack word's leading `ال` is ignored when the query token has none.
bool matchesNormalizedArabic(String normalizedHaystack, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  if (normalizedHaystack.isEmpty) return false;
  if (normalizedHaystack.contains(normalizedQuery)) return true;

  final query = _words(normalizedQuery);
  if (query.isEmpty) return false;
  final words = _words(normalizedHaystack);
  final used = List<bool>.filled(words.length, false);
  for (var j = 0; j < query.length; j++) {
    final prefix = j == query.length - 1;
    var found = false;
    for (var i = 0; i < words.length && !found; i++) {
      if (!used[i] && _wordMatches(words[i], query[j], prefix: prefix)) found = used[i] = true;
    }
    if (!found) return false;
  }
  return true;
}

List<String> _words(String s) {
  final words = <String>[];
  var i = 0;
  while (i < s.length) {
    while (i < s.length && !_isWordChar(s.codeUnitAt(i))) {
      i++;
    }
    final start = i;
    while (i < s.length && _isWordChar(s.codeUnitAt(i))) {
      i++;
    }
    if (i > start) words.add(s.substring(start, i));
  }
  return words;
}

bool _hasAl(String w) => w.length > 2 && w.codeUnitAt(0) == 0x0627 && w.codeUnitAt(1) == 0x0644;

bool _wordMatches(String word, String token, {required bool prefix}) {
  bool test(String w) => prefix ? w.startsWith(token) : w == token;
  if (test(word)) return true;
  return !_hasAl(token) && _hasAl(word) && test(word.substring(2));
}

/// Locale-aware display formatting. Digits stay Western (0-9).
abstract final class Fmt {
  static String time(AppLocalizations l10n, DateTime d) => _ascii(DateFormat('h:mm a', l10n.localeName).format(d));

  /// A calendar date in the current locale, e.g. "Feb 26, 2027" / "26 فبراير 2027".
  static String date(AppLocalizations l10n, DateTime d) => _ascii(DateFormat.yMMMd(l10n.localeName).format(d));

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
  static String files(AppLocalizations l10n, int n) => _ascii(l10n.filesCount(n));
  static String suggestions(AppLocalizations l10n, int n) => _ascii(l10n.suggestionsCount(n));

  /// Wraps user text (a project or note name) in a first-strong isolate, so
  /// a mixed name keeps its own order inside a sentence of the other
  /// direction: "2026 Work" stays "2026 Work" in Arabic.
  static String isolate(String s) => '\u2068$s\u2069';

  /// Joins one to three phrases for a sentence: "a and b", "a, b and c".
  static String list(AppLocalizations l10n, List<String> parts) => switch (parts) {
    [final a] => a,
    [final a, final b] => l10n.listTwo(a, b),
    [final a, final b, final c] => l10n.listThree(a, b, c),
    _ => throw ArgumentError.value(parts, 'parts', 'must hold one to three phrases'),
  };

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
