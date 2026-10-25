/// A structured reading of one or more pages: what the model wrote, parsed into
/// blocks that can be shown, copied and exported.
library;

/// A run of inline text with simple emphasis.
class TextRun {
  const TextRun(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is TextRun &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic;

  @override
  int get hashCode => Object.hash(text, bold, italic);

  @override
  String toString() =>
      'TextRun("$text"${bold ? ', b' : ''}${italic ? ', i' : ''})';
}

extension TextRunsPlain on List<TextRun> {
  String get plain => map((r) => r.text).join();
}

sealed class DocBlock {
  const DocBlock();

  /// The block as plain text (tables as tab-separated rows).
  String get plainText;
}

final class HeadingBlock extends DocBlock {
  const HeadingBlock(this.level, this.runs);

  /// 1..6
  final int level;
  final List<TextRun> runs;

  @override
  String get plainText => runs.plain;
}

final class ParagraphBlock extends DocBlock {
  const ParagraphBlock(this.runs);

  final List<TextRun> runs;

  @override
  String get plainText => runs.plain;
}

class ListItem {
  const ListItem(this.marker, this.runs, {this.level = 0});

  /// The marker as written ("1.", "٣-") for numbered items, "•" otherwise.
  final String marker;
  final List<TextRun> runs;

  /// Nesting depth, 0 for top-level items.
  final int level;
}

final class ListBlock extends DocBlock {
  const ListBlock({required this.ordered, required this.items});

  final bool ordered;
  final List<ListItem> items;

  @override
  String get plainText => [
    for (final item in items)
      '${'  ' * item.level}${item.marker} ${item.runs.plain}',
  ].join('\n');
}

final class QuoteBlock extends DocBlock {
  const QuoteBlock(this.runs);

  final List<TextRun> runs;

  @override
  String get plainText => runs.plain;
}

final class RuleBlock extends DocBlock {
  const RuleBlock();

  @override
  String get plainText => '';
}

class TableCell {
  const TableCell(
    this.text, {
    this.header = false,
    this.colSpan = 1,
    this.rowSpan = 1,
  });

  final String text;
  final bool header;
  final int colSpan;
  final int rowSpan;

  @override
  bool operator ==(Object other) =>
      other is TableCell &&
      other.text == text &&
      other.header == header &&
      other.colSpan == colSpan &&
      other.rowSpan == rowSpan;

  @override
  int get hashCode => Object.hash(text, header, colSpan, rowSpan);

  @override
  String toString() =>
      'TableCell("$text"${header ? ', th' : ''}${colSpan > 1 ? ', cs$colSpan' : ''}${rowSpan > 1 ? ', rs$rowSpan' : ''})';
}

/// One cell position in the expanded grid of a table.
class GridSlot {
  const GridSlot(this.cell, {required this.row, required this.col});

  final TableCell cell;

  /// Grid position of the cell's top-left slot.
  final int row;
  final int col;

  /// True when this slot is at [row], [col] (not where a span continues).
  bool isOriginAt(int r, int c) => r == row && c == col;
}

final class TableBlock extends DocBlock {
  TableBlock(this.rows, {this.caption});

  final List<List<TableCell>> rows;
  final String? caption;

  late final List<List<GridSlot?>> grid = _expand();

  int get columnCount => grid.isEmpty ? 0 : grid.first.length;
  int get rowCount => grid.length;
  bool get hasSpans =>
      rows.any((r) => r.any((c) => c.colSpan > 1 || c.rowSpan > 1));
  bool get hasHeaderRow =>
      rows.isNotEmpty &&
      rows.first.isNotEmpty &&
      rows.first.every((c) => c.header);

  /// The table as a rectangle of strings; a spanned cell's text sits at its
  /// top-left slot and the slots it covers are empty.
  List<List<String>> get matrix => [
    for (var r = 0; r < grid.length; r++)
      [
        for (var c = 0; c < grid[r].length; c++)
          (grid[r][c]?.isOriginAt(r, c) ?? false) ? grid[r][c]!.cell.text : '',
      ],
  ];

  /// Tab-separated rows, ready to paste into a spreadsheet.
  String get tsv => matrix
      .map(
        (row) =>
            row.map((t) => t.replaceAll(RegExp(r'[\t\n]+'), ' ')).join('\t'),
      )
      .join('\n');

  @override
  String get plainText =>
      [if (caption != null && caption!.isNotEmpty) caption!, tsv].join('\n');

  List<List<GridSlot?>> _expand() {
    final out = <List<GridSlot?>>[];
    var width = 0;
    for (var r = 0; r < rows.length; r++) {
      while (out.length <= r) {
        out.add(<GridSlot?>[]);
      }
      var c = 0;
      for (final cell in rows[r]) {
        while (c < out[r].length && out[r][c] != null) {
          c++;
        }
        for (var dr = 0; dr < cell.rowSpan; dr++) {
          final rr = r + dr;
          while (out.length <= rr) {
            out.add(<GridSlot?>[]);
          }
          for (var dc = 0; dc < cell.colSpan; dc++) {
            final cc = c + dc;
            while (out[rr].length <= cc) {
              out[rr].add(null);
            }
            out[rr][cc] = GridSlot(cell, row: r, col: c);
          }
        }
        c += cell.colSpan;
      }
    }
    // a rowspan may run past the last row; keep only rows the table declared
    if (out.length > rows.length) out.removeRange(rows.length, out.length);
    for (final row in out) {
      if (row.length > width) width = row.length;
    }
    for (final row in out) {
      while (row.length < width) {
        row.add(null);
      }
    }
    return out;
  }
}

/// One page of a reading.
class DocPage {
  const DocPage(this.blocks);

  final List<DocBlock> blocks;

  Iterable<TableBlock> get tables => blocks.whereType<TableBlock>();

  String get plainText =>
      blocks.map((b) => b.plainText).where((t) => t.isNotEmpty).join('\n\n');
}

class OcrDocument {
  const OcrDocument(this.pages, {this.title});

  final List<DocPage> pages;
  final String? title;

  Iterable<DocBlock> get blocks => pages.expand((p) => p.blocks);
  List<TableBlock> get tables => blocks.whereType<TableBlock>().toList();
  bool get hasTables => blocks.any((b) => b is TableBlock);

  /// True when there is more than paragraphs of text (headings, lists, tables).
  bool get isStructured =>
      blocks.any((b) => b is! ParagraphBlock && b is! RuleBlock);

  bool get isEmpty => blocks.isEmpty;

  String get plainText =>
      pages.map((p) => p.plainText).where((t) => t.isNotEmpty).join('\n\n');
}
