class ActiveSpan {
  const ActiveSpan(this.start, this.end, this.seconds);
  final DateTime start, end;
  final double seconds;
}

/// Monotonic time controls duration; UTC only assigns calendar timestamps.
/// Drains at most 120 seconds after the last user interaction. No background
/// duration is inferred from an attempt deadline or application restart.
class StudyClock {
  StudyClock({required this.utcNow, required this.monotonicNow}) {
    _cursor = _input = monotonicNow();
    _cursorUtc = utcNow().toUtc();
  }
  final DateTime Function() utcNow;
  final Duration Function() monotonicNow;
  late Duration _cursor, _input;
  late DateTime _cursorUtc;
  bool foreground = true;
  bool get idle => monotonicNow() - _input >= const Duration(seconds: 120);

  ActiveSpan? take() {
    final now = monotonicNow();
    final limit = _input + const Duration(seconds: 120);
    final end = now < limit ? now : limit;
    final delta = end - _cursor;
    final start = _cursorUtc;
    _cursor = now;
    _cursorUtc = utcNow().toUtc();
    if (!foreground || delta <= Duration.zero) return null;
    return ActiveSpan(start, start.add(delta), delta.inMicroseconds / 1000000);
  }

  void interact() {
    // The caller drains before resetting idle, so the idle gap cannot be counted.
    if (idle) {
      _cursor = monotonicNow();
      _cursorUtc = utcNow().toUtc();
    }
    _input = monotonicNow();
  }

  void setForeground(bool value) {
    foreground = value;
    _cursor = _input = monotonicNow();
    _cursorUtc = utcNow().toUtc();
  }
}
