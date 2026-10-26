import 'dart:math';

String formatNumber(int n) {
  final digits = n.abs().toString();
  final buffer = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String formatMoney(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  return '$sign\$${formatNumber(abs ~/ 100)}.${(abs % 100).toString().padLeft(2, '0')}';
}

String formatPhone(String digits) {
  if (digits.length != 10) return digits;
  return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
}

/// 6 → "6 AM", 24 → "12 AM".
String formatHour(int hour) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h ${hour % 24 < 12 ? 'AM' : 'PM'}';
}

String formatClock(DateTime time) {
  final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$h:${time.minute.toString().padLeft(2, '0')} ${time.hour < 12 ? 'AM' : 'PM'}';
}

const months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatDate(DateTime date) => '${months[date.month - 1]} ${date.day}, ${date.year}';

String relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return weekdays[date.weekday - 1];
  return '${months[date.month - 1]} ${date.day}';
}

String timeAgo(Duration age) {
  if (age.inMinutes < 60) return '${max(1, age.inMinutes)}m';
  if (age.inHours < 24) return '${age.inHours}h';
  if (age.inDays == 1) return '1d';
  return '${age.inDays}d';
}

String formatCountdown(Duration left) {
  if (left.isNegative) return '0:00';
  return '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
}

DateTime startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}
