import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';

void main() {
  group('database', _databaseTests);
  group('a sync while a page loads', _syncRaceTests);
}

void _databaseTests() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    // The customers screen watches the list; Riverpod pauses providers nobody listens to.
    container.listen(paginatedCustomerListProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  test('customers that arrive after the list was opened empty show up without a manual refresh', () async {
    final notifier = container.read(paginatedCustomerListProvider.notifier);
    await notifier.loadNextPage();
    expect(container.read(paginatedCustomerListProvider).customers, isEmpty);

    // A sync writes the driver's customers into the local database.
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(customerId: const drift.Value('c-1'), name: 'Hotel Altos de la Viña'),
        );
    await settle();

    expect(
      container.read(paginatedCustomerListProvider).customers.map((c) => c.name),
      ['Hotel Altos de la Viña'],
    );
  });

  test('a customer renamed by a pull is shown with its new name', () async {
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(customerId: const drift.Value('c-1'), name: 'Prueba'),
        );
    await container.read(paginatedCustomerListProvider.notifier).loadNextPage();
    await settle();

    await (db.update(db.customerTable)..where((t) => t.customerId.equals('c-1')))
        .write(const CustomerTableCompanion(name: drift.Value('Familia Gonzalez')));
    await settle();

    expect(
      container.read(paginatedCustomerListProvider).customers.map((c) => c.name),
      ['Familia Gonzalez'],
    );
  });
}

/// A page read the test answers when it wants, from the customers stored at
/// that moment: the database read lands before or after the sync's.
class _PageRead {
  _PageRead(this.page, this.pageSize);
  final int page;
  final int pageSize;
  final completer = Completer<List<Customer>>();
}

class _GatedCustomerRepository implements CustomerRepository {
  _GatedCustomerRepository(this.stored);

  List<Customer> stored;
  final reads = <_PageRead>[];
  final _changes = StreamController<List<Customer>>.broadcast();

  /// A sync writes the customers: the live query emits.
  void sync() => _changes.add(stored);

  void answer(_PageRead read) {
    final start = read.page * read.pageSize;
    read.completer.complete(stored.skip(start).take(read.pageSize).toList());
  }

  Future<void> close() => _changes.close();

  @override
  Stream<List<Customer>> watchAllCustomers() => _changes.stream;

  @override
  Future<List<Customer>> getCustomersPage({
    required int page,
    required int pageSize,
  }) {
    final read = _PageRead(page, pageSize);
    reads.add(read);
    return read.completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _syncRaceTests() {
  late _GatedCustomerRepository repository;
  late ProviderContainer container;

  Customer customer(int i) => Customer(
    id: 'c-${i.toString().padLeft(2, '0')}',
    name: 'Kiosco',
    addresses: const [],
    preferences: const [],
  );

  setUp(() {
    repository = _GatedCustomerRepository([
      for (var i = 1; i <= 45; i++) customer(i),
    ]);
    container = ProviderContainer(
      overrides: [customerRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(paginatedCustomerListProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  PaginatedCustomerList notifier() =>
      container.read(paginatedCustomerListProvider.notifier);

  List<String> shownIds() => [
    for (final c in container.read(paginatedCustomerListProvider).customers)
      c.id,
  ];

  /// Answers every read still waiting, oldest first.
  Future<void> answerPending() async {
    for (final read in [...repository.reads]) {
      if (!read.completer.isCompleted) repository.answer(read);
    }
    await settle();
  }

  /// Opens the list and scrolls until [pages] pages are shown.
  Future<void> scrollTo(int pages) async {
    for (var i = 0; i < pages; i++) {
      unawaited(notifier().loadNextPage());
      await settle();
      await answerPending();
    }
    expect(shownIds(), hasLength(pages * 10));
  }

  for (final loadedPages in [0, 2]) {
    for (final reloadLandsFirst in [true, false]) {
      final landing = reloadLandsFirst
          ? 'the reload lands first'
          : 'the page lands first';
      test('with $loadedPages pages shown, a sync during the next page shows '
          'every customer once and keeps the depth ($landing)', () async {
        await scrollTo(loadedPages);
        final readsBefore = repository.reads.length;

        // The driver scrolls (or opens the list) and a sync writes while
        // the page is on its way.
        unawaited(notifier().loadNextPage());
        await settle();
        repository.sync();
        await settle();

        final pending = repository.reads.skip(readsBefore).toList();
        final page = pending.first;
        final reloads = pending.skip(1).toList();
        if (reloadLandsFirst) {
          reloads.forEach(repository.answer);
          await settle();
          repository.answer(page);
        } else {
          repository.answer(page);
          await settle();
          reloads.forEach(repository.answer);
        }
        await settle();
        await answerPending();

        final ids = shownIds();
        expect(ids.toSet(), hasLength(ids.length), reason: 'duplicated customers');
        expect(ids, [
          for (final c in repository.stored.take((loadedPages + 1) * 10)) c.id,
        ]);
        expect(container.read(paginatedCustomerListProvider).isLoading, isFalse);
      });
    }
  }

  test('a page asked for after a sync started lands once the reload is '
      'shown, without repeating customers', () async {
    await scrollTo(1);

    repository.sync();
    await settle();
    // The screen asks for more while the reload is on its way.
    unawaited(notifier().loadNextPage());
    await settle();
    await answerPending();
    unawaited(notifier().loadNextPage());
    await settle();
    await answerPending();

    final ids = shownIds();
    expect(ids.toSet(), hasLength(ids.length), reason: 'duplicated customers');
    expect(ids, [for (final c in repository.stored.take(ids.length)) c.id]);
  });
}
