import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static DateTime get today => _stripTime(DateTime.now());

  static DateTime _stripTime(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static bool isToday(DateTime date) => _stripTime(date) == today;

  static bool isYesterday(DateTime date) =>
      _stripTime(date) == today.subtract(const Duration(days: 1));

  static bool isTomorrow(DateTime date) =>
      _stripTime(date) == today.add(const Duration(days: 1));

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return _stripTime(dueDate).isBefore(today);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      _stripTime(a) == _stripTime(b);

  static String formatDate(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isYesterday(date)) return 'Yesterday';
    if (isTomorrow(date)) return 'Tomorrow';
    final now = DateTime.now();
    if (date.year == now.year) {
      return DateFormat('MMM d').format(date);
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) =>
      DateFormat('MMM d').format(date);

  static String formatDateFull(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);

  static String formatDayShort(DateTime date) =>
      DateFormat('EEE').format(date); // Mon, Tue...

  static String formatDayLetter(DateTime date) =>
      DateFormat('E').format(date).substring(0, 1); // M, T, W...

  static String formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  static String formatDurationFull(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return formatDate(dt);
  }

  /// Returns the last [n] days as a list, ending today.
  static List<DateTime> lastNDays(int n) {
    return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
  }

  static String toStorageKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static DateTime? fromStorageKey(String key) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(key);
    } catch (_) {
      return null;
    }
  }

  static String greetingForTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
