import 'package:drift/drift.dart';
import 'package:app/core/services/database_mixins.dart';

class AuditLogTable extends Table with Timestamps {
  @override
  String get tableName => 'audit_logs';

  late final auditLogId = text().clientDefault(() => uuid.v4())();
  late final tableNameColumn = text().named('table_name')();
  late final recordId = text()();
  late final action = text()(); // 'INSERT' | 'UPDATE' | 'DELETE'
  late final payload = text().nullable()(); // JSON payload of the changed record

  @override
  Set<Column<Object>> get primaryKey => {auditLogId};
}
