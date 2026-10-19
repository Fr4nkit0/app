const _monthLabels = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String historySectionLabelForDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Hoy';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
  return '${day.day} ${_monthLabels[day.month - 1]}';
}

int historyDayKey(DateTime date) {
  return DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
}
