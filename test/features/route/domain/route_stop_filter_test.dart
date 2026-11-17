import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/route_stop_filter.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

RouteStop _stop(
  String id,
  String name, {
  List<String?> neighborhoods = const [],
  StopStatus status = StopStatus.pending,
  int? number,
}) => RouteStop(
  id: id,
  customer: Customer(
    id: 'c-$id',
    name: name,
    number: number,
    addresses: [
      for (final (i, n) in neighborhoods.indexed)
        CustomerAddress(id: 'a-$id-$i', neighborhood: n),
    ],
    preferences: const [],
  ),
  status: status,
  scheduledAt: DateTime(2026, 11, 17, 9),
);

void main() {
  final stops = [
    _stop('1', 'Kiosco Norte', neighborhoods: ['Barrio Güemes']),
    _stop('2', 'Almacén Doña Rosa', neighborhoods: ['Centro']),
    _stop('3', 'Servicio Penitenciario', status: StopStatus.done),
    _stop(
      '4',
      'Panadería Centro',
      neighborhoods: ['centro ', 'Barrio Guemes'],
      status: StopStatus.absent,
    ),
  ];

  List<String> ids(RouteStopFilter filter) => [
    for (final s in filter.apply(stops)) s.id,
  ];

  test('no query, neighborhood or status keeps every stop and is not '
      'active', () {
    expect(RouteStopFilter.none.isActive, isFalse);
    expect(ids(RouteStopFilter.none), ['1', '2', '3', '4']);
    expect(const RouteStopFilter(query: '   ').isActive, isFalse);
  });

  group('query: customer name only', () {
    test('matches the start of a word, ignoring case and accents', () {
      expect(ids(const RouteStopFilter(query: 'almacen')), ['2']);
      expect(ids(const RouteStopFilter(query: 'ROSA')), ['2']);
    });

    test('does not match the neighborhood', () {
      expect(ids(const RouteStopFilter(query: 'guemes')), isEmpty);
    });

    test('a word inside another word does not match ("centro" vs '
        '"Penitenciario")', () {
      expect(ids(const RouteStopFilter(query: 'centro')), ['4']);
    });

    test('letters spread over several words do not match; letters in order '
        'inside one word only show when nothing matches better', () {
      final people = [
        _stop('a', 'Fernando Ruiz'),
        _stop('b', 'Franco Calisaya'),
        _stop('c', 'Mayorista Sur'),
      ];
      List<String> peopleIds(String q) => [
        for (final s in RouteStopFilter(query: q).apply(people)) s.id,
      ];
      expect(peopleIds('franco'), ['b']);
      expect(peopleIds('f'), ['a', 'b']);
      expect(peopleIds('myrst'), ['c']);
      expect(peopleIds('frnc'), ['b']);
    });

    test('every query word must match', () {
      expect(ids(const RouteStopFilter(query: 'kiosco norte')), ['1']);
      expect(ids(const RouteStopFilter(query: 'kiosco rosa')), isEmpty);
    });
  });

  group('query: customer number', () {
    final numbered = [
      _stop('1', 'Kiosco Norte', number: 128),
      _stop('2', 'Almacén 128', number: 12),
      _stop('3', 'Nuevo sin sincronizar'),
    ];
    List<String> numberedIds(String query) => [
      for (final s in RouteStopFilter(query: query).apply(numbered)) s.id,
    ];

    test('digits match the exact number, with or without "#", and still '
        'the name', () {
      expect(numberedIds('128'), ['1', '2']);
      expect(numberedIds('#12'), ['2']);
      expect(numberedIds('129'), isEmpty);
    });

    test('a customer not synced yet has no number: found by name only', () {
      expect(numberedIds('nuevo'), ['3']);
    });
  });

  group('neighborhood', () {
    test('keeps the stops with an address in it, ignoring case, accents '
        'and spaces', () {
      expect(ids(const RouteStopFilter(neighborhood: 'Barrio Güemes')), [
        '1',
        '4',
      ]);
      expect(ids(const RouteStopFilter(neighborhood: 'Centro')), ['2', '4']);
      expect(const RouteStopFilter(neighborhood: 'Centro').isActive, isTrue);
    });

    test('combines with the query and the status', () {
      expect(
        ids(const RouteStopFilter(query: 'panaderia', neighborhood: 'Centro')),
        ['4'],
      );
      expect(
        ids(
          const RouteStopFilter(
            neighborhood: 'Centro',
            status: StopStatus.pending,
          ),
        ),
        ['2'],
      );
    });
  });

  test('a status keeps only the stops in it', () {
    expect(ids(const RouteStopFilter(status: StopStatus.pending)), ['1', '2']);
    expect(const RouteStopFilter(status: StopStatus.done).isActive, isTrue);
  });

  test('clearing one part keeps the others', () {
    const filter = RouteStopFilter(
      query: 'kiosco',
      neighborhood: 'Centro',
      status: StopStatus.done,
    );
    expect(filter.withNeighborhood(null).neighborhood, isNull);
    expect(filter.withNeighborhood(null).query, 'kiosco');
    expect(filter.withStatus(null).neighborhood, 'Centro');
    expect(filter.withQuery('').status, StopStatus.done);
  });

  group('neighborhoodsOf', () {
    test('lists each neighborhood once, by name, with how many stops it '
        'has; blank ones are left out', () {
      final list = RouteNeighborhood.of([
        ...stops,
        _stop('5', 'Sin barrio', neighborhoods: ['  ', null]),
      ]);

      expect(
        [for (final n in list) (n.name, n.stopCount)],
        [('Barrio Güemes', 2), ('Centro', 2)],
      );
    });
  });
}
