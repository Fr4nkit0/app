import 'package:flutter/foundation.dart';

import 'package:app/core/utils/string_utils.dart';
import 'package:app/features/customers/domain/customer_search.dart';
import 'package:app/features/customers/domain/models/customer_number.dart';
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
  /// in [neighborhood], and the query is the customer's number (`128` or
  /// `#128`) or every query word begins a word of the customer's name.
  /// Case, accents and spacing are ignored.
  bool matches(RouteStop stop) => _matches(stop, looseName: false);

  bool _matches(RouteStop stop, {required bool looseName}) {
    if (status != null && stop.status != status) return false;
    final wanted = neighborhood;
    if (wanted != null &&
        !stop.customer.addresses.any(
          (a) => neighborhoodKey(a.neighborhood) == neighborhoodKey(wanted),
        )) {
      return false;
    }
    if (query.trim().isEmpty) return true;
    if (CustomerNumber.matches(query, stop.customer.number)) return true;
    if (CustomerNumber.isExplicit(query)) return false;
    final name = CustomerSearch.matchName(query, stop.customer.name);
    return name == CustomerMatch.name ||
        (looseName && name == CustomerMatch.loose);
  }

  /// The stops of [stops] that pass, in their order.
  /// A name with the query's letters in order inside one of its words
  /// ("mao" in "Mayo") only shows when no stop matches better.
  List<RouteStop> apply(List<RouteStop> stops) {
    if (!isActive) return stops;
    final strong = stops.where(matches).toList();
    if (strong.isNotEmpty || query.trim().isEmpty) return strong;
    return stops.where((s) => _matches(s, looseName: true)).toList();
  }

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
