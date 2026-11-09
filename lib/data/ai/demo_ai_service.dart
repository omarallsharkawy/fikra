import 'dart:async';
import 'dart:math';

import '../local/database.dart';
import 'ai_service.dart';

/// Simulated AI for the demo APK. Deterministic, offline, and clearly labelled
/// as demo data in the UI. Real rewriting, embeddings and RAG live on the
/// backend.
class DemoAiService implements AiService {
  DemoAiService({this.latency = const Duration(milliseconds: 2500)});

  final Duration latency;

  /// keyword (lowercase) -> (concept, cluster)
  static const _dictionary = <String, (String, String)>{
    'rag': ('RAG', 'الذكاء الاصطناعي'),
    'retrieval': ('RAG', 'الذكاء الاصطناعي'),
    'llm': ('LLM', 'الذكاء الاصطناعي'),
    'نموذج لغوي': ('LLM', 'الذكاء الاصطناعي'),
    'embedding': ('Embeddings', 'الذكاء الاصطناعي'),
    'تضمين': ('Embeddings', 'الذكاء الاصطناعي'),
    'التضمينات': ('Embeddings', 'الذكاء الاصطناعي'),
    'دلالي': ('البحث الدلالي', 'الذكاء الاصطناعي'),
    'semantic': ('البحث الدلالي', 'الذكاء الاصطناعي'),
    'agent': ('AI Agents', 'الذكاء الاصطناعي'),
    'ذكاء اصطناعي': ('الذكاء الاصطناعي', 'الذكاء الاصطناعي'),
    'الذكاء الاصطناعي': ('الذكاء الاصطناعي', 'الذكاء الاصطناعي'),
    'flutter': ('Flutter', 'تطوير التطبيقات'),
    'dart': ('Flutter', 'تطوير التطبيقات'),
    'حالة': ('إدارة الحالة', 'تطوير التطبيقات'),
    'state': ('إدارة الحالة', 'تطوير التطبيقات'),
    'riverpod': ('إدارة الحالة', 'تطوير التطبيقات'),
    'واجهة': ('تصميم الواجهات', 'تطوير التطبيقات'),
    'الواجهات': ('تصميم الواجهات', 'تطوير التطبيقات'),
    'تصميم': ('تصميم الواجهات', 'تطوير التطبيقات'),
    'ui': ('تصميم الواجهات', 'تطوير التطبيقات'),
    'fastapi': ('FastAPI', 'الباك إند'),
    'api': ('APIs', 'الباك إند'),
    'postgres': ('قواعد البيانات', 'الباك إند'),
    'database': ('قواعد البيانات', 'الباك إند'),
    'قاعدة بيانات': ('قواعد البيانات', 'الباك إند'),
    'pgvector': ('قواعد البيانات', 'الباك إند'),
    'محاضرة': ('المحاضرات', 'المذاكرة'),
    'امتحان': ('الامتحانات', 'المذاكرة'),
    'مذاكرة': ('المذاكرة', 'المذاكرة'),
    'شبكات': ('الشبكات', 'المذاكرة'),
    'فيديو': ('صناعة المحتوى', 'المحتوى'),
    'يوتيوب': ('صناعة المحتوى', 'المحتوى'),
    'youtube': ('صناعة المحتوى', 'المحتوى'),
  };

  static const _expansions = <String, String>{
    'rag': 'RAG (Retrieval-Augmented Generation)',
    'llm': 'LLM (نموذج لغوي كبير)',
  };

