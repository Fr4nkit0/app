import 'package:flutter/foundation.dart';

/// Record types the delivery driver can change offline.
enum PendingEntity {
  customer('customer'),
  routeStop('route_stop'),
  visit('visit'),
  containerMovement('container_movement'),
  sale('sale'),
  payment('payment'),
  customerAgreement('customer_agreement'),

  /// An address added or changed from the customer profile; the customer
  /// push still carries the primary address of a new or edited customer.
  customerAddress('customer_address'),

  /// A delivery preference added or changed from the wizard or the profile;
  /// the customer push does not carry preferences.
  customerPreference('customer_preference'),

  /// The cancellation of a sale; its entity id is the sale's id.
  saleCancellation('sale_cancellation'),

  /// The cancellation of a payment; its entity id is the payment's id.
  paymentCancellation('payment_cancellation');

  const PendingEntity(this.wireName);

  final String wireName;

  static PendingEntity fromWire(String value) =>
      values.firstWhere((e) => e.wireName == value);
}

enum PendingAction {
  insert('insert'),
  update('update'),
  delete('delete');

  const PendingAction(this.wireName);

  final String wireName;

  static PendingAction fromWire(String value) =>
      values.firstWhere((e) => e.wireName == value);
}

enum PendingStatus {
  pending('pending'),
  sent('sent'),
  rejected('rejected');

  const PendingStatus(this.wireName);

  final String wireName;

  static PendingStatus fromWire(String value) =>
      values.firstWhere((e) => e.wireName == value);
}

/// One local mutation waiting to reach (or already handled by) the server.
@immutable
class PendingChange {
  const PendingChange({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.action,
    required this.status,
    required this.createdAt,
    this.payload,
    this.rejectionReason,
  });

  /// Monotonic position in the queue; defines the order of creation.
  final int id;
  final PendingEntity entity;

  /// UUID of the changed record.
  final String entityId;
  final PendingAction action;
  final Map<String, dynamic>? payload;
  final PendingStatus status;
  final String? rejectionReason;
  final DateTime createdAt;

  /// Payload key of an edit listing the wire fields it changed, compared
  /// with the stored row before the write: `{'fields': ['phone_number']}`.
  /// A customer's address fields carry an `address.` prefix
  /// (`address.visual_reference`).
  static const changedFieldsKey = 'fields';

  /// The wire fields this edit changed, or null when they are unknown: an
  /// insert, or an edit queued by a version that did not record them. A
  /// record with unknown fields travels whole.
  Set<String>? get changedFields {
    if (action != PendingAction.update) return null;
    final fields = payload?[changedFieldsKey];
    return fields is List ? {for (final f in fields) f as String} : null;
  }

  /// The fields any of [changes] changed, or null when any of them is
  /// unknown.
  static Set<String>? changedFieldsOf(Iterable<PendingChange> changes) {
    final union = <String>{};
    for (final change in changes) {
      final fields = change.changedFields;
      if (fields == null) return null;
      union.addAll(fields);
    }
    return union;
  }
}
