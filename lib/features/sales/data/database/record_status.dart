/// Stored status of a sale or a payment; a cancelled one stays on the
/// device but no longer counts.
abstract final class RecordStatus {
  static const confirmed = 'CONFIRMED';
  static const cancelled = 'CANCELLED';
}
