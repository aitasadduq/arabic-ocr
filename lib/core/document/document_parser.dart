import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import 'ocr_document.dart';

/// Parses what Nuqta-OCR writes into an [OcrDocument] page.
///
/// The model's Markdown is line-oriented: one line per paragraph, `#`
/// headings, `-` / `1.` / `١-` list items, `**bold**`, and tables as HTML
/// (`<table>` with optional `colspan` / `rowspan`), often with no blank line
/// around them. CommonMark would merge consecutive lines into one paragraph,
/// so this parser reads line by line instead.
///
/// In plain modes ([structured] false) lines are kept as written and only
/// tables are recognised.
abstract final class DocumentParser {
  static final _tableStart = RegExp(r'<table\b', caseSensitive: false);
  static final _tableEnd = RegExp(r'</table\s*>', caseSensitive: false);
  static final _imagePlaceholder = RegExp(
    r'<img>[^<]*</img>',
    caseSensitive: false,
  );
  static final _heading = RegExp(r'^(#{1,6})\s+(.*?)\s*#*\s*$');
  static final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
  static final _bullet = RegExp(r'^(\s*)[-*•+●▪◦]\s+(.*)$');
  static final _numbered = RegExp(
    r'^(\s*)((?:[0-9٠-٩۰-۹]{1,3})[.)\-–])\s+(.*)$',
  );
  static final _quote = RegExp(r'^\s*>\s?(.*)$');
  static final _pipeRow = RegExp(r'^\s*\|.*\|\s*$');
  static final _pipeSeparator = RegExp(
    r'^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$',
  );
  static final _space = RegExp(r'[ \t ]+');
  static final _hasMarkup = RegExp(r'[<&*_]');

  static DocPage parse(String text, {bool structured = true}) {
    final blocks = <DocBlock>[];
    final src = text.replaceAll('\r\n', '\n').replaceAll(_imagePlaceholder, '');
    var pos = 0;
    while (pos < src.length) {
      final start = _tableStart.firstMatch(src.substring(pos));
      final textEnd = start == null ? src.length : pos + start.start;
      _parseLines(src.substring(pos, textEnd), structured, blocks);
      if (start == null) break;
      final rest = src.substring(textEnd);
      final end = _tableEnd.firstMatch(rest);
      final tableHtml = end == null ? rest : rest.substring(0, end.end);
      final table = parseHtmlTable(tableHtml);
      if (table != null) blocks.add(table);
      pos = textEnd + tableHtml.length;
    }
    return DocPage(blocks);
  }

  /// Parses one HTML table (tolerates unclosed tags and a missing `</table>`).
  static TableBlock? parseHtmlTable(String source) {
    final fragment = html.parseFragment(source);
    final table = fragment.querySelector('table');
    if (table == null) return null;
    final rows = <List<TableCell>>[];
    for (final tr in table.querySelectorAll('tr')) {
      // skip rows of nested tables
      if (_closestTable(tr) != table) continue;
      final cells = <TableCell>[];
      for (final cell in tr.children) {
        final tag = cell.localName;
        if (tag != 'td' && tag != 'th') continue;
        cells.add(
          TableCell(
            _cellText(cell),
            header: tag == 'th',
            colSpan: _span(cell.attributes['colspan']),
            rowSpan: _span(cell.attributes['rowspan']),
          ),
        );
      }
      if (cells.isNotEmpty) rows.add(cells);
    }
    if (rows.isEmpty) return null;
    final caption = table.querySelector('caption')?.text.trim();
    return TableBlock(
      rows,
      caption: (caption?.isEmpty ?? true) ? null : caption,
    );
  }

  static dom.Element? _closestTable(dom.Element e) {
    dom.Element? p = e.parent;
    while (p != null && p.localName != 'table') {
      p = p.parent;
    }
    return p;
  }

  static int _span(String? v) {
    final n = int.tryParse(v?.trim() ?? '') ?? 1;
    return n.clamp(1, 100);
  }

