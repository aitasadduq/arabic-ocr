import 'dart:convert';

import '../bidi.dart';
import '../document/ocr_document.dart';

/// Plain text, Markdown, HTML and CSV renderings of an [OcrDocument].
abstract final class TextExporters {
  /// Plain text. Tables become tab-separated rows; pages are separated by a
  /// blank line.
  static String toPlainText(OcrDocument doc) => doc.plainText;

  // ---------------------------------------------------------------- Markdown

  static final _standardMarker = RegExp(r'^\d+[.)]$');

  static String toMarkdown(OcrDocument doc) {
    final out = <String>[];
    for (var p = 0; p < doc.pages.length; p++) {
      if (doc.pages.length > 1) out.add('<!-- page ${p + 1} -->');
      for (final b in doc.pages[p].blocks) {
        out.add(_mdBlock(b));
      }
    }
    return '${out.where((s) => s.isNotEmpty).join('\n\n')}\n';
  }

  static String _mdBlock(DocBlock b) => switch (b) {
    HeadingBlock(:final level, :final runs) =>
      '${'#' * level} ${_mdRuns(runs)}',
    ParagraphBlock(:final runs) => _mdRuns(runs),
    QuoteBlock(:final runs) => '> ${_mdRuns(runs)}',
    RuleBlock() => '---',
    ListBlock(:final items) =>
      items
          .map((i) {
            final indent = '  ' * i.level;
            if (i.marker == '•') return '$indent- ${_mdRuns(i.runs)}';
            if (_standardMarker.hasMatch(i.marker)) {
              return '$indent${i.marker} ${_mdRuns(i.runs)}';
            }
            // "٣-" is not a Markdown list marker: keep it as text on its own line
            return '$indent${i.marker} ${_mdRuns(i.runs)}  ';
          })
          .join('\n'),
    TableBlock() => b.hasSpans ? _htmlTable(b) : _pipeTable(b),
  };

  static String _mdRuns(List<TextRun> runs) => runs.map((r) {
    var t = r.text.replaceAll('\n', '  \n');
    if (t.trim().isEmpty) return t;
    if (r.italic) t = '*$t*';
    if (r.bold) t = '**$t**';
    return t;
  }).join();

  static String _pipeTable(TableBlock t) {
    String row(List<String> cells) =>
        '| ${cells.map((c) => c.replaceAll('|', r'\|').replaceAll('\n', '<br>')).join(' | ')} |';
    final m = t.matrix;
    if (m.isEmpty) return '';
    final lines = <String>[
      if (t.caption != null) '**${t.caption}**\n',
      row(m.first),
      '|${List.filled(t.columnCount, ' --- ').join('|')}|',
      for (final r in m.skip(1)) row(r),
    ];
    return lines.join('\n');
  }

  // -------------------------------------------------------------------- HTML

  static const _css = '''
body{font-family:"Noto Naskh Arabic","Geeza Pro","Traditional Arabic","Times New Roman",serif;line-height:1.9;max-width:50rem;margin:2rem auto;padding:0 1.25rem;color:#1d1b18;background:#fff}
h1,h2,h3,h4,h5,h6{line-height:1.4;margin:1.4em 0 .5em}
p{margin:.35em 0}
table{border-collapse:collapse;margin:1rem 0;width:100%}
th,td{border:1px solid #9a948a;padding:.35rem .6rem;text-align:start;vertical-align:top}
th{background:#f1ede6;font-weight:600}
blockquote{margin:.6em 0;padding:.2em 1em;border-inline-start:3px solid #c9c2b6;color:#55504a}
hr{border:0;border-top:1px solid #ddd6cb;margin:1.2em 0}
.page+.page{border-top:1px dashed #c9c2b6;margin-top:2.5rem;padding-top:1.5rem}
@media print{.page{break-after:page}.page+.page{border:0;margin:0;padding:0}}
''';

  static String toHtml(OcrDocument doc, {String title = 'OCR'}) {
    final rtl = Bidi.mostlyRtl(doc.blocks.map((b) => b.plainText));
    final b = StringBuffer()
      ..write(
        '<!doctype html>\n<html lang="${rtl ? 'ar' : 'en'}" dir="${rtl ? 'rtl' : 'ltr'}">\n',
      )
      ..write('<head>\n<meta charset="utf-8">\n')
      ..write(
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n',
      )
      ..write(
        '<title>${_esc(title)}</title>\n<style>$_css</style>\n</head>\n<body>\n',
      );
    for (final page in doc.pages) {
      b.write('<section class="page">\n');
      for (final block in page.blocks) {
        b
          ..write(_htmlBlock(block))
          ..write('\n');
      }
      b.write('</section>\n');
    }
    b.write('</body>\n</html>\n');
    return b.toString();
  }

  static String _dir(String text) => Bidi.isRtl(text) ? 'rtl' : 'ltr';

  static String _htmlBlock(DocBlock block) => switch (block) {
    HeadingBlock(:final level, :final runs) =>
      '<h$level dir="${_dir(runs.plain)}">${_htmlRuns(runs)}</h$level>',
    ParagraphBlock(:final runs) =>
      '<p dir="${_dir(runs.plain)}">${_htmlRuns(runs)}</p>',
    QuoteBlock(:final runs) =>
      '<blockquote dir="${_dir(runs.plain)}">${_htmlRuns(runs)}</blockquote>',
    RuleBlock() => '<hr>',
    ListBlock(:final items) => _htmlList(items),
    TableBlock() => _htmlTable(block),
  };

  static String _htmlList(List<ListItem> items) {
    // markers are kept as written ("٣-"), so the list draws none of its own
    final b = StringBuffer(
      '<ul style="list-style:none;padding-inline-start:0">',
    );
    for (final i in items) {
      final pad = 1.5 * i.level;
      b.write(
        '<li dir="${_dir(i.runs.plain)}" style="padding-inline-start:${pad}em">'
        '${_esc(i.marker)} ${_htmlRuns(i.runs)}</li>',
      );
    }
    b.write('</ul>');
    return b.toString();
  }

  static String _htmlRuns(List<TextRun> runs) => runs.map((r) {
    var t = _esc(r.text).replaceAll('\n', '<br>');
    if (r.italic) t = '<em>$t</em>';
    if (r.bold) t = '<strong>$t</strong>';
    return t;
  }).join();

  static String _htmlTable(TableBlock t) {
    final b = StringBuffer('<table dir="${_dir(t.plainText)}">');
    if (t.caption != null) b.write('<caption>${_esc(t.caption!)}</caption>');
    for (final row in t.rows) {
      b.write('<tr>');
      for (final c in row) {
        final tag = c.header ? 'th' : 'td';
        final span =
            '${c.colSpan > 1 ? ' colspan="${c.colSpan}"' : ''}'
            '${c.rowSpan > 1 ? ' rowspan="${c.rowSpan}"' : ''}';
        b.write('<$tag$span>${_esc(c.text).replaceAll('\n', '<br>')}</$tag>');
      }
      b.write('</tr>');
    }
    b.write('</table>');
    return b.toString();
  }

  static String _esc(String s) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(s);

  // --------------------------------------------------------------------- CSV

  /// The document's tables as CSV (RFC 4180), separated by a blank line.
  /// Starts with a UTF-8 byte order mark so Excel reads Arabic correctly.
  static String toCsv(OcrDocument doc) {
    String field(String s) =>
        RegExp(r'[",\n\r]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
    final tables = doc.tables.map(
      (t) => t.matrix.map((row) => row.map(field).join(',')).join('\r\n'),
    );
    return '﻿${tables.join('\r\n\r\n')}\r\n';
  }
}
