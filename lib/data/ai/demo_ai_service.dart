import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/format.dart';
import '../../l10n/app_localizations.dart';

import '../local/database.dart';
import 'ai_service.dart';

/// Simulated AI for the demo APK. Deterministic, offline, and clearly labelled
/// as demo data in the UI. Real rewriting, embeddings and RAG live on the
/// backend.
class DemoAiService implements AiService {
  DemoAiService({
    this.latency = const Duration(milliseconds: 2500),
    Locale locale = const Locale('ar'),
    Locale Function()? activeLocale,
  }) : _activeLocale = activeLocale ?? (() => locale);

  final Locale Function() _activeLocale;

  static Map<String, dynamic>? _vocabulary;

  static Future<Map<String, dynamic>> _labels(Locale locale) async {
    final vocabulary = _vocabulary ??=
        jsonDecode(await rootBundle.loadString('lib/l10n/demo_vocabulary.json', cache: false)) as Map<String, dynamic>;
    return vocabulary[locale.languageCode] as Map<String, dynamic>;
  }

  final Duration latency;

  // Normalized search text per note, rebuilt only when searchable fields change.
  final _haystacks = <String, (String, String, String, String)>{};

  String _haystack(Note n) {
    final cached = _haystacks[n.id];
    if (cached != null && cached.$1 == n.title && cached.$2 == n.displayText && cached.$3 == n.concepts) {
      return cached.$4;
    }
    final h = normalizeArabic('${n.title} ${n.displayText} ${n.concepts}');
    _haystacks[n.id] = (n.title, n.displayText, n.concepts, h);
    return h;
  }

  /// keyword (lowercase) -> (concept, cluster)
  static const _dictionary = <String, (String, String)>{
    'rag': ('RAG', 'AI'),
    'retrieval': ('RAG', 'AI'),
    'llm': ('LLM', 'AI'),
    'نموذج لغوي': ('LLM', 'AI'),
    'embedding': ('Embeddings', 'AI'),
    'تضمين': ('Embeddings', 'AI'),
    'التضمينات': ('Embeddings', 'AI'),
    'دلالي': ('Semantic_search', 'AI'),
    'semantic': ('Semantic_search', 'AI'),
    'agent': ('AI_agents', 'AI'),
    'ذكاء اصطناعي': ('AI', 'AI'),
    'الذكاء الاصطناعي': ('AI', 'AI'),
    'flutter': ('Flutter', 'App_development'),
    'dart': ('Flutter', 'App_development'),
    'حالة': ('State_management', 'App_development'),
    'state': ('State_management', 'App_development'),
    'riverpod': ('State_management', 'App_development'),
    'واجهة': ('UI_design', 'App_development'),
    'الواجهات': ('UI_design', 'App_development'),
    'تصميم': ('UI_design', 'App_development'),
    'ui': ('UI_design', 'App_development'),
    'fastapi': ('FastAPI', 'Backend'),
    'api': ('APIs', 'Backend'),
    'postgres': ('Databases', 'Backend'),
    'database': ('Databases', 'Backend'),
    'قاعدة بيانات': ('Databases', 'Backend'),
    'pgvector': ('Databases', 'Backend'),
    'محاضرة': ('Lectures', 'Studying'),
    'امتحان': ('Exams', 'Studying'),
    'مذاكرة': ('Studying', 'Studying'),
    'شبكات': ('Networking', 'Studying'),
    'فيديو': ('Content_creation', 'Content'),
    'يوتيوب': ('Content_creation', 'Content'),
    'youtube': ('Content_creation', 'Content'),
    'lecture': ('Lectures', 'Studying'),
    'exam': ('Exams', 'Studying'),
    'study': ('Studying', 'Studying'),
    'network': ('Networking', 'Studying'),
    'networks': ('Networking', 'Studying'),
    'video': ('Content_creation', 'Content'),
    'design': ('UI_design', 'App_development'),
    'interface': ('UI_design', 'App_development'),
    'ai': ('AI', 'AI'),
    'embeddings': ('Embeddings', 'AI'),
  };

  static const _stopWords = {
    'في',
    'من',
    'علي',
    'عن',
    'الي',
    'اللي',
    'ده',
    'دي',
    'ايه',
    'كنت',
    'كاتب',
    'كتبت',
    'هو',
    'هي',
    'و',
    'او',
    'مع',
    'كل',
    'بس',
    'يعني',
    'the',
    'a',
    'an',
    'is',
    'of',
    'and',
    'to',
    'what',
    'about',
    'my',
  };

