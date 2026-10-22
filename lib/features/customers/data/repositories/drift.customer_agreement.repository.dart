import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class DriftCustomerAgreementRepository implements CustomerAgreementRepository {
  DriftCustomerAgreementRepository(this.db)
    : _queue = DriftPendingChangeRepository(db);

  final AppDatabase db;
  final PendingChangeRepository _queue;

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _statusOrder = {
    AgreementStatus.inForce: 0,
    AgreementStatus.future: 1,
    AgreementStatus.ended: 2,
  };

  @override
  Stream<List<CustomerAgreement>> watchForCustomer(
    String customerId, {
    DateTime? today,
  }) {
    final query = db.select(db.customerAgreementTable).join([
      innerJoin(
        db.productTable,
        db.productTable.productId.equalsExp(db.customerAgreementTable.productId),
      ),
    ])..where(
        db.customerAgreementTable.customerId.equals(customerId) &
            db.customerAgreementTable.enabled.equals(true),
      );
    return query.watch().map((rows) {
      final day = _dateOnly(today ?? DateTime.now());
      final list = [
        for (final r in rows)
          () {
            final a = r.readTable(db.customerAgreementTable);
            return CustomerAgreement(
              id: a.agreementId,
              productId: a.productId,
              productName: r.readTable(db.productTable).name,
              unitPrice: a.unitPrice,
              validFrom: a.validFrom.substring(0, 10),
              validTo: a.validTo?.substring(0, 10),
              reason: a.reason,
              status: CustomerAgreement.statusOn(day, a.validFrom, a.validTo),
              isSynced: a.serverId != null,
            );
          }(),
      ];
      list.sort((a, b) {
        final byStatus = _statusOrder[a.status]!.compareTo(_statusOrder[b.status]!);
        return byStatus != 0 ? byStatus : b.validFrom.compareTo(a.validFrom);
      });
      return list;
    });
  }

  @override
  Future<Resource<String>> create({
    required String customerId,
    required String productId,
    required double unitPrice,
    required String validFrom,
    String? validTo,
    String? reason,
  }) async {
    final trimmed = reason?.trim();
    final cleanReason = trimmed == null || trimmed.isEmpty ? null : trimmed;
    if (unitPrice <= 0) {
      return Resource.error(Exception('El precio debe ser mayor a 0.'));
    }
    // The server keeps two decimals and rejects more, which would strand the
    // agreement in the queue while it already prices sales here.
    if ((unitPrice * 100).roundToDouble() / 100 != unitPrice) {
      return Resource.error(Exception('El precio admite hasta 2 decimales.'));
    }
    if (validTo != null && validTo.compareTo(validFrom) < 0) {
      return Resource.error(
        Exception('La fecha de fin no puede ser anterior al inicio.'),
      );
    }
    if (cleanReason != null &&
        cleanReason.length > CustomerAgreementRepository.maxReasonLength) {
      return Resource.error(
        Exception(
          'El motivo admite hasta ${CustomerAgreementRepository.maxReasonLength} caracteres.',
        ),
      );
    }
    try {
      final id = const Uuid().v4();
      await db.transaction(() async {
        await db.into(db.customerAgreementTable).insert(
              CustomerAgreementTableCompanion.insert(
                agreementId: Value(id),
                customerId: customerId,
                productId: productId,
                unitPrice: unitPrice,
                validFrom: validFrom,
                validTo: Value(validTo),
                reason: Value(cleanReason),
              ),
            );
        await _queue.enqueue(
          entity: PendingEntity.customerAgreement,
          entityId: id,
          action: PendingAction.insert,
          payload: {
            'agreementId': id,
            'customerId': customerId,
            'productId': productId,
            'unitPrice': unitPrice,
            'validFrom': validFrom,
            'validTo': validTo,
            'reason': cleanReason,
          },
        );
      });
      return Resource.success(id);
    } catch (e) {
      return Resource.error(e is Exception ? e : Exception(e.toString()));
    }
  }
}

final driftCustomerAgreementRepositoryProvider =
    Provider<CustomerAgreementRepository>(
      (ref) => DriftCustomerAgreementRepository(ref.watch(databaseProvider)),
    );
