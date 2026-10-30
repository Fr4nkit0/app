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
}