  static const _stopWords = {
    'في',
    'من',
    'على',
    'عن',
    'إلى',
    'الى',
    'اللي',
    'ده',
    'دي',
    'إيه',
    'ايه',
    'كنت',
    'كاتب',
    'كتبت',
    'هو',
    'هي',
    'و',
    'أو',
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

  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async {
    await Future<void>.delayed(latency);

    final content = note.originalText.trim();
    final concepts = detectConcepts(content);
    final cluster = _clusterFor(content);
    final improved = improve(note.originalText);
    final links = <ProposedLink>[];
    for (final other in projectNotes) {
      if (other.id == note.id) continue;
      final shared = other.conceptList.toSet().intersection(concepts.toSet());
      if (shared.isEmpty) continue;
      final union = other.conceptList.toSet().union(concepts.toSet()).length;
      links.add(
        ProposedLink(targetId: other.id, label: 'مرتبطة بـ${shared.first}', strength: shared.length / max(1, union)),
      );
    }
    links.sort((a, b) => b.strength.compareTo(a.strength));

    return NoteInsights(
      title: note.title.trim().isNotEmpty ? note.title : suggestTitle(content),
      proposedText: improved != note.originalText.trim() && improved.isNotEmpty ? improved : null,
      concepts: concepts,
      cluster: cluster,
      links: links.take(4).toList(),
    );
  }

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final qConcepts = detectConcepts(question).toSet();
    final tokens = _tokens(question);
    final scored = <(Note, double)>[];
    for (final n in projectNotes) {
      final hay = '${n.title} ${n.displayText} ${n.concepts}'.toLowerCase();
      var score = 0.0;
      for (final t in tokens) {
        if (hay.contains(t)) score += 1;
      }
      score += 2 * n.conceptList.toSet().intersection(qConcepts).length;
      if (score > 0) scored.add((n, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(3).map((e) => e.$1).toList();
    if (top.isEmpty) {
      return const ChatAnswer(
        text: 'مفيش نوت في المشروع ده بتتكلم عن الموضوع. جرّب تسأل بطريقة تانية أو ضيف نوت عنه.',
        sourceIds: [],
        found: false,
      );
    }
    final b = StringBuffer('من نوتسك في المشروع ده:\n');
    for (var i = 0; i < top.length; i++) {
      b.writeln('• ${_firstSentence(top[i].displayText)} [${i + 1}]');
    }
    b.write('\n(إجابة تجريبية من نوتسك)');
    return ChatAnswer(text: b.toString(), sourceIds: top.map((n) => n.id).toList(), found: true);
  }

  // ---- helpers (public for tests and seeding)

  static List<String> detectConcepts(String text) {
    final lower = text.toLowerCase();
    final out = <String>[];
    for (final e in _dictionary.entries) {
      if (_containsWord(lower, e.key) && !out.contains(e.value.$1)) out.add(e.value.$1);
    }
    return out.take(5).toList();
  }

  static String _clusterFor(String text) {
    final lower = text.toLowerCase();
    final counts = <String, int>{};
    for (final e in _dictionary.entries) {
      if (_containsWord(lower, e.key)) counts.update(e.value.$2, (v) => v + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) return 'أفكار عامة';
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  static String clusterFor(String text) => _clusterFor(text);

  static bool _containsWord(String lower, String key) {
    // Latin keys match whole words ("api" not in "rapid" / "apiary"). Arabic
    // keys match anywhere, so prefixed forms like "بالتضمينات" still count.
    if (RegExp(r'^[a-z]+$').hasMatch(key)) {
      return RegExp('(^|[^a-z])${RegExp.escape(key)}(?![a-z])').hasMatch(lower);
    }
    return lower.contains(key);
  }

  /// Simulated rewrite: tidy spacing, expand known terms, capitalize, end with
  /// punctuation. Labelled "اقتراح تجريبي" in the UI.
  static String improve(String raw) {
    var t = raw.trim().replaceAll(RegExp(r'[ \t]+'), ' ');
    if (t.isEmpty) return t;
    for (final e in _expansions.entries) {
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

  static String suggestTitle(String content) {
    final words = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'نوت بدون عنوان';
    final title = words.take(6).join(' ');
    return words.length > 6 ? '$title…' : title;
  }

  static String _firstSentence(String text) {
    final s = text.trim().split(RegExp(r'(?<=[.!؟?])\s|\n')).first.trim();
    return s.length > 140 ? '${s.substring(0, 140)}…' : s;
  }

  static List<String> _tokens(String q) => q
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !_stopWords.contains(w))
      .toList();
}
