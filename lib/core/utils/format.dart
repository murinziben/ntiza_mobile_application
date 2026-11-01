/// 45000 -> "45,000"
String formatNumber(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

String formatRwf(int value) => 'RWF ${formatNumber(value)}';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "24 June"
String formatDayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "24 June 2026"
String formatFullDate(DateTime d) => '${formatDayMonth(d)} ${d.year}';

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}
