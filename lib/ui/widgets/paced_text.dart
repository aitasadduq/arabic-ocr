import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Shows streamed text at its average rate. The model writes in bursts (it
/// pauses to look at each strip of the page), so revealing text at a steady
/// pace, a little behind the model, makes the page flow without stops.
class PacedText extends ChangeNotifier {
  PacedText(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  String _target = '';
  double _shown = 0;
  bool _finished = false;
  Duration _started = Duration.zero;
  Duration _last = Duration.zero;
  bool _hasStart = false;

  String get text => _target.substring(0, _cut(_shown.floor()));
  bool get caughtUp => _shown >= _target.length;

  /// Feeds the full text written so far.
  void update(String target, {required bool finished}) {
    if (!target.startsWith(
      _target.substring(0, math.min(_target.length, target.length)),
    )) {
      // a different page or an edit: start over
      _shown = 0;
      _hasStart = false;
    }
    _target = target;
    _finished = finished;
    if (finished && _shown == 0) _shown = target.length.toDouble();
    if (!_ticker.isActive && !caughtUp) _ticker.start();
    if (caughtUp) notifyListeners();
  }

  /// Shows everything at once.
  void flush() {
    _shown = _target.length.toDouble();
    _ticker.stop();
    notifyListeners();
  }

  void _tick(Duration elapsed) {
    if (!_hasStart) {
      _started = elapsed;
      _last = elapsed;
      _hasStart = true;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final total = _target.length.toDouble();
    final since = math.max((elapsed - _started).inMicroseconds / 1e6, 0.5);
    var rate = math.max(total / since * 0.95, 30.0);
    final backlog = total - _shown;
    if (_finished) {
      rate = math.max(rate, backlog / 0.4);
    } else if (backlog > rate * 5) {
      rate *= 1.6;
    }
    final before = _shown.floor();
    _shown = math.min(total, _shown + rate * dt);
    if (_shown.floor() != before) notifyListeners();
    if (caughtUp && _finished) _ticker.stop();
    if (caughtUp && !_finished) _ticker.stop();
  }

  /// Never cut a surrogate pair in half.
  int _cut(int n) {
    if (n <= 0 || n >= _target.length) return n.clamp(0, _target.length);
    final u = _target.codeUnitAt(n - 1);
    return (u >= 0xD800 && u <= 0xDBFF) ? n + 1 : n;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
