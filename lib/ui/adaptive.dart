import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';

/// Material window size classes by width.
///
/// * compact: phones, the iPhone Duo cover display (~466 pt);
/// * medium: the iPhone Duo unfolded in portrait (~626 pt), small tablets;
/// * expanded: the Duo unfolded in landscape (~890 pt), tablets.
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize of(double width) => width >= 840
      ? expanded
      : width >= 600
      ? medium
      : compact;

  bool get isCompact => this == compact;
  bool get atLeastMedium => this != compact;
}

/// A fold or hinge that splits the window into two areas (Android foldables
/// report these; a crease-free display such as the iPhone Duo's does not).
class Separator {
  const Separator(this.bounds, this.vertical);

  /// Bounds in window coordinates. Zero-width for a flat fold.
  final Rect bounds;

  /// True when the separator runs top to bottom (panes side by side).
  final bool vertical;

  static Separator? of(BuildContext context) {
    final mq = MediaQuery.of(context);
    for (final f in mq.displayFeatures) {
      final separating =
          f.type == DisplayFeatureType.hinge ||
          (f.type == DisplayFeatureType.fold &&
              f.state == DisplayFeatureState.postureHalfOpened);
      if (!separating) continue;
      return Separator(f.bounds, f.bounds.height >= f.bounds.width);
    }
    return null;
  }
}

/// Two panes side by side (or stacked), split at a hinge or fold when the
/// device has one, otherwise at a fraction the user can drag.
class AdaptiveSplit extends StatefulWidget {
  const AdaptiveSplit({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.initialFraction = 0.5,
    this.minPaneExtent = 220,
    this.resizable = true,
  });

  /// The start pane (right in right-to-left layouts) or the top pane.
  final Widget first;
  final Widget second;
  final Axis axis;
  final double initialFraction;
  final double minPaneExtent;

  /// Shows a drag handle between the panes; otherwise a hairline divider.
  final bool resizable;

  @override
  State<AdaptiveSplit> createState() => _AdaptiveSplitState();
}

class _AdaptiveSplitState extends State<AdaptiveSplit> {
  late double _fraction = widget.initialFraction;

  /// Where this split sits in the window, to place a hinge (window
  /// coordinates) inside it. Updated after each frame.
  Offset _origin = Offset.zero;

  void _trackOrigin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final o = box.localToGlobal(Offset.zero);
      if ((o - _origin).distance > 0.5) setState(() => _origin = o);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final horizontal = widget.axis == Axis.horizontal;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final separator = Separator.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final extent = horizontal ? box.maxWidth : box.maxHeight;

        // a hinge across this split decides the panes
        if (separator != null && separator.vertical == horizontal) {
          _trackOrigin();
          final b = separator.bounds.shift(-_origin);
          final start = horizontal ? b.left : b.top;
          final gap = horizontal ? b.width : b.height;
          if (start > 0 && start + gap < extent) {
            // in RTL the first pane sits on the right of the hinge
            final firstExtent = horizontal && rtl
                ? extent - start - gap
                : start;
            return Flex(
              direction: widget.axis,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: horizontal ? firstExtent : null,
                  height: horizontal ? null : firstExtent,
                  child: widget.first,
                ),
                SizedBox(
                  width: horizontal ? gap : null,
                  height: horizontal ? null : gap,
                ),
                Expanded(child: widget.second),
              ],
            );
          }
        }

        final min = (widget.minPaneExtent / extent).clamp(0.1, 0.45);
        final f = _fraction.clamp(min, 1 - min);
        final firstExtent = extent * f;
        return Flex(
          direction: widget.axis,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: horizontal ? firstExtent : null,
              height: horizontal ? null : firstExtent,
              child: widget.first,
            ),
            if (!widget.resizable)
              horizontal
                  ? VerticalDivider(width: 1, color: cs.outlineVariant)
                  : Divider(height: 1, color: cs.outlineVariant)
            else
              MouseRegion(
                cursor: horizontal
                    ? SystemMouseCursors.resizeLeftRight
                    : SystemMouseCursors.resizeUpDown,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: horizontal
                      ? (d) => setState(
                          () => _fraction +=
                              (rtl ? -d.delta.dx : d.delta.dx) / extent,
                        )
                      : null,
                  onVerticalDragUpdate: horizontal
                      ? null
                      : (d) => setState(() => _fraction += d.delta.dy / extent),
                  child: SizedBox(
                    width: horizontal ? 16 : null,
                    height: horizontal ? null : 16,
                    child: Center(
                      child: Container(
                        width: horizontal ? 4 : 40,
                        height: horizontal ? 40 : 4,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(child: widget.second),
          ],
        );
      },
    );
  }
}
