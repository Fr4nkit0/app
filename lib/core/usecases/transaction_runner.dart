/// Runs [action] atomically; the data layer provides it (a Drift
/// transaction), so every write of one use case lands, and is queued,
/// together or not at all.
typedef TransactionRunner = Future<T> Function<T>(Future<T> Function() action);