  static String _cellText(dom.Element cell) {
    final buf = StringBuffer();
    void walk(dom.Node n) {
      if (n is dom.Text) {
        buf.write(n.text);
      } else if (n is dom.Element) {
        if (n.localName == 'br') {
          buf.write('\n');
          return;
        }
        final block =
            n.localName == 'p' || n.localName == 'div' || n.localName == 'li';
        if (block && buf.isNotEmpty) buf.write('\n');
        n.nodes.forEach(walk);
      }
    }

    cell.nodes.forEach(walk);
    return buf
        .toString()
        .split('\n')
        .map((l) => l.replaceAll(_space, ' ').trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
  }

  static void _parseLines(String text, bool structured, List<DocBlock> out) {
    final lines = text.split('\n');
    ListBlock? list;
    final pipe = <String>[];

    void endList() {
      if (list != null) out.add(list!);
      list = null;
    }

    void endPipe() {
      if (pipe.isEmpty) return;
      final table = _pipeTable(pipe);
      if (table != null) {
        out.add(table);
      } else {
        for (final l in pipe) {
          out.add(ParagraphBlock(_inline(l)));
        }
      }
      pipe.clear();
    }

    void addItem(bool ordered, ListItem item) {
      if (list != null && list!.ordered != ordered && item.level == 0) {
        endList();
      }
      list ??= ListBlock(ordered: ordered, items: []);
      list!.items.add(item);
    }

    for (final raw in lines) {
      final line = raw.trimRight();
      if (!structured) {
        if (line.trim().isEmpty) continue;
        out.add(ParagraphBlock([TextRun(line.trim())]));
        continue;
      }
      if (_pipeRow.hasMatch(line)) {
        endList();
        pipe.add(line);
        continue;
      }
      endPipe();
      if (line.trim().isEmpty) {
        endList();
        continue;
      }
      RegExpMatch? m;
      if ((m = _heading.firstMatch(line.trim())) != null) {
        endList();
        out.add(HeadingBlock(m!.group(1)!.length, _inline(m.group(2)!)));
      } else if (_rule.hasMatch(line)) {
        endList();
        out.add(const RuleBlock());
      } else if ((m = _bullet.firstMatch(line)) != null) {
        addItem(
          false,
          ListItem('•', _inline(m!.group(2)!), level: _level(m.group(1)!)),
        );
      } else if ((m = _numbered.firstMatch(line)) != null) {
        addItem(
          true,
          ListItem(
            m!.group(2)!,
            _inline(m.group(3)!),
            level: _level(m.group(1)!),
          ),
        );
      } else if ((m = _quote.firstMatch(line)) != null) {
        endList();
        out.add(QuoteBlock(_inline(m!.group(1)!)));
      } else {
        endList();
        final runs = _inline(line.trim());
        if (runs.plain.trim().isNotEmpty) out.add(ParagraphBlock(runs));
      }
    }
    endPipe();
    endList();
  }

  static int _level(String indent) =>
      (indent.replaceAll('\t', '  ').length ~/ 2).clamp(0, 6);

  static TableBlock? _pipeTable(List<String> lines) {
    List<String> cells(String l) {
      var s = l.trim();
      if (s.startsWith('|')) s = s.substring(1);
      if (s.endsWith('|')) s = s.substring(0, s.length - 1);
      return s.split('|').map((c) => c.trim()).toList();
    }

    if (lines.length < 2) return null;
    final hasHeader = _pipeSeparator.hasMatch(lines[1]);
    final rows = <List<TableCell>>[];
    for (var i = 0; i < lines.length; i++) {
      if (hasHeader && i == 1) continue;
      final header = hasHeader && i == 0;
      rows.add([
        for (final c in cells(lines[i]))
          TableCell(_inline(c).plain, header: header),
      ]);
    }
    return TableBlock(rows);
  }

  /// Inline content: HTML tags (`<b>`, `<br>`, entities) and Markdown
  /// emphasis (`**bold**`, `*italic*`).
  static List<TextRun> _inline(String text) {
    final runs = <TextRun>[];
    if (!_hasMarkup.hasMatch(text)) {
      _add(runs, TextRun(text.replaceAll(_space, ' ')));
      return runs;
    }
    void walk(dom.Node n, bool bold, bool italic) {
      if (n is dom.Text) {
        _emphasis(n.text, bold, italic, runs);
      } else if (n is dom.Element) {
        switch (n.localName) {
          case 'br':
            _add(runs, TextRun('\n', bold: bold, italic: italic));
          case 'b' || 'strong':
            for (final c in n.nodes) {
              walk(c, true, italic);
            }
          case 'i' || 'em':
            for (final c in n.nodes) {
              walk(c, bold, true);
            }
          default:
            for (final c in n.nodes) {
              walk(c, bold, italic);
            }
        }
      }
    }

    for (final n in html.parseFragment(text).nodes) {
      walk(n, false, false);
    }
    return runs;
  }

  static final _emphasisToken = RegExp(r'\*\*|__|\*');

  /// Applies `**` / `__` (bold) and `*` (italic) toggles; unmatched markers stay
  /// as literal text.
  static void _emphasis(
    String text,
    bool bold,
    bool italic,
    List<TextRun> out,
  ) {
    final tokens = _emphasisToken.allMatches(text).toList();
    final counts = <String, int>{};
    for (final t in tokens) {
      counts[t[0]!] = (counts[t[0]!] ?? 0) + 1;
    }
    // only markers that come in pairs toggle style
    final usable = <String, int>{
      for (final e in counts.entries) e.key: e.value - e.value % 2,
    };
    var b = bold, i = italic, last = 0;
    final buf = StringBuffer();
    for (final t in tokens) {
      final tok = t[0]!;
      if ((usable[tok] ?? 0) == 0) continue;
      buf.write(text.substring(last, t.start));
      if (buf.isNotEmpty) {
        _add(
          out,
          TextRun(buf.toString().replaceAll(_space, ' '), bold: b, italic: i),
        );
        buf.clear();
      }
      if (tok == '*') {
        i = !i;
      } else {
        b = !b;
      }
      usable[tok] = usable[tok]! - 1;
      last = t.end;
    }
    buf.write(text.substring(last));
    if (buf.isNotEmpty) {
      _add(
        out,
        TextRun(buf.toString().replaceAll(_space, ' '), bold: b, italic: i),
      );
    }
  }

  static void _add(List<TextRun> runs, TextRun run) {
    if (run.text.isEmpty) return;
    if (runs.isNotEmpty &&
        runs.last.bold == run.bold &&
        runs.last.italic == run.italic) {
      runs[runs.length - 1] = TextRun(
        runs.last.text + run.text,
        bold: run.bold,
        italic: run.italic,
      );
    } else {
      runs.add(run);
    }
  }
}
