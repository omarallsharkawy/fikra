// Test-only data extracted from the HTML. This file is never an app asset or a
// production repository fallback; it gives both renderers identical content.
import 'dart:convert';
import 'dart:io';

import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';

class HtmlReferenceRepository extends DevelopmentKnowledgeRepository {
  HtmlReferenceRepository(this.language) : super(stepDelay: Duration.zero);
  final String language;
  static final fixture =
      jsonDecode(File('test/support/fixtures/html-reference.json').readAsStringSync()) as Map<String, dynamic>;
  static const projectId = 'reference-general';
  static final project = KnowledgeProject(id: projectId, name: 'General', isGeneral: true, createdAt: DateTime(2026));
  List<Map<String, dynamic>> get rows => (fixture['notes'] as List).cast<Map<String, dynamic>>();
  @override
  Future<List<KnowledgeProject>> projects(String accountId) async => [project];
  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) async => rows.map((r) {
    final now = DateTime.now();
    final created = DateTime(now.year, now.month, now.day, 1, 56).subtract(Duration(days: r['d'] == 't' ? 0 : 1));
    final diff = (r['df'] as Map?)?[language] as String?;
    final proposal = diff?.replaceAll(RegExp(r'<del>.*?</del>'), '').replaceAll(RegExp('<[^>]+>'), '');
    return KnowledgeNote(
      id: r['id'] as String,
      projectId: projectId,
      title: (r['t'] as Map)[language] as String,
      content: (r['b'] as Map)[language] as String,
      concepts: const [],
      proposal: proposal,
      revision: 1,
      generation: 1,
      processing: r['st'] == 'p' ? ProcessingState.processing : ProcessingState.completed,
      createdAt: created,
      updatedAt: created,
    );
  }).toList();
  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async =>
      (await notes(accountId, projectId)).firstWhere((n) => n.id == noteId);
  @override
  Future<KnowledgeGraph> graph(String accountId, String projectId) async {
    final values = await notes(accountId, projectId);
    return KnowledgeGraph(
      nodes: [
        for (final n in values)
          KnowledgeGraphNode(id: n.id, title: n.title, concepts: n.concepts, updatedAt: n.updatedAt),
      ],
      edges: [for (final e in fixture['edges'] as List) GraphRelationship(e[0] as String, e[1] as String, const [])],
    );
  }

  @override
  Future<List<NoteSourceReference>> related(String accountId, String noteId) async {
    final values = await notes(accountId, projectId);
    final ids = <String>{
      for (final e in fixture['edges'] as List)
        if (e.contains(noteId)) (e[0] == noteId ? e[1] : e[0]) as String,
    };
    return [
      for (final n in values)
        if (ids.contains(n.id)) NoteSourceReference(n.id, n.title),
    ];
  }
}
