import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerAgreementsProvider = StreamProvider.autoDispose
    .family<List<CustomerAgreement>, String>(
      (ref, customerId) => ref
          .watch(driftCustomerAgreementRepositoryProvider)
          .watchForCustomer(customerId),
    );
