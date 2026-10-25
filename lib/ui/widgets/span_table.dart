import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Places a [SpanTable] child at a grid position.
class SpanCell extends ParentDataWidget<SpanTableParentData> {
  const SpanCell({
    super.key,
    required this.row,
    required this.col,
    this.rowSpan = 1,
    this.colSpan = 1,
    required super.child,
  });

  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;

  @override
  void applyParentData(RenderObject renderObject) {
    final d = renderObject.parentData! as SpanTableParentData;
    if (d.row != row ||
        d.col != col ||
        d.rowSpan != rowSpan ||
        d.colSpan != colSpan) {
      d
        ..row = row
        ..col = col
        ..rowSpan = rowSpan
        ..colSpan = colSpan;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => SpanTable;
}

/// A table whose cells may span rows and columns (HTML `rowspan` /
/// `colspan`). Columns take the width their content asks for, between
/// [minColumnWidth] and [maxColumnWidth]; when the table is narrower than the
/// incoming minimum width the columns grow to fill it. Rows take the height
/// of their tallest cell. Grid lines are drawn around every cell.
class SpanTable extends MultiChildRenderObjectWidget {
  const SpanTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.textDirection,
    required this.borderColor,
    this.borderWidth = 1,
    this.minColumnWidth = 56,
    this.maxColumnWidth = 320,
    required super.children,
  });

  final int rows;
  final int columns;
  final TextDirection textDirection;
  final Color borderColor;
  final double borderWidth;
  final double minColumnWidth;
  final double maxColumnWidth;

  @override
  RenderSpanTable createRenderObject(BuildContext context) => RenderSpanTable(
    rows: rows,
    columns: columns,
    textDirection: textDirection,
    borderColor: borderColor,
    borderWidth: borderWidth,
    minColumnWidth: minColumnWidth,
    maxColumnWidth: maxColumnWidth,
  );

  @override
  void updateRenderObject(BuildContext context, RenderSpanTable renderObject) {
    renderObject
      ..rows = rows
      ..columns = columns
      ..textDirection = textDirection
      ..borderColor = borderColor
      ..borderWidth = borderWidth
      ..minColumnWidth = minColumnWidth
      ..maxColumnWidth = maxColumnWidth;
  }
}

class SpanTableParentData extends ContainerBoxParentData<RenderBox> {
  int row = 0;
  int col = 0;
  int rowSpan = 1;
  int colSpan = 1;
}

class _Grid {
  _Grid(this.colX, this.rowY);

  /// Column / row start offsets; the last entry is the total extent.
  final List<double> colX;
  final List<double> rowY;

  double get width => colX.last;
  double get height => rowY.last;
}

class RenderSpanTable extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, SpanTableParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, SpanTableParentData> {
  RenderSpanTable({
    required this._rows,
    required this._columns,
    required this._textDirection,
    required this._borderColor,
    required this._borderWidth,
    required this._minColumnWidth,
    required this._maxColumnWidth,
  });

  int _rows;
  set rows(int v) {
    if (v == _rows) return;
    _rows = v;
    markNeedsLayout();
  }

  int _columns;
  set columns(int v) {
    if (v == _columns) return;
    _columns = v;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection v) {
    if (v == _textDirection) return;
    _textDirection = v;
    markNeedsLayout();
  }

  Color _borderColor;
  set borderColor(Color v) {
    if (v == _borderColor) return;
    _borderColor = v;
    markNeedsPaint();
  }

  double _borderWidth;
  set borderWidth(double v) {
    if (v == _borderWidth) return;
    _borderWidth = v;
    markNeedsPaint();
  }

  double _minColumnWidth;
  set minColumnWidth(double v) {
    if (v == _minColumnWidth) return;
    _minColumnWidth = v;
    markNeedsLayout();
  }

