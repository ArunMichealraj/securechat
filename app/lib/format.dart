import 'package:intl/intl.dart';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String formatClock(DateTime t) => DateFormat.jm().format(t);

/// Chat list style: "10:42 AM", "Yesterday", "12/09/26".
String formatChatTime(DateTime t, {DateTime? now}) {
  now ??= DateTime.now();
  if (_sameDay(t, now)) return formatClock(t);
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return DateFormat('dd/MM/yy').format(t);
}

/// Date chip between messages: "Today", "Yesterday", "12 September 2026".
String formatDayHeader(DateTime t, {DateTime? now}) {
  now ??= DateTime.now();
  if (_sameDay(t, now)) return 'Today';
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return DateFormat('d MMMM y').format(t);
}

String formatLastSeen(DateTime t, {DateTime? now}) {
  now ??= DateTime.now();
  if (_sameDay(t, now)) return 'last seen today at ${formatClock(t)}';
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) return 'last seen yesterday at ${formatClock(t)}';
  return 'last seen ${DateFormat('dd/MM/yy').format(t)}';
}

bool isSameDay(DateTime a, DateTime b) => _sameDay(a, b);
