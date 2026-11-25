import 'package:flutter/foundation.dart';

/// The skeletons (container code `ESQUELETO`) on the truck of today's
/// route: what the office loaded and what is left after the route's
/// deliveries and returns.
@immutable
class TruckSkeletons {
  const TruckSkeletons({
    required this.loaded,
    required this.remaining,
    required this.hasActivity,
  });

  /// Loads and corrections of the route added up.
  final int loaded;

  /// [loaded] minus what was delivered plus what came back on the route's
  /// visits. Below zero when more went out than was loaded: taking back is
  /// not capped.
  final int remaining;

  /// True when the route has skeleton loads or movements; without either
  /// there is nothing worth showing.
  final bool hasActivity;

  /// Whether delivering [delivered] while taking back [returned] leaves the
  /// truck below zero. Only a delivery runs short; it is a warning, never a
  /// limit.
  bool runsShort({required int delivered, required int returned}) =>
      delivered > 0 && remaining - delivered + returned < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TruckSkeletons &&
          other.loaded == loaded &&
          other.remaining == remaining &&
          other.hasActivity == hasActivity;

  @override
  int get hashCode => Object.hash(loaded, remaining, hasActivity);

  @override
  String toString() =>
      'TruckSkeletons(loaded: $loaded, remaining: $remaining, '
      'hasActivity: $hasActivity)';
}
