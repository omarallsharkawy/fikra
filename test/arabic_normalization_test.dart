import 'package:fikra/core/format.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/links_library_data.dart';
import 'support/selection_fixture.dart';

Note _note(String id, {required String title, String text = '', String concepts = ''}) => Note(
  id: id,
  projectId: 'p',
  title: title,
  originalText: text,
  source: NoteSource.text,
  status: ProcessingStatus.ready,
  rewrite: RewriteStatus.none,
  imagePaths: '',
  concepts: concepts,
  createdAt: DateTime(2026, 11, 10),
  updatedAt: DateTime(2026, 11, 10),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('normalizeArabic', () {
    test('unifies Alef, Taa Marbuta, Alef Maksura, Waw/Yeh Hamza variants', () {
      expect(normalizeArabic('أحمد'), 'احمد');
      expect(normalizeArabic('إبراهيم'), 'ابراهيم');
      expect(normalizeArabic('آمال'), 'امال');
      expect(normalizeArabic('ٱسم'), 'اسم');
      expect(normalizeArabic('مدرسة'), 'مدرسه');
      expect(normalizeArabic('مستشفى'), 'مستشفي');
      expect(normalizeArabic('مؤتمر'), 'موتمر');
      expect(normalizeArabic('قائمة'), 'قايمه');
      expect(normalizeArabic('أ إ آ ٱ ة ى ؤ ئ'), 'ا ا ا ا ه ي و ي');
    });

    test('strips tashkeel (U+064B–U+0652, U+0670) and tatweel (U+0640)', () {
      expect(normalizeArabic('مُحاضَرة'), 'محاضره');
      expect(normalizeArabic('كِتَابٌ بِالتَّشْكِيلِ'), 'كتاب بالتشكيل');
      expect(normalizeArabic('هٰذا'), 'هذا');
      expect(normalizeArabic('فِـــكْـــرَة'), 'فكره');
      expect(normalizeArabic('\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0670\u0640'), '');
    });

    test('converts Arabic-Indic and Eastern Arabic-Indic digits to ASCII 0-9', () {
      expect(normalizeArabic('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(normalizeArabic('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
      expect(normalizeArabic('درس ٣ من ١٠'), 'درس 3 من 10');
    });

    test('lowercases Latin and collapses/trims whitespace', () {
      expect(normalizeArabic('  Flutter   FastAPI\t\nRAG  '), 'flutter fastapi rag');
      expect(normalizeArabic('Café\u00A0ÉLITE'), 'café élite');
      expect(normalizeArabic(''), '');
      expect(normalizeArabic('   \t\n\r  '), '');
    });

    test('lowercases extended Latin (e.g. Polish Łódź) and handles Turkish dotted İ safely', () {
      expect(normalizeArabic('Łódź'), 'łódź');
      expect(normalizeArabic('łódź'), 'łódź');
      expect(matchesNormalizedArabic(normalizeArabic('Łódź'), normalizeArabic('łódź')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('łódź'), normalizeArabic('Łódź')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('ملاحظة عن Łódź اليوم'), normalizeArabic('ملاحظه łódź')), isTrue);
      expect(normalizeArabic('İstanbul'), 'istanbul');
    });

    test('preserves the article ال to prevent false matches', () {
      expect(normalizeArabic('المدرسة'), 'المدرسه');
      expect(normalizeArabic('ألوان'), 'الوان');
      expect(normalizeArabic('الله'), 'الله');
    });
  });

  group('matchesNormalizedArabic (ال tolerance)', () {
    test('matches haystack tokens with leading ال removed when query token has none', () {
      expect(matchesNormalizedArabic(normalizeArabic('المدرسة'), normalizeArabic('مدرسة')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('المدرسة'), normalizeArabic('مدرسه')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('محاضرة المدرسة'), normalizeArabic('محاضرة مدرسة')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('الذكاء الاصطناعي'), normalizeArabic('ذكاء اصطناعي')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('«المدرسة» الجديدة'), normalizeArabic('مدرسه جديده')), isTrue);
    });

    test('does not strip ال when the query token includes it, avoiding false matches', () {
      expect(matchesNormalizedArabic(normalizeArabic('مدرسة'), normalizeArabic('المدرسة')), isFalse);
      expect(matchesNormalizedArabic(normalizeArabic('ديوان الشعر'), normalizeArabic('ألوان')), isFalse);
      expect(matchesNormalizedArabic(normalizeArabic('عنوان الكتاب'), normalizeArabic('ألوان كتاب')), isFalse);
      expect(matchesNormalizedArabic(normalizeArabic('ألوان جميلة'), normalizeArabic('ألوان')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('الكتاب'), normalizeArabic('كتاب ال')), isFalse);
      expect(matchesNormalizedArabic(normalizeArabic('كتاب الال'), normalizeArabic('ال كتاب')), isFalse);
      expect(matchesNormalizedArabic(normalizeArabic('كتاب مدرسة'), normalizeArabic('كتاب ال')), isFalse);
    });

    test('uses bounded distinct-word backtracking so exact and article matches coexist', () {
      expect(matchesNormalizedArabic(normalizeArabic('الكتاب كتاب جديد'), normalizeArabic('كتاب الكتاب')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('الكتاب الكتابة'), normalizeArabic('كتاب الكتاب')), isTrue);
      expect(matchesNormalizedArabic(normalizeArabic('الكتاب'), normalizeArabic('كتاب الكتاب')), isFalse);
      // Pathological unsatisfiable overlapping tokens stay bounded and return false.
      final hay = normalizeArabic(List.generate(12, (i) => 'الكتاب').join(' '));
      final q = normalizeArabic(List.generate(13, (i) => 'كتاب').join(' '));
      expect(matchesNormalizedArabic(hay, q), isFalse);
    });

    test('handles empty query or haystack cleanly', () {
      expect(matchesNormalizedArabic('', ''), isTrue);
      expect(matchesNormalizedArabic('احمد', ''), isTrue);
      expect(matchesNormalizedArabic('', 'احمد'), isFalse);
    });
  });

  group('Notes search', () {
    fikraTest('finds مدرسة/أحمد/مُحاضَرة/المدرسة/digits across Arabic variants', (tester, db) async {
      phone(tester);
      await seedNotes(tester, db, [
        'زيارة مدرسة جديدة',
        'ملاحظة أحمد اليوم',
        'ملخص مُحاضَرة الشبكات',
        'خطة الذكاء الاصطناعي ٣',
      ]);

      Future<void> search(String q) async {
        final field = find.descendant(of: find.byKey(const ValueKey('notes-search')), matching: find.byType(TextField));
        await tester.enterText(field, q);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 400));
      }

      await search('مدرسه');
      expect(find.text('زيارة مدرسة جديدة'), findsOneWidget);
      expect(find.text('ملاحظة أحمد اليوم'), findsNothing);

      await search('احمد');
      expect(find.text('ملاحظة أحمد اليوم'), findsOneWidget);
      expect(find.text('زيارة مدرسة جديدة'), findsNothing);

      await search('محاضرة');
      expect(find.text('ملخص مُحاضَرة الشبكات'), findsOneWidget);
      expect(find.text('ملاحظة أحمد اليوم'), findsNothing);

      await search('ذكاء اصطناعي 3');
      expect(find.text('خطة الذكاء الاصطناعي ٣'), findsOneWidget);
      expect(find.text('ملخص مُحاضَرة الشبكات'), findsNothing);
    });
  });

  group('LinksIndex Arabic matching', () {
    test('matches Arabic normalization variants and ال tolerance and shares cached views', () {
      final index = deriveLinks(
        'p',
        [
          libraryNote('a', day: 1, title: 'زيارة مدرسة', text: 'نص عن أحمد'),
          libraryNote('b', day: 2, title: 'مُحاضَرة الشبكات', text: 'عن المدرسة رقم ٣'),
          libraryNote('c', day: 3, title: 'الذكاء الاصطناعي', text: 'ديوان الشعر'),
        ],
        [libraryLink('ab', 'a', 'b'), libraryLink('bc', 'b', 'c'), libraryLink('ac', 'a', 'c', confirmed: false)],
        const [],
      );

      expect(index.filter(search: 'مدرسه').browse.map((e) => e.note.id), ['b', 'a']);
      expect(index.filter(search: 'احمد').browse.map((e) => e.note.id), ['a']);
      expect(index.filter(search: 'محاضرة').browse.map((e) => e.note.id), ['b']);
      expect(index.filter(search: 'ذكاء اصطناعي').browse.map((e) => e.note.id), ['c']);
      expect(index.filter(search: 'مدرسه 3').browse.map((e) => e.note.id), ['b']);
      expect(index.filter(search: 'ألوان').browse, isEmpty);
      expect(index.filter(search: 'احمد').suggestions.map((e) => e.link.id), ['ac']);
      expect(identical(index.filter(search: 'أحمد'), index.filter(search: 'احمد')), isTrue);
    });

    test('5,000-note non-matching multi-token filter reuses cached word lists without re-tokenizing haystacks', () {
      final data = largeLibraryData();
      final index = deriveLinks('p', data.notes, data.links, data.groups);
      debugArabicTokenizeCount = 0;

      final first = index.filter(search: 'كلمة غير موجودة تماما');
      expect(first.browse, isEmpty);
      expect(first.suggestions, isEmpty);
      // Only the query itself is tokenized once; none of the 5,000 haystacks are re-tokenized.
      expect(debugArabicTokenizeCount, 1);

      final second = index.filter(search: 'استعلام اخر مفقود');
      expect(second.browse, isEmpty);
      expect(debugArabicTokenizeCount, 2);
    });
  });

  group('DemoAiService Arabic matching', () {
    test('ask matches مدرسة/أحمد/مُحاضَرة/المدرسة variants and refreshes cache on note change', () async {
      final ai = DemoAiService(latency: Duration.zero);
      final notes = [
        _note('n1', title: 'المدرسة', text: 'ذهبت إلى مدرسة جديدة'),
        _note('n2', title: 'أحمد', text: 'مقابلة مع أَحْمَد يوم ٣'),
        _note('n3', title: 'مُحاضَرة', text: 'ملخص مُحاضَرة الشبكات'),
      ];

      final school = await ai.ask('مدرسه', notes);
      expect(school.found, isTrue);
      expect(school.sourceIds, contains('n1'));

      final ahmed = await ai.ask('احمد', notes);
      expect(ahmed.found, isTrue);
      expect(ahmed.sourceIds, contains('n2'));

      final lecture = await ai.ask('محاضرة', notes);
      expect(lecture.found, isTrue);
      expect(lecture.sourceIds, contains('n3'));

      // Updated note invalidates the cached haystack entry for that note id.
      final updated = [_note('n2', title: 'أحمد', text: 'ملاحظة عن إبراهيم فقط')];
      final ibrahim = await ai.ask('ابراهيم', updated);
      expect(ibrahim.found, isTrue);
      expect(ibrahim.sourceIds, ['n2']);
    });
  });
}
