import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:arabic_ocr/core/document/document_parser.dart';
import 'package:arabic_ocr/core/document/ocr_document.dart';
import 'package:arabic_ocr/core/export/export_format.dart';
import 'package:arabic_ocr/core/export/office_exporters.dart';
import 'package:arabic_ocr/core/export/text_exporters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// Set EXPORT_DIR to also write the files for a look in Word/LibreOffice.
final _dumpDir = Platform.environment['EXPORT_DIR'];

final _samples = (jsonDecode(
  File('test/fixtures/model_outputs.json').readAsStringSync(),
) as Map<String, dynamic>).cast<String, String>();

OcrDocument _doc() => OcrDocument([
  DocumentParser.parse(
    '# جدول النتائج\n'
    '**الشاهد:** نص عربي مع English words و ١٢٣.\n'
    '- بند أول\n- بند ثان\n'
    '<table><tr><th>الرأي</th><th>العدد</th><th>المتوسط</th></tr>'
    '<tr><td>فعالة</td><td>٧٥</td><td rowspan="2">٤,٥٩</td></tr>'
    '<tr><td>فعالة جدا</td><td>١٩٩</td></tr>'
    '<tr><td colspan="2">المجموع</td><td>٣٠٠</td></tr></table>\n'
    'سطر بعد الجدول',
  ),
  DocumentParser.parse(_samples['table']!),
]);

Map<String, String> _unzip(List<int> bytes) {
  final a = ZipDecoder().decodeBytes(bytes);
  return {
    for (final f in a.files)
      if (f.isFile) f.name: utf8.decode(f.content as List<int>),
  };
}

void _dump(String name, List<int> bytes) {
  if (_dumpDir == null) return;
  Directory(_dumpDir!).createSync(recursive: true);
  File('$_dumpDir/$name').writeAsBytesSync(bytes);
}

void main() {
  test('format suggestions follow the content', () {
    expect(ExportFormat.suggestionsFor(_doc()).first, ExportFormat.docx);
    expect(ExportFormat.suggestionsFor(_doc()), contains(ExportFormat.xlsx));
    final plain = OcrDocument([
      DocumentParser.parse('سطر\nسطر آخر', structured: false),
    ]);
    expect(ExportFormat.suggestionsFor(plain).first, ExportFormat.txt);
    expect(
      ExportFormat.suggestionsFor(plain),
      isNot(contains(ExportFormat.xlsx)),
    );
    final headings = OcrDocument([DocumentParser.parse('# عنوان\nنص')]);
    expect(ExportFormat.suggestionsFor(headings).first, ExportFormat.docx);
  });

  test('plain text keeps tables as tab-separated rows', () {
    final t = TextExporters.toPlainText(_doc());
    expect(t, contains('الرأي\tالعدد\tالمتوسط'));
    expect(t, contains('فعالة\t٧٥\t٤,٥٩'));
    expect(t, contains('• بند أول'));
    _dump('doc.txt', utf8.encode(t));
  });

  test('markdown: pipe tables when simple, HTML when spanned', () {
    final md = TextExporters.toMarkdown(_doc());
    expect(md, contains('# جدول النتائج'));
    expect(md, contains('**الشاهد:**'));
    expect(md, contains('<td rowspan="2">٤,٥٩</td>'));
    expect(md, contains('| نص الآية | اسم السورة | رقمها |'));
    expect(md, contains('<!-- page 2 -->'));
    // round trip through our own parser keeps the tables
    final back = OcrDocument([DocumentParser.parse(md)]);
    expect(back.tables, hasLength(2));
    expect(back.tables.first.matrix, _doc().tables.first.matrix);
    _dump('doc.md', utf8.encode(md));
  });

  test('html is a standalone RTL page with spans', () {
    final html = TextExporters.toHtml(_doc(), title: 'نتيجة');
    expect(html, startsWith('<!doctype html>'));
    expect(html, contains('dir="rtl"'));
    expect(html, contains('<th>الرأي</th>'));
    expect(html, contains('rowspan="2"'));
    expect(html, contains('colspan="2"'));
    expect(html, contains('<p dir="rtl"><strong>الشاهد:</strong>'));
    expect('<section class="page">'.allMatches(html), hasLength(2));
    _dump('doc.html', utf8.encode(html));
  });

  test('csv has a BOM and quotes what needs quoting', () {
    final csv = TextExporters.toCsv(_doc());
    expect(csv.codeUnitAt(0), 0xFEFF);
    expect(csv, contains('الرأي,العدد,المتوسط'));
    expect(csv, contains('فعالة,٧٥,"٤,٥٩"'));
    _dump('tables.csv', utf8.encode(csv));
  });

  test('docx is a valid package with RTL paragraphs and merged cells', () {
    final bytes = OfficeExporters.toDocx(_doc(), title: 'نتيجة');
    final files = _unzip(bytes);
    expect(
      files.keys,
      containsAll([
        '[Content_Types].xml',
        '_rels/.rels',
        'word/document.xml',
        'word/styles.xml',
        'word/_rels/document.xml.rels',
        'docProps/core.xml',
      ]),
    );
    for (final f in files.entries) {
      expect(() => XmlDocument.parse(f.value), returnsNormally, reason: f.key);
    }
    final doc = XmlDocument.parse(files['word/document.xml']!);
    String count(String name) => doc.findAllElements(name).length.toString();
    expect(count('w:tbl'), '2');
    expect(count('w:bidiVisual'), '2');
    expect(doc.findAllElements('w:vMerge').length, 2); // restart + continue
    expect(doc.findAllElements('w:gridSpan').length, greaterThanOrEqualTo(1));
    // every table row has as many grid columns as the table
    final firstTable = doc.findAllElements('w:tbl').first;
    for (final tr in firstTable.findAllElements('w:tr')) {
      var cols = 0;
      for (final tc in tr.findElements('w:tc')) {
        final span = tc
            .findAllElements('w:gridSpan')
            .firstOrNull
            ?.getAttribute('w:val');
        cols += int.parse(span ?? '1');
      }
      expect(cols, 3);
    }
    // one page break between the two pages
    expect(
      doc
          .findAllElements('w:br')
          .where((e) => e.getAttribute('w:type') == 'page'),
      hasLength(1),
    );
    expect(files['word/document.xml'], contains('English words'));
    _dump('doc.docx', bytes);
  });

  test('xlsx has one RTL sheet per table with merges', () {
    final bytes = OfficeExporters.toXlsx(_doc());
    final files = _unzip(bytes);
    for (final f in files.entries) {
      expect(() => XmlDocument.parse(f.value), returnsNormally, reason: f.key);
    }
    expect(
      files.keys,
      containsAll(['xl/worksheets/sheet1.xml', 'xl/worksheets/sheet2.xml']),
    );
    final s1 = files['xl/worksheets/sheet1.xml']!;
    expect(s1, contains('rightToLeft="1"'));
    expect(s1, contains('<mergeCell ref="C2:C3"/>'));
    expect(s1, contains('<mergeCell ref="A4:B4"/>'));
    expect(s1, contains('>٤,٥٩<'));
    _dump('tables.xlsx', bytes);
  });

  test('xml-unsafe text is escaped or dropped', () {
    final doc = OcrDocument([
      DocumentParser.parse('a < b & "c" \u0001 d', structured: false),
    ]);
    final files = _unzip(OfficeExporters.toDocx(doc));
    expect(
      () => XmlDocument.parse(files['word/document.xml']!),
      returnsNormally,
    );
    expect(
      files['word/document.xml'],
      contains('a &lt; b &amp; &quot;c&quot;  d'),
    );
  });
}
