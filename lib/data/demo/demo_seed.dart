import '../ai/demo_ai_service.dart';
import '../local/database.dart';
import '../repositories.dart';

/// "جرّب مشروع تجريبي": a ready project so the demo has something to show.
Future<Project> seedDemoProject(ProjectsRepository projects, NotesRepository notes) async {
  final project = await projects.create('مشروع التخرج');
  final ai = DemoAiService(latency: Duration.zero);

  const samples = <(String, String)>[
    ('فكرة المشروع', 'تطبيق نوتس بيستخدم الذكاء الاصطناعي عشان يربط الأفكار ببعض ويجاوب على أسئلتي من نوتسي بس.'),
    (
      'إزاي RAG بيشتغل',
      'الـrag بيجيب أقرب أجزاء من النوتس بالـembedding وبعدين الـllm بيكتب الإجابة منها مع ذكر المصدر',
    ),
    (
      'شكل الواجهة',
      'تصميم الواجهة داكن وبسيط، بالعربي من اليمين للشمال، وفيه أربع تابات: إضافة، النوتس، الروابط، اسأل.',
    ),
    ('إدارة الحالة في Flutter', 'هستخدم riverpod لإدارة الحالة في flutter، وقاعدة بيانات محلية للنسخة التجريبية.'),
    ('الباك إند', 'علاء هيعمل الباك إند بـfastapi و postgres مع pgvector، والتطبيق هيكلمه عن طريق api.'),
    ('البحث الدلالي', 'البحث الدلالي بيدوّر بالمعنى مش بالكلمة، وده معتمد على التضمينات اللي بتتخزن في قاعدة بيانات.'),
    ('محاضرة الشبكات', 'محاضرة الشبكات النهارده كانت عن TCP و UDP، لازم أراجعها قبل الامتحان.'),
  ];

  final base = DateTime.now().subtract(const Duration(days: 2));
  var i = 0;
  for (final (title, text) in samples) {
    // Spread the samples over the last two days so the list shows day groups.
    final note = await notes.create(
      projectId: project.id,
      title: title,
      text: text,
      source: NoteSource.text,
      createdAt: base.add(Duration(hours: i * 7)),
    );
    final insights = await ai.analyze(note, await notes.notesOf(project.id));
    await notes.applyInsights(note.id, insights);
    i++;
  }
  return project;
}
