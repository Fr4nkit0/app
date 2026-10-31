import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/data/repositories/customer_preference.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/data/repositories/drift.customer_preference.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/create.customer.usecase.dart';
import 'package:app/features/customers/domain/usecases/disable_preference.usecase.dart';
import 'package:app/features/customers/domain/usecases/edit_preference.usecase.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Does the whole write, then fails before the unit of work commits.
class _FailingAfterWriteRepository extends DriftCustomerPreferenceRepository {
  _FailingAfterWriteRepository(super.db, {super.now});

  @override
  Future<String> add(String customerId, PreferenceDetails details) async {
    await super.add(customerId, details);
    throw Exception('disk full');
  }

  @override
  Future<void> edit(String preferenceId, PreferenceDetails details) async {
    await super.edit(preferenceId, details);
    throw Exception('disk full');
  }

  @override
  Future<void> enable(String preferenceId, PreferenceDetails details) async {
    await super.enable(preferenceId, details);
    throw Exception('disk full');
  }

  @override
  Future<void> disable(String preferenceId) async {
    await super.disable(preferenceId);
    throw Exception('disk full');
  }
}

void main() {
  late AppDatabase db;
  final longAgo = DateTime(2020, 1, 1);
  final now = DateTime(2026, 10, 29, 12);

  Future<void> preference(
    String id, {
    String customerId = 'cust-1',
    required int day,
    required String start,
    String? end,
    bool enabled = true,
    int? serverId,
  }) => db
      .into(db.customerPreferenceTable)
      .insert(
        CustomerPreferenceTableCompanion.insert(
          customerPreferenceId: Value(id),
          customerId: Value(customerId),
          dayOfWeek: Value(day),
          timeWindowStart: start,
          timeWindowEnd: Value(end),
          enabled: Value(enabled),
          serverId: Value(serverId),
          createdAt: Value(longAgo),
          lastModifiedDate: Value(longAgo),
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final id in ['cust-1', 'cust-2']) {
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: Value(id),
              name: 'Customer $id',
              lastModifiedDate: Value(longAgo),
            ),
          );
    }
    await preference('p-1', day: 1, start: '09:00', end: '12:00', serverId: 1);
    await preference('p-2', day: 4, start: '14:00', end: '17:00', serverId: 2);
    await preference(
      'p-off',
      day: 2,
      start: '10:00',
      end: '11:00',
      enabled: false,
      serverId: 3,
    );
    await preference('q-1', customerId: 'cust-2', day: 3, start: '09:00');
  });
  tearDown(() => db.close());

  CustomerPreferenceRepository repo() =>
      DriftCustomerPreferenceRepository(db, now: () => now);
  CustomerPreferenceRepository failing() =>
      _FailingAfterWriteRepository(db, now: () => now);

  AddPreferenceUseCase add([CustomerPreferenceRepository? r]) =>
      AddPreferenceUseCase(
        preferenceRepo: r ?? repo(),
        transaction: driftTransactionRunner(db),
      );
  EditPreferenceUseCase edit([CustomerPreferenceRepository? r]) =>
      EditPreferenceUseCase(
        preferenceRepo: r ?? repo(),
        transaction: driftTransactionRunner(db),
      );
  DisablePreferenceUseCase disable([CustomerPreferenceRepository? r]) =>
      DisablePreferenceUseCase(
        preferenceRepo: r ?? repo(),
        transaction: driftTransactionRunner(db),
      );

  Future<CustomerPreferenceTableData> row(String id) => (db.select(
    db.customerPreferenceTable,
  )..where((t) => t.customerPreferenceId.equals(id))).getSingle();

  Future<List<PendingChangeTableData>> queued() => (db.select(
    db.pendingChangeTable,
  )..orderBy([(t) => OrderingTerm.asc(t.pendingChangeId)])).get();

  Future<List<CustomerPreferenceTableData>> snapshot() => (db.select(
    db.customerPreferenceTable,
  )..orderBy([(t) => OrderingTerm.asc(t.customerPreferenceId)])).get();

  Future<void> expectNothingChanged(
    List<CustomerPreferenceTableData> before,
  ) async {
    expect(await snapshot(), before);
    expect(await queued(), isEmpty);
  }

  Matcher refusedWith(String message) => throwsA(
    isA<ValidationFailure>().having((f) => f.message, 'message', message),
  );

  const endBeforeStart = 'La hora de fin debe ser posterior a la de inicio.';
  const taken = 'El cliente ya tiene una preferencia para ese día y horario.';

  /// Every way the server refuses the window itself.
  final invalid = <String, (PreferenceDetails, String)>{
    'an end before the start': (
      const PreferenceDetails(dayOfWeek: 5, start: '12:00', end: '09:00'),
      endBeforeStart,
    ),
    'an end equal to the start': (
      const PreferenceDetails(dayOfWeek: 5, start: '12:00', end: '12:00'),
      endBeforeStart,
    ),
    'a day outside 0-6': (
      const PreferenceDetails(dayOfWeek: 7, start: '09:00', end: '12:00'),
      'Elegí un día de la semana.',
    ),
    'a start that is not a time': (
      const PreferenceDetails(dayOfWeek: 5, start: '9h', end: '12:00'),
      'Elegí la hora de inicio.',
    ),
  };

  group('AddPreferenceUseCase', () {
    test('adds an enabled preference dated now with H:i times and queues one '
        'customer_preference insert', () async {
      final id = await add().execute(
        customerId: 'cust-1',
        details: const PreferenceDetails(
          dayOfWeek: 5,
          start: '9:30',
          end: '12:00:00',
        ),
      );

      final added = await row(id);
      expect(added.customerId, 'cust-1');
      expect(added.dayOfWeek, 5);
      expect(added.timeWindowStart, '09:30');
      expect(added.timeWindowEnd, '12:00');
      expect(added.enabled, isTrue);
      expect(added.serverId, isNull);
      expect(added.lastModifiedDate, now);

      final change = (await queued()).single;
      expect(change.entity, PendingEntity.customerPreference.wireName);
      expect(change.entityId, id);
      expect(change.action, PendingAction.insert.wireName);
    });

    test('takes a preference without an end', () async {
      final id = await add().execute(
        customerId: 'cust-1',
        details: const PreferenceDetails(dayOfWeek: 6, start: '09:00'),
      );

      expect((await row(id)).timeWindowEnd, isNull);
    });

    test('the same day and start of another customer is free', () async {
      final id = await add().execute(
        customerId: 'cust-1',
        details: const PreferenceDetails(dayOfWeek: 3, start: '09:00'),
      );

      expect((await row(id)).customerId, 'cust-1');
    });

    test('refuses a day and start the customer already has enabled', () async {
      final before = await snapshot();

      await expectLater(
        add().execute(
          customerId: 'cust-1',
          details: const PreferenceDetails(
            dayOfWeek: 1,
            start: '09:00:00',
            end: '13:00',
          ),
        ),
        refusedWith(taken),
      );
      await expectNothingChanged(before);
    });

    test('re-enables the disabled preference of the same day and start '
        'instead of adding one', () async {
      final id = await add().execute(
        customerId: 'cust-1',
        details: const PreferenceDetails(
          dayOfWeek: 2,
          start: '10:00',
          end: '12:30',
        ),
      );

      expect(id, 'p-off');
      final enabled = await row('p-off');
      expect(enabled.enabled, isTrue);
      expect(enabled.timeWindowEnd, '12:30');
      expect(enabled.serverId, 3);
      expect(enabled.lastModifiedDate, now);
      expect(await snapshot(), hasLength(4));

      final change = (await queued()).single;
      expect(change.entity, PendingEntity.customerPreference.wireName);
      expect(change.entityId, 'p-off');
      expect(change.action, PendingAction.update.wireName);
    });

    for (final MapEntry(key: name, value: (details, message))
        in invalid.entries) {
      test('refuses $name and stores nothing', () async {
        final before = await snapshot();

        await expectLater(
          add().execute(customerId: 'cust-1', details: details),
          refusedWith(message),
        );
        await expectNothingChanged(before);
      });
    }

    test('a missing customer throws a NotFoundFailure', () async {
      final before = await snapshot();

      await expectLater(
        add().execute(
          customerId: 'ghost',
          details: const PreferenceDetails(dayOfWeek: 5, start: '09:00'),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectNothingChanged(before);
    });

    test('a failure mid-way stores nothing', () async {
      final before = await snapshot();

      await expectLater(
        add(failing()).execute(
          customerId: 'cust-1',
          details: const PreferenceDetails(dayOfWeek: 5, start: '09:00'),
        ),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
    });

    test('a failure mid-way while re-enabling keeps it disabled', () async {
      final before = await snapshot();

      await expectLater(
        add(failing()).execute(
          customerId: 'cust-1',
          details: const PreferenceDetails(dayOfWeek: 2, start: '10:00'),
        ),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
    });
  });

  group('EditPreferenceUseCase', () {
    test('replaces the day and window, keeps the server id and queues one '
        'update', () async {
      await edit().execute(
        preferenceId: 'p-1',
        details: const PreferenceDetails(
          dayOfWeek: 5,
          start: '10:00',
          end: '13:00',
        ),
      );

      final edited = await row('p-1');
      expect(edited.dayOfWeek, 5);
      expect(edited.timeWindowStart, '10:00');
      expect(edited.timeWindowEnd, '13:00');
      expect(edited.enabled, isTrue);
      expect(edited.serverId, 1);
      expect(edited.lastModifiedDate, now);

      final change = (await queued()).single;
      expect(change.entity, PendingEntity.customerPreference.wireName);
      expect(change.entityId, 'p-1');
      expect(change.action, PendingAction.update.wireName);
    });

    test('keeping its own day and start is not a duplicate', () async {
      await edit().execute(
        preferenceId: 'p-1',
        details: const PreferenceDetails(
          dayOfWeek: 1,
          start: '09:00',
          end: '11:00',
        ),
      );

      expect((await row('p-1')).timeWindowEnd, '11:00');
    });

    for (final (name, other) in [
      ('another enabled', (4, '14:00')),
      ('a disabled', (2, '10:00')),
    ]) {
      test('refuses the day and start of $name preference', () async {
        final before = await snapshot();

        await expectLater(
          edit().execute(
            preferenceId: 'p-1',
            details: PreferenceDetails(dayOfWeek: other.$1, start: other.$2),
          ),
          refusedWith(taken),
        );
        await expectNothingChanged(before);
      });
    }

    for (final MapEntry(key: name, value: (details, message))
        in invalid.entries) {
      test('refuses $name and changes nothing', () async {
        final before = await snapshot();

        await expectLater(
          edit().execute(preferenceId: 'p-1', details: details),
          refusedWith(message),
        );
        await expectNothingChanged(before);
      });
    }

    for (final id in ['ghost', 'p-off']) {
      test('a missing or disabled preference ($id) throws a '
          'NotFoundFailure', () async {
        final before = await snapshot();

        await expectLater(
          edit().execute(
            preferenceId: id,
            details: const PreferenceDetails(dayOfWeek: 5, start: '09:00'),
          ),
          throwsA(isA<NotFoundFailure>()),
        );
        await expectNothingChanged(before);
      });
    }

    test('a failure mid-way changes nothing', () async {
      final before = await snapshot();

      await expectLater(
        edit(failing()).execute(
          preferenceId: 'p-1',
          details: const PreferenceDetails(dayOfWeek: 5, start: '09:00'),
        ),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
    });
  });

  group('DisablePreferenceUseCase', () {
    test('disables the preference, keeps its window and queues one '
        'update', () async {
      await disable().execute('p-2');

      final disabled = await row('p-2');
      expect(disabled.enabled, isFalse);
      expect(disabled.dayOfWeek, 4);
      expect(disabled.timeWindowStart, '14:00');
      expect(disabled.lastModifiedDate, now);

      final change = (await queued()).single;
      expect(change.entity, PendingEntity.customerPreference.wireName);
      expect(change.entityId, 'p-2');
      expect(change.action, PendingAction.update.wireName);
      expect(change.payload, contains('enabled'));
    });

    test('drops it from the enabled list, ordered by day', () async {
      await disable().execute('p-2');

      expect(
        [for (final p in await repo().watchForCustomer('cust-1').first) p.id],
        ['p-1'],
      );
    });

    for (final id in ['ghost', 'p-off']) {
      test('a missing or disabled preference ($id) throws a '
          'NotFoundFailure', () async {
        final before = await snapshot();

        await expectLater(
          disable().execute(id),
          throwsA(isA<NotFoundFailure>()),
        );
        await expectNothingChanged(before);
      });
    }

    test('a failure mid-way keeps it enabled', () async {
      final before = await snapshot();

      await expectLater(
        disable(failing()).execute('p-2'),
        throwsA(isA<StorageFailure>()),
      );
      await expectNothingChanged(before);
    });
  });

  group('S2 overlapping windows', () {
    Future<void> expectRefused(
      Future<void> Function() write,
      String message,
    ) async {
      final before = await snapshot();
      final queueBefore = await queued();

      await expectLater(write(), refusedWith(message));
      expect(await snapshot(), before);
      expect(await queued(), queueBefore);
    }

    Future<String> addTo(String customerId, PreferenceDetails details) =>
        add().execute(customerId: customerId, details: details);

    test('the audit windows: 08:30-13:00 is stored, 12:00-13:00 and '
        '12:30-13:30 are refused naming it', () async {
      final id = await addTo(
        'cust-2',
        const PreferenceDetails(dayOfWeek: 1, start: '08:30', end: '13:00'),
      );
      expect((await row(id)).timeWindowEnd, '13:00');

      for (final (start, end) in [('12:00', '13:00'), ('12:30', '13:30')]) {
        await expectRefused(
          () => addTo(
            'cust-2',
            PreferenceDetails(dayOfWeek: 1, start: start, end: end),
          ),
          'Se superpone con 08:30–13:00.',
        );
      }
    });

    test('names a pulled HH:mm:ss window as HH:mm', () async {
      await preference(
        'q-2',
        customerId: 'cust-2',
        day: 1,
        start: '08:30:00',
        end: '13:00:00',
      );

      await expectRefused(
        () => addTo(
          'cust-2',
          const PreferenceDetails(dayOfWeek: 1, start: '12:00', end: '14:00'),
        ),
        'Se superpone con 08:30–13:00.',
      );
    });

    test('touching edges do not overlap', () async {
      for (final (start, end) in [
        ('12:00', '13:00'),
        ('13:00', '14:00'),
        ('11:00', '12:00'),
      ]) {
        await addTo(
          'cust-1',
          PreferenceDetails(dayOfWeek: 5, start: start, end: end),
        );
      }

      expect(
        [
          for (final p in await repo().watchForCustomer('cust-1').first)
            if (p.dayOfWeek == 5) (p.timeWindowStart, p.timeWindowEnd),
        ],
        [('11:00', '12:00'), ('12:00', '13:00'), ('13:00', '14:00')],
      );
    });

    test('an existing start-only window takes the rest of the day', () async {
      await preference('s-1', day: 6, start: '12:30');

      await expectRefused(
        () => addTo(
          'cust-1',
          const PreferenceDetails(dayOfWeek: 6, start: '14:00', end: '15:00'),
        ),
        'Se superpone con desde 12:30.',
      );
      final id = await addTo(
        'cust-1',
        const PreferenceDetails(dayOfWeek: 6, start: '10:00', end: '12:30'),
      );
      expect((await row(id)).timeWindowStart, '10:00');
    });

    test('a new start-only window is refused by a later window', () async {
      await expectRefused(
        () => addTo(
          'cust-1',
          const PreferenceDetails(dayOfWeek: 1, start: '08:00'),
        ),
        'Se superpone con 09:00–12:00.',
      );
    });

    test('the same range on another day or customer is free', () async {
      final other = await addTo(
        'cust-1',
        const PreferenceDetails(dayOfWeek: 0, start: '09:00', end: '12:00'),
      );
      final otherCustomer = await addTo(
        'cust-2',
        const PreferenceDetails(dayOfWeek: 1, start: '10:00', end: '11:00'),
      );

      expect((await row(other)).dayOfWeek, 0);
      expect((await row(otherCustomer)).customerId, 'cust-2');
    });

    test('a disabled preference never blocks by overlap', () async {
      final id = await addTo(
        'cust-1',
        const PreferenceDetails(dayOfWeek: 2, start: '10:30', end: '11:30'),
      );

      expect((await row(id)).enabled, isTrue);
      expect((await row('p-off')).enabled, isFalse);
    });

    test('re-enabling a disabled slot is refused when it overlaps an enabled '
        'window', () async {
      await preference('p-3', day: 2, start: '10:30', end: '12:00');

      await expectRefused(
        () => addTo(
          'cust-1',
          const PreferenceDetails(dayOfWeek: 2, start: '10:00', end: '11:00'),
        ),
        'Se superpone con 10:30–12:00.',
      );
    });

    test('a taken slot is refused as taken before any overlap', () async {
      await expectRefused(
        () => addTo(
          'cust-1',
          const PreferenceDetails(dayOfWeek: 1, start: '09:00', end: '10:00'),
        ),
        taken,
      );
    });

    test('an edit overlapping another preference is refused', () async {
      await expectRefused(
        () => edit().execute(
          preferenceId: 'p-1',
          details: const PreferenceDetails(
            dayOfWeek: 4,
            start: '13:00',
            end: '15:00',
          ),
        ),
        'Se superpone con 14:00–17:00.',
      );
    });

    for (final (name, start, end) in [
      ('its own range', '09:00', '12:00'),
      ('a narrower range', '10:00', '11:00'),
      ('a wider range', '08:00', '13:00'),
    ]) {
      test('an edit onto $name only overlaps itself', () async {
        await edit().execute(
          preferenceId: 'p-1',
          details: PreferenceDetails(dayOfWeek: 1, start: start, end: end),
        );

        final edited = await row('p-1');
        expect((edited.timeWindowStart, edited.timeWindowEnd), (start, end));
      });
    }

    test('an edit overlapping a disabled preference is saved', () async {
      await edit().execute(
        preferenceId: 'p-1',
        details: const PreferenceDetails(
          dayOfWeek: 2,
          start: '10:30',
          end: '12:00',
        ),
      );

      expect((await row('p-1')).dayOfWeek, 2);
    });
  });

  test('the enabled list is ordered by day, then start', () async {
    await add().execute(
      customerId: 'cust-1',
      details: const PreferenceDetails(
        dayOfWeek: 1,
        start: '08:00',
        end: '09:00',
      ),
    );

    expect(
      [
        for (final p in await repo().watchForCustomer('cust-1').first)
          (p.dayOfWeek, p.timeWindowStart),
      ],
      [(1, '08:00'), (1, '09:00'), (4, '14:00')],
    );
  });

  group('new customer wizard', () {
    CreateCustomerUseCase create() => CreateCustomerUseCase(
      customerRepository: DriftCustomerRepository(db),
      transaction: driftTransactionRunner(db),
    );

    Customer customer(List<CustomerPreference> preferences) => Customer(
      id: 'cust-new',
      name: 'Nuevo',
      addresses: [CustomerAddress(id: 'addr-new', street: 'Mitre 50')],
      preferences: preferences,
    );

    test('queues one customer_preference insert per preference, after the '
        'customer', () async {
      await create().execute(
        customer([
          CustomerPreference(
            id: 'np-1',
            dayOfWeek: 1,
            timeWindowStart: '09:00',
            timeWindowEnd: '12:00',
          ),
          CustomerPreference(
            id: 'np-2',
            dayOfWeek: 3,
            timeWindowStart: '14:00',
            timeWindowEnd: '17:00',
          ),
        ]),
      );

      final changes = await queued();
      expect(
        [for (final c in changes) (c.entity, c.entityId, c.action)],
        [
          (PendingEntity.customer.wireName, 'cust-new', 'insert'),
          (PendingEntity.customerPreference.wireName, 'np-1', 'insert'),
          (PendingEntity.customerPreference.wireName, 'np-2', 'insert'),
        ],
      );
      expect((await row('np-2')).customerId, 'cust-new');
    });

    test('refuses two preferences on the same day and start and stores '
        'nothing', () async {
      final before = await snapshot();

      await expectLater(
        create().execute(
          customer([
            CustomerPreference(
              id: 'np-1',
              dayOfWeek: 1,
              timeWindowStart: '09:00',
            ),
            CustomerPreference(
              id: 'np-2',
              dayOfWeek: 1,
              timeWindowStart: '09:00',
              timeWindowEnd: '10:00',
            ),
          ]),
        ),
        refusedWith(taken),
      );
      await expectNothingChanged(before);
      expect(
        await (db.select(
          db.customerTable,
        )..where((t) => t.customerId.equals('cust-new'))).get(),
        isEmpty,
      );
    });

    test('refuses a preference ending before it starts', () async {
      await expectLater(
        create().execute(
          customer([
            CustomerPreference(
              id: 'np-1',
              dayOfWeek: 1,
              timeWindowStart: '12:00',
              timeWindowEnd: '09:00',
            ),
          ]),
        ),
        refusedWith(endBeforeStart),
      );
      expect(await queued(), isEmpty);
    });
  });
}
