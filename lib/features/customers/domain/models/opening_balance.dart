import 'package:flutter/foundation.dart';

/// What a customer already owes and holds when the driver signs them up:
/// the debt they carry and the containers on loan, by catalog code.
@immutable
class OpeningBalance {
  const OpeningBalance({this.debt = 0, this.containers = const {}});

  /// Nothing to carry over.
  static const none = OpeningBalance();

  /// Money owed in whole pesos (positive: the customer owes).
  final int debt;

  /// Containers the customer holds, by catalog code.
  final Map<String, int> containers;

  /// Whether there is nothing above zero to record.
  bool get isEmpty => debt == 0 && containers.values.every((c) => c == 0);
}
