abstract class ClockService {
  DateTime now();
  DateTime nowUtc();
}

class SystemClockService implements ClockService {
  const SystemClockService();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

class FakeClockService implements ClockService {
  DateTime _current;

  FakeClockService(DateTime initialTime) : _current = initialTime;

  @override
  DateTime now() => _current;

  @override
  DateTime nowUtc() => _current.toUtc();

  void setTime(DateTime newTime) {
    _current = newTime;
  }

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}
