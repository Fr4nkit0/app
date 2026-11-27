import 'package:uuid/uuid.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/balance_corrections/data/repositories/balance_correction.repository.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/balance_corrections/domain/usecases/correct_balance.usecase.dart';
import 'package:app/features/customers/domain/models/address_details.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/opening_balance.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/data/repositories/customer.repository.dart';

String _uuidV4() => const Uuid().v4();

class CreateCustomerUseCase {
  final CustomerRepository _customerRepository;
  final TransactionRunner _transaction;
  final BalanceCorrectionRepository? _balanceCorrections;
  final DateTime Function() _now;
  final String Function() _newId;

  /// [balanceCorrections] is only needed to sign a customer up with an
  /// [OpeningBalance].
  CreateCustomerUseCase({
    required CustomerRepository customerRepository,
    required TransactionRunner transaction,
    BalanceCorrectionRepository? balanceCorrections,
    DateTime Function() now = DateTime.now,
    String Function() newId = _uuidV4,
  }) : _customerRepository = customerRepository,
       _transaction = transaction,
       _balanceCorrections = balanceCorrections,
       _now = now,
       _newId = newId;

  /// Reason of the corrections that carry an [OpeningBalance] over.
  static const openingBalanceReason = 'Saldo inicial al dar de alta';
  static const negativeOpeningDebt = 'La deuda inicial no puede ser negativa.';

  /// Stores [customer] with its addresses, preferences and pending changes
  /// in one unit of work and returns it as stored: address fields trimmed
  /// (blank ones as null) and, when none is marked, the first address as the
  /// primary. Throws [ValidationFailure] without a name, an address or a
  /// preference, and for preferences the server would refuse: a window
  /// ending before it starts, or two on the same day and start.
  ///
  /// The [opening] debt and containers on loan above zero are recorded in
  /// the same unit of work as balance corrections of the new customer (seen
  /// balance 0), queued after it so one push carries both. Throws
  /// [ValidationFailure] for a negative debt or a container count that is
  /// not a whole number >= 0.
  Future<Customer> execute(
    Customer customer, {
    OpeningBalance opening = OpeningBalance.none,
  }) async {
    if (customer.name.isEmpty) {
      throw const ValidationFailure('El nombre es requerido');
    }
    if (customer.addresses.isEmpty) {
      throw const ValidationFailure('Debe existir al menos una dirección');
    }
    if (customer.preferences.isEmpty) {
      throw const ValidationFailure('Debe existir al menos una preferencia');
    }
    final windows = <PreferenceDetails>[];
    for (final p in customer.preferences) {
      final window = PreferenceDetails(
        dayOfWeek: p.dayOfWeek,
        start: p.timeWindowStart,
        end: p.timeWindowEnd,
      ).normalized()..validate();
      if (windows.any((w) => w.sameSlot(window.dayOfWeek, window.start))) {
        throw const ValidationFailure(AddPreferenceUseCase.slotTaken);
      }
      windows.add(window);
    }
    _validate(opening);

    final stored = Customer(
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      addresses: _withPrimary(customer.addresses.map(_trimmed).toList()),
      preferences: customer.preferences,
    );
    final corrections = _openingCorrections(stored.id, opening);
    final repo = _balanceCorrections;
    if (corrections.isNotEmpty && repo == null) {
      throw StateError('An opening balance needs balanceCorrections.');
    }
    await _transaction(() async {
      await _customerRepository.saveCustomer(stored);
      for (final correction in corrections) {
        await repo!.record(correction);
      }
    });
    return stored;
  }

  static void _validate(OpeningBalance opening) {
    if (opening.debt < 0) {
      throw const ValidationFailure(negativeOpeningDebt);
    }
    for (final MapEntry(key: code, value: count)
        in opening.containers.entries) {
      if (code.isEmpty) {
        throw const ValidationFailure(
          CorrectBalanceUseCase.missingContainerType,
        );
      }
      if (count < 0) {
        throw const ValidationFailure(CorrectBalanceUseCase.invalidContainers);
      }
    }
  }

  /// A new customer shows nothing yet, so each correction moves its balance
  /// from 0 to what the driver typed.
  List<BalanceCorrection> _openingCorrections(
    String customerId,
    OpeningBalance opening,
  ) {
    if (opening.isEmpty) return const [];
    final at = _now();
    BalanceCorrection correction(
      BalanceTarget target,
      int counted, [
      String? containerType,
    ]) => BalanceCorrection(
      id: _newId(),
      customerId: customerId,
      target: target,
      containerType: containerType,
      counted: counted,
      seenBalance: 0,
      reason: openingBalanceReason,
      correctedAt: at,
    );
    return [
      if (opening.debt > 0) correction(BalanceTarget.debt, opening.debt),
      for (final MapEntry(key: code, value: count)
          in opening.containers.entries)
        if (count > 0) correction(BalanceTarget.containers, count, code),
    ];
  }

  /// Blank fields become null, so this builds the address whole instead of
  /// through [CustomerAddress.copyWith].
  static CustomerAddress _trimmed(CustomerAddress a) {
    final clean = AddressDetails(
      street: a.street,
      neighborhood: a.neighborhood,
      apartment: a.apartment,
      floor: a.floor,
      visualReference: a.visualReference,
    ).trimmed();
    return CustomerAddress(
      id: a.id,
      street: clean.street,
      neighborhood: clean.neighborhood,
      apartment: clean.apartment,
      floor: clean.floor,
      visualReference: clean.visualReference,
      isPrimary: a.isPrimary,
      latitude: a.latitude,
      longitude: a.longitude,
    );
  }

  /// A customer keeps exactly one primary address from the start, so the
  /// device shows it before the server confirms it.
  static List<CustomerAddress> _withPrimary(List<CustomerAddress> addresses) {
    if (addresses.any((a) => a.isPrimary)) return addresses;
    return [addresses.first.copyWith(isPrimary: true), ...addresses.skip(1)];
  }
}
