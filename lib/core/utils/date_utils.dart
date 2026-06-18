import 'package:intl/intl.dart';

abstract class AppDateUtils {
  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('MMM d, yyyy • HH:mm').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('HH:mm').format(date);

  static String formatShortDate(DateTime date) =>
      DateFormat('MMM d').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  static String daysAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  static DateTime startOf7Days() =>
      DateTime.now().subtract(const Duration(days: 7));

  static DateTime startOf30Days() =>
      DateTime.now().subtract(const Duration(days: 30));

  static String greetingByHour() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// The backend's `LocalDateTime` fields (e.g. visitDate with @Past) are
  /// timezone-naive and compared against the server's own UTC clock. Sending
  /// the device's local wall-clock value as-is makes "now" look like it's in
  /// the future for any timezone ahead of UTC (e.g. Rwanda, UTC+2) — this
  /// strips the offset by re-expressing the same instant as a UTC wall-clock
  /// value, with no 'Z' suffix, so it parses straight into LocalDateTime and
  /// compares correctly against the server's now().
  static DateTime nowForServer() {
    final utc = DateTime.now().toUtc();
    return DateTime(utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second, utc.millisecond);
  }
}
