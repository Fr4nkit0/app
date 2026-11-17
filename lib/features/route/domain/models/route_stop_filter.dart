import 'package:flutter/foundation.dart';

import 'package:app/core/utils/string_utils.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

/// What the driver narrows the day's route to: a text matched against the
/// customer's name, one neighborhood and one stop status. Each part is
/// optional and they combine.
@immutable
class RouteStopFilter {
  const RouteStopFilter({this.query = '', this.neighborhood, this.status});

  static const none = RouteStopFilter();

  final String query;

  /// Only stops with an address in this neighborhood; null keeps all.
  final String? neighborhood;

  /// Only stops in this status; null keeps every status.
  final StopStatus? status;

  /// Whether the filter leaves any stop out.
  bool get isActive =>
      query.trim().isNotEmpty || neighborhood != null || status != null;

  RouteStopFilter withQuery(String value) =>
      RouteStopFilter(query: value, neighborhood: neighborhood, status: status);

  RouteStopFilter withNeighborhood(String? value) =>
      RouteStopFilter(query: query, neighborhood: value, status: status);

  RouteStopFilter withStatus(StopStatus? value) =>
      RouteStopFilter(query: query, neighborhood: neighborhood, status: value);

  /// Whether [stop] passes: its status is [status], one of its addresses is
  /// in [neighborhood], and every query word starts a word of the
  /// customer's name. Case, accents and spacing are ignored.
  bool matches(RouteStop stop) {
    if (status != null && stop.status != status) return false;
    final wanted = neighborhood;
    if (wanted != null &&
        !stop.customer.addresses.any(
          (a) => neighborhoodKey(a.neighborhood) == neighborhoodKey(wanted),
        )) {
      return false;
    }
    if (query.trim().isEmpty) return true;
    return StringUtils.wordStartMatch(query, stop.customer.name);
  }

  /// The stops of [stops] that pass, in their order.
  List<RouteStop> apply(List<RouteStop> stops) =>
      isActive ? stops.where(matches).toList() : stops;

  /// The comparable form of a neighborhood name; empty for none.
  static String neighborhoodKey(String? name) => name == null
      ? ''
      : StringUtils.removeDiacritics(name).replaceAll(RegExp(r'\s+'), ' ');

  @override
  bool operator ==(Object other) =>
      other is RouteStopFilter &&
      other.query == query &&
      other.neighborhood == neighborhood &&
      other.status == status;

  @override
  int get hashCode => Object.hash(query, neighborhood, status);
}

/// A neighborhood of the day's route and how many stops it holds.
@immutable
class RouteNeighborhood {
  const RouteNeighborhood(this.name, this.stopCount);

  final String name;
  final int stopCount;

  /// Each neighborhood of [stops] once (spelled as it first appears),
  /// ordered by name, counting a stop once even when several of its
  /// addresses are in it. Blank neighborhoods are left out.
  static List<RouteNeighborhood> of(List<RouteStop> stops) {
    final names = <String, String>{};
    final counts = <String, int>{};
    for (final stop in stops) {
      final keys = <String>{};
      for (final address in stop.customer.addresses) {
        final key = RouteStopFilter.neighborhoodKey(address.neighborhood);
        if (key.isEmpty || !keys.add(key)) continue;
        names.putIfAbsent(key, () => address.neighborhood!.trim());
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final keys = names.keys.toList()..sort();
    return [for (final k in keys) RouteNeighborhood(names[k]!, counts[k]!)];
  }
}
