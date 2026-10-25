import 'package:flutter/material.dart';

import '../../core/bidi.dart';
import '../../core/document/ocr_document.dart';
import '../labels.dart';
import '../theme.dart';
import 'span_table.dart';

/// Renders parsed blocks: each block takes the direction of its own text, so
/// English lines inside an Arabic page read left to right.
class DocumentView extends StatelessWidget {
  const DocumentView({
    super.key,
    required this.blocks,
    required this.textScale,
    this.onCopyTable,
    this.onSaveTable,
    this.writing = false,
  });

  final List<DocBlock> blocks;
  final double textScale;
  final void Function(TableBlock table)? onCopyTable;
  final void Function(TableBlock table)? onSaveTable;

  /// Shows a "writing" indicator after the last block.
  final bool writing;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      children.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : _gapBefore(blocks[i])),
          child: _block(context, blocks[i]),
        ),
      );
    }
    if (writing) children.add(const _WritingDots());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  double _gapBefore(DocBlock b) => switch (b) {
    HeadingBlock() => 18 * textScale,
    TableBlock() => 14,
    ListBlock() => 6 * textScale,
    _ => 6 * textScale,
  };

  Widget _block(BuildContext context, DocBlock b) {
    final base = AppTheme.reading(context, textScale);
    final cs = Theme.of(context).colorScheme;
    return switch (b) {
      HeadingBlock(:final level, :final runs) => _dir(
        runs.plain,
        Text.rich(
          _spans(runs),
          style: base.copyWith(
            fontSize:
                base.fontSize! *
                switch (level) {
                  1 => 1.45,
                  2 => 1.28,
                  3 => 1.15,
                  _ => 1.05,
                },
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ),
      ParagraphBlock(:final runs) => _dir(
        runs.plain,
        Text.rich(_spans(runs), style: base),
      ),
      QuoteBlock(:final runs) => _dir(
        runs.plain,
        Container(
          padding: const EdgeInsetsDirectional.only(start: 14),
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: cs.outline, width: 3),
            ),
          ),
          child: Text.rich(
            _spans(runs),
            style: base.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ),
      RuleBlock() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: cs.outlineVariant),
      ),
      ListBlock(:final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            _dir(
              item.runs.plain,
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: 22.0 * item.level * textScale,
                  bottom: 2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 22 * textScale),
                      child: Text(
                        item.marker,
                        style: base.copyWith(
                          color: item.marker == '•'
                              ? cs.primary
                              : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text.rich(_spans(item.runs), style: base)),
                  ],
                ),
              ),
            ),
        ],
      ),
      TableBlock() => _TableCard(
        table: b,
        textScale: textScale,
        onCopy: onCopyTable,
        onSave: onSaveTable,
      ),
    };
  }

  static Widget _dir(String text, Widget child) => Directionality(
    textDirection: Bidi.isRtl(text) ? TextDirection.rtl : TextDirection.ltr,
    child: child,
  );

  static TextSpan _spans(List<TextRun> runs) => TextSpan(
    children: [
      for (final r in runs)
        TextSpan(
          text: r.text,
          style: TextStyle(
            fontWeight: r.bold ? FontWeight.w700 : null,
            fontStyle: r.italic ? FontStyle.italic : null,
          ),
        ),
    ],
  );
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.table,
    required this.textScale,
    this.onCopy,
    this.onSave,
  });

  final TableBlock table;
  final double textScale;
  final void Function(TableBlock)? onCopy;
  final void Function(TableBlock)? onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
    final rtl = Bidi.isRtl(table.plainText);
    final dir = rtl ? TextDirection.rtl : TextDirection.ltr;
    final style = AppTheme.reading(
      context,
      textScale * 0.88,
    ).copyWith(height: 1.55);
    final cells = <Widget>[];
    for (var r = 0; r < table.rowCount; r++) {
      for (var c = 0; c < table.columnCount; c++) {
        final slot = table.grid[r][c];
        if (slot == null) {
          cells.add(SpanCell(row: r, col: c, child: const SizedBox()));
          continue;
        }
        if (!slot.isOriginAt(r, c)) continue;
        final cell = slot.cell;
        cells.add(
          SpanCell(
            row: r,
            col: c,
            rowSpan: cell.rowSpan,
            colSpan: cell.colSpan,
            child: Container(
              color: cell.header ? cs.surfaceContainerHigh : null,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                cell.text,
                textDirection: Bidi.isRtl(cell.text)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: style.copyWith(
                  fontWeight: cell.header ? FontWeight.w700 : null,
                ),
              ),
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (table.caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              table.caption!,
              textDirection: dir,
              style: style.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(color: cs.surfaceContainerLowest),
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: rtl,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: box.maxWidth),
                  child: SpanTable(
                    rows: table.rowCount,
                    columns: table.columnCount,
                    textDirection: dir,
                    borderColor: cs.outlineVariant,
                    maxColumnWidth: 280 * textScale,
                    children: cells,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onCopy != null || onSave != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: 4,
              children: [
                if (onCopy != null)
                  TextButton.icon(
                    onPressed: () => onCopy!(table),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l.copyTable),
                  ),
                if (onSave != null)
                  TextButton.icon(
                    onPressed: () => onSave!(table),
                    icon: const Icon(Icons.grid_on_rounded, size: 18),
                    label: Text(l.saveTable),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WritingDots extends StatefulWidget {
  const _WritingDots();

  @override
  State<_WritingDots> createState() => _WritingDotsState();
}

class _WritingDotsState extends State<_WritingDots>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = (_c.value - i * 0.18) % 1.0;
                final o = 0.25 + 0.75 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsetsDirectional.only(end: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: o),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