  static final _normalizedDictionary = <(String, String, String)>[
    for (final e in _dictionary.entries) (normalizeArabic(e.key), e.value.$1, e.value.$2),
  ];

  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async {
    await Future<void>.delayed(latency);

    final locale = _activeLocale();
    final l10n = lookupAppLocalizations(locale);
    final content = note.originalText.trim();
    final concepts = await detectConcepts(content, locale: locale);
    final cluster = await clusterFor(content, locale: locale);
    final improved = improve(note.originalText, locale: locale);
    final links = <ProposedLink>[];
    for (final other in projectNotes) {
      if (other.id == note.id) continue;
      final shared = other.conceptList.toSet().intersection(concepts.toSet());
      if (shared.isEmpty) continue;
      final union = other.conceptList.toSet().union(concepts.toSet()).length;
      links.add(
        ProposedLink(
          targetId: other.id,
          label: l10n.demoLinkReason(shared.first),
          strength: shared.length / max(1, union),
        ),
      );
    }
    links.sort((a, b) => b.strength.compareTo(a.strength));

    return NoteInsights(
      title: note.title.trim().isNotEmpty ? note.title : suggestTitle(content, locale: locale),
      proposedText: improved != note.originalText.trim() && improved.isNotEmpty ? improved : null,
      concepts: concepts,
      cluster: cluster,
      links: links.take(4).toList(),
    );
  }

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final locale = _activeLocale();
    final l10n = lookupAppLocalizations(locale);
    final qConcepts = (await detectConcepts(question, locale: locale)).toSet();
    final tokens = _tokens(question);
    final scored = <(Note, double)>[];
    for (final n in projectNotes) {
      final hay = _haystack(n);
      var score = 0.0;
      for (final t in tokens) {
        if (matchesNormalizedArabic(hay, t)) score += 1;
      }
      score += 2 * n.conceptList.toSet().intersection(qConcepts).length;
      if (score > 0) scored.add((n, score));
    }
    if (_haystacks.length > projectNotes.length * 2 && projectNotes.isNotEmpty) {
      final live = {for (final n in projectNotes) n.id};
      _haystacks.removeWhere((id, _) => !live.contains(id));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(3).map((e) => e.$1).toList();
    if (top.isEmpty) {
      return ChatAnswer(text: l10n.demoAnswerNotFound, sourceIds: [], found: false);
    }
    final b = StringBuffer('${l10n.demoAnswerIntro}\n');
    for (var i = 0; i < top.length; i++) {
      b.writeln('• ${_firstSentence(top[i].displayText)} [${i + 1}]');
    }
    return ChatAnswer(text: b.toString(), sourceIds: top.map((n) => n.id).toList(), found: true);
  }

  // ---- helpers (public for tests and seeding)

  static Future<List<String>> detectConcepts(String text, {Locale locale = const Locale('ar')}) async {
    final labels = await _labels(locale);
    final normalized = normalizeArabic(text);
    final out = <String>[];
    for (final (key, concept, _) in _normalizedDictionary) {
      if (_containsWord(normalized, key) && !out.contains(labels[concept])) out.add(labels[concept] as String);
    }
    return out.take(5).toList();
  }

  static Future<String> clusterFor(String text, {Locale locale = const Locale('ar')}) async {
    final labels = await _labels(locale);
    final normalized = normalizeArabic(text);
    final counts = <String, int>{};
    for (final (key, _, cluster) in _normalizedDictionary) {
      if (_containsWord(normalized, key)) counts.update(cluster, (v) => v + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return lookupAppLocalizations(locale).clusterGeneral;
    return labels[(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key] as String;
  }

  static bool _containsWord(String normalized, String key) {
    // Latin keys match whole words ("api" not in "rapid" / "apiary"). Arabic
    // keys match with normalization and leading-ال tolerance, so prefixed forms
    // like "بالتضمينات" still count.
    if (RegExp(r'^[a-z]+$').hasMatch(key)) {
      return RegExp('(^|[^a-z])${RegExp.escape(key)}(?![a-z])').hasMatch(normalized);
    }
    return matchesNormalizedArabic(normalized, key);
  }

  /// Simulated rewrite: tidy spacing, expand known terms, capitalize, end with
  /// punctuation. Labelled "اقتراح تجريبي" in the UI.
  static String improve(String raw, {Locale locale = const Locale('ar')}) {
    final l10n = lookupAppLocalizations(locale);
    final expansions = {'rag': l10n.expandRag, 'llm': l10n.expandLlm};
    var t = raw.trim().replaceAll(RegExp(r'[ \t]+'), ' ');
    if (t.isEmpty) return t;
    for (final e in expansions.entries) {
      final re = RegExp('(^|[^a-zA-Z])(${e.key})(?![a-zA-Z])', caseSensitive: false);
      final m = re.firstMatch(t);
      if (m != null && !t.contains(e.value)) {
        t = t.replaceRange(m.start + m.group(1)!.length, m.end, e.value);
      }
    }
    if (RegExp(r'^[a-z]').hasMatch(t)) t = t[0].toUpperCase() + t.substring(1);
    if (!RegExp(r'[.!؟?…]$').hasMatch(t)) t = '$t.';
    return t;
  }

  static String suggestTitle(String content, {Locale locale = const Locale('ar')}) {
    final words = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return lookupAppLocalizations(locale).untitledNoteFallback;
    final title = words.take(6).join(' ');
    return words.length > 6 ? '$title…' : title;
  }

  static String _firstSentence(String text) {
    final s = text.trim().split(RegExp(r'(?<=[.!؟?])\s|\n')).first.trim();
    return s.length > 140 ? '${s.substring(0, 140)}…' : s;
  }

  static List<String> _tokens(String q) =>
      normalizeArabic(q)
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2 && !_stopWords.contains(w))
          .toList();
}
