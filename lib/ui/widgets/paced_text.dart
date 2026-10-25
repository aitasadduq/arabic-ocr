import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Shows streamed text at its average rate. The model writes in bursts (it
/// pauses to look at each strip of the page), so revealing text at a steady
/// pace, a little behind the model, makes the page flow without stops.
///
/// Time is measured with a wall clock: the ticker only runs while there is
/// text left to reveal, and restarting a ticker restarts its own clock.
class PacedText extends ChangeNotifier {
  PacedText(TickerProvider vsync, {Stopwatch? clock})
    : _clock = clock ?? Stopwatch() {
    _ticker = vsync.createTicker((_) => tick());
  }

  late final Ticker _ticker;
  final Stopwatch _clock;
  String _target = '';
  double _shown = 0;
  bool _finished = false;
  int _lastMicros = 0;

  String get text => _target.substring(0, _cut(_shown.floor()));
  bool get caughtUp => _shown >= _target.length;

  /// Starts over (another page).
  void reset() {
    _target = '';
    _shown = 0;
    _finished = false;
    _clock
      ..stop()
      ..reset();
    _ticker.stop();
    notifyListeners();
  }

  /// Feeds the full text written so far.
  void update(String target, {required bool finished}) {
    if (!target.startsWith(_target) && !_target.startsWith(target)) {
      // the text was replaced (cleaned up at the end, or edited): show it all
      _shown = target.length.toDouble();
    }
    _target = target;
    _shown = math.min(_shown, target.length.toDouble());
    _finished = finished;
    if (target.isNotEmpty && !_clock.isRunning) _clock.start();
    if (!caughtUp && !_ticker.isActive) {
      _lastMicros = _clock.elapsedMicroseconds;
      _ticker.start();
    }
    notifyListeners();
  }

  /// Shows everything at once.
  void flush() {
    _shown = _target.length.toDouble();
    _ticker.stop();
    notifyListeners();
  }

  /// One frame of reveal; public for tests.
  @visibleForTesting
  void tick() {
    final now = _clock.elapsedMicroseconds;
    final dt = math.max(0, now - _lastMicros) / 1e6;
    _lastMicros = now;
    final total = _target.length.toDouble();
    final since = math.max(now / 1e6, 0.5);
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
    if (caughtUp) _ticker.stop();
  }

  /// Never cut a surrogate pair in half.
  int _cut(int n) {
    if (n <= 0) return 0;
    if (n >= _target.length) return _target.length;
    final u = _target.codeUnitAt(n - 1);
    return (u >= 0xD800 && u <= 0xDBFF) ? n + 1 : n;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
