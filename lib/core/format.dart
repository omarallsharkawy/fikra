import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// Test hook counting calls to [tokenizeNormalizedArabic] / internal word scans.
int debugArabicTokenizeCount = 0;

/// Single-pass Arabic + Latin text normalization for search and matching.
///
/// Unifies أ/إ/آ/ٱ → ا, ة → ه, ى/ئ → ي, ؤ → و; strips tashkeel
/// (U+064B–U+0652, U+0670) and tatweel (U+0640); converts Arabic-Indic digits
/// (٠-٩, ۰-۹) to ASCII 0-9; lowercases ASCII, Latin-1 and extended Unicode
/// letters; and trims/collapses whitespace. Keeps the article `ال` intact so
/// words like ألوان/الله do not false-match.
String normalizeArabic(String s) {
  final len = s.length;
  if (len == 0) return '';
  var out = Uint16List(len);
  var count = 0;
  var pendingSpace = false;

  void appendCodeUnit(int cu) {
    if (count == out.length) {
      final grown = Uint16List(out.length * 2);
      grown.setRange(0, count, out);
      out = grown;
    }
    out[count++] = cu;
  }

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

    if (cu < 0x80) {
      final mapped = cu >= 0x41 && cu <= 0x5A ? cu + 32 : cu;
      if (pendingSpace) {
        appendCodeUnit(0x20);
        pendingSpace = false;
      }
      appendCodeUnit(mapped);
    } else if (cu >= 0x0600 && cu <= 0x06FF) {
      final mapped = switch (cu) {
        0x0622 || 0x0623 || 0x0625 || 0x0671 => 0x0627, // آ أ إ ٱ → ا
        0x0629 => 0x0647, // ة → ه
        0x0649 || 0x0626 => 0x064A, // ى ئ → ي
        0x0624 => 0x0648, // ؤ → و
        >= 0x0660 && <= 0x0669 => cu - 0x0660 + 0x30, // ٠-٩ → 0-9
        >= 0x06F0 && <= 0x06F9 => cu - 0x06F0 + 0x30, // ۰-۹ → 0-9
        _ => cu,
      };
      if (pendingSpace) {
        appendCodeUnit(0x20);
        pendingSpace = false;
      }
      appendCodeUnit(mapped);
    } else if ((cu >= 0x00C0 && cu <= 0x00D6) || (cu >= 0x00D8 && cu <= 0x00DE)) {
      if (pendingSpace) {
        appendCodeUnit(0x20);
        pendingSpace = false;
      }
      appendCodeUnit(cu + 32);
    } else {
      final String chunk;
      if (cu >= 0xD800 && cu <= 0xDBFF && i + 1 < len) {
        chunk = s.substring(i, i + 2).toLowerCase();
        i++;
      } else {
        chunk = String.fromCharCode(cu).toLowerCase();
      }
      if (pendingSpace) {
        appendCodeUnit(0x20);
        pendingSpace = false;
      }
      for (var k = 0; k < chunk.length; k++) {
        appendCodeUnit(chunk.codeUnitAt(k));
      }
    }
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

const _maxBacktrackSteps = 256;
const _maxCandidatesPerToken = 32;

/// Splits a [normalizeArabic] string into searchable words for reuse across
/// keystrokes (pass into [matchesNormalizedArabic]).
List<String> tokenizeNormalizedArabic(String normalized) => _words(normalized);

/// Matches a [normalizedQuery] against a [normalizedHaystack] (both produced by
/// [normalizeArabic]). A direct substring always matches. Otherwise every query
/// token must match a distinct haystack word, in any order: all tokens but the
/// last must match a whole word, the last may be a word prefix (still typing),
/// and a haystack word's leading `ال` is ignored when the query token does not
/// start with `ال`.
///
/// Pass cached [haystackWords] and [queryWords] (from [tokenizeNormalizedArabic])
/// to avoid re-tokenizing on every keystroke.
bool matchesNormalizedArabic(
  String normalizedHaystack,
  String normalizedQuery, {
  List<String>? haystackWords,
  List<String>? queryWords,
}) {
  if (normalizedQuery.isEmpty) return true;
  if (normalizedHaystack.isEmpty) return false;
  if (normalizedHaystack.contains(normalizedQuery)) return true;

  final query = queryWords ?? _words(normalizedQuery);
  final m = query.length;
  if (m == 0) return false;
  final words = haystackWords ?? _words(normalizedHaystack);
  if (m > words.length) return false;

  if (m == 1) {
    final token = query[0];
    for (var i = 0; i < words.length; i++) {
      if (_wordMatches(words[i], token, prefix: true)) return true;
    }
    return false;
  }

  final cap = m < _maxCandidatesPerToken ? m : _maxCandidatesPerToken;
  final candidates = List<List<int>>.filled(m, const []);
  for (var j = 0; j < m; j++) {
    final token = query[j];
    final prefix = j == m - 1;
    List<int>? exact;
    List<int>? alt;
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      if (w == token) {
        (exact ??= <int>[]).add(i);
        if (exact.length >= cap) break;
      } else if (_wordMatchesAlt(w, token, prefix: prefix)) {
        if ((alt?.length ?? 0) < cap) (alt ??= <int>[]).add(i);
      }
    }
    if (exact == null && alt == null) return false;
    if (alt == null) {
      candidates[j] = exact!;
    } else if (exact == null) {
      candidates[j] = alt;
    } else {
      final remaining = cap - exact.length;
      if (remaining > 0) {
        exact.addAll(alt.length <= remaining ? alt : alt.sublist(0, remaining));
      }
      candidates[j] = exact;
    }
  }

  // Assign the most constrained tokens first; each candidate list already puts
  // exact matches ahead of article/prefix alternatives.
  final order = List<int>.generate(m, (i) => i)..sort((a, b) => candidates[a].length.compareTo(candidates[b].length));
  final used = List<bool>.filled(words.length, false);
  var steps = 0;

  bool assign(int depth) {
    if (depth == m) return true;
    if (++steps > _maxBacktrackSteps) return false;
    final cands = candidates[order[depth]];
    for (var k = 0; k < cands.length; k++) {
      final idx = cands[k];
      if (used[idx]) continue;
      used[idx] = true;
      if (assign(depth + 1)) return true;
      used[idx] = false;
      if (steps >= _maxBacktrackSteps) return false;
    }
    return false;
  }

  return assign(0);
}

