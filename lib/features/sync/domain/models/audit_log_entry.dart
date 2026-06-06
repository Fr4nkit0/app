import 'package:flutter/foundation.dart';

@immutable
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    required this.createdAt,
    required this.synced,
    this.payload,
  });

  final String id;
  final String tableName;
  final String recordId;
  final String action; // 'INSERT' | 'UPDATE' | 'DELETE'
  final String? payload;
  final DateTime createdAt;

  // enabled = false in the DB means the log has been synced to the backend.
  final bool synced;
}
