/// Containers delivered per container code by sale lines: the quantity of
/// each line whose product comes in a returnable container. Types with
/// nothing delivered are omitted.
Map<String, int> deliveredByContainerType(
  Iterable<({String? containerType, int quantity})> items,
) {
  final delivered = <String, int>{};
  for (final item in items) {
    final code = item.containerType;
    if (code == null || item.quantity <= 0) continue;
    delivered[code] = (delivered[code] ?? 0) + item.quantity;
  }
  return delivered;
}
