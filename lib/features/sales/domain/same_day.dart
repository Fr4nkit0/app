/// Whether [a] and [b] fall on the same local calendar day; sales and
/// payments can only be cancelled on the day they were made.
bool isSameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}