  double _maxColumnWidth;
  set maxColumnWidth(double v) {
    if (v == _maxColumnWidth) return;
    _maxColumnWidth = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! SpanTableParentData) {
      child.parentData = SpanTableParentData();
    }
  }

  Iterable<RenderBox> get _cells sync* {
    var child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  SpanTableParentData _data(RenderBox c) =>
      c.parentData! as SpanTableParentData;

  ({int row, int col, int rowSpan, int colSpan}) _span(RenderBox c) {
    final d = _data(c);
    final row = math.min(math.max(d.row, 0), math.max(0, _rows - 1));
    final col = math.min(math.max(d.col, 0), math.max(0, _columns - 1));
    return (
      row: row,
      col: col,
      rowSpan: math.min(math.max(d.rowSpan, 1), _rows - row),
      colSpan: math.min(math.max(d.colSpan, 1), _columns - col),
    );
  }

  List<double> _columnWidths(double minTotal) {
    final w = List<double>.filled(_columns, _minColumnWidth);
    final spanned = <RenderBox>[];
    for (final c in _cells) {
      final s = _span(c);
      if (s.colSpan > 1) {
        spanned.add(c);
        continue;
      }
      final want = c
          .getMaxIntrinsicWidth(double.infinity)
          .clamp(_minColumnWidth, _maxColumnWidth);
      w[s.col] = math.max(w[s.col], want);
    }
    for (final c in spanned) {
      final s = _span(c);
      final want = c
          .getMaxIntrinsicWidth(double.infinity)
          .clamp(_minColumnWidth, _maxColumnWidth * s.colSpan);
      var have = 0.0;
      for (var i = s.col; i < s.col + s.colSpan; i++) {
        have += w[i];
      }
      if (want > have) {
        final extra = (want - have) / s.colSpan;
        for (var i = s.col; i < s.col + s.colSpan; i++) {
          w[i] += extra;
        }
      }
    }
    final total = w.fold<double>(0, (a, b) => a + b);
    if (minTotal.isFinite && total < minTotal && total > 0) {
      final k = minTotal / total;
      for (var i = 0; i < w.length; i++) {
        w[i] *= k;
      }
    }
    return w;
  }

  _Grid _grid(BoxConstraints constraints) {
    if (_rows == 0 || _columns == 0) return _Grid([0], [0]);
    final widths = _columnWidths(constraints.minWidth);
    final colX = [0.0];
    for (final w in widths) {
      colX.add(colX.last + w);
    }
    final h = List<double>.filled(_rows, 0);
    final spanned = <RenderBox>[];
    for (final c in _cells) {
      final s = _span(c);
      if (s.rowSpan > 1) {
        spanned.add(c);
        continue;
      }
      final cw = colX[s.col + s.colSpan] - colX[s.col];
      h[s.row] = math.max(h[s.row], c.getMinIntrinsicHeight(cw));
    }
    for (final c in spanned) {
      final s = _span(c);
      final cw = colX[s.col + s.colSpan] - colX[s.col];
      final want = c.getMinIntrinsicHeight(cw);
      var have = 0.0;
      for (var i = s.row; i < s.row + s.rowSpan; i++) {
        have += h[i];
      }
      if (want > have) {
        final extra = (want - have) / s.rowSpan;
        for (var i = s.row; i < s.row + s.rowSpan; i++) {
          h[i] += extra;
        }
      }
    }
    final rowY = [0.0];
    for (final v in h) {
      rowY.add(rowY.last + v);
    }
    return _Grid(colX, rowY);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final g = _grid(constraints);
    return constraints.constrain(Size(g.width, g.height));
  }

  @override
  void performLayout() {
    final g = _grid(constraints);
    final total = g.width;
    for (final c in _cells) {
      final s = _span(c);
      final x0 = g.colX[s.col], x1 = g.colX[s.col + s.colSpan];
      final y0 = g.rowY[s.row], y1 = g.rowY[s.row + s.rowSpan];
      c.layout(BoxConstraints.tight(Size(x1 - x0, y1 - y0)));
      final x = _textDirection == TextDirection.rtl ? total - x1 : x0;
      _data(c).offset = Offset(x, y0);
    }
    size = constraints.constrain(Size(g.width, g.height));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _columnWidths(0).fold<double>(0, (a, b) => a + b);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _grid(BoxConstraints(minWidth: width.isFinite ? width : 0)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    final paint = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
    // inner lines are centred on the shared edge (neighbours draw the same
    // line); outer lines are pulled inside the table's bounds
    final half = _borderWidth / 2;
    for (final c in _cells) {
      final o = _data(c).offset;
      final l = o.dx <= 0.5 ? half : 0.0;
      final t = o.dy <= 0.5 ? half : 0.0;
      final r = o.dx + c.size.width >= size.width - 0.5 ? half : 0.0;
      final b = o.dy + c.size.height >= size.height - 0.5 ? half : 0.0;
      context.canvas.drawRect(
        Rect.fromLTRB(
          offset.dx + o.dx + l,
          offset.dy + o.dy + t,
          offset.dx + o.dx + c.size.width - r,
          offset.dy + o.dy + c.size.height - b,
        ),
        paint,
      );
    }
  }
}