List<String> _words(String s) {
  debugArabicTokenizeCount++;
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

bool _startsWithAl(String w) => w.length >= 2 && w.codeUnitAt(0) == 0x0627 && w.codeUnitAt(1) == 0x0644;

bool _hasAl(String w) => w.length > 2 && w.codeUnitAt(0) == 0x0627 && w.codeUnitAt(1) == 0x0644;

bool _wordMatches(String word, String token, {required bool prefix}) =>
    word == token || _wordMatchesAlt(word, token, prefix: prefix);

bool _wordMatchesAlt(String word, String token, {required bool prefix}) {
  if (prefix && word.startsWith(token)) return true;
  if (_startsWithAl(token) || !_hasAl(word)) return false;
  return prefix ? word.startsWith(token, 2) : (word.length == token.length + 2 && word.startsWith(token, 2));
}

/// Locale-aware display formatting. Digits stay Western (0-9).
abstract final class Fmt {
  static final _arabicDigits = RegExp(r'[\u0660-\u0669\u06f0-\u06f9]');
  static final _dateFormats = <String, DateFormat>{};
  static DateFormat _df(String key, DateFormat Function() create) => _dateFormats.putIfAbsent(key, create);

  static String weekday(AppLocalizations l10n, DateTime d) =>
      _df('EEEE:${l10n.localeName}', () => DateFormat.EEEE(l10n.localeName)).format(d);

  static String time(AppLocalizations l10n, DateTime d) =>
      _ascii(_df('hm:${l10n.localeName}', () => DateFormat('h:mm a', l10n.localeName)).format(d));

  /// A calendar date in the current locale, e.g. "Feb 26, 2027" / "26 فبراير 2027".
  static String date(AppLocalizations l10n, DateTime d) =>
      _ascii(_df('yMMMd:${l10n.localeName}', () => DateFormat.yMMMd(l10n.localeName)).format(d));

  static String dayHeader(AppLocalizations l10n, DateTime d, {DateTime? now}) {
    now ??= DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    final pattern = l10n.localeName == 'ar' ? 'EEEE d MMMM' : 'EEEE, d MMMM';
    return _ascii(_df('day:$pattern:${l10n.localeName}', () => DateFormat(pattern, l10n.localeName)).format(d));
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

  static String _ascii(String s) => s.replaceAllMapped(_arabicDigits, (m) {
    final code = m[0]!.codeUnitAt(0);
    return '${code - (code >= 0x6f0 ? 0x6f0 : 0x660)}';
  });
}
