import 'dart:convert';
import 'dart:io';

import 'package:arabic_ocr/core/document/document_parser.dart';
import 'package:arabic_ocr/core/document/ocr_document.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real Nuqta-OCR 0.8B outputs (markdown mode) from the upstream benchmark
/// predictions.
final Map<String, String> samples = (jsonDecode(
  File('test/fixtures/model_outputs.json').readAsStringSync(),
) as Map<String, dynamic>).cast<String, String>();

void main() {
  group('structured (markdown mode)', () {
    test('headings, bullets and plain lines', () {
      final page = DocumentParser.parse(
        '# عنوان رئيسي\n## فرعي ##\nسطر أول\nسطر ثان\n- بند\n- بند آخر\nبعد القائمة',
      );
      expect(page.blocks.map((b) => b.runtimeType.toString()), [
        'HeadingBlock',
        'HeadingBlock',
        'ParagraphBlock',
        'ParagraphBlock',
        'ListBlock',
        'ParagraphBlock',
      ]);
      final h2 = page.blocks[1] as HeadingBlock;
      expect(h2.level, 2);
      expect(h2.runs.plain, 'فرعي');
      final list = page.blocks[4] as ListBlock;
      expect(list.ordered, isFalse);
      expect(list.items.map((i) => i.runs.plain), ['بند', 'بند آخر']);
    });

    test('numbered items keep their markers, including Arabic digits', () {
      final page = DocumentParser.parse('٣- الثالث\n٤- الرابع\n10. ten');
      final list = page.blocks.single as ListBlock;
      expect(list.ordered, isTrue);
      expect(list.items.map((i) => i.marker), ['٣-', '٤-', '10.']);
    });

    test('nested bullets get a level', () {
      final page = DocumentParser.parse('- a\n  - b\n    - c');
      final list = page.blocks.single as ListBlock;
      expect(list.items.map((i) => i.level), [0, 1, 2]);
    });

    test('bold and italic runs', () {
      final page = DocumentParser.parse('**الشاهد:** نص *مائل* و <b>غامق</b>');
      final runs = (page.blocks.single as ParagraphBlock).runs;
      expect(runs, [
        const TextRun('الشاهد:', bold: true),
        const TextRun(' نص '),
        const TextRun('مائل', italic: true),
        const TextRun(' و '),
        const TextRun('غامق', bold: true),
      ]);
    });

    test('an unmatched star stays literal', () {
      final page = DocumentParser.parse('٥ * ٣ = ١٥');
      expect((page.blocks.single as ParagraphBlock).runs.plain, '٥ * ٣ = ١٥');
    });

    test('entities are decoded and <br> breaks a line', () {
      final page = DocumentParser.parse('A &amp; B<br>C');
      expect((page.blocks.single as ParagraphBlock).runs.plain, 'A & B\nC');
    });

    test('rules and image placeholders', () {
      final page = DocumentParser.parse('<img>image here</img>\nقبل\n---\nبعد');
      expect(page.blocks.map((b) => b.runtimeType.toString()), [
        'ParagraphBlock',
        'RuleBlock',
        'ParagraphBlock',
      ]);
    });

    test('an HTML table between lines with no blank lines', () {
      final page = DocumentParser.parse(samples['table']!);
      final tables = page.tables.toList();
      expect(tables, hasLength(1));
      final t = tables.single;
      expect(t.hasHeaderRow, isTrue);
      expect(t.columnCount, 3);
      expect(t.rowCount, 4);
      expect(t.matrix.first, ['نص الآية', 'اسم السورة', 'رقمها']);
      expect(t.matrix[2][1], 'الدخان');
      // the text after </table> is still read
      expect(page.blocks.last, isA<ParagraphBlock>());
      expect(page.plainText, contains('الإعراب'));
    });

    test('colspan expands to the full width', () {
      final t = DocumentParser.parse(samples['colspan']!).tables.first;
      expect(t.hasSpans, isTrue);
      expect(t.columnCount, 2);
      final spanRow = t.grid.indexWhere((r) => r[0]!.cell.colSpan == 2);
      expect(spanRow, isNonNegative);
      expect(t.grid[spanRow][1]!.isOriginAt(spanRow, 1), isFalse);
      expect(t.matrix[spanRow][1], '');
    });

    test('rowspan covers the rows below', () {
      final t = DocumentParser.parseHtmlTable(
        '<table><tr><th>الرأي</th><th>العدد</th><th>المتوسط</th></tr>'
        '<tr><td>فعالة</td><td>٧٥</td><td rowspan="2">٤,٥٩</td></tr>'
        '<tr><td>فعالة جدا</td><td>١٩٩</td></tr></table>',
      )!;
      expect(t.columnCount, 3);
      expect(t.matrix, [
        ['الرأي', 'العدد', 'المتوسط'],
        ['فعالة', '٧٥', '٤,٥٩'],
        ['فعالة جدا', '١٩٩', ''],
      ]);
      expect(t.grid[2][2]!.isOriginAt(2, 2), isFalse);
      expect(t.grid[2][2]!.row, 1);
    });

    test('a table cut off by the token limit is still read', () {
      final page = DocumentParser.parse(
        'قبل\n<table><tr><td>أ</td><td>ب</td></tr><tr><td>ج',
      );
      final t = page.tables.single;
      expect(t.matrix, [
        ['أ', 'ب'],
        ['ج', ''],
      ]);
    });

    test('pipe tables', () {
      final page = DocumentParser.parse(
        '| الاسم | العمر |\n|---|---|\n| علي | ٣٠ |\n| منى | ٢٥ |',
      );
      final t = page.tables.single;
      expect(t.hasHeaderRow, isTrue);
      expect(t.matrix, [
        ['الاسم', 'العمر'],
        ['علي', '٣٠'],
        ['منى', '٢٥'],
      ]);
    });

    test('every sample parses without losing text', () {
      for (final MapEntry(:key, :value) in samples.entries) {
        final page = DocumentParser.parse(value);
        expect(page.blocks, isNotEmpty, reason: key);
        // every Arabic word of the source shows up in the parsed text
        final words = RegExp(r'[ء-ي]{4,}')
            .allMatches(value.replaceAll(RegExp(r'<[^>]+>'), ' '))
            .map((m) => m[0]!)
            .toSet();
        final parsed = page.plainText;
        final missing = words.where((w) => !parsed.contains(w)).toList();
        expect(missing, isEmpty, reason: key);
      }
    });
  });

  group('plain modes', () {
    test('lines are kept as written', () {
      final page = DocumentParser.parse(
        '# ليس عنوانا\n- ليس بندا\n**ليس غامقا**',
        structured: false,
      );
      expect(page.blocks, hasLength(3));
      expect(page.blocks.every((b) => b is ParagraphBlock), isTrue);
      expect(page.plainText, '# ليس عنوانا\n\n- ليس بندا\n\n**ليس غامقا**');
    });

    test('tables are still recognised', () {
      final page = DocumentParser.parse(
        'نص\n<table><tr><td>١</td></tr></table>',
        structured: false,
      );
      expect(page.tables, hasLength(1));
    });
  });
}
