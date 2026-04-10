class LogService {
  static final List<String> _logs = [];

  static void add(String log) {
    final time = DateTime.now().toIso8601String();
    _logs.add("$time  $log");
  }

  static List<String> getLogs() {
    return _logs.reversed.toList();
  }

  static void clear() {
    _logs.clear();
  }
}
